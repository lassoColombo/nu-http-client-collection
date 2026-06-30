# Auto-generated client for Use a [New Version](https://icons8.github.io/icons8-docs/) Instead v1.0.0
# Source: https://api.apis.guru/v2/specs/icons8.com/1.0.0/openapi.json
# Auth: --token flag or $env.USE_A_NEW_VERSION_HTTPS_ICONS8_GITHUB_IO_ICONS8_DOCS_INSTEAD_TOKEN

const BASE_URL = "https://api.icons8.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o USE_A_NEW_VERSION_HTTPS_ICONS8_GITHUB_IO_ICONS8_DOCS_INSTEAD_TOKEN | default "" }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.icons8.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "iconsets-categories-platformplatformlanguagelanguage get-categories" } } | get name | first)
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

# Categories
#
# GET /api/iconsets/v3/categories?platform={platform}&language={language}
# operationId: Categories
export def "iconsets-categories-platformplatformlanguagelanguage get-categories" [
  platform: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<parameters: record<language: string, platform: string>, result: record<categories: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  let full_url = (build-url $base ({platform: (encode-path-segment $platform), language: (encode-path-segment $language)} | format pattern "/api/iconsets/v3/categories?platform={platform}&language={language}") $auth.query)
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

# By Category
#
# GET /api/iconsets/v3/category?category={category}&subcategory={subcategory}&amount={amount}&offset={offset}&platform={platform}&language={language}
# operationId: By Category
export def "iconsets-category-categorycategorysubcategorysubcategoryamountamountoffsetoffsetplatformplatformlanguagelanguage get" [
  category: string
  subcategory: string
  amount: float
  offset: float
  platform: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<parameters: record<amount: float, category: string, language: string, offset: string, platform: string, subcategory: string>, result: record<category: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  if ($subcategory | is-empty) { error make --unspanned { msg: "path parameter 'subcategory' must be non-empty" } }
  if ($amount | is-empty) { error make --unspanned { msg: "path parameter 'amount' must be non-empty" } }
  if ($offset | is-empty) { error make --unspanned { msg: "path parameter 'offset' must be non-empty" } }
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  let full_url = (build-url $base ({category: (encode-path-segment $category), subcategory: (encode-path-segment $subcategory), amount: (encode-path-segment $amount), offset: (encode-path-segment $offset), platform: (encode-path-segment $platform), language: (encode-path-segment $language)} | format pattern "/api/iconsets/v3/category?category={category}&subcategory={subcategory}&amount={amount}&offset={offset}&platform={platform}&language={language}") $auth.query)
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

# Latest
#
# GET /api/iconsets/v3/latest?term={term}&amount={amount}&offset={offset}&platform={platform}&language={language}
# operationId: Latest
export def "iconsets-latest-termtermamountamountoffsetoffsetplatformplatformlanguagelanguage get-latest" [
  term: any
  amount: float
  offset: float
  platform: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<parameters: record<amount: float, language: string, offset: string, platform: string, term: string>, result: record<latest: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  if ($amount | is-empty) { error make --unspanned { msg: "path parameter 'amount' must be non-empty" } }
  if ($offset | is-empty) { error make --unspanned { msg: "path parameter 'offset' must be non-empty" } }
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  let full_url = (build-url $base ({term: (encode-path-segment $term), amount: (encode-path-segment $amount), offset: (encode-path-segment $offset), platform: (encode-path-segment $platform), language: (encode-path-segment $language)} | format pattern "/api/iconsets/v3/latest?term={term}&amount={amount}&offset={offset}&platform={platform}&language={language}") $auth.query)
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

# By Keyword v3
#
# GET /api/iconsets/v3/search?term={term}&amount={amount}&offset={offset}&platform={platform}&language={language}&exact_amount={exact_amount}
# operationId: By Keyword v3
export def "iconsets-search-termtermamountamountoffsetoffsetplatformplatformlanguagelanguageexact-amountexact-amount get-by-keyword-by-term-amount-offset-platform-language-exact-amount" [
  term: string
  amount: float
  offset: float
  platform: string
  language: string
  exact_amount: bool
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<parameters: record<amount: float, language: string, offset: string, platform: string, term: string>, result: record<search: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  if ($amount | is-empty) { error make --unspanned { msg: "path parameter 'amount' must be non-empty" } }
  if ($offset | is-empty) { error make --unspanned { msg: "path parameter 'offset' must be non-empty" } }
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  if ($exact_amount | is-empty) { error make --unspanned { msg: "path parameter 'exact_amount' must be non-empty" } }
  let full_url = (build-url $base ({term: (encode-path-segment $term), amount: (encode-path-segment $amount), offset: (encode-path-segment $offset), platform: (encode-path-segment $platform), language: (encode-path-segment $language), exact_amount: (encode-path-segment $exact_amount)} | format pattern "/api/iconsets/v3/search?term={term}&amount={amount}&offset={offset}&platform={platform}&language={language}&exact_amount={exact_amount}") $auth.query)
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

# Totals
#
# GET /api/iconsets/v3/total?since={since}
# operationId: Totals
export def "iconsets-total-sincesince get-totals" [
  since: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<parameters: record<since: string>, result: record<total: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($since | is-empty) { error make --unspanned { msg: "path parameter 'since' must be non-empty" } }
  let full_url = (build-url $base ({since: (encode-path-segment $since)} | format pattern "/api/iconsets/v3/total?since={since}") $auth.query)
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

# By Keyword v4
#
# GET /api/iconsets/v4/search?term={term}&amount={amount}&offset={offset}&platform={platform}&language={language}&exact_amount={exact_amount}
# operationId: By Keyword v4
export def "iconsets-search-termtermamountamountoffsetoffsetplatformplatformlanguagelanguageexact-amountexact-amount get-by-keyword-by-term-amount-offset-platform-language-exact-amount-1" [
  term: string
  amount: float
  offset: float
  platform: string
  language: string
  exact_amount: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<icons: list<any>, parameters: record<amount__50_: string, language: string, offset: string, platform: string, term: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  if ($amount | is-empty) { error make --unspanned { msg: "path parameter 'amount' must be non-empty" } }
  if ($offset | is-empty) { error make --unspanned { msg: "path parameter 'offset' must be non-empty" } }
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  if ($exact_amount | is-empty) { error make --unspanned { msg: "path parameter 'exact_amount' must be non-empty" } }
  let full_url = (build-url $base ({term: (encode-path-segment $term), amount: (encode-path-segment $amount), offset: (encode-path-segment $offset), platform: (encode-path-segment $platform), language: (encode-path-segment $language), exact_amount: (encode-path-segment $exact_amount)} | format pattern "/api/iconsets/v4/search?term={term}&amount={amount}&offset={offset}&platform={platform}&language={language}&exact_amount={exact_amount}") $auth.query)
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

# From a Collection
#
# POST /api/task/web-font/collection
# operationId: From a Collection
# --auth shape: {hash: string}
# --task shape: {arguments?: record}
export def "task-web-font-collection create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-auth: record # shape: {hash: string}
  --task: record # shape: {arguments?: record}
]: any -> record<messages: list<any>, result: record<description: string, id: string, results: record<zip: string>, status: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/task/web-font/collection" $auth.query)
  let req_body = {"auth": $body_auth, "task": $task} | compact
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

# From Separate Icons
#
# POST /api/task/web-font/icons
# operationId: From Separate Icons
# --auth shape: {hash: string}
# --task shape: {arguments?: record}
export def "task-web-font-icons create-from-separate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-auth: record # shape: {hash: string}
  --task: record # shape: {arguments?: record}
]: any -> record<messages: list<any>, result: record<description: string, id: string, results: record<zip: string>, status: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/task/web-font/icons" $auth.query)
  let req_body = {"auth": $body_auth, "task": $task} | compact
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
