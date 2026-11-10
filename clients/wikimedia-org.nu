# Auto-generated client for Wikimedia v1.0.0
# Source: https://api.apis.guru/v2/specs/wikimedia.org/1.0.0/swagger.json
# Auth: --token flag or $env.WIKIMEDIA_TOKEN

const BASE_URL = "https://wikimedia.org/api/rest_v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o WIKIMEDIA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "cookie" => { {scheme: $scheme, headers: {"cookie": $token_val}, query: "", location: "header"} }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://wikimedia.org/api/rest_v1"] }
def auth-scheme-completer [] { ["cookie"] }

# Completers for enum parameters
def accept-completer [] { ["application/json; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/Availability/1.0.1\"" "application/problem+json"] }
def type-completer [] { ["chem" "inline-tex" "tex"] }
def accept-completer-1 [] { ["application/json" "application/problem+json"] }
def format-completer [] { ["mml" "png" "svg"] }
def accept-completer-2 [] { ["application/mathml+xml" "application/problem+json" "image/png" "image/svg+xml"] }
def editor-type-completer [] { ["all-editor-types" "anonymous" "group-bot" "name-bot" "user"] }
def page-type-completer [] { ["all-page-types" "content" "non-content"] }
def granularity-completer [] { ["daily" "monthly"] }
def activity-level-completer [] { ["1..4-edits" "100..-edits" "25..99-edits" "5..24-edits" "all-activity-levels"] }
def access-site-completer [] { ["all-sites" "desktop-site" "mobile-site"] }
def granularity-completer-1 [] { ["daily" "hourly" "monthly"] }
def access-completer [] { ["all-access" "desktop" "mobile-app" "mobile-web"] }
def agent-completer [] { ["all-agents" "spider" "user"] }
def agent-completer-1 [] { ["all-agents" "bot" "spider" "user"] }
def provider-completer [] { ["Apertium" "Yandex" "Youdao"] }
def tool-completer [] { ["dictionary" "mt"] }
def provider-completer-1 [] { ["Dictd" "JsonDict"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-feed-availability" "post-media-math-check-type" "get-media-math-formula-hash" "get-media-math-render-format-hash" "get-metrics-bytes-difference-absolute-aggregate-project-editor-type-page-type-granularity-start-end" "get-metrics-bytes-difference-absolute-per-page-project-page-title-editor-type-granularity-start-end" "get-metrics-bytes-difference-net-aggregate-project-editor-type-page-type-granularity-start-end" "get-metrics-bytes-difference-net-per-page-project-page-title-editor-type-granularity-start-end" "get-metrics-edited-pages-aggregate-project-editor-type-page-type-activity-level-granularity-start-end" "get-metrics-edited-pages-new-project-editor-type-page-type-granularity-start-end" "get-metrics-edited-pages-top-by-absolute-bytes-difference-project-editor-type-page-type-year-month-day" "get-metrics-edited-pages-top-by-edits-project-editor-type-page-type-year-month-day" "get-metrics-edited-pages-top-by-net-bytes-difference-project-editor-type-page-type-year-month-day" "get-metrics-editors-aggregate-project-editor-type-page-type-activity-level-granularity-start-end" "get-metrics-editors-top-by-absolute-bytes-difference-project-editor-type-page-type-year-month-day" "get-metrics-editors-top-by-edits-project-editor-type-page-type-year-month-day" "get-metrics-editors-top-by-net-bytes-difference-project-editor-type-page-type-year-month-day" "get-metrics-edits-aggregate-project-editor-type-page-type-granularity-start-end" "get-metrics-edits-per-page-project-page-title-editor-type-granularity-start-end" "get-metrics-legacy-pagecounts-aggregate-project-access-site-granularity-start-end" "get-metrics-pageviews-aggregate-project-access-agent-granularity-start-end" "get-metrics-pageviews-per-article-project-access-agent-article-granularity-start-end" "get-metrics-pageviews-top-by-country-project-access-year-month" "get-metrics-pageviews-top-project-access-year-month-day" "get-metrics-registered-users-new-project-granularity-start-end" "get-metrics-unique-devices-project-access-site-granularity-start-end" "post-transform-html-from-from-lang-to-to-lang" "post-transform-html-from-from-lang-to-to-lang-provider" "get-transform-list-languagepairs" "get-transform-list-pair-from-to" "get-transform-list-tool-tool" "get-transform-list-tool-tool-from" "get-transform-list-tool-tool-from-to" "get-transform-word-from-from-lang-to-to-lang-word" "get-transform-word-from-from-lang-to-to-lang-word-provider" "commands"] | sort) } | get name | first)
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

# Gets availability of featured feed content for the apps by wiki domain.
#
# GET /feed/availability
export def "get-feed-availability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record<in_the_news: list<string>, most_read: list<string>, on_this_day: list<string>, picture_of_the_day: list<string>, todays_featured_article: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/feed/availability" $auth.query)
  let accept_val = ($accept | default "application/json; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/Availability/1.0.1\"")
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

# Check and normalize a TeX formula.
#
# POST /media/math/check/{type}
export def "post-media-math-check-type" [
  type: string@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  q: string # The formula to check
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/media/math/check/{type}") $auth.query)
  let req_body = {"q": $q} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get a previously-stored formula
#
# GET /media/math/formula/{hash}
export def "get-media-math-formula-hash" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($hash | is-empty) { error make --unspanned { msg: "path parameter 'hash' must be non-empty" } }
  let full_url = (build-url $base ({hash: (encode-path-segment $hash)} | format pattern "/media/math/formula/{hash}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get rendered formula in the given format.
#
# GET /media/math/render/{format}/{hash}
export def "get-media-math-render-format-hash" [
  format: string@format-completer
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($hash | is-empty) { error make --unspanned { msg: "path parameter 'hash' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), hash: (encode-path-segment $hash)} | format pattern "/media/math/render/{format}/{hash}") $auth.query)
  let accept_val = ($accept | default "image/svg+xml")
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

# Get the sum of absolute value of text bytes difference between current edit and previous one.
#
# GET /metrics/bytes-difference/absolute/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
export def "get-metrics-bytes-difference-absolute-aggregate-project-editor-type-page-type-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/bytes-difference/absolute/aggregate/{project}/{editor_type}/{page_type}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get the sum of absolute text bytes difference per page.
#
# GET /metrics/bytes-difference/absolute/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}
export def "get-metrics-bytes-difference-absolute-per-page-project-page-title-editor-type-granularity-start-end" [
  project: string
  page_title: string
  editor_type: string@editor-type-completer
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_title: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($page_title | is-empty) { error make --unspanned { msg: "path parameter 'page-title' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), page_title: (encode-path-segment $page_title), editor_type: (encode-path-segment $editor_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/bytes-difference/absolute/per-page/{project}/{page_title}/{editor_type}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get the sum of net text bytes difference between current edit and previous one.
#
# GET /metrics/bytes-difference/net/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
export def "get-metrics-bytes-difference-net-aggregate-project-editor-type-page-type-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/bytes-difference/net/aggregate/{project}/{editor_type}/{page_type}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get the sum of net text bytes difference per page.
#
# GET /metrics/bytes-difference/net/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}
export def "get-metrics-bytes-difference-net-per-page-project-page-title-editor-type-granularity-start-end" [
  project: string
  page_title: string
  editor_type: string@editor-type-completer
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_title: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($page_title | is-empty) { error make --unspanned { msg: "path parameter 'page-title' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), page_title: (encode-path-segment $page_title), editor_type: (encode-path-segment $editor_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/bytes-difference/net/per-page/{project}/{page_title}/{editor_type}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get edited-pages counts for a project.
#
# GET /metrics/edited-pages/aggregate/{project}/{editor-type}/{page-type}/{activity-level}/{granularity}/{start}/{end}
export def "get-metrics-edited-pages-aggregate-project-editor-type-page-type-activity-level-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  activity_level: string@activity-level-completer
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<activity_level: string, editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($activity_level | is-empty) { error make --unspanned { msg: "path parameter 'activity-level' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), activity_level: (encode-path-segment $activity_level), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/edited-pages/aggregate/{project}/{editor_type}/{page_type}/{activity_level}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get new pages counts for a project.
#
# GET /metrics/edited-pages/new/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
export def "get-metrics-edited-pages-new-project-editor-type-page-type-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/edited-pages/new/{project}/{editor_type}/{page_type}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get top 100 edited-pages by absolute bytes-difference.
#
# GET /metrics/edited-pages/top-by-absolute-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "get-metrics-edited-pages-top-by-absolute-bytes-difference-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($month | is-empty) { error make --unspanned { msg: "path parameter 'month' must be non-empty" } }
  if ($day | is-empty) { error make --unspanned { msg: "path parameter 'day' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/edited-pages/top-by-absolute-bytes-difference/{project}/{editor_type}/{page_type}/{year}/{month}/{day}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get top 100 edited-pages by edits count.
#
# GET /metrics/edited-pages/top-by-edits/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "get-metrics-edited-pages-top-by-edits-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($month | is-empty) { error make --unspanned { msg: "path parameter 'month' must be non-empty" } }
  if ($day | is-empty) { error make --unspanned { msg: "path parameter 'day' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/edited-pages/top-by-edits/{project}/{editor_type}/{page_type}/{year}/{month}/{day}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get top 100 edited-pages by net bytes-difference.
#
# GET /metrics/edited-pages/top-by-net-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "get-metrics-edited-pages-top-by-net-bytes-difference-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($month | is-empty) { error make --unspanned { msg: "path parameter 'month' must be non-empty" } }
  if ($day | is-empty) { error make --unspanned { msg: "path parameter 'day' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/edited-pages/top-by-net-bytes-difference/{project}/{editor_type}/{page_type}/{year}/{month}/{day}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get editors counts for a project.
#
# GET /metrics/editors/aggregate/{project}/{editor-type}/{page-type}/{activity-level}/{granularity}/{start}/{end}
export def "get-metrics-editors-aggregate-project-editor-type-page-type-activity-level-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  activity_level: string@activity-level-completer
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<activity_level: string, editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($activity_level | is-empty) { error make --unspanned { msg: "path parameter 'activity-level' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), activity_level: (encode-path-segment $activity_level), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/editors/aggregate/{project}/{editor_type}/{page_type}/{activity_level}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get top 100 editors by absolute bytes-difference.
#
# GET /metrics/editors/top-by-absolute-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "get-metrics-editors-top-by-absolute-bytes-difference-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($month | is-empty) { error make --unspanned { msg: "path parameter 'month' must be non-empty" } }
  if ($day | is-empty) { error make --unspanned { msg: "path parameter 'day' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/editors/top-by-absolute-bytes-difference/{project}/{editor_type}/{page_type}/{year}/{month}/{day}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get top 100 editors by edits count.
#
# GET /metrics/editors/top-by-edits/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "get-metrics-editors-top-by-edits-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($month | is-empty) { error make --unspanned { msg: "path parameter 'month' must be non-empty" } }
  if ($day | is-empty) { error make --unspanned { msg: "path parameter 'day' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/editors/top-by-edits/{project}/{editor_type}/{page_type}/{year}/{month}/{day}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get top 100 editors by net bytes-difference.
#
# GET /metrics/editors/top-by-net-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "get-metrics-editors-top-by-net-bytes-difference-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($month | is-empty) { error make --unspanned { msg: "path parameter 'month' must be non-empty" } }
  if ($day | is-empty) { error make --unspanned { msg: "path parameter 'day' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/editors/top-by-net-bytes-difference/{project}/{editor_type}/{page_type}/{year}/{month}/{day}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get edits counts for a project.
#
# GET /metrics/edits/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
export def "get-metrics-edits-aggregate-project-editor-type-page-type-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($page_type | is-empty) { error make --unspanned { msg: "path parameter 'page-type' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/edits/aggregate/{project}/{editor_type}/{page_type}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get edit counts for a page in a project.
#
# GET /metrics/edits/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}
export def "get-metrics-edits-per-page-project-page-title-editor-type-granularity-start-end" [
  project: string
  page_title: string
  editor_type: string@editor-type-completer
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<editor_type: string, granularity: string, page_title: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($page_title | is-empty) { error make --unspanned { msg: "path parameter 'page-title' must be non-empty" } }
  if ($editor_type | is-empty) { error make --unspanned { msg: "path parameter 'editor-type' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), page_title: (encode-path-segment $page_title), editor_type: (encode-path-segment $editor_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/edits/per-page/{project}/{page_title}/{editor_type}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Given a project and a date range, returns a timeseries of pagecounts. You can filter by access site (mobile or desktop) and you can choose between monthly, daily and hourly granularity as well. - Stability: [experimental](https://www.mediawiki.org/wiki/API_versioning#Experimental) - Rate limit: 100 req/s - License: Data accessible via this endpoint is available under the [CC0 1.0 license](https://creativecommons.org/publicdomain/zero/1.0/).
#
# GET /metrics/legacy/pagecounts/aggregate/{project}/{access-site}/{granularity}/{start}/{end}
export def "get-metrics-legacy-pagecounts-aggregate-project-access-site-granularity-start-end" [
  project: string
  access_site: string@access-site-completer
  granularity: string@granularity-completer-1
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<access_site: string, count: int, granularity: string, project: string, timestamp: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($access_site | is-empty) { error make --unspanned { msg: "path parameter 'access-site' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), access_site: (encode-path-segment $access_site), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/legacy/pagecounts/aggregate/{project}/{access_site}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get pageview counts for a project.
#
# GET /metrics/pageviews/aggregate/{project}/{access}/{agent}/{granularity}/{start}/{end}
export def "get-metrics-pageviews-aggregate-project-access-agent-granularity-start-end" [
  project: string
  access: string@access-completer
  agent: string@agent-completer
  granularity: string@granularity-completer-1
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<access: string, agent: string, granularity: string, project: string, timestamp: string, views: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($access | is-empty) { error make --unspanned { msg: "path parameter 'access' must be non-empty" } }
  if ($agent | is-empty) { error make --unspanned { msg: "path parameter 'agent' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), access: (encode-path-segment $access), agent: (encode-path-segment $agent), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/pageviews/aggregate/{project}/{access}/{agent}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get pageview counts for a page.
#
# GET /metrics/pageviews/per-article/{project}/{access}/{agent}/{article}/{granularity}/{start}/{end}
export def "get-metrics-pageviews-per-article-project-access-agent-article-granularity-start-end" [
  project: string
  access: string@access-completer
  agent: string@agent-completer-1
  article: string
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<access: string, agent: string, article: string, granularity: string, project: string, timestamp: string, views: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($access | is-empty) { error make --unspanned { msg: "path parameter 'access' must be non-empty" } }
  if ($agent | is-empty) { error make --unspanned { msg: "path parameter 'agent' must be non-empty" } }
  if ($article | is-empty) { error make --unspanned { msg: "path parameter 'article' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), access: (encode-path-segment $access), agent: (encode-path-segment $agent), article: (encode-path-segment $article), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/pageviews/per-article/{project}/{access}/{agent}/{article}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get pageviews by country and access method.
#
# GET /metrics/pageviews/top-by-country/{project}/{access}/{year}/{month}
export def "get-metrics-pageviews-top-by-country-project-access-year-month" [
  project: string
  access: string@access-completer
  year: string
  month: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<access: string, countries: list, month: string, project: string, year: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($access | is-empty) { error make --unspanned { msg: "path parameter 'access' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($month | is-empty) { error make --unspanned { msg: "path parameter 'month' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), access: (encode-path-segment $access), year: (encode-path-segment $year), month: (encode-path-segment $month)} | format pattern "/metrics/pageviews/top-by-country/{project}/{access}/{year}/{month}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get the most viewed articles for a project.
#
# GET /metrics/pageviews/top/{project}/{access}/{year}/{month}/{day}
export def "get-metrics-pageviews-top-project-access-year-month-day" [
  project: string
  access: string@access-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<access: string, articles: list, day: string, month: string, project: string, year: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($access | is-empty) { error make --unspanned { msg: "path parameter 'access' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($month | is-empty) { error make --unspanned { msg: "path parameter 'month' must be non-empty" } }
  if ($day | is-empty) { error make --unspanned { msg: "path parameter 'day' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), access: (encode-path-segment $access), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/pageviews/top/{project}/{access}/{year}/{month}/{day}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get newly registered users counts for a project.
#
# GET /metrics/registered-users/new/{project}/{granularity}/{start}/{end}
export def "get-metrics-registered-users-new-project-granularity-start-end" [
  project: string
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<granularity: string, project: string, results: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/registered-users/new/{project}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get unique devices count per project
#
# GET /metrics/unique-devices/{project}/{access-site}/{granularity}/{start}/{end}
export def "get-metrics-unique-devices-project-access-site-granularity-start-end" [
  project: string
  access_site: string@access-site-completer
  granularity: string@granularity-completer
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<items: table<access_site: string, devices: int, granularity: string, project: string, timestamp: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($access_site | is-empty) { error make --unspanned { msg: "path parameter 'access-site' must be non-empty" } }
  if ($granularity | is-empty) { error make --unspanned { msg: "path parameter 'granularity' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($end | is-empty) { error make --unspanned { msg: "path parameter 'end' must be non-empty" } }
  let full_url = (build-url $base ({project: (encode-path-segment $project), access_site: (encode-path-segment $access_site), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/unique-devices/{project}/{access_site}/{granularity}/{start}/{end}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Machine-translate content
#
# POST /transform/html/from/{from_lang}/to/{to_lang}
export def "post-transform-html-from-from-lang-to-to-lang" [
  from_lang: string
  to_lang: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  html: string # The HTML content to translate
]: any -> oneof<record<contents: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($from_lang | is-empty) { error make --unspanned { msg: "path parameter 'from_lang' must be non-empty" } }
  if ($to_lang | is-empty) { error make --unspanned { msg: "path parameter 'to_lang' must be non-empty" } }
  let full_url = (build-url $base ({from_lang: (encode-path-segment $from_lang), to_lang: (encode-path-segment $to_lang)} | format pattern "/transform/html/from/{from_lang}/to/{to_lang}") $auth.query)
  let req_body = {"html": $html} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Machine-translate content
#
# POST /transform/html/from/{from_lang}/to/{to_lang}/{provider}
export def "post-transform-html-from-from-lang-to-to-lang-provider" [
  from_lang: string
  to_lang: string
  provider: string@provider-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  html: string # The HTML content to translate
]: any -> oneof<record<contents: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($from_lang | is-empty) { error make --unspanned { msg: "path parameter 'from_lang' must be non-empty" } }
  if ($to_lang | is-empty) { error make --unspanned { msg: "path parameter 'to_lang' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({from_lang: (encode-path-segment $from_lang), to_lang: (encode-path-segment $to_lang), provider: (encode-path-segment $provider)} | format pattern "/transform/html/from/{from_lang}/to/{to_lang}/{provider}") $auth.query)
  let req_body = {"html": $html} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Lists the language pairs supported by the back-end
#
# GET /transform/list/languagepairs/
export def "get-transform-list-languagepairs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<source: list<string>, target: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transform/list/languagepairs/" $auth.query)
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

# Lists the tools available for a language pair
#
# GET /transform/list/pair/{from}/{to}/
export def "get-transform-list-pair-from-to" [
  from: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<tools: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($from | is-empty) { error make --unspanned { msg: "path parameter 'from' must be non-empty" } }
  if ($to | is-empty) { error make --unspanned { msg: "path parameter 'to' must be non-empty" } }
  let full_url = (build-url $base ({from: (encode-path-segment $from), to: (encode-path-segment $to)} | format pattern "/transform/list/pair/{from}/{to}/") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Lists the tools and language pairs available for the given tool category
#
# GET /transform/list/tool/{tool}
export def "get-transform-list-tool-tool" [
  tool: string@tool-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($tool | is-empty) { error make --unspanned { msg: "path parameter 'tool' must be non-empty" } }
  let full_url = (build-url $base ({tool: (encode-path-segment $tool)} | format pattern "/transform/list/tool/{tool}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Lists the tools and language pairs available for the given tool category
#
# GET /transform/list/tool/{tool}/{from}
export def "get-transform-list-tool-tool-from" [
  tool: string@tool-completer
  from: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($tool | is-empty) { error make --unspanned { msg: "path parameter 'tool' must be non-empty" } }
  if ($from | is-empty) { error make --unspanned { msg: "path parameter 'from' must be non-empty" } }
  let full_url = (build-url $base ({tool: (encode-path-segment $tool), from: (encode-path-segment $from)} | format pattern "/transform/list/tool/{tool}/{from}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Lists the tools and language pairs available for the given tool category
#
# GET /transform/list/tool/{tool}/{from}/{to}
export def "get-transform-list-tool-tool-from-to" [
  tool: string@tool-completer
  from: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($tool | is-empty) { error make --unspanned { msg: "path parameter 'tool' must be non-empty" } }
  if ($from | is-empty) { error make --unspanned { msg: "path parameter 'from' must be non-empty" } }
  if ($to | is-empty) { error make --unspanned { msg: "path parameter 'to' must be non-empty" } }
  let full_url = (build-url $base ({tool: (encode-path-segment $tool), from: (encode-path-segment $from), to: (encode-path-segment $to)} | format pattern "/transform/list/tool/{tool}/{from}/{to}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Fetch the dictionary meaning of a word
#
# GET /transform/word/from/{from_lang}/to/{to_lang}/{word}
export def "get-transform-word-from-from-lang-to-to-lang-word" [
  from_lang: string
  to_lang: string
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<source: string, translations: table<info: string, phrase: string, sources: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($from_lang | is-empty) { error make --unspanned { msg: "path parameter 'from_lang' must be non-empty" } }
  if ($to_lang | is-empty) { error make --unspanned { msg: "path parameter 'to_lang' must be non-empty" } }
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let full_url = (build-url $base ({from_lang: (encode-path-segment $from_lang), to_lang: (encode-path-segment $to_lang), word: (encode-path-segment $word)} | format pattern "/transform/word/from/{from_lang}/to/{to_lang}/{word}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Fetch the dictionary meaning of a word
#
# GET /transform/word/from/{from_lang}/to/{to_lang}/{word}/{provider}
export def "get-transform-word-from-from-lang-to-to-lang-word-provider" [
  from_lang: string
  to_lang: string
  word: string
  provider: string@provider-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record<source: string, translations: table<info: string, phrase: string, sources: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($from_lang | is-empty) { error make --unspanned { msg: "path parameter 'from_lang' must be non-empty" } }
  if ($to_lang | is-empty) { error make --unspanned { msg: "path parameter 'to_lang' must be non-empty" } }
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({from_lang: (encode-path-segment $from_lang), to_lang: (encode-path-segment $to_lang), word: (encode-path-segment $word), provider: (encode-path-segment $provider)} | format pattern "/transform/word/from/{from_lang}/to/{to_lang}/{word}/{provider}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
