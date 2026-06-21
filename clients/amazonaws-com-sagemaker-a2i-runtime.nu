# Auto-generated client for Amazon Augmented AI Runtime v2019-11-07
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sagemaker-a2i-runtime/2019-11-07/openapi.json
# Auth: --token flag or $env.AMAZON_AUGMENTED_AI_RUNTIME_TOKEN

const BASE_URL = "http://a2i-runtime.sagemaker.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_AUGMENTED_AI_RUNTIME_TOKEN | default "" }
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

def base-url-completer [] { ["http://a2i-runtime.sagemaker.us-east-1.amazonaws.com" "http://a2i-runtime.sagemaker.us-east-2.amazonaws.com" "http://a2i-runtime.sagemaker.us-west-1.amazonaws.com" "http://a2i-runtime.sagemaker.us-west-2.amazonaws.com" "http://a2i-runtime.sagemaker.us-gov-west-1.amazonaws.com" "http://a2i-runtime.sagemaker.us-gov-east-1.amazonaws.com" "http://a2i-runtime.sagemaker.ca-central-1.amazonaws.com" "http://a2i-runtime.sagemaker.eu-north-1.amazonaws.com" "http://a2i-runtime.sagemaker.eu-west-1.amazonaws.com" "http://a2i-runtime.sagemaker.eu-west-2.amazonaws.com" "http://a2i-runtime.sagemaker.eu-west-3.amazonaws.com" "http://a2i-runtime.sagemaker.eu-central-1.amazonaws.com" "http://a2i-runtime.sagemaker.eu-south-1.amazonaws.com" "http://a2i-runtime.sagemaker.af-south-1.amazonaws.com" "http://a2i-runtime.sagemaker.ap-northeast-1.amazonaws.com" "http://a2i-runtime.sagemaker.ap-northeast-2.amazonaws.com" "http://a2i-runtime.sagemaker.ap-northeast-3.amazonaws.com" "http://a2i-runtime.sagemaker.ap-southeast-1.amazonaws.com" "http://a2i-runtime.sagemaker.ap-southeast-2.amazonaws.com" "http://a2i-runtime.sagemaker.ap-east-1.amazonaws.com" "http://a2i-runtime.sagemaker.ap-south-1.amazonaws.com" "http://a2i-runtime.sagemaker.sa-east-1.amazonaws.com" "http://a2i-runtime.sagemaker.me-south-1.amazonaws.com" "https://a2i-runtime.sagemaker.us-east-1.amazonaws.com" "https://a2i-runtime.sagemaker.us-east-2.amazonaws.com" "https://a2i-runtime.sagemaker.us-west-1.amazonaws.com" "https://a2i-runtime.sagemaker.us-west-2.amazonaws.com" "https://a2i-runtime.sagemaker.us-gov-west-1.amazonaws.com" "https://a2i-runtime.sagemaker.us-gov-east-1.amazonaws.com" "https://a2i-runtime.sagemaker.ca-central-1.amazonaws.com" "https://a2i-runtime.sagemaker.eu-north-1.amazonaws.com" "https://a2i-runtime.sagemaker.eu-west-1.amazonaws.com" "https://a2i-runtime.sagemaker.eu-west-2.amazonaws.com" "https://a2i-runtime.sagemaker.eu-west-3.amazonaws.com" "https://a2i-runtime.sagemaker.eu-central-1.amazonaws.com" "https://a2i-runtime.sagemaker.eu-south-1.amazonaws.com" "https://a2i-runtime.sagemaker.af-south-1.amazonaws.com" "https://a2i-runtime.sagemaker.ap-northeast-1.amazonaws.com" "https://a2i-runtime.sagemaker.ap-northeast-2.amazonaws.com" "https://a2i-runtime.sagemaker.ap-northeast-3.amazonaws.com" "https://a2i-runtime.sagemaker.ap-southeast-1.amazonaws.com" "https://a2i-runtime.sagemaker.ap-southeast-2.amazonaws.com" "https://a2i-runtime.sagemaker.ap-east-1.amazonaws.com" "https://a2i-runtime.sagemaker.ap-south-1.amazonaws.com" "https://a2i-runtime.sagemaker.sa-east-1.amazonaws.com" "https://a2i-runtime.sagemaker.me-south-1.amazonaws.com" "http://a2i-runtime.sagemaker.cn-north-1.amazonaws.com.cn" "http://a2i-runtime.sagemaker.cn-northwest-1.amazonaws.com.cn" "https://a2i-runtime.sagemaker.cn-north-1.amazonaws.com.cn" "https://a2i-runtime.sagemaker.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-order-completer [] { ["Ascending" "Descending"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "human-loops delete" } } | get name | first)
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

# Deletes the specified human loop for a flow definition. If the human loop was deleted, this operation will return a ResourceNotFoundException.
#
# DELETE /human-loops/{HumanLoopName}
# operationId: DeleteHumanLoop
export def "human-loops delete" [
  human_loop_name: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($human_loop_name | is-empty) { error make --unspanned { msg: "path parameter 'HumanLoopName' must be non-empty" } }
  let full_url = (build-url $base ({human_loop_name: (encode-path-segment $human_loop_name)} | format pattern "/human-loops/{human_loop_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns information about the specified human loop. If the human loop was deleted, this operation will return a ResourceNotFoundException error.
#
# GET /human-loops/{HumanLoopName}
# operationId: DescribeHumanLoop
export def "human-loops get" [
  human_loop_name: string
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
]: nothing -> record<CreationTime: record, FailureReason: record, FailureCode: record, HumanLoopStatus: record, HumanLoopName: record, HumanLoopArn: record, FlowDefinitionArn: record, HumanLoopOutput: record<OutputS3Uri: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($human_loop_name | is-empty) { error make --unspanned { msg: "path parameter 'HumanLoopName' must be non-empty" } }
  let full_url = (build-url $base ({human_loop_name: (encode-path-segment $human_loop_name)} | format pattern "/human-loops/{human_loop_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns information about human loops, given the specified parameters. If a human loop was deleted, it will not be included.
#
# GET /human-loops
# operationId: ListHumanLoops
export def "human-loops list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --creation-time-after: string # (Optional) The timestamp of the date when you want the human loops to begin in ISO 8601 format. For example, 2020-02-24. (format: date-time)
  --creation-time-before: string # (Optional) The timestamp of the date before which you want the human loops to begin in ISO 8601 format. For example, 2020-02-24. (format: date-time)
  --flow-definition-arn: string # The Amazon Resource Name (ARN) of a flow definition.
  --sort-order: string@sort-order-completer # Optional. The order for displaying results. Valid values: Ascending and Descending.
  --next-token: string # A token to display the next page of results.
  --max-results: int # The total number of items to return. If the total number of available items is more than the value specified in MaxResults, then a NextToken is returned in the output. You can use this token to display the next page of results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<HumanLoopSummaries: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CreationTimeAfter" $creation_time_after "scalar") (serialize-qp "CreationTimeBefore" $creation_time_before "scalar") (serialize-qp "FlowDefinitionArn" $flow_definition_arn "scalar") (serialize-qp "SortOrder" $sort_order "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/human-loops" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "FlowDefinitionArn": $flow_definition_arn, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact), body: null}
}

# Starts a human loop, provided that at least one activation condition is met.
#
# POST /human-loops
# operationId: StartHumanLoop
# --HumanLoopInput shape: {InputContent?: any}
# --DataAttributes shape: {ContentClassifiers?: any}
export def "human-loops start" [
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
  human_loop_name: string # The name of the human loop.
  flow_definition_arn: string # The Amazon Resource Name (ARN) of the flow definition associated with this human loop.
  human_loop_input: record # An object containing the human loop input in JSON format. — shape: {InputContent?: any}
  --data-attributes: record # Attributes of the data specified by the customer. Use these to describe the data to be labeled. — shape: {ContentClassifiers?: any}
]: any -> record<HumanLoopArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/human-loops")
  let req_body = {"HumanLoopName": $human_loop_name, "FlowDefinitionArn": $flow_definition_arn, "HumanLoopInput": $human_loop_input, "DataAttributes": $data_attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Stops the specified human loop.
#
# POST /human-loops/stop
# operationId: StopHumanLoop
export def "human-loops-stop stop" [
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
  human_loop_name: string # The name of the human loop that you want to stop.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/human-loops/stop")
  let req_body = {"HumanLoopName": $human_loop_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
