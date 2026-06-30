# Auto-generated client for Geneea Natural Language Processing v1.0
# Source: https://api.apis.guru/v2/specs/geneea.com/1.0/swagger.json
# Auth: --token flag or $env.GENEEA_NATURAL_LANGUAGE_PROCESSING_TOKEN

const BASE_URL = "https://api.geneea.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o GENEEA_NATURAL_LANGUAGE_PROCESSING_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-user_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "user_key")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://api.geneea.com"] }
def auth-scheme-completer [] { ["query-user_key"] }

# Completers for enum parameters
def extractor-completer [] { ["article" "default" "keep-everything"] }
def accept-completer [] { ["application/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get" } } | get name | first)
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

# Information about current user account
#
# GET /account
# operationId: getInfo
export def "account get" [
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
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account" $auth.query)
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

# Performs text correction (diacritization) on the given document
#
# GET /s1/correction
# operationId: correctionGet
export def "s1-correction get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # document ID
  --text: string # raw document text
  --url: string # document URL
  --extractor: string@extractor-completer # document extractor
  --language: string # document language
  --return-text-info: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "url" $url "scalar") (serialize-qp "extractor" $extractor "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "returnTextInfo" $return_text_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/s1/correction" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "text": $text, "url": $url, "extractor": $extractor, "language": $language, "returnTextInfo": $return_text_info} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Performs text correction (diacritization) on the given document
#
# POST /s1/correction
# operationId: correctionPost
export def "s1-correction create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extractor: string@extractor-completer # [optional] Text extractor to be used when analyzing HTML document
  --id: string # Unique identifier of the document, it's optional
  --language: string # [optional] The language of the document, auto-detection will be used if omitted
  --options: record # [optional] Additional options for the internal modules (key-value pairs)
  --return-text-info: oneof<nothing, bool> # [optional] Indicates whether to return the source text within the response object
  --text: string # The raw text to be analyzed, mutually exclusive with the 'url' parameter
  --url: string # URL of a document to be analysed, mutually exclusive with the 'text' parameter
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/s1/correction" $auth.query)
  let req_body = {"extractor": $extractor, "id": $id, "language": $language, "options": $options, "returnTextInfo": $return_text_info, "text": $text, "url": $url} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Performs named-entity recognition on the given document
#
# GET /s1/entities
# operationId: entitiesGet
export def "s1-entities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # document ID
  --text: string # raw document text
  --url: string # document URL
  --extractor: string@extractor-completer # document extractor
  --language: string # document language
  --return-text-info: oneof<nothing, bool>
]: nothing -> record<entities: table<entity: string, links: record, sentiment: float, textOffset: int, type: string>, id: string, language: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "url" $url "scalar") (serialize-qp "extractor" $extractor "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "returnTextInfo" $return_text_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/s1/entities" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "text": $text, "url": $url, "extractor": $extractor, "language": $language, "returnTextInfo": $return_text_info} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Performs named-entity recognition on the given document
#
# POST /s1/entities
# operationId: entitiesPost
export def "s1-entities create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extractor: string@extractor-completer # [optional] Text extractor to be used when analyzing HTML document
  --id: string # Unique identifier of the document, it's optional
  --language: string # [optional] The language of the document, auto-detection will be used if omitted
  --options: record # [optional] Additional options for the internal modules (key-value pairs)
  --return-text-info: oneof<nothing, bool> # [optional] Indicates whether to return the source text within the response object
  --text: string # The raw text to be analyzed, mutually exclusive with the 'url' parameter
  --url: string # URL of a document to be analysed, mutually exclusive with the 'text' parameter
]: any -> record<entities: table<entity: string, links: record, sentiment: float, textOffset: int, type: string>, id: string, language: string, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/s1/entities" $auth.query)
  let req_body = {"extractor": $extractor, "id": $id, "language": $language, "options": $options, "returnTextInfo": $return_text_info, "text": $text, "url": $url} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Performs lemmatization on the given document
#
# GET /s1/lemmatize
# operationId: lemmatizeGet
export def "s1-lemmatize get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # document ID
  --text: string # raw document text
  --url: string # document URL
  --extractor: string@extractor-completer # document extractor
  --language: string # document language
  --return-text-info: oneof<nothing, bool>
]: nothing -> record<id: string, language: string, lemmatizedText: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "url" $url "scalar") (serialize-qp "extractor" $extractor "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "returnTextInfo" $return_text_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/s1/lemmatize" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "text": $text, "url": $url, "extractor": $extractor, "language": $language, "returnTextInfo": $return_text_info} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Performs lemmatization on the given document
#
# POST /s1/lemmatize
# operationId: lemmatizePost
export def "s1-lemmatize create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extractor: string@extractor-completer # [optional] Text extractor to be used when analyzing HTML document
  --id: string # Unique identifier of the document, it's optional
  --language: string # [optional] The language of the document, auto-detection will be used if omitted
  --options: record # [optional] Additional options for the internal modules (key-value pairs)
  --return-text-info: oneof<nothing, bool> # [optional] Indicates whether to return the source text within the response object
  --text: string # The raw text to be analyzed, mutually exclusive with the 'url' parameter
  --url: string # URL of a document to be analysed, mutually exclusive with the 'text' parameter
]: any -> record<id: string, language: string, lemmatizedText: string, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/s1/lemmatize" $auth.query)
  let req_body = {"extractor": $extractor, "id": $id, "language": $language, "options": $options, "returnTextInfo": $return_text_info, "text": $text, "url": $url} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Performs sentiment analysis on the given document
#
# GET /s1/sentiment
# operationId: sentimentGet
export def "s1-sentiment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # document ID
  --text: string # raw document text
  --url: string # document URL
  --extractor: string@extractor-completer # document extractor
  --language: string # document language
  --return-text-info: oneof<nothing, bool>
]: nothing -> record<id: string, language: string, sentiment: float, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "url" $url "scalar") (serialize-qp "extractor" $extractor "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "returnTextInfo" $return_text_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/s1/sentiment" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "text": $text, "url": $url, "extractor": $extractor, "language": $language, "returnTextInfo": $return_text_info} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Performs sentiment analysis on the given document
#
# POST /s1/sentiment
# operationId: sentimentPost
export def "s1-sentiment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extractor: string@extractor-completer # [optional] Text extractor to be used when analyzing HTML document
  --id: string # Unique identifier of the document, it's optional
  --language: string # [optional] The language of the document, auto-detection will be used if omitted
  --options: record # [optional] Additional options for the internal modules (key-value pairs)
  --return-text-info: oneof<nothing, bool> # [optional] Indicates whether to return the source text within the response object
  --text: string # The raw text to be analyzed, mutually exclusive with the 'url' parameter
  --url: string # URL of a document to be analysed, mutually exclusive with the 'text' parameter
]: any -> record<id: string, language: string, sentiment: float, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/s1/sentiment" $auth.query)
  let req_body = {"extractor": $extractor, "id": $id, "language": $language, "options": $options, "returnTextInfo": $return_text_info, "text": $text, "url": $url} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Performs topic detection on the given document
#
# GET /s1/topic
# operationId: topicGet
export def "s1-topic get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # document ID
  --text: string # raw document text
  --url: string # document URL
  --extractor: string@extractor-completer # document extractor
  --language: string # document language
  --return-text-info: oneof<nothing, bool>
]: nothing -> record<confidence: float, id: string, labels: table<confidence: float, label: string>, language: string, text: string, topic: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "url" $url "scalar") (serialize-qp "extractor" $extractor "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "returnTextInfo" $return_text_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/s1/topic" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "text": $text, "url": $url, "extractor": $extractor, "language": $language, "returnTextInfo": $return_text_info} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Performs topic detection on the given document
#
# POST /s1/topic
# operationId: topicPost
export def "s1-topic create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extractor: string@extractor-completer # [optional] Text extractor to be used when analyzing HTML document
  --id: string # Unique identifier of the document, it's optional
  --language: string # [optional] The language of the document, auto-detection will be used if omitted
  --options: record # [optional] Additional options for the internal modules (key-value pairs)
  --return-text-info: oneof<nothing, bool> # [optional] Indicates whether to return the source text within the response object
  --text: string # The raw text to be analyzed, mutually exclusive with the 'url' parameter
  --url: string # URL of a document to be analysed, mutually exclusive with the 'text' parameter
]: any -> record<confidence: float, id: string, labels: table<confidence: float, label: string>, language: string, text: string, topic: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/s1/topic" $auth.query)
  let req_body = {"extractor": $extractor, "id": $id, "language": $language, "options": $options, "returnTextInfo": $return_text_info, "text": $text, "url": $url} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Gets status of the Interpretor service
#
# GET /status
# operationId: status
export def "status get" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status" $auth.query)
  let accept_val = ($accept | default "text/plain")
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
