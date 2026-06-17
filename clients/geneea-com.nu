# Auto-generated client for Geneea Natural Language Processing v1.0
# Source: https://api.apis.guru/v2/specs/geneea.com/1.0/swagger.json
# Auth: --token flag or $env.GENEEA_NATURAL_LANGUAGE_PROCESSING_TOKEN

const BASE_URL = "https://api.geneea.com"
const DEFAULT_AUTH = "query-user_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GENEEA_NATURAL_LANGUAGE_PROCESSING_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-user_key" => { {headers: {}, query: $"user_key=($token_val)"} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def base-url-completer [] { ["https://api.geneea.com"] }
def auth-scheme-completer [] { ["query-user_key"] }

# Completers for enum parameters
def extractor-completer [] { ["article" "default" "keep-everything"] }
def accept-completer [] { ["application/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get-info" } } | get name | first)
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
export def "account get-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Performs text correction (diacritization) on the given document
#
# GET /s1/correction
# operationId: correctionGet
export def "s1-correction correctionGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # document ID
  --text: string # raw document text
  --qp-url: string # document URL
  --extractor: string@extractor-completer # document extractor
  --language: string # document language
  --return-text-info: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "extractor" $extractor "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "returnTextInfo" $return_text_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/s1/correction" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Performs text correction (diacritization) on the given document
#
# POST /s1/correction
# operationId: correctionPost
export def "s1-correction correctionPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extractor: string@extractor-completer # [optional] Text extractor to be used when analyzing HTML document
  --id: string # Unique identifier of the document, it's optional
  --language: string # [optional] The language of the document, auto-detection will be used if omitted
  --options: record # [optional] Additional options for the internal modules (key-value pairs)
  --return-text-info: oneof<nothing, bool> # [optional] Indicates whether to return the source text within the response object
  --text: string # The raw text to be analyzed, mutually exclusive with the 'url' parameter
  --body-url: string # URL of a document to be analysed, mutually exclusive with the 'text' parameter
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/s1/correction")
  let body = {"extractor": $extractor, "id": $id, "language": $language, "options": $options, "returnTextInfo": $return_text_info, "text": $text, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Performs named-entity recognition on the given document
#
# GET /s1/entities
# operationId: entitiesGet
export def "s1-entities entitiesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # document ID
  --text: string # raw document text
  --qp-url: string # document URL
  --extractor: string@extractor-completer # document extractor
  --language: string # document language
  --return-text-info: oneof<nothing, bool>
]: nothing -> record<entities: table<entity: string, links: record, sentiment: float, textOffset: int, type: string>, id: string, language: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "extractor" $extractor "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "returnTextInfo" $return_text_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/s1/entities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Performs named-entity recognition on the given document
#
# POST /s1/entities
# operationId: entitiesPost
export def "s1-entities entitiesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extractor: string@extractor-completer # [optional] Text extractor to be used when analyzing HTML document
  --id: string # Unique identifier of the document, it's optional
  --language: string # [optional] The language of the document, auto-detection will be used if omitted
  --options: record # [optional] Additional options for the internal modules (key-value pairs)
  --return-text-info: oneof<nothing, bool> # [optional] Indicates whether to return the source text within the response object
  --text: string # The raw text to be analyzed, mutually exclusive with the 'url' parameter
  --body-url: string # URL of a document to be analysed, mutually exclusive with the 'text' parameter
]: any -> record<entities: table<entity: string, links: record, sentiment: float, textOffset: int, type: string>, id: string, language: string, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/s1/entities")
  let body = {"extractor": $extractor, "id": $id, "language": $language, "options": $options, "returnTextInfo": $return_text_info, "text": $text, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Performs lemmatization on the given document
#
# GET /s1/lemmatize
# operationId: lemmatizeGet
export def "s1-lemmatize lemmatizeGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # document ID
  --text: string # raw document text
  --qp-url: string # document URL
  --extractor: string@extractor-completer # document extractor
  --language: string # document language
  --return-text-info: oneof<nothing, bool>
]: nothing -> record<id: string, language: string, lemmatizedText: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "extractor" $extractor "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "returnTextInfo" $return_text_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/s1/lemmatize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Performs lemmatization on the given document
#
# POST /s1/lemmatize
# operationId: lemmatizePost
export def "s1-lemmatize lemmatizePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extractor: string@extractor-completer # [optional] Text extractor to be used when analyzing HTML document
  --id: string # Unique identifier of the document, it's optional
  --language: string # [optional] The language of the document, auto-detection will be used if omitted
  --options: record # [optional] Additional options for the internal modules (key-value pairs)
  --return-text-info: oneof<nothing, bool> # [optional] Indicates whether to return the source text within the response object
  --text: string # The raw text to be analyzed, mutually exclusive with the 'url' parameter
  --body-url: string # URL of a document to be analysed, mutually exclusive with the 'text' parameter
]: any -> record<id: string, language: string, lemmatizedText: string, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/s1/lemmatize")
  let body = {"extractor": $extractor, "id": $id, "language": $language, "options": $options, "returnTextInfo": $return_text_info, "text": $text, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Performs sentiment analysis on the given document
#
# GET /s1/sentiment
# operationId: sentimentGet
export def "s1-sentiment sentimentGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # document ID
  --text: string # raw document text
  --qp-url: string # document URL
  --extractor: string@extractor-completer # document extractor
  --language: string # document language
  --return-text-info: oneof<nothing, bool>
]: nothing -> record<id: string, language: string, sentiment: float, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "extractor" $extractor "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "returnTextInfo" $return_text_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/s1/sentiment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Performs sentiment analysis on the given document
#
# POST /s1/sentiment
# operationId: sentimentPost
export def "s1-sentiment sentimentPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extractor: string@extractor-completer # [optional] Text extractor to be used when analyzing HTML document
  --id: string # Unique identifier of the document, it's optional
  --language: string # [optional] The language of the document, auto-detection will be used if omitted
  --options: record # [optional] Additional options for the internal modules (key-value pairs)
  --return-text-info: oneof<nothing, bool> # [optional] Indicates whether to return the source text within the response object
  --text: string # The raw text to be analyzed, mutually exclusive with the 'url' parameter
  --body-url: string # URL of a document to be analysed, mutually exclusive with the 'text' parameter
]: any -> record<id: string, language: string, sentiment: float, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/s1/sentiment")
  let body = {"extractor": $extractor, "id": $id, "language": $language, "options": $options, "returnTextInfo": $return_text_info, "text": $text, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Performs topic detection on the given document
#
# GET /s1/topic
# operationId: topicGet
export def "s1-topic top-ic-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # document ID
  --text: string # raw document text
  --qp-url: string # document URL
  --extractor: string@extractor-completer # document extractor
  --language: string # document language
  --return-text-info: oneof<nothing, bool>
]: nothing -> record<confidence: float, id: string, labels: table<confidence: float, label: string>, language: string, text: string, topic: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "extractor" $extractor "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "returnTextInfo" $return_text_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/s1/topic" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Performs topic detection on the given document
#
# POST /s1/topic
# operationId: topicPost
export def "s1-topic top-ic-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --extractor: string@extractor-completer # [optional] Text extractor to be used when analyzing HTML document
  --id: string # Unique identifier of the document, it's optional
  --language: string # [optional] The language of the document, auto-detection will be used if omitted
  --options: record # [optional] Additional options for the internal modules (key-value pairs)
  --return-text-info: oneof<nothing, bool> # [optional] Indicates whether to return the source text within the response object
  --text: string # The raw text to be analyzed, mutually exclusive with the 'url' parameter
  --body-url: string # URL of a document to be analysed, mutually exclusive with the 'text' parameter
]: any -> record<confidence: float, id: string, labels: table<confidence: float, label: string>, language: string, text: string, topic: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/s1/topic")
  let body = {"extractor": $extractor, "id": $id, "language": $language, "options": $options, "returnTextInfo": $return_text_info, "text": $text, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
