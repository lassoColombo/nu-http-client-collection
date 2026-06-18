# Auto-generated client for Word Associations API v1.0
# Source: https://api.apis.guru/v2/specs/wordassociations.net/1.0/swagger.json
# Auth: --token flag or $env.WORD_ASSOCIATIONS_API_TOKEN

const BASE_URL = "https://api.wordassociations.net/associations/v1.0"
const DEFAULT_AUTH = "query-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WORD_ASSOCIATIONS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-apikey" => { {headers: {}, query: $"apikey=($token_val)"} }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://api.wordassociations.net/associations/v1.0"] }
def auth-scheme-completer [] { ["query-apikey"] }

# Completers for enum parameters
def lang-completer [] { ["de" "en" "es" "fr" "it" "pt" "ru"] }
def type-completer [] { ["response" "stimulus"] }
def indent-completer [] { ["no" "yes"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  let full_url = (build-url $base "/json/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/json/search")
  let req_body = {"text": $text, "lang": $lang, "type": $type, "limit": $limit, "pos": $pos, "indent": $indent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}
