# Auto-generated client for Amazon Augmented AI Runtime v2019-11-07
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sagemaker-a2i-runtime/2019-11-07/openapi.json
# Auth: --token flag or $env.AMAZON_AUGMENTED_AI_RUNTIME_TOKEN

const BASE_URL = "http://a2i-runtime.sagemaker.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_AUGMENTED_AI_RUNTIME_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
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
  let full_url = (build-url $base ({human_loop_name: (encode-path-segment $human_loop_name)} | format pattern "/human-loops/{human_loop_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({human_loop_name: (encode-path-segment $human_loop_name)} | format pattern "/human-loops/{human_loop_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/human-loops" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "FlowDefinitionArn": $flow_definition_arn, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/human-loops" $auth.query)
  let req_body = {"HumanLoopName": $human_loop_name, "FlowDefinitionArn": $flow_definition_arn, "HumanLoopInput": $human_loop_input, "DataAttributes": $data_attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/human-loops/stop" $auth.query)
  let req_body = {"HumanLoopName": $human_loop_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
