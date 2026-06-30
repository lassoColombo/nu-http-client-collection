# Auto-generated client for Oxford Dictionaries v1.11.0
# Source: https://api.apis.guru/v2/specs/oxforddictionaries.com/1.11.0/openapi.json
# Auth: --token flag or $env.OXFORD_DICTIONARIES_TOKEN

const BASE_URL = "https://od-api-demo.oxforddictionaries.com:443/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o OXFORD_DICTIONARIES_TOKEN | default "" }
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

def base-url-completer [] { ["https://od-api-demo.oxforddictionaries.com:443/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def source-language-completer [] { ["de" "en" "es" "gu" "hi" "id" "lv" "ms" "nso" "pt" "ro" "sw" "ta" "tn" "ur" "zu"] }
def target-language-completer [] { ["en" "es" "hi" "id" "lv" "ms" "nso" "ro" "sw" "tn" "ur" "zu"] }
def prefix-completer [] { ["false" "true"] }
def accept-completer [] { ["application/json" "text/csv"] }
def exact-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domains get" } } | get name | first)
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

# Lists available domains in a bilingual dataset
#
# GET /domains/{source_domains_language}/{target_domains_language}
export def "domains get" [
  source_domains_language: string
  target_domains_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_domains_language | is-empty) { error make --unspanned { msg: "path parameter 'source_domains_language' must be non-empty" } }
  if ($target_domains_language | is-empty) { error make --unspanned { msg: "path parameter 'target_domains_language' must be non-empty" } }
  let full_url = (build-url $base ({source_domains_language: (encode-path-segment $source_domains_language), target_domains_language: (encode-path-segment $target_domains_language)} | format pattern "/domains/{source_domains_language}/{target_domains_language}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists available domains in a monolingual dataset
#
# GET /domains/{source_language}
export def "domains list" [
  source_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_language | is-empty) { error make --unspanned { msg: "path parameter 'source_language' must be non-empty" } }
  let full_url = (build-url $base ({source_language: (encode-path-segment $source_language)} | format pattern "/domains/{source_language}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve corpus sentences for a given word
#
# GET /entries/{source_language}/{word_id}/sentences
# Docs: https://helloreverb.com/about — find more info here
export def "entries-sentences get" [
  source_language: string
  word_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_language | is-empty) { error make --unspanned { msg: "path parameter 'source_language' must be non-empty" } }
  if ($word_id | is-empty) { error make --unspanned { msg: "path parameter 'word_id' must be non-empty" } }
  let full_url = (build-url $base ({source_language: (encode-path-segment $source_language), word_id: (encode-path-segment $word_id)} | format pattern "/entries/{source_language}/{word_id}/sentences") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve dictionary information for a given word
#
# GET /entries/{source_lang}/{word_id}
# Docs: https://helloreverb.com/about — find more info here
export def "entries list" [
  source_lang: string
  word_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  if ($word_id | is-empty) { error make --unspanned { msg: "path parameter 'word_id' must be non-empty" } }
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang), word_id: (encode-path-segment $word_id)} | format pattern "/entries/{source_lang}/{word_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve words that mean the opposite
#
# GET /entries/{source_lang}/{word_id}/antonyms
# Docs: https://helloreverb.com/about — find more info here
export def "entries-antonyms get" [
  source_lang: string
  word_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  if ($word_id | is-empty) { error make --unspanned { msg: "path parameter 'word_id' must be non-empty" } }
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang), word_id: (encode-path-segment $word_id)} | format pattern "/entries/{source_lang}/{word_id}/antonyms") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Specify GB or US dictionary for English entry search
#
# GET /entries/{source_lang}/{word_id}/regions={region}
# Docs: https://helloreverb.com/about — find more info here
export def "entries-regionsregion get" [
  source_lang: string
  word_id: string
  region: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  if ($word_id | is-empty) { error make --unspanned { msg: "path parameter 'word_id' must be non-empty" } }
  if ($region | is-empty) { error make --unspanned { msg: "path parameter 'region' must be non-empty" } }
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang), word_id: (encode-path-segment $word_id), region: (encode-path-segment $region)} | format pattern "/entries/{source_lang}/{word_id}/regions={region}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve words that are similar
#
# GET /entries/{source_lang}/{word_id}/synonyms
# Docs: https://helloreverb.com/about — find more info here
export def "entries-synonyms get" [
  source_lang: string
  word_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  if ($word_id | is-empty) { error make --unspanned { msg: "path parameter 'word_id' must be non-empty" } }
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang), word_id: (encode-path-segment $word_id)} | format pattern "/entries/{source_lang}/{word_id}/synonyms") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve synonyms and antonyms for a given word
#
# GET /entries/{source_lang}/{word_id}/synonyms;antonyms
# Docs: https://helloreverb.com/about — find more info here
export def "entries-synonyms-antonyms get" [
  source_lang: string
  word_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  if ($word_id | is-empty) { error make --unspanned { msg: "path parameter 'word_id' must be non-empty" } }
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang), word_id: (encode-path-segment $word_id)} | format pattern "/entries/{source_lang}/{word_id}/synonyms;antonyms") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Apply filters to response
#
# GET /entries/{source_lang}/{word_id}/{filters}
export def "entries get" [
  source_lang: string
  word_id: string
  filters: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  if ($word_id | is-empty) { error make --unspanned { msg: "path parameter 'word_id' must be non-empty" } }
  if ($filters | is-empty) { error make --unspanned { msg: "path parameter 'filters' must be non-empty" } }
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang), word_id: (encode-path-segment $word_id), filters: (encode-path-segment $filters)} | format pattern "/entries/{source_lang}/{word_id}/{filters}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve translation for a given word
#
# GET /entries/{source_translation_language}/{word_id}/translations={target_translation_language}
export def "entries-translationstarget-translation-language get" [
  source_translation_language: string
  word_id: string
  target_translation_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, pronunciations: list, type: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_translation_language | is-empty) { error make --unspanned { msg: "path parameter 'source_translation_language' must be non-empty" } }
  if ($word_id | is-empty) { error make --unspanned { msg: "path parameter 'word_id' must be non-empty" } }
  if ($target_translation_language | is-empty) { error make --unspanned { msg: "path parameter 'target_translation_language' must be non-empty" } }
  let full_url = (build-url $base ({source_translation_language: (encode-path-segment $source_translation_language), word_id: (encode-path-segment $word_id), target_translation_language: (encode-path-segment $target_translation_language)} | format pattern "/entries/{source_translation_language}/{word_id}/translations={target_translation_language}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists available filters
#
# GET /filters
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
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: record<entries: list<string>, inflections: list<string>, translations: list<string>, wordlist: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/filters" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists available filters for specific endpoint
#
# GET /filters/{endpoint}
export def "filters get" [
  endpoint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: record<entries: list<string>, inflections: list<string>, translations: list<string>, wordlist: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($endpoint | is-empty) { error make --unspanned { msg: "path parameter 'endpoint' must be non-empty" } }
  let full_url = (build-url $base ({endpoint: (encode-path-segment $endpoint)} | format pattern "/filters/{endpoint}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists available grammatical features in a dataset
#
# GET /grammaticalFeatures/{source_language}
export def "grammatical-features get" [
  source_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_language | is-empty) { error make --unspanned { msg: "path parameter 'source_language' must be non-empty" } }
  let full_url = (build-url $base ({source_language: (encode-path-segment $source_language)} | format pattern "/grammaticalFeatures/{source_language}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Check a word exists in the dictionary and retrieve its root form
#
# GET /inflections/{source_lang}/{word_id}/{filters}
export def "inflections get" [
  source_lang: string
  word_id: string
  filters: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, language: string, lexicalEntries: list, type: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  if ($word_id | is-empty) { error make --unspanned { msg: "path parameter 'word_id' must be non-empty" } }
  if ($filters | is-empty) { error make --unspanned { msg: "path parameter 'filters' must be non-empty" } }
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang), word_id: (encode-path-segment $word_id), filters: (encode-path-segment $filters)} | format pattern "/inflections/{source_lang}/{word_id}/{filters}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists available dictionaries
#
# GET /languages
export def "languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language: string@source-language-completer # IANA language code. If provided output will be filtered by sourceLanguage.
  --target-language: string@target-language-completer # IANA language code. If provided output will be filtered by sourceLanguage.
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<region: string, source: string, sourceLanguage: record, targetLanguage: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceLanguage" $source_language "scalar") (serialize-qp "targetLanguage" $target_language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/languages" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sourceLanguage": $source_language, "targetLanguage": $target_language} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists available lexical categories in a dataset
#
# GET /lexicalcategories/{language}
export def "lexicalcategories get" [
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
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  let full_url = (build-url $base ({language: (encode-path-segment $language)} | format pattern "/lexicalcategories/{language}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists available regions in a monolingual dataset
#
# GET /regions/{source_language}
export def "regions get" [
  source_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_language | is-empty) { error make --unspanned { msg: "path parameter 'source_language' must be non-empty" } }
  let full_url = (build-url $base ({source_language: (encode-path-segment $source_language)} | format pattern "/regions/{source_language}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists available registers in a monolingual dataset
#
# GET /registers/{source_language}
export def "registers list" [
  source_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_language | is-empty) { error make --unspanned { msg: "path parameter 'source_language' must be non-empty" } }
  let full_url = (build-url $base ({source_language: (encode-path-segment $source_language)} | format pattern "/registers/{source_language}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists available registers in a bilingual dataset
#
# GET /registers/{source_register_language}/{target_register_language}
export def "registers get" [
  source_register_language: string
  target_register_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_register_language | is-empty) { error make --unspanned { msg: "path parameter 'source_register_language' must be non-empty" } }
  if ($target_register_language | is-empty) { error make --unspanned { msg: "path parameter 'target_register_language' must be non-empty" } }
  let full_url = (build-url $base ({source_register_language: (encode-path-segment $source_register_language), target_register_language: (encode-path-segment $target_register_language)} | format pattern "/registers/{source_register_language}/{target_register_language}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve possible matches to input
#
# GET /search/{source_lang}
# Docs: https://helloreverb.com/about — find more info here
export def "search get" [
  source_lang: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search string (default: eye)
  --prefix: oneof<nothing, bool> # Set prefix to true if you'd like to get results only starting with search string. (default: false)
  --regions: string # If searching in English, filter words with specific region(s) either 'us' or 'gb'.
  --limit: string # Limit the number of results per response. Default and maximum limit is 5000.
  --offset: string # Offset the start number of the result.
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "regions" $regions "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang)} | format pattern "/search/{source_lang}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "prefix": $prefix, "regions": $regions, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve possible translation matches to input
#
# GET /search/{source_search_language}/translations={target_search_language}
# Docs: https://helloreverb.com/about — find more info here
export def "search-translationstarget-search-language get" [
  source_search_language: string
  target_search_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search string. (default: eye)
  --prefix: oneof<nothing, bool> # Set prefix to true if you'd like to get results only starting with search string. (default: false)
  --regions: string # Filter words with specific region(s) E.g., regions=us. For now gb, us are available for en language.
  --limit: string # Limit the number of results per response. Default and maximum limit is 5000.
  --offset: string # Offset the start number of the result.
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_search_language | is-empty) { error make --unspanned { msg: "path parameter 'source_search_language' must be non-empty" } }
  if ($target_search_language | is-empty) { error make --unspanned { msg: "path parameter 'target_search_language' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "regions" $regions "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_search_language: (encode-path-segment $source_search_language), target_search_language: (encode-path-segment $target_search_language)} | format pattern "/search/{source_search_language}/translations={target_search_language}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "prefix": $prefix, "regions": $regions, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve the frequency of ngrams (1-4) derived from a corpus
#
# GET /stats/frequency/ngrams/{source_lang}/{corpus}/{ngram-size}/
export def "stats-frequency-ngrams get" [
  source_lang: string
  corpus: string
  ngram_size: string
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
  --tokens: string # List of tokens to filter. The tokens are separated by spaces, the list items are separated by comma (e.g., for bigrams (n=2) tokens=this is,this was, this will) (default: a word)
  --contains: string # Find ngrams containing the given token(s). Use comma or space as token separators; the order of tokens is irrelevant.
  --punctuation: string # Flag specifying whether to lookup ngrams that include punctuation or not (possible values are "true" and "false"; default is "false")
  --format: string # Option specifying whether tokens should be returned as a single string (option "google") or as a list of strings (option "oup") (default: oup)
  --min-frequency: int # Restrict the query to entries with frequency of at least `minFrequency` (format: int64)
  --max-frequency: int # Restrict the query to entries with frequency of at most `maxFrequency` (format: int64)
  --min-document-frequency: int # Restrict the query to entries that appear in at least `minDocumentFrequency` documents (format: int64)
  --max-document-frequency: int # Restrict the query to entries that appera in at most `maxDocumentFrequency` documents (format: int64)
  --collate: string # collate the results by wordform, trueCase, lemma, lexicalCategory. Multiple values can be separated by commas (e.g., collate=trueCase,lemma,lexicalCategory).
  --qp-sort: string # sort the resulting list by wordform, trueCase, lemma, lexicalCategory, frequency, normalizedFrequency. Descending order is achieved by prepending the value with the minus sign ('-'). Multiple values can be separated by commas (e.g., sort=lexicalCategory,-frequency)
  --offset: int # pagination - results offset (format: int64, default: 0)
  --limit: int # pagination - results limit (format: int64, default: 100)
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<frequency: int, tokens: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  if ($corpus | is-empty) { error make --unspanned { msg: "path parameter 'corpus' must be non-empty" } }
  if ($ngram_size | is-empty) { error make --unspanned { msg: "path parameter 'ngram-size' must be non-empty" } }
  let qp = [(serialize-qp "tokens" $tokens "scalar") (serialize-qp "contains" $contains "scalar") (serialize-qp "punctuation" $punctuation "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "minFrequency" $min_frequency "scalar") (serialize-qp "maxFrequency" $max_frequency "scalar") (serialize-qp "minDocumentFrequency" $min_document_frequency "scalar") (serialize-qp "maxDocumentFrequency" $max_document_frequency "scalar") (serialize-qp "collate" $collate "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang), corpus: (encode-path-segment $corpus), ngram_size: (encode-path-segment $ngram_size)} | format pattern "/stats/frequency/ngrams/{source_lang}/{corpus}/{ngram_size}/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tokens": $tokens, "contains": $contains, "punctuation": $punctuation, "format": $format, "minFrequency": $min_frequency, "maxFrequency": $max_frequency, "minDocumentFrequency": $min_document_frequency, "maxDocumentFrequency": $max_document_frequency, "collate": $collate, "sort": $qp_sort, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve the frequency of a word derived from a corpus.
#
# GET /stats/frequency/word/{source_lang}/
export def "stats-frequency-word get" [
  source_lang: string
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
  --corpus: string # For corpora other than 'nmc' (New Monitor Corpus) please contact api@oxforddictionaries.com (default: nmc)
  --wordform: string # The written form of the word to look up (preserving case e.g., Books vs books)
  --true-case: string # The written form of the word to look up with normalised case (Books --> books)
  --lemma: string # The lemma of the word to look up (e.g., Book, booked, books all have the lemma "book") (default: test)
  --lexical-category: string # The lexical category of the word(s) to look up (e.g., noun or verb)
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, result: record<frequency: int, lemma: string, lexicalCategory: string, matchCount: int, normalizedFrequency: int, trueCase: string, wordform: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  let qp = [(serialize-qp "corpus" $corpus "scalar") (serialize-qp "wordform" $wordform "scalar") (serialize-qp "trueCase" $true_case "scalar") (serialize-qp "lemma" $lemma "scalar") (serialize-qp "lexicalCategory" $lexical_category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang)} | format pattern "/stats/frequency/word/{source_lang}/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"corpus": $corpus, "wordform": $wordform, "trueCase": $true_case, "lemma": $lemma, "lexicalCategory": $lexical_category} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of frequencies of a word/words derived from a corpus.
#
# GET /stats/frequency/words/{source_lang}/
export def "stats-frequency-words get" [
  source_lang: string
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
  --corpus: string # For corpora other than 'nmc' (New Monitor Corpus) please contact api@oxforddictionaries.com (default: nmc)
  --wordform: string # The written form of the word to look up (preserving case e.g., Book vs book)
  --true-case: string # The written form of the word to look up with normalised case (Books --> books)
  --lemma: string # The lemma of the word to look up (e.g., Book, booked, books all have the lemma "book") (default: test)
  --lexical-category: string # The lexical category of the word(s) to look up (e.g., adjective or noun)
  --grammatical-features: string # The grammatical features of the word(s) to look up entered as a list of k:v (e.g., degree_type:comparative)
  --qp-sort: string # sort the resulting list by wordform, trueCase, lemma, lexicalCategory, frequency, normalizedFrequency. Descending order is achieved by prepending the value with the minus sign ('-'). Multiple values can be separated by commas (e.g., sort=lexicalCategory,-frequency)
  --collate: string # collate the results by wordform, trueCase, lemma, lexicalCategory. Multiple values can be separated by commas (e.g., collate=trueCase,lemma,lexicalCategory).
  --min-frequency: int # Restrict the query to entries with frequency of at least `minFrequency` (format: int64)
  --max-frequency: int # Restrict the query to entries with frequency of at most `maxFrequency` (format: int64)
  --min-normalized-frequency: float # Restrict the query to entries with frequency of at least `minNormalizedFrequency` (format: float)
  --max-normalized-frequency: float # Restrict the query to entries with frequency of at most `maxNormalizedFrequency` (format: float)
  --offset: int # pagination - results offset (format: int64, default: 0)
  --limit: int # pagination - results limit (format: int64, default: 100)
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<frequency: int, lemma: string, lexicalCategory: string, normalizedFrequency: int, trueCase: string, wordform: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  let qp = [(serialize-qp "corpus" $corpus "scalar") (serialize-qp "wordform" $wordform "scalar") (serialize-qp "trueCase" $true_case "scalar") (serialize-qp "lemma" $lemma "scalar") (serialize-qp "lexicalCategory" $lexical_category "scalar") (serialize-qp "grammaticalFeatures" $grammatical_features "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "collate" $collate "scalar") (serialize-qp "minFrequency" $min_frequency "scalar") (serialize-qp "maxFrequency" $max_frequency "scalar") (serialize-qp "minNormalizedFrequency" $min_normalized_frequency "scalar") (serialize-qp "maxNormalizedFrequency" $max_normalized_frequency "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang)} | format pattern "/stats/frequency/words/{source_lang}/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"corpus": $corpus, "wordform": $wordform, "trueCase": $true_case, "lemma": $lemma, "lexicalCategory": $lexical_category, "grammaticalFeatures": $grammatical_features, "sort": $qp_sort, "collate": $collate, "minFrequency": $min_frequency, "maxFrequency": $max_frequency, "minNormalizedFrequency": $min_normalized_frequency, "maxNormalizedFrequency": $max_normalized_frequency, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve list of words for category with advanced options
#
# GET /wordlist/{source_lang}/{filters_advanced}
export def "wordlist get-by-source-lang-filters-advanced" [
  source_lang: string
  filters_advanced: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude: string # Semicolon separated list of parameters-value pairs (same as filters). Excludes headwords that have any senses in specified exclusion attributes (lexical categories, domains, etc.) from results.
  --exclude-senses: string # Semicolon separated list of parameters-value pairs (same as filters). Excludes only those senses of a particular headword that match specified exclusion attributes (lexical categories, domains, etc.) from results but includes the headword if it has other permitted senses.
  --exclude-prime-senses: string # Semicolon separated list of parameters-value pairs (same as filters). Excludes a headword only if the primary sense matches the specified exclusion attributes (registers, domains only).
  --word-length: string # Parameter to speficy the minimum (>), exact or maximum (<) length of the words required. E.g., >5 - more than 5 chars; <4 - less than 4 chars; >5<10 - from 5 to 10 chars; 3 - exactly 3 chars. (default: >5,<10)
  --prefix: string # Filter words that start with prefix parameter (default: goal)
  --exact: oneof<nothing, bool> # If exact=true wordlist returns a list of entries that exactly matches the search string. Otherwise wordlist lists entries that start with prefix string. (default: false)
  --limit: string # Limit the number of results per response. Default and maximum limit is 5000.
  --offset: string # Offset the start number of the result.
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  if ($filters_advanced | is-empty) { error make --unspanned { msg: "path parameter 'filters_advanced' must be non-empty" } }
  let qp = [(serialize-qp "exclude" $exclude "scalar") (serialize-qp "exclude_senses" $exclude_senses "scalar") (serialize-qp "exclude_prime_senses" $exclude_prime_senses "scalar") (serialize-qp "word_length" $word_length "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "exact" $exact "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang), filters_advanced: (encode-path-segment $filters_advanced)} | format pattern "/wordlist/{source_lang}/{filters_advanced}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"exclude": $exclude, "exclude_senses": $exclude_senses, "exclude_prime_senses": $exclude_prime_senses, "word_length": $word_length, "prefix": $prefix, "exact": $exact, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of words in a category
#
# GET /wordlist/{source_lang}/{filters_basic}
export def "wordlist get-by-source-lang-filters-basic" [
  source_lang: string
  filters_basic: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Limit the number of results per response. Default and maximum limit is 5000.
  --offset: string # Offset the start number of the result
  --app-id: string # App ID Authentication Parameter
  --app-key: string # App Key Authentication Parameter
]: nothing -> record<metadata: record, results: table<id: string, matchString: string, matchType: string, region: string, word: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_lang | is-empty) { error make --unspanned { msg: "path parameter 'source_lang' must be non-empty" } }
  if ($filters_basic | is-empty) { error make --unspanned { msg: "path parameter 'filters_basic' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_lang: (encode-path-segment $source_lang), filters_basic: (encode-path-segment $filters_basic)} | format pattern "/wordlist/{source_lang}/{filters_basic}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"app_id": $app_id, "app_key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
