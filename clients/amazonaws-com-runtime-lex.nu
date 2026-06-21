# Auto-generated client for Amazon Lex Runtime Service v2016-11-28
# Source: https://api.apis.guru/v2/specs/amazonaws.com/runtime.lex/2016-11-28/openapi.json
# Auth: --token flag or $env.AMAZON_LEX_RUNTIME_SERVICE_TOKEN

const BASE_URL = "http://runtime.lex.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_LEX_RUNTIME_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://runtime.lex.us-east-1.amazonaws.com" "http://runtime.lex.us-east-2.amazonaws.com" "http://runtime.lex.us-west-1.amazonaws.com" "http://runtime.lex.us-west-2.amazonaws.com" "http://runtime.lex.us-gov-west-1.amazonaws.com" "http://runtime.lex.us-gov-east-1.amazonaws.com" "http://runtime.lex.ca-central-1.amazonaws.com" "http://runtime.lex.eu-north-1.amazonaws.com" "http://runtime.lex.eu-west-1.amazonaws.com" "http://runtime.lex.eu-west-2.amazonaws.com" "http://runtime.lex.eu-west-3.amazonaws.com" "http://runtime.lex.eu-central-1.amazonaws.com" "http://runtime.lex.eu-south-1.amazonaws.com" "http://runtime.lex.af-south-1.amazonaws.com" "http://runtime.lex.ap-northeast-1.amazonaws.com" "http://runtime.lex.ap-northeast-2.amazonaws.com" "http://runtime.lex.ap-northeast-3.amazonaws.com" "http://runtime.lex.ap-southeast-1.amazonaws.com" "http://runtime.lex.ap-southeast-2.amazonaws.com" "http://runtime.lex.ap-east-1.amazonaws.com" "http://runtime.lex.ap-south-1.amazonaws.com" "http://runtime.lex.sa-east-1.amazonaws.com" "http://runtime.lex.me-south-1.amazonaws.com" "https://runtime.lex.us-east-1.amazonaws.com" "https://runtime.lex.us-east-2.amazonaws.com" "https://runtime.lex.us-west-1.amazonaws.com" "https://runtime.lex.us-west-2.amazonaws.com" "https://runtime.lex.us-gov-west-1.amazonaws.com" "https://runtime.lex.us-gov-east-1.amazonaws.com" "https://runtime.lex.ca-central-1.amazonaws.com" "https://runtime.lex.eu-north-1.amazonaws.com" "https://runtime.lex.eu-west-1.amazonaws.com" "https://runtime.lex.eu-west-2.amazonaws.com" "https://runtime.lex.eu-west-3.amazonaws.com" "https://runtime.lex.eu-central-1.amazonaws.com" "https://runtime.lex.eu-south-1.amazonaws.com" "https://runtime.lex.af-south-1.amazonaws.com" "https://runtime.lex.ap-northeast-1.amazonaws.com" "https://runtime.lex.ap-northeast-2.amazonaws.com" "https://runtime.lex.ap-northeast-3.amazonaws.com" "https://runtime.lex.ap-southeast-1.amazonaws.com" "https://runtime.lex.ap-southeast-2.amazonaws.com" "https://runtime.lex.ap-east-1.amazonaws.com" "https://runtime.lex.ap-south-1.amazonaws.com" "https://runtime.lex.sa-east-1.amazonaws.com" "https://runtime.lex.me-south-1.amazonaws.com" "http://runtime.lex.cn-north-1.amazonaws.com.cn" "http://runtime.lex.cn-northwest-1.amazonaws.com.cn" "https://runtime.lex.cn-north-1.amazonaws.com.cn" "https://runtime.lex.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bot-alias-user-session delete" } } | get name | first)
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

# Removes session information for a specified bot, alias, and user ID.
#
# DELETE /bot/{botName}/alias/{botAlias}/user/{userId}/session
# operationId: DeleteSession
export def "bot-alias-user-session delete" [
  bot_name: string
  bot_alias: string
  user_id: string
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
]: nothing -> record<botName: record, botAlias: record, userId: record, sessionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($bot_alias | is-empty) { error make --unspanned { msg: "path parameter 'botAlias' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), bot_alias: (encode-path-segment $bot_alias), user_id: (encode-path-segment $user_id)} | format pattern "/bot/{bot_name}/alias/{bot_alias}/user/{user_id}/session"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new session or modifies an existing session with an Amazon Lex bot. Use this operation to enable your application to set the state of the bot. For more information, see Managing Sessions (https://docs.aws.amazon.com/lex/latest/dg/how-session-api.html).
#
# POST /bot/{botName}/alias/{botAlias}/user/{userId}/session
# operationId: PutSession
# --dialogAction shape: {type?: any, intentName?: any, slots?: any, slotToElicit?: any, fulfillmentState?: any, message?: any, messageFormat?: any}
# --recentIntentSummaryView item shape: {intentName?: any, checkpointLabel?: any, slots?: any, confirmationStatus?: any, dialogActionType: any, fulfillmentState?: any, slotToElicit?: any}
# --activeContexts item shape: {name: any, timeToLive: any, parameters: any}
export def "bot-alias-user-session update" [
  bot_name: string
  bot_alias: string
  user_id: string
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
  --hdr-accept: string # The message that Amazon Lex returns in the response can be either text or speech based depending on the value of this field. If the value is text/plain; charset=utf-8, Amazon Lex returns text in the response. If the value begins with audio/, Amazon Lex returns speech in the response. Amazon Lex uses Amazon Polly to generate the speech in the configuration that you specify. For example, if you specify audio/mpeg as the value, Amazon Lex returns speech in the MPEG format. If the value is audio/pcm, the speech is returned as audio/pcm in 16-bit, little endian format. The following are the accepted values: audio/mpeg audio/ogg audio/pcm audio/* (defaults to mpeg) text/plain; charset=utf-8
  --session-attributes: record # Map of key/value pairs representing the session-specific context information. It contains application information passed between Amazon Lex and a client application.
  --dialog-action: record # Describes the next action that the bot should take in its interaction with the user and provides information about the context in which the action takes place. Use the DialogAction data type to set the interaction to a specific state, or to return the interaction to a previous state. — shape: {type?: any, intentName?: any, slots?: any, slotToElicit?: any, fulfillmentState?: any, message?: any, messageFormat?: any}
  --recent-intent-summary-view: list # A summary of the recent intents for the bot. You can use the intent summary view to set a checkpoint label on an intent and modify attributes of intents. You can also use it to remove or add intent summary objects to the list. An intent that you modify or add to the list must make sense for the bot. For example, the intent name must be valid for the bot. You must provide valid values for: intentName slot names slotToElict If you send the recentIntentSummaryView parameter in a PutSession request, the contents of the new summary view replaces the old summary view. For example, if a GetSession request returns three intents in the summary view and you call PutSession with one intent in the summary view, the next call to GetSession will only return one intent. — item shape: {intentName?: any, checkpointLabel?: any, slots?: any, confirmationStatus?: any, dialogActionType: any, fulfillmentState?: any, slotToElicit?: any}
  --active-contexts: list # A list of contexts active for the request. A context can be activated when a previous intent is fulfilled, or by including the context in the request, If you don't specify a list of contexts, Amazon Lex will use the current list of contexts for the session. If you specify an empty list, all contexts for the session are cleared. — item shape: {name: any, timeToLive: any, parameters: any}
]: any -> record<audioStream: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($bot_alias | is-empty) { error make --unspanned { msg: "path parameter 'botAlias' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), bot_alias: (encode-path-segment $bot_alias), user_id: (encode-path-segment $user_id)} | format pattern "/bot/{bot_name}/alias/{bot_alias}/user/{user_id}/session"))
  let req_body = {"sessionAttributes": $session_attributes, "dialogAction": $dialog_action, "recentIntentSummaryView": $recent_intent_summary_view, "activeContexts": $active_contexts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns session information for a specified bot, alias, and user ID.
#
# GET /bot/{botName}/alias/{botAlias}/user/{userId}/session/
# operationId: GetSession
export def "bot-alias-user-session get" [
  bot_name: string
  bot_alias: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checkpoint-label-filter: string # A string used to filter the intents returned in the recentIntentSummaryView structure. When you specify a filter, only intents with their checkpointLabel field set to that string are returned.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<recentIntentSummaryView: record, sessionAttributes: record, sessionId: record, dialogAction: record<type: record, intentName: record, slots: record, slotToElicit: record, fulfillmentState: record, message: record, messageFormat: record>, activeContexts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($bot_alias | is-empty) { error make --unspanned { msg: "path parameter 'botAlias' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "checkpointLabelFilter" $checkpoint_label_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), bot_alias: (encode-path-segment $bot_alias), user_id: (encode-path-segment $user_id)} | format pattern "/bot/{bot_name}/alias/{bot_alias}/user/{user_id}/session/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"checkpointLabelFilter": $checkpoint_label_filter} | compact), body: null}
}

# Sends user input (text or speech) to Amazon Lex. Clients use this API to send text and audio requests to Amazon Lex at runtime. Amazon Lex interprets the user input using the machine learning model that it built for the bot. The PostContent operation supports audio input at 8kHz and 16kHz. You can use 8kHz audio to achieve higher speech recognition accuracy in telephone audio applications. In response, Amazon Lex returns the next message to convey to the user. Consider the following example messages: For a user input "I would like a pizza," Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?". After the user provides all of the pizza order information, Amazon Lex might return a response with a message to get user confirmation: "Order the pizza?". After the user replies "Yes" to the confirmation prompt, Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". Not all Amazon Lex messages require a response from the user. For example, conclusion statements do not require a response. Some messages require only a yes or no response. In addition to the message, Amazon Lex provides additional context about the message in the response that you can use to enhance client behavior, such as displaying the appropriate client user interface. Consider the following examples: If the message is to elicit slot data, Amazon Lex returns the following context information: x-amz-lex-dialog-state header set to ElicitSlot x-amz-lex-intent-name header set to the intent name in the current context x-amz-lex-slot-to-elicit header set to the slot name for which the message is eliciting information x-amz-lex-slots header set to a map of slots configured for the intent with their current values If the message is a confirmation prompt, the x-amz-lex-dialog-state header is set to Confirmation and the x-amz-lex-slot-to-elicit header is omitted. If the message is a clarification prompt configured for the intent, indicating that the user intent is not understood, the x-amz-dialog-state header is set to ElicitIntent and the x-amz-slot-to-elicit header is omitted. In addition, Amazon Lex also returns your application-specific sessionAttributes. For more information, see Managing Conversation Context (https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html).
#
# POST /bot/{botName}/alias/{botAlias}/user/{userId}/content
# operationId: PostContent
export def "bot-alias-user-content create" [
  bot_name: string
  bot_alias: string
  user_id: string
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
  --x-amz-lex-session-attributes: string # You pass this value as the x-amz-lex-session-attributes HTTP header. Application-specific information passed between Amazon Lex and a client application. The value must be a JSON serialized and base64 encoded map with string keys and values. The total size of the sessionAttributes and requestAttributes headers is limited to 12 KB. For more information, see Setting Session Attributes (https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html#context-mgmt-session-attribs).
  --x-amz-lex-request-attributes: string # You pass this value as the x-amz-lex-request-attributes HTTP header. Request-specific information passed between Amazon Lex and a client application. The value must be a JSON serialized and base64 encoded map with string keys and values. The total size of the requestAttributes and sessionAttributes headers is limited to 12 KB. The namespace x-amz-lex: is reserved for special attributes. Don't create any request attributes with the prefix x-amz-lex:. For more information, see Setting Request Attributes (https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html#context-mgmt-request-attribs).
  --content-type: string # You pass this value as the Content-Type HTTP header. Indicates the audio format or text. The header value must start with one of the following prefixes: PCM format, audio data must be in little-endian byte order. audio/l16; rate=16000; channels=1 audio/x-l16; sample-rate=16000; channel-count=1 audio/lpcm; sample-rate=8000; sample-size-bits=16; channel-count=1; is-big-endian=false Opus format audio/x-cbr-opus-with-preamble; preamble-size=0; bit-rate=256000; frame-size-milliseconds=4 Text format text/plain; charset=utf-8
  --hdr-accept: string # You pass this value as the Accept HTTP header. The message Amazon Lex returns in the response can be either text or speech based on the Accept HTTP header value in the request. If the value is text/plain; charset=utf-8, Amazon Lex returns text in the response. If the value begins with audio/, Amazon Lex returns speech in the response. Amazon Lex uses Amazon Polly to generate the speech (using the configuration you specified in the Accept header). For example, if you specify audio/mpeg as the value, Amazon Lex returns speech in the MPEG format. If the value is audio/pcm, the speech returned is audio/pcm in 16-bit, little endian format. The following are the accepted values: audio/mpeg audio/ogg audio/pcm text/plain; charset=utf-8 audio/* (defaults to mpeg)
  --x-amz-lex-active-contexts: string # A list of contexts active for the request. A context can be activated when a previous intent is fulfilled, or by including the context in the request, If you don't specify a list of contexts, Amazon Lex will use the current list of contexts for the session. If you specify an empty list, all contexts for the session are cleared.
  input_stream: string # User input in PCM or Opus audio format or text format as described in the Content-Type HTTP header. You can stream audio data to Amazon Lex or you can create a local buffer that captures all of the audio data before sending. In general, you get better performance if you stream audio data rather than buffering the data locally.
]: any -> record<audioStream: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($bot_alias | is-empty) { error make --unspanned { msg: "path parameter 'botAlias' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), bot_alias: (encode-path-segment $bot_alias), user_id: (encode-path-segment $user_id)} | format pattern "/bot/{bot_name}/alias/{bot_alias}/user/{user_id}/content"))
  let req_body = {"inputStream": $input_stream} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-lex-session-attributes": $x_amz_lex_session_attributes, "x-amz-lex-request-attributes": $x_amz_lex_request_attributes, "Content-Type": $content_type, "Accept": $hdr_accept, "x-amz-lex-active-contexts": $x_amz_lex_active_contexts} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Sends user input to Amazon Lex. Client applications can use this API to send requests to Amazon Lex at runtime. Amazon Lex then interprets the user input using the machine learning model it built for the bot. In response, Amazon Lex returns the next message to convey to the user an optional responseCard to display. Consider the following example messages: For a user input "I would like a pizza", Amazon Lex might return a response with a message eliciting slot data (for example, PizzaSize): "What size pizza would you like?" After the user provides all of the pizza order information, Amazon Lex might return a response with a message to obtain user confirmation "Proceed with the pizza order?". After the user replies to a confirmation prompt with a "yes", Amazon Lex might return a conclusion statement: "Thank you, your cheese pizza has been ordered.". Not all Amazon Lex messages require a user response. For example, a conclusion statement does not require a response. Some messages require only a "yes" or "no" user response. In addition to the message, Amazon Lex provides additional context about the message in the response that you might use to enhance client behavior, for example, to display the appropriate client user interface. These are the slotToElicit, dialogState, intentName, and slots fields in the response. Consider the following examples: If the message is to elicit slot data, Amazon Lex returns the following context information: dialogState set to ElicitSlot intentName set to the intent name in the current context slotToElicit set to the slot name for which the message is eliciting information slots set to a map of slots, configured for the intent, with currently known values If the message is a confirmation prompt, the dialogState is set to ConfirmIntent and SlotToElicit is set to null. If the message is a clarification prompt (configured for the intent) that indicates that user intent is not understood, the dialogState is set to ElicitIntent and slotToElicit is set to null. In addition, Amazon Lex also returns your application-specific sessionAttributes. For more information, see Managing Conversation Context (https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html).
#
# POST /bot/{botName}/alias/{botAlias}/user/{userId}/text
# operationId: PostText
# --activeContexts item shape: {name: any, timeToLive: any, parameters: any}
export def "bot-alias-user-text create" [
  bot_name: string
  bot_alias: string
  user_id: string
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
  --session-attributes: record # Application-specific information passed between Amazon Lex and a client application. For more information, see Setting Session Attributes (https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html#context-mgmt-session-attribs).
  --request-attributes: record # Request-specific information passed between Amazon Lex and a client application. The namespace x-amz-lex: is reserved for special attributes. Don't create any request attributes with the prefix x-amz-lex:. For more information, see Setting Request Attributes (https://docs.aws.amazon.com/lex/latest/dg/context-mgmt.html#context-mgmt-request-attribs).
  input_text: string # The text that the user entered (Amazon Lex interprets this text). (format: password)
  --active-contexts: list # A list of contexts active for the request. A context can be activated when a previous intent is fulfilled, or by including the context in the request, If you don't specify a list of contexts, Amazon Lex will use the current list of contexts for the session. If you specify an empty list, all contexts for the session are cleared. — item shape: {name: any, timeToLive: any, parameters: any}
]: any -> record<intentName: record, nluIntentConfidence: record<score: record>, alternativeIntents: record, slots: record, sessionAttributes: record, message: record, sentimentResponse: record<sentimentLabel: record, sentimentScore: record>, messageFormat: record, dialogState: record, slotToElicit: record, responseCard: record<version: record, contentType: record, genericAttachments: record>, sessionId: record, botVersion: record, activeContexts: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($bot_alias | is-empty) { error make --unspanned { msg: "path parameter 'botAlias' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), bot_alias: (encode-path-segment $bot_alias), user_id: (encode-path-segment $user_id)} | format pattern "/bot/{bot_name}/alias/{bot_alias}/user/{user_id}/text"))
  let req_body = {"sessionAttributes": $session_attributes, "requestAttributes": $request_attributes, "inputText": $input_text, "activeContexts": $active_contexts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
