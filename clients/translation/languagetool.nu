# Auto-generated client for LanguageTool API v1.1.2
# Source: https://api.apis.guru/v2/specs/languagetool.org/1.1.2/swagger.json
# Auth: --token flag or $env.LANGUAGETOOL_API_TOKEN

const BASE_URL = "https://api.languagetoolplus.com/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LANGUAGETOOL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def base-url-completer [] { ["https://api.languagetoolplus.com/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def level-completer [] { ["default" "picky"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "check post" } } | get name | first)
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

# Check a text
#
# POST /check
export def "check post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # The text to be checked. This or 'data' is required.
  --data: string # The text to be checked, given as a JSON document that specifies what's text and what's markup. This or 'text' is required. Markup will be ignored when looking for errors. Example text: <pre>A &lt;b>test&lt;/b></pre>JSON for the example text: <pre>{"annotation":[  {"text": "A "},  {"markup": "&lt;b>"},  {"text": "test"},  {"markup": "&lt;/b>"} ]}</pre> <p>If you have markup that should be interpreted as whitespace, like <tt>&lt;p&gt;</tt> in HTML, you can have it interpreted like this: <pre>{"markup": "&lt;p&gt;", "interpretAs": "\n\n"}</pre><p>The 'data' feature is not limited to HTML or XML, it can be used for any kind of markup. Entities will need to be expanded in this input.
  language: string # A language code like `en-US`, `de-DE`, `fr`, or `auto` to guess the language automatically (see `preferredVariants` below). For languages with variants (English, German, Portuguese) spell checking will only be activated when you specify the variant, e.g. `en-GB` instead of just `en`.
  --username: string # Set to get Premium API access: Your username/email as used to log in at languagetool.org.
  --apiKey: string # Set to get Premium API access: <a target='_blank' href='https://languagetool.org/editor/settings/access-tokens'>your API key</a>
  --dicts: string # Comma-separated list of dictionaries to include words from; uses special default dictionary if this is unset
  --motherTongue: string # A language code of the user's native language, enabling false friends checks for some language pairs.
  --preferredVariants: string # Comma-separated list of preferred language variants. The language detector used with `language=auto` can detect e.g. English, but it cannot decide whether British English or American English is used. Thus this parameter can be used to specify the preferred variants like `en-GB` and `de-AT`. Only available with `language=auto`. You should set variants for at least German and English, as otherwise the spell checking will not work for those, as no spelling dictionary can be selected for just `en` or `de`.
  --enabledRules: string # IDs of rules to be enabled, comma-separated
  --disabledRules: string # IDs of rules to be disabled, comma-separated
  --enabledCategories: string # IDs of categories to be enabled, comma-separated
  --disabledCategories: string # IDs of categories to be disabled, comma-separated
  --enabledOnly: oneof<nothing, bool> # If true, only the rules and categories whose IDs are specified with `enabledRules` or `enabledCategories` are enabled.
  --level: string@level-completer # If set to `picky`, additional rules will be activated, i.e. rules that you might only find useful when checking formal text.
]: any -> record<language: record<code: string, detectedLanguage: record<code: string, name: string>, name: string>, matches: table<context: record, length: int, message: string, offset: int, replacements: list, rule: record, sentence: string, shortMessage: string>, software: record<apiVersion: int, buildDate: string, name: string, premium: bool, status: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/check")
  let body = {text: $text, data: $data, language: $language, username: $username, apiKey: $apiKey, dicts: $dicts, motherTongue: $motherTongue, preferredVariants: $preferredVariants, enabledRules: $enabledRules, disabledRules: $disabledRules, enabledCategories: $enabledCategories, disabledCategories: $disabledCategories, enabledOnly: $enabledOnly, level: $level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of supported languages.
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
]: nothing -> table<code: string, longCode: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List words in dictionaries
#
# GET /words
export def "words get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Offset of where to start in the list of words. Defaults to 0.
  --limit: int # Maximum number of words to return. Defaults to 10.
  --username: string # Your username as used to log in at languagetool.org.
  --apiKey: string # <a target='_blank' href='https://languagetool.org/editor/settings/access-tokens'>Your API key</a> (format: password)
  --dicts: string # Comma-separated list of dictionaries to include words from; uses special default dictionary if this is unset
]: nothing -> record<words: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "apiKey" $apiKey "scalar") (serialize-qp "dicts" $dicts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/words" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add word to a dictionary
#
# POST /words/add
export def "words-add post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  word: string # The word to be added. Must not be a phrase, i.e. cannot contain white space. The word is added to a global dictionary that applies to all languages.
  username: string # Your username as used to log in at languagetool.org.
  apiKey: string # <a target='_blank' href='https://languagetool.org/editor/settings/access-tokens'>Your API key</a>
  --dict: string # Name of the dictionary to add the word to; non-existent dictionaries are created after calling this; if unset, adds to special default dictionary
]: any -> record<added: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/words/add")
  let body = {word: $word, username: $username, apiKey: $apiKey, dict: $dict} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove word from a dictionary
#
# POST /words/delete
export def "words-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  word: string # The word to be removed.
  username: string # Your username as used to log in at languagetool.org.
  apiKey: string # <a target='_blank' href='https://languagetool.org/editor/settings/access-tokens'>Your API key</a>
  --dict: string # Name of the dictionary to remove the word from; if the dictionary is empty upon calling this, it is deleted; if unset, removes from special default dictionary
]: any -> record<deleted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/words/delete")
  let body = {word: $word, username: $username, apiKey: $apiKey, dict: $dict} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
