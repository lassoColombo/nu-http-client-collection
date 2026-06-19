# Auto-generated client for Amazon Simple Queue Service v2012-11-05
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sqs/2012-11-05/openapi.json
# Auth: --token flag or $env.AMAZON_SIMPLE_QUEUE_SERVICE_TOKEN

const BASE_URL = "http://sqs.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_SIMPLE_QUEUE_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://sqs.us-east-1.amazonaws.com" "http://sqs.us-east-2.amazonaws.com" "http://sqs.us-west-1.amazonaws.com" "http://sqs.us-west-2.amazonaws.com" "http://sqs.us-gov-west-1.amazonaws.com" "http://sqs.us-gov-east-1.amazonaws.com" "http://sqs.ca-central-1.amazonaws.com" "http://sqs.eu-north-1.amazonaws.com" "http://sqs.eu-west-1.amazonaws.com" "http://sqs.eu-west-2.amazonaws.com" "http://sqs.eu-west-3.amazonaws.com" "http://sqs.eu-central-1.amazonaws.com" "http://sqs.eu-south-1.amazonaws.com" "http://sqs.af-south-1.amazonaws.com" "http://sqs.ap-northeast-1.amazonaws.com" "http://sqs.ap-northeast-2.amazonaws.com" "http://sqs.ap-northeast-3.amazonaws.com" "http://sqs.ap-southeast-1.amazonaws.com" "http://sqs.ap-southeast-2.amazonaws.com" "http://sqs.ap-east-1.amazonaws.com" "http://sqs.ap-south-1.amazonaws.com" "http://sqs.sa-east-1.amazonaws.com" "http://sqs.me-south-1.amazonaws.com" "https://sqs.us-east-1.amazonaws.com" "https://sqs.us-east-2.amazonaws.com" "https://sqs.us-west-1.amazonaws.com" "https://sqs.us-west-2.amazonaws.com" "https://sqs.us-gov-west-1.amazonaws.com" "https://sqs.us-gov-east-1.amazonaws.com" "https://sqs.ca-central-1.amazonaws.com" "https://sqs.eu-north-1.amazonaws.com" "https://sqs.eu-west-1.amazonaws.com" "https://sqs.eu-west-2.amazonaws.com" "https://sqs.eu-west-3.amazonaws.com" "https://sqs.eu-central-1.amazonaws.com" "https://sqs.eu-south-1.amazonaws.com" "https://sqs.af-south-1.amazonaws.com" "https://sqs.ap-northeast-1.amazonaws.com" "https://sqs.ap-northeast-2.amazonaws.com" "https://sqs.ap-northeast-3.amazonaws.com" "https://sqs.ap-southeast-1.amazonaws.com" "https://sqs.ap-southeast-2.amazonaws.com" "https://sqs.ap-east-1.amazonaws.com" "https://sqs.ap-south-1.amazonaws.com" "https://sqs.sa-east-1.amazonaws.com" "https://sqs.me-south-1.amazonaws.com" "http://sqs.cn-north-1.amazonaws.com.cn" "http://sqs.cn-northwest-1.amazonaws.com.cn" "https://sqs.cn-north-1.amazonaws.com.cn" "https://sqs.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["AddPermission"] }
def version-completer [] { ["2012-11-05"] }
def action-completer-1 [] { ["ChangeMessageVisibility"] }
def action-completer-2 [] { ["ChangeMessageVisibilityBatch"] }
def action-completer-3 [] { ["CreateQueue"] }
def action-completer-4 [] { ["DeleteMessage"] }
def action-completer-5 [] { ["DeleteMessageBatch"] }
def action-completer-6 [] { ["DeleteQueue"] }
def action-completer-7 [] { ["GetQueueAttributes"] }
def action-completer-8 [] { ["GetQueueUrl"] }
def action-completer-9 [] { ["ListDeadLetterSourceQueues"] }
def action-completer-10 [] { ["ListQueueTags"] }
def action-completer-11 [] { ["ListQueues"] }
def action-completer-12 [] { ["PurgeQueue"] }
def action-completer-13 [] { ["ReceiveMessage"] }
def action-completer-14 [] { ["RemovePermission"] }
def action-completer-15 [] { ["SendMessage"] }
def action-completer-16 [] { ["SendMessageBatch"] }
def action-completer-17 [] { ["SetQueueAttributes"] }
def action-completer-18 [] { ["TagQueue"] }
def action-completer-19 [] { ["UntagQueue"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api get-create-permission" } } | get name | first)
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

# Adds a permission to a queue for a specific principal (https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P). This allows sharing access to the queue. When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see Allow Developers to Write Messages to a Shared Queue (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue) in the Amazon SQS Developer Guide. AddPermission generates a policy for you. You can use SetQueueAttributes to upload your policy. For more information, see Using Custom Policies with the Amazon SQS Access Policy Language (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html) in the Amazon SQS Developer Guide. An Amazon SQS policy can have a maximum of 7 actions. To remove the ability to change queue permissions, you must deny permission to the AddPermission, RemovePermission, and SetQueueAttributes actions in your IAM policy. Some actions take lists of parameters. These lists are specified using the param.n notation. Values of n are integers starting from 1. For example, a parameter list with two elements looks like this: &AttributeName.1=first &AttributeName.2=second Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_AddPermission
export def "api get-create-permission" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The unique identification of the permission you're setting (for example, AliceSendMessage). Maximum 80 characters. Allowed characters include alphanumeric characters, hyphens (-), and underscores (_).
  --aws-account-ids: list # The Amazon Web Services account numbers of the principals (https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P) who are to receive permission. For information about locating the Amazon Web Services account identification, see Your Amazon Web Services Identifiers (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-making-api-requests.html#sqs-api-request-authentication) in the Amazon SQS Developer Guide.
  --actions: list # The action the client wants to allow for the specified principal. Valid values: the name of any action or *. For more information about these actions, see Overview of Managing Access Permissions to Your Amazon Simple Queue Service Resource (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-overview-of-managing-access.html) in the Amazon SQS Developer Guide. Specifying SendMessage, DeleteMessage, or ChangeMessageVisibility for ActionName.n also grants permissions for the corresponding batch versions of those actions: SendMessageBatch, DeleteMessageBatch, and ChangeMessageVisibilityBatch.
  --action: string@action-completer
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "Label" $label "scalar") (serialize-qp "AWSAccountIds" $aws_account_ids "multi") (serialize-qp "Actions" $actions "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Label": $label, "AWSAccountIds": $aws_account_ids, "Actions": $actions, "Action": $action, "Version": $version} | compact), body: null}
}

# Adds a permission to a queue for a specific principal (https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P). This allows sharing access to the queue. When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see Allow Developers to Write Messages to a Shared Queue (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue) in the Amazon SQS Developer Guide. AddPermission generates a policy for you. You can use SetQueueAttributes to upload your policy. For more information, see Using Custom Policies with the Amazon SQS Access Policy Language (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html) in the Amazon SQS Developer Guide. An Amazon SQS policy can have a maximum of 7 actions. To remove the ability to change queue permissions, you must deny permission to the AddPermission, RemovePermission, and SetQueueAttributes actions in your IAM policy. Some actions take lists of parameters. These lists are specified using the param.n notation. Values of n are integers starting from 1. For example, a parameter list with two elements looks like this: &AttributeName.1=first &AttributeName.2=second Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# POST /
# operationId: POST_AddPermission
export def "api create-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see Visibility Timeout (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html) in the Amazon SQS Developer Guide. For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call ChangeMessageVisibility with a timeout of 10 minutes. You can continue to call ChangeMessageVisibility to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected. An Amazon SQS message has three basic states: Sent to a queue by a producer. Received from the queue by a consumer. Deleted from the queue. A message is considered to be stored after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be in flight after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages. Limits that apply to inflight messages are unrelated to the unlimited number of stored messages. For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the OverLimit error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, file a support request (https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&limitType=service-code-sqs). For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages. If you attempt to set the VisibilityTimeout to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time. Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the ChangeMessageVisibility action) the next time the message is received.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_ChangeMessageVisibility
export def "api get-change-message-visibility" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --receipt-handle: string # The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the ReceiveMessage action.
  --visibility-timeout: int # The new value for the message's visibility timeout (in seconds). Values range: 0 to 43200. Maximum: 12 hours.
  --action: string@action-completer-1
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "ReceiptHandle" $receipt_handle "scalar") (serialize-qp "VisibilityTimeout" $visibility_timeout "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ReceiptHandle": $receipt_handle, "VisibilityTimeout": $visibility_timeout, "Action": $action, "Version": $version} | compact), body: null}
}

# Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see Visibility Timeout (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html) in the Amazon SQS Developer Guide. For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call ChangeMessageVisibility with a timeout of 10 minutes. You can continue to call ChangeMessageVisibility to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected. An Amazon SQS message has three basic states: Sent to a queue by a producer. Received from the queue by a consumer. Deleted from the queue. A message is considered to be stored after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be in flight after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages. Limits that apply to inflight messages are unrelated to the unlimited number of stored messages. For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the OverLimit error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, file a support request (https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&limitType=service-code-sqs). For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages. If you attempt to set the VisibilityTimeout to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time. Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the ChangeMessageVisibility action) the next time the message is received.
#
# POST /
# operationId: POST_ChangeMessageVisibility
export def "api create-change-message-visibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Changes the visibility timeout of multiple messages. This is a batch version of ChangeMessageVisibility. The result of the action on each message is reported individually in the response. You can send up to 10 ChangeMessageVisibility requests with each ChangeMessageVisibilityBatch action. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of 200. Some actions take lists of parameters. These lists are specified using the param.n notation. Values of n are integers starting from 1. For example, a parameter list with two elements looks like this: &AttributeName.1=first &AttributeName.2=second
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_ChangeMessageVisibilityBatch
export def "api get-change-message-visibility-batch" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entries: list # A list of receipt handles of the messages for which the visibility timeout must be changed.
  --action: string@action-completer-2
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "Entries" $entries "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Entries": $entries, "Action": $action, "Version": $version} | compact), body: null}
}

# Changes the visibility timeout of multiple messages. This is a batch version of ChangeMessageVisibility. The result of the action on each message is reported individually in the response. You can send up to 10 ChangeMessageVisibility requests with each ChangeMessageVisibilityBatch action. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of 200. Some actions take lists of parameters. These lists are specified using the param.n notation. Values of n are integers starting from 1. For example, a parameter list with two elements looks like this: &AttributeName.1=first &AttributeName.2=second
#
# POST /
# operationId: POST_ChangeMessageVisibilityBatch
export def "api create-change-message-visibility-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-2
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following in mind: If you don't specify the FifoQueue attribute, Amazon SQS creates a standard queue. You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see Moving From a Standard Queue to a FIFO Queue (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving) in the Amazon SQS Developer Guide. If you don't provide a value for an attribute, the queue is created with the default value for the attribute. If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name. To successfully create a new queue, you must provide a queue name that adheres to the limits related to queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html) and is unique within the scope of your queues. After you create a queue, you must wait at least one second after the queue is created to be able to use the queue. To get the queue URL, use the GetQueueUrl action. GetQueueUrl requires only the QueueName parameter. be aware of existing queue names: If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, CreateQueue returns the queue URL for the existing queue. If the queue name, attribute names, or attribute values don't match an existing queue, CreateQueue returns an error. Some actions take lists of parameters. These lists are specified using the param.n notation. Values of n are integers starting from 1. For example, a parameter list with two elements looks like this: &AttributeName.1=first &AttributeName.2=second Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# GET /
# operationId: GET_CreateQueue
export def "api get-create-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --queue-name: string # The name of the new queue. The following limits apply to this name: A queue name can have up to 80 characters. Valid values: alphanumeric characters, hyphens (-), and underscores (_). A FIFO queue name must end with the .fifo suffix. Queue URLs and names are case-sensitive.
  --attribute: record # A map of attributes with their corresponding values. The following lists the names, descriptions, and values of the special request parameters that the CreateQueue action uses: DelaySeconds – The length of time, in seconds, for which the delivery of all messages in the queue is delayed. Valid values: An integer from 0 to 900 seconds (15 minutes). Default: 0. MaximumMessageSize – The limit of how many bytes a message can contain before Amazon SQS rejects it. Valid values: An integer from 1,024 bytes (1 KiB) to 262,144 bytes (256 KiB). Default: 262,144 (256 KiB). MessageRetentionPeriod – The length of time, in seconds, for which Amazon SQS retains a message. Valid values: An integer from 60 seconds (1 minute) to 1,209,600 seconds (14 days). Default: 345,600 (4 days). Policy – The queue's policy. A valid Amazon Web Services policy. For more information about policy structure, see Overview of Amazon Web Services IAM Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/PoliciesOverview.html) in the Amazon IAM User Guide. ReceiveMessageWaitTimeSeconds – The length of time, in seconds, for which a ReceiveMessage action waits for a message to arrive. Valid values: An integer from 0 to 20 (seconds). Default: 0. RedrivePolicy – The string that includes the parameters for the dead-letter queue functionality of the source queue as a JSON object. For more information about the redrive policy and dead-letter queues, see Using Amazon SQS Dead-Letter Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) in the Amazon SQS Developer Guide. deadLetterTargetArn – The Amazon Resource Name (ARN) of the dead-letter queue to which Amazon SQS moves messages after the value of maxReceiveCount is exceeded. maxReceiveCount – The number of times a message is delivered to the source queue before being moved to the dead-letter queue. When the ReceiveCount for a message exceeds the maxReceiveCount for a queue, Amazon SQS moves the message to the dead-letter-queue. The dead-letter queue of a FIFO queue must also be a FIFO queue. Similarly, the dead-letter queue of a standard queue must also be a standard queue. VisibilityTimeout – The visibility timeout for the queue, in seconds. Valid values: An integer from 0 to 43,200 (12 hours). Default: 30. For more information about the visibility timeout, see Visibility Timeout (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html) in the Amazon SQS Developer Guide. The following attributes apply only to server-side-encryption (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html): KmsMasterKeyId – The ID of an Amazon Web Services managed customer master key (CMK) for Amazon SQS or a custom CMK. For more information, see Key Terms (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-sse-key-terms). While the alias of the Amazon Web Services managed CMK for Amazon SQS is always alias/aws/sqs, the alias of a custom CMK can, for example, be alias/MyAlias . For more examples, see KeyId (https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters) in the Key Management Service API Reference. KmsDataKeyReusePeriodSeconds – The length of time, in seconds, for which Amazon SQS can reuse a data key (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys) to encrypt or decrypt messages before calling KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours). Default: 300 (5 minutes). A shorter time period provides better security but results in more calls to KMS which might incur charges after Free Tier. For more information, see How Does the Data Key Reuse Period Work? (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-how-does-the-data-key-reuse-period-work). SqsManagedSseEnabled – Enables server-side queue encryption using SQS owned encryption keys. Only one server-side encryption option is supported per queue (e.g. SSE-KMS (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sse-existing-queue.html) or SSE-SQS (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sqs-sse-queue.html)). The following attributes apply only to FIFO (first-in-first-out) queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html): FifoQueue – Designates a queue as FIFO. Valid values are true and false. If you don't specify the FifoQueue attribute, Amazon SQS creates a standard queue. You can provide this attribute only during queue creation. You can't change it for an existing queue. When you set this attribute, you must also provide the MessageGroupId for your messages explicitly. For more information, see FIFO queue logic (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues-understanding-logic.html) in the Amazon SQS Developer Guide. ContentBasedDeduplication – Enables content-based deduplication. Valid values are true and false. For more information, see Exactly-once processing (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues-exactly-once-processing.html) in the Amazon SQS Developer Guide. Note the following: Every message must have a unique MessageDeduplicationId. You may provide a MessageDeduplicationId explicitly. If you aren't able to provide a MessageDeduplicationId and you enable ContentBasedDeduplication for your queue, Amazon SQS uses a SHA-256 hash to generate the MessageDeduplicationId using the body of the message (but not the attributes of the message). If you don't provide a MessageDeduplicationId and the queue doesn't have ContentBasedDeduplication set, the action fails with an error. If the queue has ContentBasedDeduplication set, your MessageDeduplicationId overrides the generated one. When ContentBasedDeduplication is in effect, messages with identical content sent within the deduplication interval are treated as duplicates and only one copy of the message is delivered. If you send one message with ContentBasedDeduplication enabled and then another message with a MessageDeduplicationId that is the same as the one generated for the first MessageDeduplicationId, the two messages are treated as duplicates and only one copy of the message is delivered. The following attributes apply only to high throughput for FIFO queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/high-throughput-fifo.html): DeduplicationScope – Specifies whether message deduplication occurs at the message group or queue level. Valid values are messageGroup and queue. FifoThroughputLimit – Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are perQueue and perMessageGroupId. The perMessageGroupId value is allowed only when the value for DeduplicationScope is messageGroup. To enable high throughput for FIFO queues, do the following: Set DeduplicationScope to messageGroup. Set FifoThroughputLimit to perMessageGroupId. If you set these attributes to anything other than the values shown for enabling high throughput, normal throughput is in effect and deduplication occurs as specified. For information on throughput quotas, see Quotas related to messages (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/quotas-messages.html) in the Amazon SQS Developer Guide.
  --tag: record # Add cost allocation tags to the specified Amazon SQS queue. For an overview, see Tagging Your Amazon SQS Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html) in the Amazon SQS Developer Guide. When you use queue tags, keep the following guidelines in mind: Adding more than 50 tags to a queue isn't recommended. Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings. Tags are case-sensitive. A new tag with a key identical to that of an existing tag overwrites the existing tag. For a full list of tag restrictions, see Quotas related to queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues) in the Amazon SQS Developer Guide. To be able to tag a queue on creation, you must have the sqs:CreateQueue and sqs:TagQueue permissions. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
  --action: string@action-completer-3
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "QueueName" $queue_name "scalar") (serialize-qp "Attribute" $attribute "multi") (serialize-qp "Tag" $tag "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"QueueName": $queue_name, "Attribute": $attribute, "Tag": $tag, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following in mind: If you don't specify the FifoQueue attribute, Amazon SQS creates a standard queue. You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see Moving From a Standard Queue to a FIFO Queue (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving) in the Amazon SQS Developer Guide. If you don't provide a value for an attribute, the queue is created with the default value for the attribute. If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name. To successfully create a new queue, you must provide a queue name that adheres to the limits related to queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html) and is unique within the scope of your queues. After you create a queue, you must wait at least one second after the queue is created to be able to use the queue. To get the queue URL, use the GetQueueUrl action. GetQueueUrl requires only the QueueName parameter. be aware of existing queue names: If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, CreateQueue returns the queue URL for the existing queue. If the queue name, attribute names, or attribute values don't match an existing queue, CreateQueue returns an error. Some actions take lists of parameters. These lists are specified using the param.n notation. Values of n are integers starting from 1. For example, a parameter list with two elements looks like this: &AttributeName.1=first &AttributeName.2=second Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# POST /
# operationId: POST_CreateQueue
export def "api create-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-3
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes the specified message from the specified queue. To select the message to delete, use the ReceiptHandle of the message (not the MessageId which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. The ReceiptHandle is associated with a specific instance of receiving a message. If you receive a message more than once, the ReceiptHandle is different each time you receive a message. When you use the DeleteMessage action, you must provide the most recently received ReceiptHandle for the message (otherwise, the request succeeds, but the message might not be deleted). For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_DeleteMessage
export def "api get-delete-message" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --receipt-handle: string # The receipt handle associated with the message to delete.
  --action: string@action-completer-4
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "ReceiptHandle" $receipt_handle "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ReceiptHandle": $receipt_handle, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified message from the specified queue. To select the message to delete, use the ReceiptHandle of the message (not the MessageId which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. The ReceiptHandle is associated with a specific instance of receiving a message. If you receive a message more than once, the ReceiptHandle is different each time you receive a message. When you use the DeleteMessage action, you must provide the most recently received ReceiptHandle for the message (otherwise, the request succeeds, but the message might not be deleted). For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.
#
# POST /
# operationId: POST_DeleteMessage
export def "api create-delete-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-4
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes up to ten messages from the specified queue. This is a batch version of DeleteMessage. The result of the action on each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of 200. Some actions take lists of parameters. These lists are specified using the param.n notation. Values of n are integers starting from 1. For example, a parameter list with two elements looks like this: &AttributeName.1=first &AttributeName.2=second
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_DeleteMessageBatch
export def "api get-delete-message-batch" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entries: list # A list of receipt handles for the messages to be deleted.
  --action: string@action-completer-5
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "Entries" $entries "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Entries": $entries, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes up to ten messages from the specified queue. This is a batch version of DeleteMessage. The result of the action on each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of 200. Some actions take lists of parameters. These lists are specified using the param.n notation. Values of n are integers starting from 1. For example, a parameter list with two elements looks like this: &AttributeName.1=first &AttributeName.2=second
#
# POST /
# operationId: POST_DeleteMessageBatch
export def "api create-delete-message-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-5
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes the queue specified by the QueueUrl, regardless of the queue's contents. Be careful with the DeleteQueue action: When you delete a queue, any messages in the queue are no longer available. When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a SendMessage request might succeed, but after 60 seconds the queue and the message you sent no longer exist. When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_DeleteQueue
export def "api get-delete-queue" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-6
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the queue specified by the QueueUrl, regardless of the queue's contents. Be careful with the DeleteQueue action: When you delete a queue, any messages in the queue are no longer available. When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a SendMessage request might succeed, but after 60 seconds the queue and the message you sent no longer exist. When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# POST /
# operationId: POST_DeleteQueue
export def "api create-delete-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-6
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Gets attributes for the specified queue. To determine whether a queue is FIFO (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html), you can check whether QueueName ends with the .fifo suffix.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_GetQueueAttributes
export def "api get-queue-attributes" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-names: list # A list of attributes for which to retrieve information. The AttributeName.N parameter is optional, but if you don't specify values for this parameter, the request returns empty results. In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully. The following attributes are supported: The ApproximateNumberOfMessagesDelayed, ApproximateNumberOfMessagesNotVisible, and ApproximateNumberOfMessagesVisible metrics may not achieve consistency until at least 1 minute after the producers stop sending messages. This period is required for the queue metadata to reach eventual consistency. All – Returns all values. ApproximateNumberOfMessages – Returns the approximate number of messages available for retrieval from the queue. ApproximateNumberOfMessagesDelayed – Returns the approximate number of messages in the queue that are delayed and not available for reading immediately. This can happen when the queue is configured as a delay queue or when a message has been sent with a delay parameter. ApproximateNumberOfMessagesNotVisible – Returns the approximate number of messages that are in flight. Messages are considered to be in flight if they have been sent to a client but have not yet been deleted or have not yet reached the end of their visibility window. CreatedTimestamp – Returns the time when the queue was created in seconds (epoch time (http://en.wikipedia.org/wiki/Unix_time)). DelaySeconds – Returns the default delay on the queue in seconds. LastModifiedTimestamp – Returns the time when the queue was last changed in seconds (epoch time (http://en.wikipedia.org/wiki/Unix_time)). MaximumMessageSize – Returns the limit of how many bytes a message can contain before Amazon SQS rejects it. MessageRetentionPeriod – Returns the length of time, in seconds, for which Amazon SQS retains a message. Policy – Returns the policy of the queue. QueueArn – Returns the Amazon resource name (ARN) of the queue. ReceiveMessageWaitTimeSeconds – Returns the length of time, in seconds, for which the ReceiveMessage action waits for a message to arrive. RedrivePolicy – The string that includes the parameters for the dead-letter queue functionality of the source queue as a JSON object. For more information about the redrive policy and dead-letter queues, see Using Amazon SQS Dead-Letter Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) in the Amazon SQS Developer Guide. deadLetterTargetArn – The Amazon Resource Name (ARN) of the dead-letter queue to which Amazon SQS moves messages after the value of maxReceiveCount is exceeded. maxReceiveCount – The number of times a message is delivered to the source queue before being moved to the dead-letter queue. When the ReceiveCount for a message exceeds the maxReceiveCount for a queue, Amazon SQS moves the message to the dead-letter-queue. VisibilityTimeout – Returns the visibility timeout for the queue. For more information about the visibility timeout, see Visibility Timeout (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html) in the Amazon SQS Developer Guide. The following attributes apply only to server-side-encryption (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html): KmsMasterKeyId – Returns the ID of an Amazon Web Services managed customer master key (CMK) for Amazon SQS or a custom CMK. For more information, see Key Terms (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-sse-key-terms). KmsDataKeyReusePeriodSeconds – Returns the length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling KMS again. For more information, see How Does the Data Key Reuse Period Work? (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-how-does-the-data-key-reuse-period-work). SqsManagedSseEnabled – Returns information about whether the queue is using SSE-SQS encryption using SQS owned encryption keys. Only one server-side encryption option is supported per queue (e.g. SSE-KMS (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sse-existing-queue.html) or SSE-SQS (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sqs-sse-queue.html)). The following attributes apply only to FIFO (first-in-first-out) queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html): FifoQueue – Returns information about whether the queue is FIFO. For more information, see FIFO queue logic (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues-understanding-logic.html) in the Amazon SQS Developer Guide. To determine whether a queue is FIFO (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html), you can check whether QueueName ends with the .fifo suffix. ContentBasedDeduplication – Returns whether content-based deduplication is enabled for the queue. For more information, see Exactly-once processing (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues-exactly-once-processing.html) in the Amazon SQS Developer Guide. The following attributes apply only to high throughput for FIFO queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/high-throughput-fifo.html): DeduplicationScope – Specifies whether message deduplication occurs at the message group or queue level. Valid values are messageGroup and queue. FifoThroughputLimit – Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are perQueue and perMessageGroupId. The perMessageGroupId value is allowed only when the value for DeduplicationScope is messageGroup. To enable high throughput for FIFO queues, do the following: Set DeduplicationScope to messageGroup. Set FifoThroughputLimit to perMessageGroupId. If you set these attributes to anything other than the values shown for enabling high throughput, normal throughput is in effect and deduplication occurs as specified. For information on throughput quotas, see Quotas related to messages (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/quotas-messages.html) in the Amazon SQS Developer Guide.
  --action: string@action-completer-7
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "AttributeNames" $attribute_names "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AttributeNames": $attribute_names, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets attributes for the specified queue. To determine whether a queue is FIFO (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html), you can check whether QueueName ends with the .fifo suffix.
#
# POST /
# operationId: POST_GetQueueAttributes
export def "api create-get-queue-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-7
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns the URL of an existing Amazon SQS queue. To access a queue that belongs to another AWS account, use the QueueOwnerAWSAccountId parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see AddPermission or see Allow Developers to Write Messages to a Shared Queue (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue) in the Amazon SQS Developer Guide.
#
# GET /
# operationId: GET_GetQueueUrl
export def "api get-queue-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --queue-name: string # The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (-), and underscores (_). Queue URLs and names are case-sensitive.
  --queue-owner-aws-account-id: string # The Amazon Web Services account ID of the account that created the queue.
  --action: string@action-completer-8
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "QueueName" $queue_name "scalar") (serialize-qp "QueueOwnerAWSAccountId" $queue_owner_aws_account_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"QueueName": $queue_name, "QueueOwnerAWSAccountId": $queue_owner_aws_account_id, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns the URL of an existing Amazon SQS queue. To access a queue that belongs to another AWS account, use the QueueOwnerAWSAccountId parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see AddPermission or see Allow Developers to Write Messages to a Shared Queue (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue) in the Amazon SQS Developer Guide.
#
# POST /
# operationId: POST_GetQueueUrl
export def "api create-get-queue-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-8
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of your queues that have the RedrivePolicy queue attribute configured with a dead-letter queue. The ListDeadLetterSourceQueues methods supports pagination. Set parameter MaxResults in the request to specify the maximum number of results to be returned in the response. If you do not set MaxResults, the response includes a maximum of 1,000 results. If you set MaxResults and there are additional results to display, the response includes a value for NextToken. Use NextToken as a parameter in your next request to ListDeadLetterSourceQueues to receive the next page of results. For more information about using dead-letter queues, see Using Amazon SQS Dead-Letter Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) in the Amazon SQS Developer Guide.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_ListDeadLetterSourceQueues
export def "api get-list-dead-letter-source-queues" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token to request the next set of results.
  --max-results: int # Maximum number of results to include in the response. Value range is 1 to 1000. You must set MaxResults to receive a value for NextToken in the response.
  --action: string@action-completer-9
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"NextToken": $next_token, "MaxResults": $max_results, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of your queues that have the RedrivePolicy queue attribute configured with a dead-letter queue. The ListDeadLetterSourceQueues methods supports pagination. Set parameter MaxResults in the request to specify the maximum number of results to be returned in the response. If you do not set MaxResults, the response includes a maximum of 1,000 results. If you set MaxResults and there are additional results to display, the response includes a value for NextToken. Use NextToken as a parameter in your next request to ListDeadLetterSourceQueues to receive the next page of results. For more information about using dead-letter queues, see Using Amazon SQS Dead-Letter Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) in the Amazon SQS Developer Guide.
#
# POST /
# operationId: POST_ListDeadLetterSourceQueues
export def "api create-list-dead-letter-source-queues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-9
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see Tagging Your Amazon SQS Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html) in the Amazon SQS Developer Guide. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_ListQueueTags
export def "api get-list-queue-tags" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-10
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see Tagging Your Amazon SQS Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html) in the Amazon SQS Developer Guide. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# POST /
# operationId: POST_ListQueueTags
export def "api create-list-queue-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-10
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Returns a list of your queues in the current region. The response includes a maximum of 1,000 results. If you specify a value for the optional QueueNamePrefix parameter, only queues with a name that begins with the specified value are returned. The listQueues methods supports pagination. Set parameter MaxResults in the request to specify the maximum number of results to be returned in the response. If you do not set MaxResults, the response includes a maximum of 1,000 results. If you set MaxResults and there are additional results to display, the response includes a value for NextToken. Use NextToken as a parameter in your next request to listQueues to receive the next page of results. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# GET /
# operationId: GET_ListQueues
export def "api get-list-queues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --queue-name-prefix: string # A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned. Queue URLs and names are case-sensitive.
  --next-token: string # Pagination token to request the next set of results.
  --max-results: int # Maximum number of results to include in the response. Value range is 1 to 1000. You must set MaxResults to receive a value for NextToken in the response.
  --action: string@action-completer-11
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "QueueNamePrefix" $queue_name_prefix "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"QueueNamePrefix": $queue_name_prefix, "NextToken": $next_token, "MaxResults": $max_results, "Action": $action, "Version": $version} | compact), body: null}
}

# Returns a list of your queues in the current region. The response includes a maximum of 1,000 results. If you specify a value for the optional QueueNamePrefix parameter, only queues with a name that begins with the specified value are returned. The listQueues methods supports pagination. Set parameter MaxResults in the request to specify the maximum number of results to be returned in the response. If you do not set MaxResults, the response includes a maximum of 1,000 results. If you set MaxResults and there are additional results to display, the response includes a value for NextToken. Use NextToken as a parameter in your next request to listQueues to receive the next page of results. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# POST /
# operationId: POST_ListQueues
export def "api create-list-queues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-11
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes the messages in a queue specified by the QueueURL parameter. When you use the PurgeQueue action, you can't retrieve any messages deleted from a queue. The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. Messages sent to the queue before you call PurgeQueue might be received but are deleted within the next minute. Messages sent to the queue after you call PurgeQueue might be deleted while the queue is being purged.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_PurgeQueue
export def "api get-purge-queue" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-12
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the messages in a queue specified by the QueueURL parameter. When you use the PurgeQueue action, you can't retrieve any messages deleted from a queue. The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. Messages sent to the queue before you call PurgeQueue might be received but are deleted within the next minute. Messages sent to the queue after you call PurgeQueue might be deleted while the queue is being purged.
#
# POST /
# operationId: POST_PurgeQueue
export def "api create-purge-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-12
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Retrieves one or more messages (up to 10), from the specified queue. Using the WaitTimeSeconds parameter enables long-poll support. For more information, see Amazon SQS Long Polling (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html) in the Amazon SQS Developer Guide. Short poll is the default behavior where a weighted random set of machines is sampled on a ReceiveMessage call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per ReceiveMessage call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular ReceiveMessage response. If this happens, repeat the request. For each message returned, the response includes the following: The message body. An MD5 digest of the message body. For information about MD5, see RFC1321 (https://www.ietf.org/rfc/rfc1321.txt). The MessageId you received when you sent the message to the queue. The receipt handle. The message attributes. An MD5 digest of the message attributes. The receipt handle is the identifier you must provide when deleting the message. For more information, see Queue and Message Identifiers (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html) in the Amazon SQS Developer Guide. You can provide the VisibilityTimeout parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see Visibility Timeout (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html) in the Amazon SQS Developer Guide. A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue. In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_ReceiveMessage
export def "api get-receive-message" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-names: list # A list of attributes that need to be returned along with each message. These attributes include: All – Returns all values. ApproximateFirstReceiveTimestamp – Returns the time the message was first received from the queue (epoch time (http://en.wikipedia.org/wiki/Unix_time) in milliseconds). ApproximateReceiveCount – Returns the number of times a message has been received across all queues but not deleted. AWSTraceHeader – Returns the X-Ray trace header string. SenderId For an IAM user, returns the IAM user ID, for example ABCDEFGHI1JKLMNOPQ23R. For an IAM role, returns the IAM role ID, for example ABCDE1F2GH3I4JK5LMNOP:i-a123b456. SentTimestamp – Returns the time the message was sent to the queue (epoch time (http://en.wikipedia.org/wiki/Unix_time) in milliseconds). SqsManagedSseEnabled – Enables server-side queue encryption using SQS owned encryption keys. Only one server-side encryption option is supported per queue (e.g. SSE-KMS (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sse-existing-queue.html) or SSE-SQS (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sqs-sse-queue.html)). MessageDeduplicationId – Returns the value provided by the producer that calls the SendMessage action. MessageGroupId – Returns the value provided by the producer that calls the SendMessage action. Messages with the same MessageGroupId are returned in sequence. SequenceNumber – Returns the value provided by Amazon SQS.
  --message-attribute-names: list # The name of the message attribute, where N is the index. The name can contain alphanumeric characters and the underscore (_), hyphen (-), and period (.). The name is case-sensitive and must be unique among all attribute names for the message. The name must not start with AWS-reserved prefixes such as AWS. or Amazon. (or any casing variants). The name must not start or end with a period (.), and it should not have periods in succession (..). The name can be up to 256 characters long. When using ReceiveMessage, you can send a list of attribute names to receive, or you can return all of the attributes by specifying All or .* in your request. You can also use all message attributes starting with a prefix, for example bar.*.
  --max-number-of-messages: int # The maximum number of messages to return. Amazon SQS never returns more messages than this value (however, fewer messages might be returned). Valid values: 1 to 10. Default: 1.
  --visibility-timeout: int # The duration (in seconds) that the received messages are hidden from subsequent retrieve requests after being retrieved by a ReceiveMessage request.
  --wait-time-seconds: int # The duration (in seconds) for which the call waits for a message to arrive in the queue before returning. If a message is available, the call returns sooner than WaitTimeSeconds. If no messages are available and the wait time expires, the call returns successfully with an empty list of messages. To avoid HTTP errors, ensure that the HTTP response timeout for ReceiveMessage requests is longer than the WaitTimeSeconds parameter. For example, with the Java SDK, you can set HTTP transport settings using the NettyNioAsyncHttpClient (https://sdk.amazonaws.com/java/api/latest/software/amazon/awssdk/http/nio/netty/NettyNioAsyncHttpClient.html) for asynchronous clients, or the ApacheHttpClient (https://sdk.amazonaws.com/java/api/latest/software/amazon/awssdk/http/apache/ApacheHttpClient.html) for synchronous clients.
  --receive-request-attempt-id: string # This parameter applies only to FIFO (first-in-first-out) queues. The token used for deduplication of ReceiveMessage calls. If a networking issue occurs after a ReceiveMessage action, and instead of a response you receive a generic error, it is possible to retry the same action with an identical ReceiveRequestAttemptId to retrieve the same set of messages, even if their visibility timeout has not yet expired. You can use ReceiveRequestAttemptId only for 5 minutes after a ReceiveMessage action. When you set FifoQueue, a caller of the ReceiveMessage action can provide a ReceiveRequestAttemptId explicitly. If a caller of the ReceiveMessage action doesn't provide a ReceiveRequestAttemptId, Amazon SQS generates a ReceiveRequestAttemptId. It is possible to retry the ReceiveMessage action with the same ReceiveRequestAttemptId if none of the messages have been modified (deleted or had their visibility changes). During a visibility timeout, subsequent calls with the same ReceiveRequestAttemptId return the same messages and receipt handles. If a retry occurs within the deduplication interval, it resets the visibility timeout. For more information, see Visibility Timeout (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html) in the Amazon SQS Developer Guide. If a caller of the ReceiveMessage action still processes messages when the visibility timeout expires and messages become visible, another worker consuming from the same queue can receive the same messages and therefore process duplicates. Also, if a consumer whose message processing time is longer than the visibility timeout tries to delete the processed messages, the action fails with an error. To mitigate this effect, ensure that your application observes a safe threshold before the visibility timeout expires and extend the visibility timeout as necessary. While messages with a particular MessageGroupId are invisible, no more messages belonging to the same MessageGroupId are returned until the visibility timeout expires. You can still receive messages with another MessageGroupId as long as it is also visible. If a caller of ReceiveMessage can't track the ReceiveRequestAttemptId, no retries work until the original visibility timeout expires. As a result, delays might occur but the messages in the queue remain in a strict order. The maximum length of ReceiveRequestAttemptId is 128 characters. ReceiveRequestAttemptId can contain alphanumeric characters (a-z, A-Z, 0-9) and punctuation (!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~). For best practices of using ReceiveRequestAttemptId, see Using the ReceiveRequestAttemptId Request Parameter (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-receiverequestattemptid-request-parameter.html) in the Amazon SQS Developer Guide.
  --action: string@action-completer-13
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "AttributeNames" $attribute_names "multi") (serialize-qp "MessageAttributeNames" $message_attribute_names "multi") (serialize-qp "MaxNumberOfMessages" $max_number_of_messages "scalar") (serialize-qp "VisibilityTimeout" $visibility_timeout "scalar") (serialize-qp "WaitTimeSeconds" $wait_time_seconds "scalar") (serialize-qp "ReceiveRequestAttemptId" $receive_request_attempt_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AttributeNames": $attribute_names, "MessageAttributeNames": $message_attribute_names, "MaxNumberOfMessages": $max_number_of_messages, "VisibilityTimeout": $visibility_timeout, "WaitTimeSeconds": $wait_time_seconds, "ReceiveRequestAttemptId": $receive_request_attempt_id, "Action": $action, "Version": $version} | compact), body: null}
}

# Retrieves one or more messages (up to 10), from the specified queue. Using the WaitTimeSeconds parameter enables long-poll support. For more information, see Amazon SQS Long Polling (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html) in the Amazon SQS Developer Guide. Short poll is the default behavior where a weighted random set of machines is sampled on a ReceiveMessage call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per ReceiveMessage call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular ReceiveMessage response. If this happens, repeat the request. For each message returned, the response includes the following: The message body. An MD5 digest of the message body. For information about MD5, see RFC1321 (https://www.ietf.org/rfc/rfc1321.txt). The MessageId you received when you sent the message to the queue. The receipt handle. The message attributes. An MD5 digest of the message attributes. The receipt handle is the identifier you must provide when deleting the message. For more information, see Queue and Message Identifiers (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html) in the Amazon SQS Developer Guide. You can provide the VisibilityTimeout parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see Visibility Timeout (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html) in the Amazon SQS Developer Guide. A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue. In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.
#
# POST /
# operationId: POST_ReceiveMessage
export def "api create-receive-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-13
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Revokes any permissions in the queue policy that matches the specified Label parameter. Only the owner of a queue can remove permissions from it. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide. To remove the ability to change queue permissions, you must deny permission to the AddPermission, RemovePermission, and SetQueueAttributes actions in your IAM policy.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_RemovePermission
export def "api get-delete-permission" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The identification of the permission to remove. This is the label added using the AddPermission action.
  --action: string@action-completer-14
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "Label" $label "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Label": $label, "Action": $action, "Version": $version} | compact), body: null}
}

# Revokes any permissions in the queue policy that matches the specified Label parameter. Only the owner of a queue can remove permissions from it. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide. To remove the ability to change queue permissions, you must deny permission to the AddPermission, RemovePermission, and SetQueueAttributes actions in your IAM policy.
#
# POST /
# operationId: POST_RemovePermission
export def "api create-delete-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-14
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Delivers a message to the specified queue. A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed: #x9 | #xA | #xD | #x20 to #xD7FF | #xE000 to #xFFFD | #x10000 to #x10FFFF Any characters not included in this list will be rejected. For more information, see the W3C specification for characters (http://www.w3.org/TR/REC-xml/#charsets).
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_SendMessage
export def "api get-send-message" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message-body: string # The message to send. The minimum size is one character. The maximum size is 256 KB. A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed: #x9 | #xA | #xD | #x20 to #xD7FF | #xE000 to #xFFFD | #x10000 to #x10FFFF Any characters not included in this list will be rejected. For more information, see the W3C specification for characters (http://www.w3.org/TR/REC-xml/#charsets).
  --delay-seconds: int # The length of time, in seconds, for which to delay a specific message. Valid values: 0 to 900. Maximum: 15 minutes. Messages with a positive DelaySeconds value become available for processing after the delay period is finished. If you don't specify a value, the default value for the queue applies. When you set FifoQueue, you can't set DelaySeconds per message. You can set this parameter only on a queue level.
  --message-attribute: record # Each message attribute consists of a Name, Type, and Value. For more information, see Amazon SQS message attributes (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-message-metadata.html#sqs-message-attributes) in the Amazon SQS Developer Guide.
  --message-system-attribute: record # The message system attribute to send. Each message system attribute consists of a Name, Type, and Value. Currently, the only supported message system attribute is AWSTraceHeader. Its type must be String and its value must be a correctly formatted X-Ray trace header string. The size of a message system attribute doesn't count towards the total size of a message.
  --message-deduplication-id: string # This parameter applies only to FIFO (first-in-first-out) queues. The token used for deduplication of sent messages. If a message with a particular MessageDeduplicationId is sent successfully, any messages sent with the same MessageDeduplicationId are accepted successfully but aren't delivered during the 5-minute deduplication interval. For more information, see Exactly-once processing (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues-exactly-once-processing.html) in the Amazon SQS Developer Guide. Every message must have a unique MessageDeduplicationId, You may provide a MessageDeduplicationId explicitly. If you aren't able to provide a MessageDeduplicationId and you enable ContentBasedDeduplication for your queue, Amazon SQS uses a SHA-256 hash to generate the MessageDeduplicationId using the body of the message (but not the attributes of the message). If you don't provide a MessageDeduplicationId and the queue doesn't have ContentBasedDeduplication set, the action fails with an error. If the queue has ContentBasedDeduplication set, your MessageDeduplicationId overrides the generated one. When ContentBasedDeduplication is in effect, messages with identical content sent within the deduplication interval are treated as duplicates and only one copy of the message is delivered. If you send one message with ContentBasedDeduplication enabled and then another message with a MessageDeduplicationId that is the same as the one generated for the first MessageDeduplicationId, the two messages are treated as duplicates and only one copy of the message is delivered. The MessageDeduplicationId is available to the consumer of the message (this can be useful for troubleshooting delivery issues). If a message is sent successfully but the acknowledgement is lost and the message is resent with the same MessageDeduplicationId after the deduplication interval, Amazon SQS can't detect duplicate messages. Amazon SQS continues to keep track of the message deduplication ID even after the message is received and deleted. The maximum length of MessageDeduplicationId is 128 characters. MessageDeduplicationId can contain alphanumeric characters (a-z, A-Z, 0-9) and punctuation (!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~). For best practices of using MessageDeduplicationId, see Using the MessageDeduplicationId Property (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagededuplicationid-property.html) in the Amazon SQS Developer Guide.
  --message-group-id: string # This parameter applies only to FIFO (first-in-first-out) queues. The tag that specifies that a message belongs to a specific message group. Messages that belong to the same message group are processed in a FIFO manner (however, messages in different message groups might be processed out of order). To interleave multiple ordered streams within a single queue, use MessageGroupId values (for example, session data for multiple users). In this scenario, multiple consumers can process the queue, but the session data of each user is processed in a FIFO fashion. You must associate a non-empty MessageGroupId with a message. If you don't provide a MessageGroupId, the action fails. ReceiveMessage might return messages with multiple MessageGroupId values. For each MessageGroupId, the messages are sorted by time sent. The caller can't specify a MessageGroupId. The length of MessageGroupId is 128 characters. Valid values: alphanumeric characters and punctuation (!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~). For best practices of using MessageGroupId, see Using the MessageGroupId Property (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagegroupid-property.html) in the Amazon SQS Developer Guide. MessageGroupId is required for FIFO queues. You can't use it for Standard queues.
  --action: string@action-completer-15
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "MessageBody" $message_body "scalar") (serialize-qp "DelaySeconds" $delay_seconds "scalar") (serialize-qp "MessageAttribute" $message_attribute "multi") (serialize-qp "MessageSystemAttribute" $message_system_attribute "multi") (serialize-qp "MessageDeduplicationId" $message_deduplication_id "scalar") (serialize-qp "MessageGroupId" $message_group_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"MessageBody": $message_body, "DelaySeconds": $delay_seconds, "MessageAttribute": $message_attribute, "MessageSystemAttribute": $message_system_attribute, "MessageDeduplicationId": $message_deduplication_id, "MessageGroupId": $message_group_id, "Action": $action, "Version": $version} | compact), body: null}
}

# Delivers a message to the specified queue. A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed: #x9 | #xA | #xD | #x20 to #xD7FF | #xE000 to #xFFFD | #x10000 to #x10FFFF Any characters not included in this list will be rejected. For more information, see the W3C specification for characters (http://www.w3.org/TR/REC-xml/#charsets).
#
# POST /
# operationId: POST_SendMessage
export def "api create-send-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-15
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Delivers up to ten messages to the specified queue. This is a batch version of SendMessage. For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent. The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of 200. The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes). A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed: #x9 | #xA | #xD | #x20 to #xD7FF | #xE000 to #xFFFD | #x10000 to #x10FFFF Any characters not included in this list will be rejected. For more information, see the W3C specification for characters (http://www.w3.org/TR/REC-xml/#charsets). If you don't specify the DelaySeconds parameter for an entry, Amazon SQS uses the default value for the queue. Some actions take lists of parameters. These lists are specified using the param.n notation. Values of n are integers starting from 1. For example, a parameter list with two elements looks like this: &AttributeName.1=first &AttributeName.2=second
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_SendMessageBatch
export def "api get-send-message-batch" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entries: list # A list of SendMessageBatchRequestEntry items.
  --action: string@action-completer-16
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "Entries" $entries "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Entries": $entries, "Action": $action, "Version": $version} | compact), body: null}
}

# Delivers up to ten messages to the specified queue. This is a batch version of SendMessage. For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent. The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of 200. The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes). A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed: #x9 | #xA | #xD | #x20 to #xD7FF | #xE000 to #xFFFD | #x10000 to #x10FFFF Any characters not included in this list will be rejected. For more information, see the W3C specification for characters (http://www.w3.org/TR/REC-xml/#charsets). If you don't specify the DelaySeconds parameter for an entry, Amazon SQS uses the default value for the queue. Some actions take lists of parameters. These lists are specified using the param.n notation. Values of n are integers starting from 1. For example, a parameter list with two elements looks like this: &AttributeName.1=first &AttributeName.2=second
#
# POST /
# operationId: POST_SendMessageBatch
export def "api create-send-message-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-16
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the MessageRetentionPeriod attribute can take up to 15 minutes. In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide. To remove the ability to change queue permissions, you must deny permission to the AddPermission, RemovePermission, and SetQueueAttributes actions in your IAM policy.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_SetQueueAttributes
export def "api get-update-queue-attributes" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute: record # A map of attributes to set. The following lists the names, descriptions, and values of the special request parameters that the SetQueueAttributes action uses: DelaySeconds – The length of time, in seconds, for which the delivery of all messages in the queue is delayed. Valid values: An integer from 0 to 900 (15 minutes). Default: 0. MaximumMessageSize – The limit of how many bytes a message can contain before Amazon SQS rejects it. Valid values: An integer from 1,024 bytes (1 KiB) up to 262,144 bytes (256 KiB). Default: 262,144 (256 KiB). MessageRetentionPeriod – The length of time, in seconds, for which Amazon SQS retains a message. Valid values: An integer representing seconds, from 60 (1 minute) to 1,209,600 (14 days). Default: 345,600 (4 days). Policy – The queue's policy. A valid Amazon Web Services policy. For more information about policy structure, see Overview of Amazon Web Services IAM Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/PoliciesOverview.html) in the Identity and Access Management User Guide. ReceiveMessageWaitTimeSeconds – The length of time, in seconds, for which a ReceiveMessage action waits for a message to arrive. Valid values: An integer from 0 to 20 (seconds). Default: 0. RedrivePolicy – The string that includes the parameters for the dead-letter queue functionality of the source queue as a JSON object. For more information about the redrive policy and dead-letter queues, see Using Amazon SQS Dead-Letter Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) in the Amazon SQS Developer Guide. deadLetterTargetArn – The Amazon Resource Name (ARN) of the dead-letter queue to which Amazon SQS moves messages after the value of maxReceiveCount is exceeded. maxReceiveCount – The number of times a message is delivered to the source queue before being moved to the dead-letter queue. When the ReceiveCount for a message exceeds the maxReceiveCount for a queue, Amazon SQS moves the message to the dead-letter-queue. The dead-letter queue of a FIFO queue must also be a FIFO queue. Similarly, the dead-letter queue of a standard queue must also be a standard queue. VisibilityTimeout – The visibility timeout for the queue, in seconds. Valid values: An integer from 0 to 43,200 (12 hours). Default: 30. For more information about the visibility timeout, see Visibility Timeout (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html) in the Amazon SQS Developer Guide. The following attributes apply only to server-side-encryption (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html): KmsMasterKeyId – The ID of an Amazon Web Services managed customer master key (CMK) for Amazon SQS or a custom CMK. For more information, see Key Terms (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-sse-key-terms). While the alias of the AWS-managed CMK for Amazon SQS is always alias/aws/sqs, the alias of a custom CMK can, for example, be alias/MyAlias . For more examples, see KeyId (https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters) in the Key Management Service API Reference. KmsDataKeyReusePeriodSeconds – The length of time, in seconds, for which Amazon SQS can reuse a data key (https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys) to encrypt or decrypt messages before calling KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours). Default: 300 (5 minutes). A shorter time period provides better security but results in more calls to KMS which might incur charges after Free Tier. For more information, see How Does the Data Key Reuse Period Work? (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-server-side-encryption.html#sqs-how-does-the-data-key-reuse-period-work). SqsManagedSseEnabled – Enables server-side queue encryption using SQS owned encryption keys. Only one server-side encryption option is supported per queue (e.g. SSE-KMS (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sse-existing-queue.html) or SSE-SQS (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-sqs-sse-queue.html)). The following attribute applies only to FIFO (first-in-first-out) queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html): ContentBasedDeduplication – Enables content-based deduplication. For more information, see Exactly-once processing (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues-exactly-once-processing.html) in the Amazon SQS Developer Guide. Note the following: Every message must have a unique MessageDeduplicationId. You may provide a MessageDeduplicationId explicitly. If you aren't able to provide a MessageDeduplicationId and you enable ContentBasedDeduplication for your queue, Amazon SQS uses a SHA-256 hash to generate the MessageDeduplicationId using the body of the message (but not the attributes of the message). If you don't provide a MessageDeduplicationId and the queue doesn't have ContentBasedDeduplication set, the action fails with an error. If the queue has ContentBasedDeduplication set, your MessageDeduplicationId overrides the generated one. When ContentBasedDeduplication is in effect, messages with identical content sent within the deduplication interval are treated as duplicates and only one copy of the message is delivered. If you send one message with ContentBasedDeduplication enabled and then another message with a MessageDeduplicationId that is the same as the one generated for the first MessageDeduplicationId, the two messages are treated as duplicates and only one copy of the message is delivered. The following attributes apply only to high throughput for FIFO queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/high-throughput-fifo.html): DeduplicationScope – Specifies whether message deduplication occurs at the message group or queue level. Valid values are messageGroup and queue. FifoThroughputLimit – Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group. Valid values are perQueue and perMessageGroupId. The perMessageGroupId value is allowed only when the value for DeduplicationScope is messageGroup. To enable high throughput for FIFO queues, do the following: Set DeduplicationScope to messageGroup. Set FifoThroughputLimit to perMessageGroupId. If you set these attributes to anything other than the values shown for enabling high throughput, normal throughput is in effect and deduplication occurs as specified. For information on throughput quotas, see Quotas related to messages (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/quotas-messages.html) in the Amazon SQS Developer Guide.
  --action: string@action-completer-17
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "Attribute" $attribute "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Attribute": $attribute, "Action": $action, "Version": $version} | compact), body: null}
}

# Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the MessageRetentionPeriod attribute can take up to 15 minutes. In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide. To remove the ability to change queue permissions, you must deny permission to the AddPermission, RemovePermission, and SetQueueAttributes actions in your IAM policy.
#
# POST /
# operationId: POST_SetQueueAttributes
export def "api create-update-queue-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-17
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Add cost allocation tags to the specified Amazon SQS queue. For an overview, see Tagging Your Amazon SQS Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html) in the Amazon SQS Developer Guide. When you use queue tags, keep the following guidelines in mind: Adding more than 50 tags to a queue isn't recommended. Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings. Tags are case-sensitive. A new tag with a key identical to that of an existing tag overwrites the existing tag. For a full list of tag restrictions, see Quotas related to queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues) in the Amazon SQS Developer Guide. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_TagQueue
export def "api get-tag-queue" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: record # The list of tags to be added to the specified queue.
  --action: string@action-completer-18
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Add cost allocation tags to the specified Amazon SQS queue. For an overview, see Tagging Your Amazon SQS Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html) in the Amazon SQS Developer Guide. When you use queue tags, keep the following guidelines in mind: Adding more than 50 tags to a queue isn't recommended. Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings. Tags are case-sensitive. A new tag with a key identical to that of an existing tag overwrites the existing tag. For a full list of tag restrictions, see Quotas related to queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues) in the Amazon SQS Developer Guide. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# POST /
# operationId: POST_TagQueue
export def "api create-tag-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-18
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see Tagging Your Amazon SQS Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html) in the Amazon SQS Developer Guide. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# GET /{AccountNumber}/{QueueName}/
# operationId: GET_UntagQueue
export def "api get-untag-queue" [
  account_number: int
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # The list of tags to be removed from the specified queue.
  --action: string@action-completer-19
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_number | is-empty) { error make --unspanned { msg: "path parameter 'AccountNumber' must be non-empty" } }
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'QueueName' must be non-empty" } }
  let qp = [(serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_number: (encode-path-segment $account_number), queue_name: (encode-path-segment $queue_name)} | format pattern "/{account_number}/{queue_name}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"TagKeys": $tag_keys, "Action": $action, "Version": $version} | compact), body: null}
}

# Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see Tagging Your Amazon SQS Queues (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html) in the Amazon SQS Developer Guide. Cross-account permissions don't apply to this action. For more information, see Grant cross-account permissions to a role and a user name (https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name) in the Amazon SQS Developer Guide.
#
# POST /
# operationId: POST_UntagQueue
export def "api create-untag-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-19
  --version: string@version-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}
