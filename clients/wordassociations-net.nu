# Auto-generated client for Word Associations API v1.0
# Source: https://api.apis.guru/v2/specs/wordassociations.net/1.0/swagger.json
# Auth: --token flag or $env.WORD_ASSOCIATIONS_API_TOKEN

const BASE_URL = "https://api.wordassociations.net/associations/v1.0"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o WORD_ASSOCIATIONS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-apikey" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "apikey")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://api.wordassociations.net/associations/v1.0"] }
def auth-scheme-completer [] { ["query-apikey"] }

# Completers for enum parameters
def lang-completer [] { ["de" "en" "es" "fr" "it" "pt" "ru"] }
def type-completer [] { ["response" "stimulus"] }
def indent-completer [] { ["no" "yes"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "json-search get" } } | get name | first)
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

# Gets associations with the given word or phrase.
#
# GET /json/search
export def "json-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: list<string> # Word or phrase to find associations with. Tip. You can use multiple parameters 'text' in a request (from 1 to 10 inclusive). This way you can get associations for several input words or phrases in one response. Restriction: regardless of the size of the text association lookup is always performed by the first 10 words of the text.
  --lang: string@lang-completer # Query language. Use language code for the language of the text: * de - German; * en - English; * es - Spanish; * fr - French; * it - Italian; * pt - Portuguese; * ru - Russian;
  --type: string@type-completer # Type of result. Possible values: * stimulus - an input data (the text parameter) is considered as a response word. The service returns a list of stimuli words, which evoke a given response word; * response - an input data (the text parameter) is considered as a stimulus word. The service returns a list of response words, which come to mind for a given stimulus word. (default: stimulus)
  --limit: int # Maximum number of results to return. Allows to limit the number of results (associations) in response. The value of this parameter is an integer number from 1 to 300 inclusive. (default: 50)
  --pos: list<string> # Parts of speech to return. Allows to limit results by specified parts of speech. The value of this parameter is a list of parts of speech separated by comma. The following parts of speech codes are supported: * noun * adjective * verb * adverb (default: [noun, adjective, verb, adverb])
  --indent: string@indent-completer # Indentation switch for pretty printing of JSON response. Allows to either turn on or off space indentation for a response. The following values are allowed: * yes - turns indentation with spaces on; * no - turn indentation with spaces off; (default: yes)
]: nothing -> record<code: int, request: record<indent: string, lang: string, limit: int, pos: string, text: list<string>, type: string>, response: table<items: list, text: string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "multi") (serialize-qp "lang" $lang "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pos" $pos "csv") (serialize-qp "indent" $indent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"text": $text, "lang": $lang, "type": $type, "limit": $limit, "pos": $pos, "indent": $indent} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets associations with the given word or phrase.
#
# POST /json/search
export def "json-search create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: list # Word or phrase to find associations with. Tip. You can use multiple parameters 'text' in a request (from 1 to 10 inclusive). This way you can get associations for several input words or phrases in one response. Restriction: regardless of the size of the text association lookup is always performed by the first 10 words of the text.
  lang: string@lang-completer # Query language. Use language code for the language of the text: * de - German; * en - English; * es - Spanish; * fr - French; * it - Italian; * pt - Portuguese; * ru - Russian;
  --type: string@type-completer # Type of result. Possible values: * stimulus - an input data (the text parameter) is considered as a response word. The service returns a list of stimuli words, which evoke a given response word; * response - an input data (the text parameter) is considered as a stimulus word. The service returns a list of response words, which come to mind for a given stimulus word.
  --limit: int # Maximum number of results to return. Allows to limit the number of results (associations) in response. The value of this parameter is an integer number from 1 to 300 inclusive.
  --pos: list # Parts of speech to return. Allows to limit results by specified parts of speech. The value of this parameter is a list of parts of speech separated by comma. The following parts of speech codes are supported: * noun * adjective * verb * adverb
  --indent: string@indent-completer # Indentation switch for pretty printing of JSON response. Allows to either turn on or off space indentation for a response. The following values are allowed: * yes - turns indentation with spaces on; * no - turn indentation with spaces off;
]: any -> record<code: int, request: record<indent: string, lang: string, limit: int, pos: string, text: list<string>, type: string>, response: table<items: list, text: string>, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/json/search" $auth.query)
  let req_body = {"text": $text, "lang": $lang, "type": $type, "limit": $limit, "pos": $pos, "indent": $indent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
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
