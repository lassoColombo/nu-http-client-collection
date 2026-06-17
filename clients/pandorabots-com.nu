# Auto-generated client for Pandorabots AIaaS v1.0.0
# Source: https://api.apis.guru/v2/specs/pandorabots.com/1.0.0/swagger.json
# Auth: --token flag or $env.PANDORABOTS_AIAAS_TOKEN

const BASE_URL = "https://aiaas.pandorabots.com"
const DEFAULT_AUTH = "query-user_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PANDORABOTS_AIAAS_TOKEN | default "" }
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

def base-url-completer [] { ["https://aiaas.pandorabots.com"] }
def auth-scheme-completer [] { ["query-user_key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "atalk atalkBot" } } | get name | first)
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

# Anonymous Talk
#
# POST /atalk/{app_id}/{botname}
# operationId: atalkBot
export def "atalk atalkBot" [
  app_id: string
  botname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --input: string # Message to be sent to the bot. This can contain multiple sentences. Currently the limit is 500 characters.
  --client-name: string # Leave blank to request Pandorabots to create a client_name which will support persistent predicates. Including a valid client_name in this parameter will work in the same way that Talk to Bot API but with persistent predicates. It is recommended to use this API only to create an end-user client_name, and then use normal Talk to Bot API to continue conversation with the bot.
  --sessionid: string # Session ID generated by Pandorabots. This allows the application to group individual conversations into a collection as needed. If not included in the call, Pandorabots will issue a new session ID. (4-byte integer type)
  --recent: string # If true, the system will not signal an error if the bot is uncompiled, and will instead look for a previous version of the bot that is available.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "input" $input "scalar") (serialize-qp "client_name" $client_name "scalar") (serialize-qp "sessionid" $sessionid "scalar") (serialize-qp "recent" $recent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname} | format pattern "/atalk/{app_id}/{botname}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of bots
#
# GET /bot/{app_id}
# operationId: listBots
export def "bot list" [
  app_id: string
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
  let full_url = (build-url $base ({app_id: $app_id} | format pattern "/bot/{app_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a bot
#
# DELETE /bot/{app_id}/{botname}
# operationId: deleteBot
export def "bot delete" [
  app_id: string
  botname: string
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
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname} | format pattern "/bot/{app_id}/{botname}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of bot files
#
# GET /bot/{app_id}/{botname}
# operationId: listBotFiles
export def "bot list-bot-files" [
  app_id: string
  botname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-return: string # If set to zip, a zip file with all bot files will be returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "return" $qp_return "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname} | format pattern "/bot/{app_id}/{botname}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a bot
#
# PUT /bot/{app_id}/{botname}
# operationId: createBot
export def "bot create" [
  app_id: string
  botname: string
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
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname} | format pattern "/bot/{app_id}/{botname}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compile a bot
#
# GET /bot/{app_id}/{botname}/verify
# operationId: compileBot
export def "bot-verify compileBot" [
  app_id: string
  botname: string
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
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname} | format pattern "/bot/{app_id}/{botname}/verify"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a bot file (pdefaults, properties)
#
# DELETE /bot/{app_id}/{botname}/{file-kind}
# operationId: deleteBotFile2
export def "bot delete-bot-file2" [
  app_id: string
  botname: string
  file_kind: string
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
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname, file_kind: $file_kind} | format pattern "/bot/{app_id}/{botname}/{file_kind}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a bot file (pdefaults, properties)
#
# GET /bot/{app_id}/{botname}/{file-kind}
# operationId: getBotFile2
export def "bot get-bot-file2" [
  app_id: string
  botname: string
  file_kind: string
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
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname, file_kind: $file_kind} | format pattern "/bot/{app_id}/{botname}/{file_kind}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a bot file (pdefaults, properties)
#
# PUT /bot/{app_id}/{botname}/{file-kind}
# operationId: uploadFile2
export def "bot upload-file2" [
  app_id: string
  botname: string
  file_kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname, file_kind: $file_kind} | format pattern "/bot/{app_id}/{botname}/{file_kind}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a bot file (AIML, set, map, substitution)
#
# DELETE /bot/{app_id}/{botname}/{file-kind}/{filename}
# operationId: deleteBotFile1
export def "bot delete-bot-file1" [
  app_id: string
  botname: string
  file_kind: string
  filename: string
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
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname, file_kind: $file_kind, filename: $filename} | format pattern "/bot/{app_id}/{botname}/{file_kind}/{filename}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a bot file (AIML, set, map, substitution)
#
# GET /bot/{app_id}/{botname}/{file-kind}/{filename}
# operationId: getBotFile1
export def "bot get-bot-file1" [
  app_id: string
  botname: string
  file_kind: string
  filename: string
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
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname, file_kind: $file_kind, filename: $filename} | format pattern "/bot/{app_id}/{botname}/{file_kind}/{filename}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a bot file (AIML, set, substitution, map)
#
# PUT /bot/{app_id}/{botname}/{file-kind}/{filename}
# operationId: uploadFile1
export def "bot upload-file1" [
  app_id: string
  botname: string
  file_kind: string
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname, file_kind: $file_kind, filename: $filename} | format pattern "/bot/{app_id}/{botname}/{file_kind}/{filename}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Debug a bot conversation
#
# POST /talk/{app_id}/{botname}
# operationId: debugBot
export def "talk debugBot" [
  app_id: string
  botname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --input: string # Message to be sent to the bot. This can contain multiple sentences. Currently the limit is 500 characters.
  --client-name: string # Identifies your application's end user. You can assign each of your end users a unique client_name. This will allow you to set predicates and other variable information that is specific to an individual. Format required is 3-64 characters in length and only numbers or lower-case letters [0-9][a-z]
  --sessionid: string # Session ID generated by Pandorabots. This allows the application to group individual conversations into a collection. While testing your bot, not including this parameter, Pandorabots will issue a new session ID. (4-byte integer type)
  --that: string # For debugging purposes, you can specify a 'that' with the input that supersedes the existing that in bot memory.
  --topic: string # For debugging purposes, you can specify a 'topic' with the input that supersedes the existing topic in bot memory.
  --extra: string # Return extra conversation information. If true, input, pattern, that, topic, filename, and template associated with the pattern matched are returned in addition to response and sessionid.
  --reset: string # Reset the bot memory. If true, all predicate values in the bot will be discarded, and the user can talk to the bot as if it is the first time
  --trace: string # Include trace data in the response. If true, the system will generate AIML trace information for the input. Trace data includes pattern matched, filename, input, template for all recursion levels. NOTE: for security reasons, trace does not work with client_name.
  --reload: string # If true, the system will force a reload of the bot into memory. This can be useful if you've recently uploaded an AIML file, recompiled your bot and want access to your bot's latest changes.
  --recent: string # If true, the system will not signal an error if the bot is uncompiled, and will instead look for a previous version of the bot that is available.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "input" $input "scalar") (serialize-qp "client_name" $client_name "scalar") (serialize-qp "sessionid" $sessionid "scalar") (serialize-qp "that" $that "scalar") (serialize-qp "topic" $topic "scalar") (serialize-qp "extra" $extra "scalar") (serialize-qp "reset" $reset "scalar") (serialize-qp "trace" $trace "scalar") (serialize-qp "reload" $reload "scalar") (serialize-qp "recent" $recent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: $app_id, botname: $botname} | format pattern "/talk/{app_id}/{botname}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
