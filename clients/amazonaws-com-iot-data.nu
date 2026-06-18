# Auto-generated client for AWS IoT Data Plane v2015-05-28
# Source: https://api.apis.guru/v2/specs/amazonaws.com/iot-data/2015-05-28/openapi.json
# Auth: --token flag or $env.AWS_IOT_DATA_PLANE_TOKEN

const BASE_URL = "http://data-ats.iot.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_IOT_DATA_PLANE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://data-ats.iot.us-east-1.amazonaws.com" "http://data-ats.iot.us-east-2.amazonaws.com" "http://data-ats.iot.us-west-1.amazonaws.com" "http://data-ats.iot.us-west-2.amazonaws.com" "http://data-ats.iot.us-gov-west-1.amazonaws.com" "http://data-ats.iot.us-gov-east-1.amazonaws.com" "http://data-ats.iot.ca-central-1.amazonaws.com" "http://data-ats.iot.eu-north-1.amazonaws.com" "http://data-ats.iot.eu-west-1.amazonaws.com" "http://data-ats.iot.eu-west-2.amazonaws.com" "http://data-ats.iot.eu-west-3.amazonaws.com" "http://data-ats.iot.eu-central-1.amazonaws.com" "http://data-ats.iot.eu-south-1.amazonaws.com" "http://data-ats.iot.af-south-1.amazonaws.com" "http://data-ats.iot.ap-northeast-1.amazonaws.com" "http://data-ats.iot.ap-northeast-2.amazonaws.com" "http://data-ats.iot.ap-northeast-3.amazonaws.com" "http://data-ats.iot.ap-southeast-1.amazonaws.com" "http://data-ats.iot.ap-southeast-2.amazonaws.com" "http://data-ats.iot.ap-east-1.amazonaws.com" "http://data-ats.iot.ap-south-1.amazonaws.com" "http://data-ats.iot.sa-east-1.amazonaws.com" "http://data-ats.iot.me-south-1.amazonaws.com" "https://data-ats.iot.us-east-1.amazonaws.com" "https://data-ats.iot.us-east-2.amazonaws.com" "https://data-ats.iot.us-west-1.amazonaws.com" "https://data-ats.iot.us-west-2.amazonaws.com" "https://data-ats.iot.us-gov-west-1.amazonaws.com" "https://data-ats.iot.us-gov-east-1.amazonaws.com" "https://data-ats.iot.ca-central-1.amazonaws.com" "https://data-ats.iot.eu-north-1.amazonaws.com" "https://data-ats.iot.eu-west-1.amazonaws.com" "https://data-ats.iot.eu-west-2.amazonaws.com" "https://data-ats.iot.eu-west-3.amazonaws.com" "https://data-ats.iot.eu-central-1.amazonaws.com" "https://data-ats.iot.eu-south-1.amazonaws.com" "https://data-ats.iot.af-south-1.amazonaws.com" "https://data-ats.iot.ap-northeast-1.amazonaws.com" "https://data-ats.iot.ap-northeast-2.amazonaws.com" "https://data-ats.iot.ap-northeast-3.amazonaws.com" "https://data-ats.iot.ap-southeast-1.amazonaws.com" "https://data-ats.iot.ap-southeast-2.amazonaws.com" "https://data-ats.iot.ap-east-1.amazonaws.com" "https://data-ats.iot.ap-south-1.amazonaws.com" "https://data-ats.iot.sa-east-1.amazonaws.com" "https://data-ats.iot.me-south-1.amazonaws.com" "http://data-ats.iot.cn-north-1.amazonaws.com.cn" "http://data-ats.iot.cn-northwest-1.amazonaws.com.cn" "https://data-ats.iot.cn-north-1.amazonaws.com.cn" "https://data-ats.iot.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-mqtt5-payload-format-indicator-completer [] { ["UNSPECIFIED_BYTES" "UTF8_DATA"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "things-shadow delete" } } | get name | first)
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

# Deletes the shadow for the specified thing. Requires permission to access the DeleteThingShadow (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action. For more information, see DeleteThingShadow (http://docs.aws.amazon.com/iot/latest/developerguide/API_DeleteThingShadow.html) in the IoT Developer Guide.
#
# DELETE /things/{thingName}/shadow
# operationId: DeleteThingShadow
export def "things-shadow delete" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the shadow.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<payload: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({thing_name: (encode-path-segment $thing_name)} | format pattern "/things/{thing_name}/shadow") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the shadow for the specified thing. Requires permission to access the GetThingShadow (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action. For more information, see GetThingShadow (http://docs.aws.amazon.com/iot/latest/developerguide/API_GetThingShadow.html) in the IoT Developer Guide.
#
# GET /things/{thingName}/shadow
# operationId: GetThingShadow
export def "things-shadow get" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the shadow.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<payload: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({thing_name: (encode-path-segment $thing_name)} | format pattern "/things/{thing_name}/shadow") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the shadow for the specified thing. Requires permission to access the UpdateThingShadow (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action. For more information, see UpdateThingShadow (http://docs.aws.amazon.com/iot/latest/developerguide/API_UpdateThingShadow.html) in the IoT Developer Guide.
#
# POST /things/{thingName}/shadow
# operationId: UpdateThingShadow
export def "things-shadow update" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the shadow.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  payload: string # The state information, in JSON format.
]: any -> record<payload: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({thing_name: (encode-path-segment $thing_name)} | format pattern "/things/{thing_name}/shadow") $qp)
  let req_body = {"payload": $payload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets the details of a single retained message for the specified topic. This action returns the message payload of the retained message, which can incur messaging costs. To list only the topic names of the retained messages, call ListRetainedMessages (https://docs.aws.amazon.com/iot/latest/apireference/API_iotdata_ListRetainedMessages.html). Requires permission to access the GetRetainedMessage (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiotfleethubfordevicemanagement.html#awsiotfleethubfordevicemanagement-actions-as-permissions) action. For more information about messaging costs, see Amazon Web Services IoT Core pricing - Messaging (http://aws.amazon.com/iot-core/pricing/#Messaging).
#
# GET /retainedMessage/{topic}
# operationId: GetRetainedMessage
export def "retained-message get" [
  topic: string
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
]: nothing -> record<topic: record, payload: record, qos: record, lastModifiedTime: record, userProperties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({topic: (encode-path-segment $topic)} | format pattern "/retainedMessage/{topic}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the shadows for the specified thing. Requires permission to access the ListNamedShadowsForThing (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /api/things/shadow/ListNamedShadowsForThing/{thingName}
# operationId: ListNamedShadowsForThing
export def "things-shadow-list-named-shadows-for-thing list" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token to retrieve the next set of results.
  --page-size: int # The result page size.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<results: record, nextToken: record, timestamp: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({thing_name: (encode-path-segment $thing_name)} | format pattern "/api/things/shadow/ListNamedShadowsForThing/{thing_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists summary information about the retained messages stored for the account. This action returns only the topic names of the retained messages. It doesn't return any message payloads. Although this action doesn't return a message payload, it can still incur messaging costs. To get the message payload of a retained message, call GetRetainedMessage (https://docs.aws.amazon.com/iot/latest/apireference/API_iotdata_GetRetainedMessage.html) with the topic name of the retained message. Requires permission to access the ListRetainedMessages (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiotfleethubfordevicemanagement.html#awsiotfleethubfordevicemanagement-actions-as-permissions) action. For more information about messaging costs, see Amazon Web Services IoT Core pricing - Messaging (http://aws.amazon.com/iot-core/pricing/#Messaging).
#
# GET /retainedMessage
# operationId: ListRetainedMessages
export def "retained-message list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return at one time.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<retainedTopics: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/retainedMessage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Publishes an MQTT message. Requires permission to access the Publish (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action. For more information about MQTT messages, see MQTT Protocol (http://docs.aws.amazon.com/iot/latest/developerguide/mqtt.html) in the IoT Developer Guide. For more information about messaging costs, see Amazon Web Services IoT Core pricing - Messaging (http://aws.amazon.com/iot-core/pricing/#Messaging).
#
# POST /topics/{topic}
# operationId: Publish
export def "topics publish" [
  topic: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qos: int # The Quality of Service (QoS) level. The default QoS level is 0.
  --retain: oneof<nothing, bool> # A Boolean value that determines whether to set the RETAIN flag when the message is published. Setting the RETAIN flag causes the message to be retained and sent to new subscribers to the topic. Valid values: true | false Default value: false
  --content-type: string # A UTF-8 encoded string that describes the content of the publishing message.
  --response-topic: string # A UTF-8 encoded string that's used as the topic name for a response message. The response topic is used to describe the topic which the receiver should publish to as part of the request-response flow. The topic must not contain wildcard characters.
  --message-expiry: int # A user-defined integer value that represents the message expiry interval in seconds. If absent, the message doesn't expire. For more information about the limits of messageExpiry, see Amazon Web Services IoT Core message broker and protocol limits and quotas (https://docs.aws.amazon.com/general/latest/gr/iot-core.html#message-broker-limits) from the Amazon Web Services Reference Guide.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-mqtt5-user-properties: string # A JSON string that contains an array of JSON objects. If you don’t use Amazon Web Services SDK or CLI, you must encode the JSON string to base64 format before adding it to the HTTP header. userProperties is an HTTP header value in the API. The following example userProperties parameter is a JSON string which represents two User Properties. Note that it needs to be base64-encoded: [{"deviceName": "alpha"}, {"deviceCnt": "45"}]
  --x-amz-mqtt5-payload-format-indicator: string@x-amz-mqtt5-payload-format-indicator-completer # An Enum string value that indicates whether the payload is formatted as UTF-8. payloadFormatIndicator is an HTTP header value in the API.
  --x-amz-mqtt5-correlation-data: string # The base64-encoded binary data used by the sender of the request message to identify which request the response message is for when it's received. correlationData is an HTTP header value in the API.
  --payload: string # The message body. MQTT accepts text, binary, and empty (null) message payloads. Publishing an empty (null) payload with retain = true deletes the retained message identified by topic from Amazon Web Services IoT Core.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "qos" $qos "scalar") (serialize-qp "retain" $retain "scalar") (serialize-qp "contentType" $content_type "scalar") (serialize-qp "responseTopic" $response_topic "scalar") (serialize-qp "messageExpiry" $message_expiry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({topic: (encode-path-segment $topic)} | format pattern "/topics/{topic}") $qp)
  let req_body = {"payload": $payload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-mqtt5-user-properties": $x_amz_mqtt5_user_properties, "x-amz-mqtt5-payload-format-indicator": $x_amz_mqtt5_payload_format_indicator, "x-amz-mqtt5-correlation-data": $x_amz_mqtt5_correlation_data} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
