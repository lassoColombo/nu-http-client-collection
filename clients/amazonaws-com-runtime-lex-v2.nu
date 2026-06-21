# Auto-generated client for Amazon Lex Runtime V2 v2020-08-07
# Source: https://api.apis.guru/v2/specs/amazonaws.com/runtime.lex.v2/2020-08-07/openapi.json
# Auth: --token flag or $env.AMAZON_LEX_RUNTIME_V2_TOKEN

const BASE_URL = "http://runtime-v2-lex.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_LEX_RUNTIME_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["http://runtime-v2-lex.us-east-1.amazonaws.com" "http://runtime-v2-lex.us-east-2.amazonaws.com" "http://runtime-v2-lex.us-west-1.amazonaws.com" "http://runtime-v2-lex.us-west-2.amazonaws.com" "http://runtime-v2-lex.us-gov-west-1.amazonaws.com" "http://runtime-v2-lex.us-gov-east-1.amazonaws.com" "http://runtime-v2-lex.ca-central-1.amazonaws.com" "http://runtime-v2-lex.eu-north-1.amazonaws.com" "http://runtime-v2-lex.eu-west-1.amazonaws.com" "http://runtime-v2-lex.eu-west-2.amazonaws.com" "http://runtime-v2-lex.eu-west-3.amazonaws.com" "http://runtime-v2-lex.eu-central-1.amazonaws.com" "http://runtime-v2-lex.eu-south-1.amazonaws.com" "http://runtime-v2-lex.af-south-1.amazonaws.com" "http://runtime-v2-lex.ap-northeast-1.amazonaws.com" "http://runtime-v2-lex.ap-northeast-2.amazonaws.com" "http://runtime-v2-lex.ap-northeast-3.amazonaws.com" "http://runtime-v2-lex.ap-southeast-1.amazonaws.com" "http://runtime-v2-lex.ap-southeast-2.amazonaws.com" "http://runtime-v2-lex.ap-east-1.amazonaws.com" "http://runtime-v2-lex.ap-south-1.amazonaws.com" "http://runtime-v2-lex.sa-east-1.amazonaws.com" "http://runtime-v2-lex.me-south-1.amazonaws.com" "https://runtime-v2-lex.us-east-1.amazonaws.com" "https://runtime-v2-lex.us-east-2.amazonaws.com" "https://runtime-v2-lex.us-west-1.amazonaws.com" "https://runtime-v2-lex.us-west-2.amazonaws.com" "https://runtime-v2-lex.us-gov-west-1.amazonaws.com" "https://runtime-v2-lex.us-gov-east-1.amazonaws.com" "https://runtime-v2-lex.ca-central-1.amazonaws.com" "https://runtime-v2-lex.eu-north-1.amazonaws.com" "https://runtime-v2-lex.eu-west-1.amazonaws.com" "https://runtime-v2-lex.eu-west-2.amazonaws.com" "https://runtime-v2-lex.eu-west-3.amazonaws.com" "https://runtime-v2-lex.eu-central-1.amazonaws.com" "https://runtime-v2-lex.eu-south-1.amazonaws.com" "https://runtime-v2-lex.af-south-1.amazonaws.com" "https://runtime-v2-lex.ap-northeast-1.amazonaws.com" "https://runtime-v2-lex.ap-northeast-2.amazonaws.com" "https://runtime-v2-lex.ap-northeast-3.amazonaws.com" "https://runtime-v2-lex.ap-southeast-1.amazonaws.com" "https://runtime-v2-lex.ap-southeast-2.amazonaws.com" "https://runtime-v2-lex.ap-east-1.amazonaws.com" "https://runtime-v2-lex.ap-south-1.amazonaws.com" "https://runtime-v2-lex.sa-east-1.amazonaws.com" "https://runtime-v2-lex.me-south-1.amazonaws.com" "http://runtime-v2-lex.cn-north-1.amazonaws.com.cn" "http://runtime-v2-lex.cn-northwest-1.amazonaws.com.cn" "https://runtime-v2-lex.cn-north-1.amazonaws.com.cn" "https://runtime-v2-lex.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bots-bot-aliases-bot-locales-sessions delete" } } | get name | first)
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

# Removes session information for a specified bot, alias, and user ID. You can use this operation to restart a conversation with a bot. When you remove a session, the entire history of the session is removed so that you can start again. You don't need to delete a session. Sessions have a time limit and will expire. Set the session time limit when you create the bot. The default is 5 minutes, but you can specify anything between 1 minute and 24 hours. If you specify a bot or alias ID that doesn't exist, you receive a BadRequestException. If the locale doesn't exist in the bot, or if the locale hasn't been enables for the alias, you receive a BadRequestException.
#
# DELETE /bots/{botId}/botAliases/{botAliasId}/botLocales/{localeId}/sessions/{sessionId}
# operationId: DeleteSession
export def "bots-bot-aliases-bot-locales-sessions delete" [
  bot_id: string
  bot_alias_id: string
  locale_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<botId: record, botAliasId: record, localeId: record, sessionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_alias_id | is-empty) { error make --unspanned { msg: "path parameter 'botAliasId' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_alias_id: (encode-path-segment $bot_alias_id), locale_id: (encode-path-segment $locale_id), session_id: (encode-path-segment $session_id)} | format pattern "/bots/{bot_id}/botAliases/{bot_alias_id}/botLocales/{locale_id}/sessions/{session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns session information for a specified bot, alias, and user. For example, you can use this operation to retrieve session information for a user that has left a long-running session in use. If the bot, alias, or session identifier doesn't exist, Amazon Lex V2 returns a BadRequestException. If the locale doesn't exist or is not enabled for the alias, you receive a BadRequestException.
#
# GET /bots/{botId}/botAliases/{botAliasId}/botLocales/{localeId}/sessions/{sessionId}
# operationId: GetSession
export def "bots-bot-aliases-bot-locales-sessions get" [
  bot_id: string
  bot_alias_id: string
  locale_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<sessionId: record, messages: record, interpretations: record, sessionState: record<dialogAction: record<type: record, slotToElicit: record, slotElicitationStyle: record, subSlotToElicit: record>, intent: record<name: record, slots: record, state: record, confirmationState: record>, activeContexts: record, sessionAttributes: record, originatingRequestId: record, runtimeHints: record<slotHints: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_alias_id | is-empty) { error make --unspanned { msg: "path parameter 'botAliasId' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_alias_id: (encode-path-segment $bot_alias_id), locale_id: (encode-path-segment $locale_id), session_id: (encode-path-segment $session_id)} | format pattern "/bots/{bot_id}/botAliases/{bot_alias_id}/botLocales/{locale_id}/sessions/{session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new session or modifies an existing session with an Amazon Lex V2 bot. Use this operation to enable your application to set the state of the bot.
#
# POST /bots/{botId}/botAliases/{botAliasId}/botLocales/{localeId}/sessions/{sessionId}
# operationId: PutSession
# --messages item shape: {content?: any, contentType: any, imageResponseCard?: record}
# --sessionState shape: {dialogAction?: any, intent?: any, activeContexts?: any, sessionAttributes?: any, originatingRequestId?: any, runtimeHints?: any}
export def "bots-bot-aliases-bot-locales-sessions update" [
  bot_id: string
  bot_alias_id: string
  locale_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --response-content-type: string # The message that Amazon Lex V2 returns in the response can be either text or speech depending on the value of this parameter. If the value is text/plain; charset=utf-8, Amazon Lex V2 returns text in the response.
  --messages: list # A list of messages to send to the user. Messages are sent in the order that they are defined in the list. — item shape: {content?: any, contentType: any, imageResponseCard?: record}
  session_state: record # The state of the user's session with Amazon Lex V2. — shape: {dialogAction?: any, intent?: any, activeContexts?: any, sessionAttributes?: any, originatingRequestId?: any, runtimeHints?: any}
  --request-attributes: record # Request-specific information passed between Amazon Lex V2 and the client application. The namespace x-amz-lex: is reserved for special attributes. Don't create any request attributes with the prefix x-amz-lex:.
]: any -> record<audioStream: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_alias_id | is-empty) { error make --unspanned { msg: "path parameter 'botAliasId' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_alias_id: (encode-path-segment $bot_alias_id), locale_id: (encode-path-segment $locale_id), session_id: (encode-path-segment $session_id)} | format pattern "/bots/{bot_id}/botAliases/{bot_alias_id}/botLocales/{locale_id}/sessions/{session_id}"))
  let req_body = {"messages": $messages, "sessionState": $session_state, "requestAttributes": $request_attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "ResponseContentType": $response_content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sends user input to Amazon Lex V2. Client applications use this API to send requests to Amazon Lex V2 at runtime. Amazon Lex V2 then interprets the user input using the machine learning model that it build for the bot. In response, Amazon Lex V2 returns the next message to convey to the user and an optional response card to display. If the optional post-fulfillment response is specified, the messages are returned as follows. For more information, see PostFulfillmentStatusSpecification (https://docs.aws.amazon.com/lexv2/latest/dg/API_PostFulfillmentStatusSpecification.html). Success message - Returned if the Lambda function completes successfully and the intent state is fulfilled or ready fulfillment if the message is present. Failed message - The failed message is returned if the Lambda function throws an exception or if the Lambda function returns a failed intent state without a message. Timeout message - If you don't configure a timeout message and a timeout, and the Lambda function doesn't return within 30 seconds, the timeout message is returned. If you configure a timeout, the timeout message is returned when the period times out. For more information, see Completion message (https://docs.aws.amazon.com/lexv2/latest/dg/streaming-progress.html#progress-complete.html).
#
# POST /bots/{botId}/botAliases/{botAliasId}/botLocales/{localeId}/sessions/{sessionId}/text
# operationId: RecognizeText
# --sessionState shape: {dialogAction?: any, intent?: any, activeContexts?: any, sessionAttributes?: any, originatingRequestId?: any, runtimeHints?: any}
export def "bots-bot-aliases-bot-locales-sessions-text create-recognize" [
  bot_id: string
  bot_alias_id: string
  locale_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  text: string # The text that the user entered. Amazon Lex V2 interprets this text. (format: password)
  --session-state: record # The state of the user's session with Amazon Lex V2. — shape: {dialogAction?: any, intent?: any, activeContexts?: any, sessionAttributes?: any, originatingRequestId?: any, runtimeHints?: any}
  --request-attributes: record # Request-specific information passed between the client application and Amazon Lex V2 The namespace x-amz-lex: is reserved for special attributes. Don't create any request attributes with the prefix x-amz-lex:.
]: any -> record<messages: record, sessionState: record<dialogAction: record<type: record, slotToElicit: record, slotElicitationStyle: record, subSlotToElicit: record>, intent: record<name: record, slots: record, state: record, confirmationState: record>, activeContexts: record, sessionAttributes: record, originatingRequestId: record, runtimeHints: record<slotHints: record>>, interpretations: record, requestAttributes: record, sessionId: record, recognizedBotMember: record<botId: record, botName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_alias_id | is-empty) { error make --unspanned { msg: "path parameter 'botAliasId' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_alias_id: (encode-path-segment $bot_alias_id), locale_id: (encode-path-segment $locale_id), session_id: (encode-path-segment $session_id)} | format pattern "/bots/{bot_id}/botAliases/{bot_alias_id}/botLocales/{locale_id}/sessions/{session_id}/text"))
  let req_body = {"text": $text, "sessionState": $session_state, "requestAttributes": $request_attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sends user input to Amazon Lex V2. You can send text or speech. Clients use this API to send text and audio requests to Amazon Lex V2 at runtime. Amazon Lex V2 interprets the user input using the machine learning model built for the bot. The following request fields must be compressed with gzip and then base64 encoded before you send them to Amazon Lex V2. requestAttributes sessionState The following response fields are compressed using gzip and then base64 encoded by Amazon Lex V2. Before you can use these fields, you must decode and decompress them. inputTranscript interpretations messages requestAttributes sessionState The example contains a Java application that compresses and encodes a Java object to send to Amazon Lex V2, and a second that decodes and decompresses a response from Amazon Lex V2. If the optional post-fulfillment response is specified, the messages are returned as follows. For more information, see PostFulfillmentStatusSpecification (https://docs.aws.amazon.com/lexv2/latest/dg/API_PostFulfillmentStatusSpecification.html). Success message - Returned if the Lambda function completes successfully and the intent state is fulfilled or ready fulfillment if the message is present. Failed message - The failed message is returned if the Lambda function throws an exception or if the Lambda function returns a failed intent state without a message. Timeout message - If you don't configure a timeout message and a timeout, and the Lambda function doesn't return within 30 seconds, the timeout message is returned. If you configure a timeout, the timeout message is returned when the period times out. For more information, see Completion message (https://docs.aws.amazon.com/lexv2/latest/dg/streaming-progress.html#progress-complete.html).
#
# POST /bots/{botId}/botAliases/{botAliasId}/botLocales/{localeId}/sessions/{sessionId}/utterance
# operationId: RecognizeUtterance
export def "bots-bot-aliases-bot-locales-sessions-utterance create-recognize" [
  bot_id: string
  bot_alias_id: string
  locale_id: string
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-lex-session-state: string # Sets the state of the session with the user. You can use this to set the current intent, attributes, context, and dialog action. Use the dialog action to determine the next step that Amazon Lex V2 should use in the conversation with the user. The sessionState field must be compressed using gzip and then base64 encoded before sending to Amazon Lex V2.
  --x-amz-lex-request-attributes: string # Request-specific information passed between the client application and Amazon Lex V2 The namespace x-amz-lex: is reserved for special attributes. Don't create any request attributes for prefix x-amz-lex:. The requestAttributes field must be compressed using gzip and then base64 encoded before sending to Amazon Lex V2.
  --content-type: string # Indicates the format for audio input or that the content is text. The header must start with one of the following prefixes: PCM format, audio data must be in little-endian byte order. audio/l16; rate=16000; channels=1 audio/x-l16; sample-rate=16000; channel-count=1 audio/lpcm; sample-rate=8000; sample-size-bits=16; channel-count=1; is-big-endian=false Opus format audio/x-cbr-opus-with-preamble;preamble-size=0;bit-rate=256000;frame-size-milliseconds=4 Text format text/plain; charset=utf-8
  --response-content-type: string # The message that Amazon Lex V2 returns in the response can be either text or speech based on the responseContentType value. If the value is text/plain;charset=utf-8, Amazon Lex V2 returns text in the response. If the value begins with audio/, Amazon Lex V2 returns speech in the response. Amazon Lex V2 uses Amazon Polly to generate the speech using the configuration that you specified in the responseContentType parameter. For example, if you specify audio/mpeg as the value, Amazon Lex V2 returns speech in the MPEG format. If the value is audio/pcm, the speech returned is audio/pcm at 16 KHz in 16-bit, little-endian format. The following are the accepted values: audio/mpeg audio/ogg audio/pcm (16 KHz) audio/* (defaults to mpeg) text/plain; charset=utf-8
  --input-stream: string # User input in PCM or Opus audio format or text format as described in the requestContentType parameter.
]: any -> record<audioStream: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_alias_id | is-empty) { error make --unspanned { msg: "path parameter 'botAliasId' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($session_id | is-empty) { error make --unspanned { msg: "path parameter 'sessionId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_alias_id: (encode-path-segment $bot_alias_id), locale_id: (encode-path-segment $locale_id), session_id: (encode-path-segment $session_id)} | format pattern "/bots/{bot_id}/botAliases/{bot_alias_id}/botLocales/{locale_id}/sessions/{session_id}/utterance"))
  let req_body = {"inputStream": $input_stream} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-lex-session-state": $x_amz_lex_session_state, "x-amz-lex-request-attributes": $x_amz_lex_request_attributes, "Content-Type": $content_type, "Response-Content-Type": $response_content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}
