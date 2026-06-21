# Auto-generated client for Pandorabots AIaaS v1.0.0
# Source: https://api.apis.guru/v2/specs/pandorabots.com/1.0.0/swagger.json
# Auth: --token flag or $env.PANDORABOTS_AIAAS_TOKEN

const BASE_URL = "https://aiaas.pandorabots.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PANDORABOTS_AIAAS_TOKEN | default "" }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://aiaas.pandorabots.com"] }
def auth-scheme-completer [] { ["query-user_key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "atalk create-bot" } } | get name | first)
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
export def "atalk create-bot" [
  app_id: string
  botname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --input: string # Message to be sent to the bot. This can contain multiple sentences. Currently the limit is 500 characters.
  --client-name: string # Leave blank to request Pandorabots to create a client_name which will support persistent predicates. Including a valid client_name in this parameter will work in the same way that Talk to Bot API but with persistent predicates. It is recommended to use this API only to create an end-user client_name, and then use normal Talk to Bot API to continue conversation with the bot.
  --sessionid: string # Session ID generated by Pandorabots. This allows the application to group individual conversations into a collection as needed. If not included in the call, Pandorabots will issue a new session ID. (4-byte integer type)
  --recent: string # If true, the system will not signal an error if the bot is uncompiled, and will instead look for a previous version of the bot that is available.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  let qp = [(serialize-qp "input" $input "scalar") (serialize-qp "client_name" $client_name "scalar") (serialize-qp "sessionid" $sessionid "scalar") (serialize-qp "recent" $recent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname)} | format pattern "/atalk/{app_id}/{botname}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"input": $input, "client_name": $client_name, "sessionid": $sessionid, "recent": $recent} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/bot/{app_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname)} | format pattern "/bot/{app_id}/{botname}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of bot files
#
# GET /bot/{app_id}/{botname}
# operationId: listBotFiles
export def "bot list-files" [
  app_id: string
  botname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-return: string # If set to zip, a zip file with all bot files will be returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  let qp = [(serialize-qp "return" $qp_return "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname)} | format pattern "/bot/{app_id}/{botname}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"return": $qp_return} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname)} | format pattern "/bot/{app_id}/{botname}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Compile a bot
#
# GET /bot/{app_id}/{botname}/verify
# operationId: compileBot
export def "bot-verify get-compile" [
  app_id: string
  botname: string
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
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname)} | format pattern "/bot/{app_id}/{botname}/verify"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a bot file (pdefaults, properties)
#
# DELETE /bot/{app_id}/{botname}/{file-kind}
# operationId: deleteBotFile2
export def "bot delete-file2" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  if ($file_kind | is-empty) { error make --unspanned { msg: "path parameter 'file-kind' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname), file_kind: (encode-path-segment $file_kind)} | format pattern "/bot/{app_id}/{botname}/{file_kind}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a bot file (pdefaults, properties)
#
# GET /bot/{app_id}/{botname}/{file-kind}
# operationId: getBotFile2
export def "bot get-file2" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  if ($file_kind | is-empty) { error make --unspanned { msg: "path parameter 'file-kind' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname), file_kind: (encode-path-segment $file_kind)} | format pattern "/bot/{app_id}/{botname}/{file_kind}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  if ($file_kind | is-empty) { error make --unspanned { msg: "path parameter 'file-kind' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname), file_kind: (encode-path-segment $file_kind)} | format pattern "/bot/{app_id}/{botname}/{file_kind}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml" $req_body {query: {}, body: $req_body}
}

# Delete a bot file (AIML, set, map, substitution)
#
# DELETE /bot/{app_id}/{botname}/{file-kind}/{filename}
# operationId: deleteBotFile1
export def "bot delete-file1" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  if ($file_kind | is-empty) { error make --unspanned { msg: "path parameter 'file-kind' must be non-empty" } }
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname), file_kind: (encode-path-segment $file_kind), filename: (encode-path-segment $filename)} | format pattern "/bot/{app_id}/{botname}/{file_kind}/{filename}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a bot file (AIML, set, map, substitution)
#
# GET /bot/{app_id}/{botname}/{file-kind}/{filename}
# operationId: getBotFile1
export def "bot get-file1" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  if ($file_kind | is-empty) { error make --unspanned { msg: "path parameter 'file-kind' must be non-empty" } }
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname), file_kind: (encode-path-segment $file_kind), filename: (encode-path-segment $filename)} | format pattern "/bot/{app_id}/{botname}/{file_kind}/{filename}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-user_key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  if ($file_kind | is-empty) { error make --unspanned { msg: "path parameter 'file-kind' must be non-empty" } }
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname), file_kind: (encode-path-segment $file_kind), filename: (encode-path-segment $filename)} | format pattern "/bot/{app_id}/{botname}/{file_kind}/{filename}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml" $req_body {query: {}, body: $req_body}
}

# Debug a bot conversation
#
# POST /talk/{app_id}/{botname}
# operationId: debugBot
export def "talk create-debug-bot" [
  app_id: string
  botname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  let qp = [(serialize-qp "input" $input "scalar") (serialize-qp "client_name" $client_name "scalar") (serialize-qp "sessionid" $sessionid "scalar") (serialize-qp "that" $that "scalar") (serialize-qp "topic" $topic "scalar") (serialize-qp "extra" $extra "scalar") (serialize-qp "reset" $reset "scalar") (serialize-qp "trace" $trace "scalar") (serialize-qp "reload" $reload "scalar") (serialize-qp "recent" $recent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), botname: (encode-path-segment $botname)} | format pattern "/talk/{app_id}/{botname}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"input": $input, "client_name": $client_name, "sessionid": $sessionid, "that": $that, "topic": $topic, "extra": $extra, "reset": $reset, "trace": $trace, "reload": $reload, "recent": $recent} | compact), body: null}
}
