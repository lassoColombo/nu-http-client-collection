# Auto-generated client for Amazon WorkMail Message Flow v2019-05-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/workmailmessageflow/2019-05-01/openapi.json
# Auth: --token flag or $env.AMAZON_WORKMAIL_MESSAGE_FLOW_TOKEN

const BASE_URL = "http://workmailmessageflow.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_WORKMAIL_MESSAGE_FLOW_TOKEN | default "" }
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

def base-url-completer [] { ["http://workmailmessageflow.us-east-1.amazonaws.com" "http://workmailmessageflow.us-east-2.amazonaws.com" "http://workmailmessageflow.us-west-1.amazonaws.com" "http://workmailmessageflow.us-west-2.amazonaws.com" "http://workmailmessageflow.us-gov-west-1.amazonaws.com" "http://workmailmessageflow.us-gov-east-1.amazonaws.com" "http://workmailmessageflow.ca-central-1.amazonaws.com" "http://workmailmessageflow.eu-north-1.amazonaws.com" "http://workmailmessageflow.eu-west-1.amazonaws.com" "http://workmailmessageflow.eu-west-2.amazonaws.com" "http://workmailmessageflow.eu-west-3.amazonaws.com" "http://workmailmessageflow.eu-central-1.amazonaws.com" "http://workmailmessageflow.eu-south-1.amazonaws.com" "http://workmailmessageflow.af-south-1.amazonaws.com" "http://workmailmessageflow.ap-northeast-1.amazonaws.com" "http://workmailmessageflow.ap-northeast-2.amazonaws.com" "http://workmailmessageflow.ap-northeast-3.amazonaws.com" "http://workmailmessageflow.ap-southeast-1.amazonaws.com" "http://workmailmessageflow.ap-southeast-2.amazonaws.com" "http://workmailmessageflow.ap-east-1.amazonaws.com" "http://workmailmessageflow.ap-south-1.amazonaws.com" "http://workmailmessageflow.sa-east-1.amazonaws.com" "http://workmailmessageflow.me-south-1.amazonaws.com" "https://workmailmessageflow.us-east-1.amazonaws.com" "https://workmailmessageflow.us-east-2.amazonaws.com" "https://workmailmessageflow.us-west-1.amazonaws.com" "https://workmailmessageflow.us-west-2.amazonaws.com" "https://workmailmessageflow.us-gov-west-1.amazonaws.com" "https://workmailmessageflow.us-gov-east-1.amazonaws.com" "https://workmailmessageflow.ca-central-1.amazonaws.com" "https://workmailmessageflow.eu-north-1.amazonaws.com" "https://workmailmessageflow.eu-west-1.amazonaws.com" "https://workmailmessageflow.eu-west-2.amazonaws.com" "https://workmailmessageflow.eu-west-3.amazonaws.com" "https://workmailmessageflow.eu-central-1.amazonaws.com" "https://workmailmessageflow.eu-south-1.amazonaws.com" "https://workmailmessageflow.af-south-1.amazonaws.com" "https://workmailmessageflow.ap-northeast-1.amazonaws.com" "https://workmailmessageflow.ap-northeast-2.amazonaws.com" "https://workmailmessageflow.ap-northeast-3.amazonaws.com" "https://workmailmessageflow.ap-southeast-1.amazonaws.com" "https://workmailmessageflow.ap-southeast-2.amazonaws.com" "https://workmailmessageflow.ap-east-1.amazonaws.com" "https://workmailmessageflow.ap-south-1.amazonaws.com" "https://workmailmessageflow.sa-east-1.amazonaws.com" "https://workmailmessageflow.me-south-1.amazonaws.com" "http://workmailmessageflow.cn-north-1.amazonaws.com.cn" "http://workmailmessageflow.cn-northwest-1.amazonaws.com.cn" "https://workmailmessageflow.cn-north-1.amazonaws.com.cn" "https://workmailmessageflow.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "messages get-raw-content" } } | get name | first)
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

# Retrieves the raw content of an in-transit email message, in MIME format.
#
# GET /messages/{messageId}
# operationId: GetRawMessageContent
export def "messages get-raw-content" [
  message_id: string
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
]: nothing -> record<messageContent: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/messages/{message_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the raw content of an in-transit email message, in MIME format. This example describes how to update in-transit email message. For more information and examples for using this API, see Updating message content with AWS Lambda (https://docs.aws.amazon.com/workmail/latest/adminguide/update-with-lambda.html). Updates to an in-transit message only appear when you call PutRawMessageContent from an AWS Lambda function configured with a synchronous Run Lambda (https://docs.aws.amazon.com/workmail/latest/adminguide/lambda.html#synchronous-rules) rule. If you call PutRawMessageContent on a delivered or sent message, the message remains unchanged, even though GetRawMessageContent (https://docs.aws.amazon.com/workmail/latest/APIReference/API_messageflow_GetRawMessageContent.html) returns an updated message.
#
# POST /messages/{messageId}
# operationId: PutRawMessageContent
# --content shape: {s3Reference?: any}
export def "messages update-raw-content" [
  message_id: string
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
  content: record # Provides the MIME content of the updated email message as an S3 object. All MIME content must meet the following criteria: Each part of a multipart MIME message must be formatted properly. Attachments must be of a content type that Amazon SES supports. For more information, see Unsupported Attachment Types (https://docs.aws.amazon.com/ses/latest/DeveloperGuide/mime-types-appendix.html). If any of the MIME parts in a message contain content that is outside of the 7-bit ASCII character range, we recommend encoding that content. Per RFC 5321 (https://tools.ietf.org/html/rfc5321#section-4.5.3.1.6), the maximum length of each line of text, including the <CRLF>, must not exceed 1,000 characters. The message must contain all the required header fields. Check the returned error message for more information. The value of immutable headers must remain unchanged. Check the returned error message for more information. Certain unique headers can only appear once. Check the returned error message for more information. — shape: {s3Reference?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/messages/{message_id}"))
  let req_body = {"content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
