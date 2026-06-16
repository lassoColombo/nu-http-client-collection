# Auto-generated client for They Said So Quotes API v3.1
# Source: https://api.apis.guru/v2/specs/quotes.rest/3.1/openapi.json
# Auth: --token flag or $env.THEY_SAID_SO_QUOTES_API_TOKEN

const BASE_URL = "https://quotes.rest"
const DEFAULT_AUTH = "x-theysaidso-api-secret"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o THEY_SAID_SO_QUOTES_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-theysaidso-api-secret" => { {headers: {X-TheySaidSo-Api-Secret: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://quotes.rest" "http://quotes.rest" "http://api01.quotes.rest"] }
def auth-scheme-completer [] { ["x-theysaidso-api-secret"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "qod get" } } | get name | first)
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

# Gets `Quote of the Day`. Optional `category` param determines the category of returned quote of the day
#
# GET /qod
export def "qod get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --category: string # QOD Category (format: string)
  --language: string # Language of the QOD. The language must be supported in our QOD system. (format: string, default: en)
]: nothing -> record<contents: record<quotes: list<record>>, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qod" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of `Quote of the Day` Categories.
#
# GET /qod/categories
export def "qod-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the QOD category. The language must be supported in our QOD system. (format: string, default: en)
  --detailed: oneof<nothing, bool> # Return detailed information of the categories. Note the data format changes between the two values of this switch. (format: boolean, default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qod/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of supported languages for `Quote of the Day`. 
#
# GET /qod/languages
export def "qod-languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qod/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a qshow.
#
# DELETE /qshow
export def "qshow delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Qshow ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a details about a qshow.
#
# GET /qshow
export def "qshow get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # Qshow ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing qshow.
#
# PATCH /qshow
export def "qshow patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Qshow ID (format: string)
  --title: string # Qshow title (format: string)
  --description: string # Qshow description (format: string)
  --tags: list # Tags for the qshow
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create and add a new qshow to your private collection.
#
# PUT /qshow
export def "qshow put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # Qshow title (format: string)
  --description: string # Qshow description (format: string)
  --tags: list # Tags for the qshow
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of Qshows in They Said So platform.
#
# GET /qshow/list
export def "qshow-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --public: oneof<nothing, bool> # Should include public qshows or not in the list (format: boolean, default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "public" $public "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the quotes in a given Qshow.
#
# GET /qshow/quotes
export def "qshow-quotes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Qshow ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow/quotes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a quote to a given Qshow.
#
# POST /qshow/quotes/add
export def "qshow-quotes-add post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Qshow ID (format: string)
  --quoteid: string # Quote ID to add the qshow collection (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "quoteid" $quoteid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow/quotes/add" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a quote to a given Qshow.
#
# POST /qshow/quotes/remove
export def "qshow-quotes-remove post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Qshow ID (format: string)
  --quoteid: string # Quote ID to remove from the qshow collection (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "quoteid" $quoteid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow/quotes/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a quote. The user needs to be the owner of the quote to be able to delete it.
#
# DELETE /quote
export def "quote delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a `Quote` with a given `id`.
#
# GET /quote
export def "quote get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # Quote ID (format: string)
]: nothing -> record<contents: record<quotes: list<record>>, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a quote
#
# PATCH /quote
export def "quote patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote ID (format: string)
  --quote: string # Quote (format: string)
  --author: string # Quote Author (format: string)
  --language: string # Language. If not supplied an auto detection mechanism will be used to detect a language. (format: string, default: en)
  --tags: string # Comma Separated tags
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "quote" $quote "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new quote to your private collection. Same as 'PUT' but added since some clients don't handle PUT well.
#
# POST /quote
export def "quote post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote: string # Quote (format: string)
  --author: string # Quote Author (format: string)
  --tags: string # Comma Separated tags (format: string)
  --language: string # Language. If not supplied an auto detection mechanism will be used to detect a language. (format: string, default: en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote" $quote "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new quote to your private collection.
#
# PUT /quote
export def "quote put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote: string # Quote (format: string)
  --author: string # Quote Author (format: string)
  --tags: string # Comma Separated tags (format: string)
  --language: string # Language. If not supplied an auto detection mechanism will be used to detect a language. (format: string, default: en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote" $quote "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of popular author names in the system. 
#
# GET /quote/authors/popular
export def "quote-authors-popular get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language. A same author may have quotes in two or more different languages. So for example 'Mahatma Gandhi' may be returned for language "en"(English), and "மஹாத்மா காந்தி" may be returned when the language is "ta" (Tamil). (format: string, default: en)
  --detailed: oneof<nothing, bool> # Should return detailed author information such as `birthday`, `death date`, `occupation`, `description` etc. Only available at certain subscription levels. (format: boolean, default: false)
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --limit: int # Response is paged. This parameter controls how many is returned in the result. The maximum depends on the subscription level. (format: int32, default: 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "detailed" $detailed "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/authors/popular" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of author names in the system. 
#
# GET /quote/authors/search
export def "quote-authors-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Text string to search for in author names (format: string)
  --language: string # Language. A same author may have quotes in two or more different languages. So for example 'Mahatma Gandhi' may be returned for language "en"(English), and "மஹாத்மா காந்தி" may be returned when the language is "ta" (Tamil). (format: string, default: en)
  --detailed: oneof<nothing, bool> # Should return detailed author information such as `birthday`, `death date`, `occupation`, `description` etc. Only available at certain subscription levels. (format: boolean, default: false)
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --limit: int # Response is paged. This parameter controls how many is returned in the result. The maximum depends on the subscription level. (format: int32, default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "detailed" $detailed "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/authors/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of popular `Quote` Categories.
#
# GET /quote/categories/popular
export def "quote-categories-popular get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --limit: int # Response is paged. This parameter controls how many is returned in the result. The maximum depends on the subscription level. (format: int32, default: 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/categories/popular" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of `Quote` Categories matching the query string.
#
# GET /quote/categories/search
export def "quote-categories-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Text string to search for in the categories (format: string, default: 0)
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --limit: int # Response is paged. This parameter controls how many is returned in the result. The maximum depends on the subscription level. (format: int32, default: 2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/categories/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove the disLike for the given Quote as a user of the API Key.
#
# DELETE /quote/dislike
export def "quote-dislike delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/dislike" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Dislike the given Quote as a user of the API Key. Same as `put` but a convenient alias for those clients that don't support `put` cleanly.
#
# POST /quote/dislike
export def "quote-dislike post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/dislike" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Dislike the given Quote as a user of the API Key. Some clients don't cleanly support `PUT`, in such scenarios use the `POST` version of this.
#
# PUT /quote/dislike
export def "quote-dislike put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/dislike" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a quote image. The user needs to be the owner of the quote image to be able to delete it.
#
# DELETE /quote/image
export def "quote-image delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote Image ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a Quote image for a given id. Response can be an image file as a binary or a base64 encoded contents wrapped in json. `TODO`
#
# GET /quote/image
export def "quote-image get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote Image id (format: string)
  --binary: oneof<nothing, bool> # Should the response be a direct file download of the image or a base64 encoded image file wrapped in json? (format: boolean, default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "binary" $binary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new quote image for a given quote. Choose background colors/images , choose different font styles and generate a beautiful quote image. Did you just had a feeling of being a god or what?!
#
# PUT /quote/image
export def "quote-image put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote id (format: string)
  --bgimage-id: string # Background Image id ( Will override bgcolor if supplied) (format: string, default: theysaidso_default_background_image)
  --bg-color: string # Background Color(if background image id is not supplied) (format: string)
  --font-id: string # Font id (format: string, default: theysaidso_default_font)
  --text-color: string # Text Color (format: string)
  --text-size: string # Text/font size (format: string)
  --halign: string # Horizontal text Alignment Value (format: string, default: center)
  --valign: string # Vertical text Alignment Value (format: string, default: center)
  --width: int # Image Width(By default this takes the width of the background image) (format: integer)
  --height: int # Image Height(By default this takes the height of the background image) (format: integer)
  --branding: oneof<nothing, bool> # Disable They Said So branding (Only available in certain subscription levels. Ignored in other levels) (format: boolean, default: false)
  --include-transparent-layer: oneof<nothing, bool> # Should include a transparent layer between the text and the background image? This helps when the background image is bright and obscures the text. (format: boolean, default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar") (serialize-qp "bgimage_id" $bgimage_id "scalar") (serialize-qp "bg_color" $bg_color "scalar") (serialize-qp "font_id" $font_id "scalar") (serialize-qp "text_color" $text_color "scalar") (serialize-qp "text_size" $text_size "scalar") (serialize-qp "halign" $halign "scalar") (serialize-qp "valign" $valign "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "branding" $branding "scalar") (serialize-qp "include_transparent_layer" $include_transparent_layer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a background image file. The user needs to be the owner of the background image to be able to delete it.
#
# DELETE /quote/image/background
export def "quote-image-background delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Font ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/background" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an image for use later as a quote background image.
#
# POST /quote/image/background
export def "quote-image-background post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  image: string # Image file to add to your collection (png/jpg/gif are supported) (format: binary)
  --tags: string # Optional comma separated tags (format: string)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/quote/image/background")
  let body = {image: $image, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Lists background images in your private collection. 
#
# GET /quote/image/background/list
export def "quote-image-background-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Response is paged. This parameter determines where the response should start. (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/background/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches for a background image with a given tag. 
#
# GET /quote/image/background/search
export def "quote-image-background-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tag string (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/background/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a tag to a given Image.
#
# POST /quote/image/background/tags/add
export def "quote-image-background-tags-add post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Image ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/background/tags/add" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a tag from a given Image.
#
# POST /quote/image/background/tags/remove
export def "quote-image-background-tags-remove post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Image ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/background/tags/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a font file. The user needs to be the owner of the font to be able to delete it.
#
# DELETE /quote/image/font
export def "quote-image-font delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Font ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/font" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a font file for use later in creating a quote image. This is essentially a `PUT` but not many clients handle PUT with binary stream i.e. a file, gracefully.
#
# POST /quote/image/font
export def "quote-image-font post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  font: string # Font file to add to your collection (ttf/otf are supported) (format: binary)
  --tags: string # Optional comma separated tags (format: string)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/quote/image/font")
  let body = {font: $font, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Lists background images in your private collection. 
#
# GET /quote/image/font/list
export def "quote-image-font-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Response is paged. This parameter determines where the response should start. (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/font/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches for a font with a given tag. 
#
# GET /quote/image/font/search
export def "quote-image-font-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tag string (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/font/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a tag to a given font.
#
# POST /quote/image/font/tags/add
export def "quote-image-font-tags-add post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Font ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/font/tags/add" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a tag from a given Font.
#
# POST /quote/image/font/tags/remove
export def "quote-image-font-tags-remove post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Font ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/font/tags/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a Random Quote image. Optional `category` param determines the category of quote used in the image. Optional `author` param gets the quote image of a given author. 
#
# GET /quote/image/search
export def "quote-image-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # Quote Category (format: string)
  --author: string # Quote Author (format: string)
  --private: oneof<nothing, bool> # Should search private collection. Default searches public image collection. (format: boolean, default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "private" $private "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove the Like for the given Quote as a user of the API Key.
#
# DELETE /quote/like
export def "quote-like delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/like" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Like the given Quote as a user of the API Key. Same as `PUT` but a convenient alias for those clients that don't support `PUT` cleanly.
#
# POST /quote/like
export def "quote-like post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/like" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Like the given Quote as a user of the API Key. Some clients don't cleanly support `PUT`, in such scenarios use the `POST` version of this.
#
# PUT /quote/like
export def "quote-like put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/like" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of quotes in your private collection.
#
# GET /quote/list
export def "quote-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --limit: int # Response is paged. This parameter controls how many is returned in the result. (format: int32, default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a `Random Quote`. When you are in a hurry this is what you call to get a random famous quote.
#
# GET /quote/random
export def "quote-random get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --language: string # Language of the Quote. The language must be supported in our system. (format: string, default: en)
  --limit: int # No of quotes to return. The max limit depends on the subscription level. (format: integer, default: 1)
]: nothing -> record<contents: record<quotes: list<record>>, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/random" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for a `Quote` in They Said So platform. Optional `category` , `author`, `minlength`, `maxlength` params determines the filters applied while searching for the quote. 
#
# GET /quote/search
export def "quote-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --category: string # Quote Category (format: string)
  --author: string # Quote Author (format: string)
  --minlength: int # Quote minimum Length (format: int32, default: 100)
  --maxlength: int # Quote maximum Length (format: int32, default: 300)
  --query: string # keyword to search for in the quote (format: string)
  --private: oneof<nothing, bool> # Should search private collection? Default searches public collection. (format: boolean, default: false)
  --language: string # Language of the Quote. The language must be supported in our system. (format: string, default: en)
  --limit: int # No of quotes to return. The max limit depends on the subscription level. (format: integer, default: 1)
  --sfw: oneof<nothing, bool> # Should search only SFW (Safe For Work) quotes? (format: boolean, default: false)
]: nothing -> record<contents: record<quotes: list<record>>, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "minlength" $minlength "scalar") (serialize-qp "maxlength" $maxlength "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "private" $private "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sfw" $sfw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a tag to a given Quote.
#
# POST /quote/tags/add
export def "quote-tags-add post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/tags/add" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a tag from a given quote.
#
# POST /quote/tags/remove
export def "quote-tags-remove post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/tags/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
