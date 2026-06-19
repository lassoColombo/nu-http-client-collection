# Auto-generated client for AWS Elemental MediaLive v2017-10-14
# Source: https://api.apis.guru/v2/specs/amazonaws.com/medialive/2017-10-14/openapi.json
# Auth: --token flag or $env.AWS_ELEMENTAL_MEDIALIVE_TOKEN

const BASE_URL = "http://medialive.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_ELEMENTAL_MEDIALIVE_TOKEN | default "" }
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

def base-url-completer [] { ["http://medialive.us-east-1.amazonaws.com" "http://medialive.us-east-2.amazonaws.com" "http://medialive.us-west-1.amazonaws.com" "http://medialive.us-west-2.amazonaws.com" "http://medialive.us-gov-west-1.amazonaws.com" "http://medialive.us-gov-east-1.amazonaws.com" "http://medialive.ca-central-1.amazonaws.com" "http://medialive.eu-north-1.amazonaws.com" "http://medialive.eu-west-1.amazonaws.com" "http://medialive.eu-west-2.amazonaws.com" "http://medialive.eu-west-3.amazonaws.com" "http://medialive.eu-central-1.amazonaws.com" "http://medialive.eu-south-1.amazonaws.com" "http://medialive.af-south-1.amazonaws.com" "http://medialive.ap-northeast-1.amazonaws.com" "http://medialive.ap-northeast-2.amazonaws.com" "http://medialive.ap-northeast-3.amazonaws.com" "http://medialive.ap-southeast-1.amazonaws.com" "http://medialive.ap-southeast-2.amazonaws.com" "http://medialive.ap-east-1.amazonaws.com" "http://medialive.ap-south-1.amazonaws.com" "http://medialive.sa-east-1.amazonaws.com" "http://medialive.me-south-1.amazonaws.com" "https://medialive.us-east-1.amazonaws.com" "https://medialive.us-east-2.amazonaws.com" "https://medialive.us-west-1.amazonaws.com" "https://medialive.us-west-2.amazonaws.com" "https://medialive.us-gov-west-1.amazonaws.com" "https://medialive.us-gov-east-1.amazonaws.com" "https://medialive.ca-central-1.amazonaws.com" "https://medialive.eu-north-1.amazonaws.com" "https://medialive.eu-west-1.amazonaws.com" "https://medialive.eu-west-2.amazonaws.com" "https://medialive.eu-west-3.amazonaws.com" "https://medialive.eu-central-1.amazonaws.com" "https://medialive.eu-south-1.amazonaws.com" "https://medialive.af-south-1.amazonaws.com" "https://medialive.ap-northeast-1.amazonaws.com" "https://medialive.ap-northeast-2.amazonaws.com" "https://medialive.ap-northeast-3.amazonaws.com" "https://medialive.ap-southeast-1.amazonaws.com" "https://medialive.ap-southeast-2.amazonaws.com" "https://medialive.ap-east-1.amazonaws.com" "https://medialive.ap-south-1.amazonaws.com" "https://medialive.sa-east-1.amazonaws.com" "https://medialive.me-south-1.amazonaws.com" "http://medialive.cn-north-1.amazonaws.com.cn" "http://medialive.cn-northwest-1.amazonaws.com.cn" "https://medialive.cn-north-1.amazonaws.com.cn" "https://medialive.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def channel-class-completer [] { ["SINGLE_PIPELINE" "STANDARD"] }
def log-level-completer [] { ["DEBUG" "DISABLED" "ERROR" "INFO" "WARNING"] }
def type-completer [] { ["AWS_CDI" "INPUT_DEVICE" "MEDIACONNECT" "MP4_FILE" "RTMP_PULL" "RTMP_PUSH" "RTP_PUSH" "TS_FILE" "UDP_PUSH" "URL_PULL"] }
def accept-completer [] { ["image/jpeg"] }
def force-completer [] { ["NO" "YES"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "prod-input-devices-accept create-transfer" } } | get name | first)
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

# Accept an incoming input device transfer. The ownership of the device will transfer to your AWS account.
#
# POST /prod/inputDevices/{inputDeviceId}/accept
# operationId: AcceptInputDeviceTransfer
export def "prod-input-devices-accept create-transfer" [
  input_device_id: string
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
  if ($input_device_id | is-empty) { error make --unspanned { msg: "path parameter 'inputDeviceId' must be non-empty" } }
  let full_url = (build-url $base ({input_device_id: (encode-path-segment $input_device_id)} | format pattern "/prod/inputDevices/{input_device_id}/accept"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Starts delete of resources.
#
# POST /prod/batch/delete
# operationId: BatchDelete
export def "prod-batch-delete delete" [
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
  --channel-ids: list<string> # Placeholder documentation for __listOf__string
  --input-ids: list<string> # Placeholder documentation for __listOf__string
  --input-security-group-ids: list<string> # Placeholder documentation for __listOf__string
  --multiplex-ids: list<string> # Placeholder documentation for __listOf__string
]: any -> record<Failed: record, Successful: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/batch/delete")
  let req_body = {"channelIds": $channel_ids, "inputIds": $input_ids, "inputSecurityGroupIds": $input_security_group_ids, "multiplexIds": $multiplex_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Starts existing resources
#
# POST /prod/batch/start
# operationId: BatchStart
export def "prod-batch-start start" [
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
  --channel-ids: list<string> # Placeholder documentation for __listOf__string
  --multiplex-ids: list<string> # Placeholder documentation for __listOf__string
]: any -> record<Failed: record, Successful: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/batch/start")
  let req_body = {"channelIds": $channel_ids, "multiplexIds": $multiplex_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Stops running resources
#
# POST /prod/batch/stop
# operationId: BatchStop
export def "prod-batch-stop stop" [
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
  --channel-ids: list<string> # Placeholder documentation for __listOf__string
  --multiplex-ids: list<string> # Placeholder documentation for __listOf__string
]: any -> record<Failed: record, Successful: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/batch/stop")
  let req_body = {"channelIds": $channel_ids, "multiplexIds": $multiplex_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update a channel schedule
#
# PUT /prod/channels/{channelId}/schedule
# operationId: BatchUpdateSchedule
# --creates shape: {ScheduleActions?: any}
# --deletes shape: {ActionNames?: any}
export def "prod-channels-schedule update-batch" [
  channel_id: string
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
  --creates: record # A list of schedule actions to create (in a request) or that have been created (in a response). — shape: {ScheduleActions?: any}
  --deletes: record # A list of schedule actions to delete. — shape: {ActionNames?: any}
]: any -> record<Creates: record<ScheduleActions: record>, Deletes: record<ScheduleActions: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/prod/channels/{channel_id}/schedule"))
  let req_body = {"creates": $creates, "deletes": $deletes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete all schedule actions on a channel.
#
# DELETE /prod/channels/{channelId}/schedule
# operationId: DeleteSchedule
export def "prod-channels-schedule delete" [
  channel_id: string
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
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/prod/channels/{channel_id}/schedule"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a channel schedule
#
# GET /prod/channels/{channelId}/schedule
# operationId: DescribeSchedule
export def "prod-channels-schedule get" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, ScheduleActions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/prod/channels/{channel_id}/schedule") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Cancel an input device transfer that you have requested.
#
# POST /prod/inputDevices/{inputDeviceId}/cancel
# operationId: CancelInputDeviceTransfer
export def "prod-input-devices-cancel cancel-transfer" [
  input_device_id: string
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
  if ($input_device_id | is-empty) { error make --unspanned { msg: "path parameter 'inputDeviceId' must be non-empty" } }
  let full_url = (build-url $base ({input_device_id: (encode-path-segment $input_device_id)} | format pattern "/prod/inputDevices/{input_device_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Send a request to claim an AWS Elemental device that you have purchased from a third-party vendor. After the request succeeds, you will own the device.
#
# POST /prod/claimDevice
# operationId: ClaimDevice
export def "prod-claim-device create" [
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
  --id: string # Placeholder documentation for __string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/claimDevice")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a new channel
#
# POST /prod/channels
# operationId: CreateChannel
# --cdiInputSpecification shape: {Resolution?: any}
# --destinations item shape: {Id?: any, MediaPackageSettings?: any, MultiplexSettings?: any, Settings?: any}
# --encoderSettings shape: {AudioDescriptions?: any, AvailBlanking?: any, AvailConfiguration?: any, BlackoutSlate?: any, CaptionDescriptions?: any, FeatureActivations?: any, GlobalConfiguration?: any, MotionGraphicsConfiguration?: any, NielsenConfiguration?: any, OutputGroups?: any, TimecodeConfig?: any, VideoDescriptions?: any}
# --inputAttachments item shape: {AutomaticInputFailoverSettings?: any, InputAttachmentName?: any, InputId?: any, InputSettings?: any}
# --inputSpecification shape: {Codec?: any, MaximumBitrate?: any, Resolution?: any}
# --maintenance shape: {MaintenanceDay?: any, MaintenanceStartTime?: any}
# --vpc shape: {PublicAddressAllocationIds?: any, SecurityGroupIds?: any, SubnetIds?: any}
export def "prod-channels create" [
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
  --cdi-input-specification: record # Placeholder documentation for CdiInputSpecification — shape: {Resolution?: any}
  --channel-class: string@channel-class-completer # A standard channel has two encoding pipelines and a single pipeline channel only has one.
  --destinations: list # Placeholder documentation for __listOfOutputDestination — item shape: {Id?: any, MediaPackageSettings?: any, MultiplexSettings?: any, Settings?: any}
  --encoder-settings: record # Encoder Settings — shape: {AudioDescriptions?: any, AvailBlanking?: any, AvailConfiguration?: any, BlackoutSlate?: any, CaptionDescriptions?: any, FeatureActivations?: any, GlobalConfiguration?: any, MotionGraphicsConfiguration?: any, NielsenConfiguration?: any, OutputGroups?: any, TimecodeConfig?: any, VideoDescriptions?: any}
  --input-attachments: list # Placeholder documentation for __listOfInputAttachment — item shape: {AutomaticInputFailoverSettings?: any, InputAttachmentName?: any, InputId?: any, InputSettings?: any}
  --input-specification: record # Placeholder documentation for InputSpecification — shape: {Codec?: any, MaximumBitrate?: any, Resolution?: any}
  --log-level: string@log-level-completer # The log level the user wants for their channel.
  --maintenance: record # Placeholder documentation for MaintenanceCreateSettings — shape: {MaintenanceDay?: any, MaintenanceStartTime?: any}
  --name: string # Placeholder documentation for __string
  --request-id: string # Placeholder documentation for __string
  --reserved: string # Placeholder documentation for __string
  --role-arn: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
  --vpc: record # The properties for a private VPC Output When this property is specified, the output egress addresses will be created in a user specified VPC — shape: {PublicAddressAllocationIds?: any, SecurityGroupIds?: any, SubnetIds?: any}
]: any -> record<Channel: record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: record, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: record, TimecodeConfig: record, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/channels")
  let req_body = {"cdiInputSpecification": $cdi_input_specification, "channelClass": $channel_class, "destinations": $destinations, "encoderSettings": $encoder_settings, "inputAttachments": $input_attachments, "inputSpecification": $input_specification, "logLevel": $log_level, "maintenance": $maintenance, "name": $name, "requestId": $request_id, "reserved": $reserved, "roleArn": $role_arn, "tags": $tags, "vpc": $vpc} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Produces list of channels that have been created
#
# GET /prod/channels
# operationId: ListChannels
export def "prod-channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Channels: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Create an input
#
# POST /prod/inputs
# operationId: CreateInput
# --destinations item shape: {StreamName?: any}
# --inputDevices item shape: {Id?: any}
# --mediaConnectFlows item shape: {FlowArn?: any}
# --sources item shape: {PasswordParam?: any, Url?: any, Username?: any}
# --vpc shape: {SecurityGroupIds?: any, SubnetIds?: any}
export def "prod-inputs create" [
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
  --destinations: list # Placeholder documentation for __listOfInputDestinationRequest — item shape: {StreamName?: any}
  --input-devices: list # Placeholder documentation for __listOfInputDeviceSettings — item shape: {Id?: any}
  --input-security-groups: list<string> # Placeholder documentation for __listOf__string
  --media-connect-flows: list # Placeholder documentation for __listOfMediaConnectFlowRequest — item shape: {FlowArn?: any}
  --name: string # Placeholder documentation for __string
  --request-id: string # Placeholder documentation for __string
  --role-arn: string # Placeholder documentation for __string
  --sources: list # Placeholder documentation for __listOfInputSourceRequest — item shape: {PasswordParam?: any, Url?: any, Username?: any}
  --tags: record # Placeholder documentation for Tags
  --type: string@type-completer # The different types of inputs that AWS Elemental MediaLive supports.
  --vpc: record # Settings for a private VPC Input. When this property is specified, the input destination addresses will be created in a VPC rather than with public Internet addresses. This property requires setting the roleArn property on Input creation. Not compatible with the inputSecurityGroups property. — shape: {SecurityGroupIds?: any, SubnetIds?: any}
]: any -> record<Input: record<Arn: record, AttachedChannels: record, Destinations: record, Id: record, InputClass: record, InputDevices: record, InputPartnerIds: record, InputSourceType: record, MediaConnectFlows: record, Name: record, RoleArn: record, SecurityGroups: record, Sources: record, State: record, Tags: record, Type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/inputs")
  let req_body = {"destinations": $destinations, "inputDevices": $input_devices, "inputSecurityGroups": $input_security_groups, "mediaConnectFlows": $media_connect_flows, "name": $name, "requestId": $request_id, "roleArn": $role_arn, "sources": $sources, "tags": $tags, "type": $type, "vpc": $vpc} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Produces list of inputs that have been created
#
# GET /prod/inputs
# operationId: ListInputs
export def "prod-inputs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Inputs: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/inputs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Creates a Input Security Group
#
# POST /prod/inputSecurityGroups
# operationId: CreateInputSecurityGroup
# --whitelistRules item shape: {Cidr?: any}
export def "prod-input-security-groups create" [
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
  --tags: record # Placeholder documentation for Tags
  --whitelist-rules: list # Placeholder documentation for __listOfInputWhitelistRuleCidr — item shape: {Cidr?: any}
]: any -> record<SecurityGroup: record<Arn: record, Id: record, Inputs: record, State: record, Tags: record, WhitelistRules: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/inputSecurityGroups")
  let req_body = {"tags": $tags, "whitelistRules": $whitelist_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Produces a list of Input Security Groups for an account
#
# GET /prod/inputSecurityGroups
# operationId: ListInputSecurityGroups
export def "prod-input-security-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<InputSecurityGroups: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/inputSecurityGroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Create a new multiplex.
#
# POST /prod/multiplexes
# operationId: CreateMultiplex
# --multiplexSettings shape: {MaximumVideoBufferDelayMilliseconds?: any, TransportStreamBitrate?: any, TransportStreamId?: any, TransportStreamReservedBitrate?: any}
export def "prod-multiplexes create-multiplex" [
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
  availability_zones: list<string> # Placeholder documentation for __listOf__string
  multiplex_settings: record # Contains configuration for a Multiplex event — shape: {MaximumVideoBufferDelayMilliseconds?: any, TransportStreamBitrate?: any, TransportStreamId?: any, TransportStreamReservedBitrate?: any}
  name: string # Placeholder documentation for __string
  request_id: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
]: any -> record<Multiplex: record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/multiplexes")
  let req_body = {"availabilityZones": $availability_zones, "multiplexSettings": $multiplex_settings, "name": $name, "requestId": $request_id, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of the existing multiplexes.
#
# GET /prod/multiplexes
# operationId: ListMultiplexes
export def "prod-multiplexes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of items to return.
  --next-token: string # The token to retrieve the next page of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Multiplexes: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/multiplexes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Create a new program in the multiplex.
#
# POST /prod/multiplexes/{multiplexId}/programs
# operationId: CreateMultiplexProgram
# --multiplexProgramSettings shape: {PreferredChannelPipeline?: any, ProgramNumber?: any, ServiceDescriptor?: any, VideoSettings?: any}
export def "prod-multiplexes-programs create-multiplex" [
  multiplex_id: string
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
  multiplex_program_settings: record # Multiplex Program settings configuration. — shape: {PreferredChannelPipeline?: any, ProgramNumber?: any, ServiceDescriptor?: any, VideoSettings?: any}
  program_name: string # Placeholder documentation for __string
  request_id: string # Placeholder documentation for __string
]: any -> record<MultiplexProgram: record<ChannelId: record, MultiplexProgramSettings: record<PreferredChannelPipeline: record, ProgramNumber: record, ServiceDescriptor: record, VideoSettings: record>, PacketIdentifiersMap: record<AudioPids: record, DvbSubPids: record, DvbTeletextPid: record, EtvPlatformPid: record, EtvSignalPid: record, KlvDataPids: record, PcrPid: record, PmtPid: record, PrivateMetadataPid: record, Scte27Pids: record, Scte35Pid: record, TimedMetadataPid: record, VideoPid: record>, PipelineDetails: record, ProgramName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($multiplex_id | is-empty) { error make --unspanned { msg: "path parameter 'multiplexId' must be non-empty" } }
  let full_url = (build-url $base ({multiplex_id: (encode-path-segment $multiplex_id)} | format pattern "/prod/multiplexes/{multiplex_id}/programs"))
  let req_body = {"multiplexProgramSettings": $multiplex_program_settings, "programName": $program_name, "requestId": $request_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List the programs that currently exist for a specific multiplex.
#
# GET /prod/multiplexes/{multiplexId}/programs
# operationId: ListMultiplexPrograms
export def "prod-multiplexes-programs list-multiplex" [
  multiplex_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of items to return.
  --next-token: string # The token to retrieve the next page of results.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<MultiplexPrograms: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($multiplex_id | is-empty) { error make --unspanned { msg: "path parameter 'multiplexId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({multiplex_id: (encode-path-segment $multiplex_id)} | format pattern "/prod/multiplexes/{multiplex_id}/programs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Create a partner input
#
# POST /prod/inputs/{inputId}/partners
# operationId: CreatePartnerInput
export def "prod-inputs-partners create" [
  input_id: string
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
  --request-id: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
]: any -> record<Input: record<Arn: record, AttachedChannels: record, Destinations: record, Id: record, InputClass: record, InputDevices: record, InputPartnerIds: record, InputSourceType: record, MediaConnectFlows: record, Name: record, RoleArn: record, SecurityGroups: record, Sources: record, State: record, Tags: record, Type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($input_id | is-empty) { error make --unspanned { msg: "path parameter 'inputId' must be non-empty" } }
  let full_url = (build-url $base ({input_id: (encode-path-segment $input_id)} | format pattern "/prod/inputs/{input_id}/partners"))
  let req_body = {"requestId": $request_id, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create tags for a resource
#
# POST /prod/tags/{resource-arn}
# operationId: CreateTags
export def "prod-tags create" [
  resource_arn: string
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
  --tags: record # Placeholder documentation for Tags
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/prod/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Produces list of tags that have been created for a resource
#
# GET /prod/tags/{resource-arn}
# operationId: ListTagsForResource
export def "prod-tags list" [
  resource_arn: string
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
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/prod/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Starts deletion of channel. The associated outputs are also deleted.
#
# DELETE /prod/channels/{channelId}
# operationId: DeleteChannel
export def "prod-channels delete" [
  channel_id: string
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
]: nothing -> record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record<AvailBlankingImage: record, State: record>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: record, NetworkEndBlackoutImage: record, NetworkId: record, State: record>, CaptionDescriptions: record, FeatureActivations: record<InputPrepareScheduleActions: record>, GlobalConfiguration: record<InitialAudioGain: record, InputEndAction: record, InputLossBehavior: record, OutputLockingMode: record, OutputTimingSource: record, SupportLowFramerateInputs: record>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: record, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: record, NielsenPcmToId3Tagging: record>, OutputGroups: record, TimecodeConfig: record<Source: record, SyncThreshold: record>, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/prod/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets details about a channel
#
# GET /prod/channels/{channelId}
# operationId: DescribeChannel
export def "prod-channels get" [
  channel_id: string
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
]: nothing -> record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record<AvailBlankingImage: record, State: record>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: record, NetworkEndBlackoutImage: record, NetworkId: record, State: record>, CaptionDescriptions: record, FeatureActivations: record<InputPrepareScheduleActions: record>, GlobalConfiguration: record<InitialAudioGain: record, InputEndAction: record, InputLossBehavior: record, OutputLockingMode: record, OutputTimingSource: record, SupportLowFramerateInputs: record>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: record, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: record, NielsenPcmToId3Tagging: record>, OutputGroups: record, TimecodeConfig: record<Source: record, SyncThreshold: record>, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/prod/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a channel.
#
# PUT /prod/channels/{channelId}
# operationId: UpdateChannel
# --cdiInputSpecification shape: {Resolution?: any}
# --destinations item shape: {Id?: any, MediaPackageSettings?: any, MultiplexSettings?: any, Settings?: any}
# --encoderSettings shape: {AudioDescriptions?: any, AvailBlanking?: any, AvailConfiguration?: any, BlackoutSlate?: any, CaptionDescriptions?: any, FeatureActivations?: any, GlobalConfiguration?: any, MotionGraphicsConfiguration?: any, NielsenConfiguration?: any, OutputGroups?: any, TimecodeConfig?: any, VideoDescriptions?: any}
# --inputAttachments item shape: {AutomaticInputFailoverSettings?: any, InputAttachmentName?: any, InputId?: any, InputSettings?: any}
# --inputSpecification shape: {Codec?: any, MaximumBitrate?: any, Resolution?: any}
# --maintenance shape: {MaintenanceDay?: any, MaintenanceScheduledDate?: any, MaintenanceStartTime?: any}
export def "prod-channels update" [
  channel_id: string
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
  --cdi-input-specification: record # Placeholder documentation for CdiInputSpecification — shape: {Resolution?: any}
  --destinations: list # Placeholder documentation for __listOfOutputDestination — item shape: {Id?: any, MediaPackageSettings?: any, MultiplexSettings?: any, Settings?: any}
  --encoder-settings: record # Encoder Settings — shape: {AudioDescriptions?: any, AvailBlanking?: any, AvailConfiguration?: any, BlackoutSlate?: any, CaptionDescriptions?: any, FeatureActivations?: any, GlobalConfiguration?: any, MotionGraphicsConfiguration?: any, NielsenConfiguration?: any, OutputGroups?: any, TimecodeConfig?: any, VideoDescriptions?: any}
  --input-attachments: list # Placeholder documentation for __listOfInputAttachment — item shape: {AutomaticInputFailoverSettings?: any, InputAttachmentName?: any, InputId?: any, InputSettings?: any}
  --input-specification: record # Placeholder documentation for InputSpecification — shape: {Codec?: any, MaximumBitrate?: any, Resolution?: any}
  --log-level: string@log-level-completer # The log level the user wants for their channel.
  --maintenance: record # Placeholder documentation for MaintenanceUpdateSettings — shape: {MaintenanceDay?: any, MaintenanceScheduledDate?: any, MaintenanceStartTime?: any}
  --name: string # Placeholder documentation for __string
  --role-arn: string # Placeholder documentation for __string
]: any -> record<Channel: record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: record, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: record, TimecodeConfig: record, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/prod/channels/{channel_id}"))
  let req_body = {"cdiInputSpecification": $cdi_input_specification, "destinations": $destinations, "encoderSettings": $encoder_settings, "inputAttachments": $input_attachments, "inputSpecification": $input_specification, "logLevel": $log_level, "maintenance": $maintenance, "name": $name, "roleArn": $role_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the input end point
#
# DELETE /prod/inputs/{inputId}
# operationId: DeleteInput
export def "prod-inputs delete" [
  input_id: string
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
  if ($input_id | is-empty) { error make --unspanned { msg: "path parameter 'inputId' must be non-empty" } }
  let full_url = (build-url $base ({input_id: (encode-path-segment $input_id)} | format pattern "/prod/inputs/{input_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Produces details about an input
#
# GET /prod/inputs/{inputId}
# operationId: DescribeInput
export def "prod-inputs get" [
  input_id: string
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
]: nothing -> record<Arn: record, AttachedChannels: record, Destinations: record, Id: record, InputClass: record, InputDevices: record, InputPartnerIds: record, InputSourceType: record, MediaConnectFlows: record, Name: record, RoleArn: record, SecurityGroups: record, Sources: record, State: record, Tags: record, Type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($input_id | is-empty) { error make --unspanned { msg: "path parameter 'inputId' must be non-empty" } }
  let full_url = (build-url $base ({input_id: (encode-path-segment $input_id)} | format pattern "/prod/inputs/{input_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an input.
#
# PUT /prod/inputs/{inputId}
# operationId: UpdateInput
# --destinations item shape: {StreamName?: any}
# --inputDevices item shape: {Id?: any}
# --mediaConnectFlows item shape: {FlowArn?: any}
# --sources item shape: {PasswordParam?: any, Url?: any, Username?: any}
export def "prod-inputs update" [
  input_id: string
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
  --destinations: list # Placeholder documentation for __listOfInputDestinationRequest — item shape: {StreamName?: any}
  --input-devices: list # Placeholder documentation for __listOfInputDeviceRequest — item shape: {Id?: any}
  --input-security-groups: list<string> # Placeholder documentation for __listOf__string
  --media-connect-flows: list # Placeholder documentation for __listOfMediaConnectFlowRequest — item shape: {FlowArn?: any}
  --name: string # Placeholder documentation for __string
  --role-arn: string # Placeholder documentation for __string
  --sources: list # Placeholder documentation for __listOfInputSourceRequest — item shape: {PasswordParam?: any, Url?: any, Username?: any}
]: any -> record<Input: record<Arn: record, AttachedChannels: record, Destinations: record, Id: record, InputClass: record, InputDevices: record, InputPartnerIds: record, InputSourceType: record, MediaConnectFlows: record, Name: record, RoleArn: record, SecurityGroups: record, Sources: record, State: record, Tags: record, Type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($input_id | is-empty) { error make --unspanned { msg: "path parameter 'inputId' must be non-empty" } }
  let full_url = (build-url $base ({input_id: (encode-path-segment $input_id)} | format pattern "/prod/inputs/{input_id}"))
  let req_body = {"destinations": $destinations, "inputDevices": $input_devices, "inputSecurityGroups": $input_security_groups, "mediaConnectFlows": $media_connect_flows, "name": $name, "roleArn": $role_arn, "sources": $sources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an Input Security Group
#
# DELETE /prod/inputSecurityGroups/{inputSecurityGroupId}
# operationId: DeleteInputSecurityGroup
export def "prod-input-security-groups delete" [
  input_security_group_id: string
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
  if ($input_security_group_id | is-empty) { error make --unspanned { msg: "path parameter 'inputSecurityGroupId' must be non-empty" } }
  let full_url = (build-url $base ({input_security_group_id: (encode-path-segment $input_security_group_id)} | format pattern "/prod/inputSecurityGroups/{input_security_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Produces a summary of an Input Security Group
#
# GET /prod/inputSecurityGroups/{inputSecurityGroupId}
# operationId: DescribeInputSecurityGroup
export def "prod-input-security-groups get" [
  input_security_group_id: string
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
]: nothing -> record<Arn: record, Id: record, Inputs: record, State: record, Tags: record, WhitelistRules: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($input_security_group_id | is-empty) { error make --unspanned { msg: "path parameter 'inputSecurityGroupId' must be non-empty" } }
  let full_url = (build-url $base ({input_security_group_id: (encode-path-segment $input_security_group_id)} | format pattern "/prod/inputSecurityGroups/{input_security_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an Input Security Group's Whilelists.
#
# PUT /prod/inputSecurityGroups/{inputSecurityGroupId}
# operationId: UpdateInputSecurityGroup
# --whitelistRules item shape: {Cidr?: any}
export def "prod-input-security-groups update" [
  input_security_group_id: string
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
  --tags: record # Placeholder documentation for Tags
  --whitelist-rules: list # Placeholder documentation for __listOfInputWhitelistRuleCidr — item shape: {Cidr?: any}
]: any -> record<SecurityGroup: record<Arn: record, Id: record, Inputs: record, State: record, Tags: record, WhitelistRules: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($input_security_group_id | is-empty) { error make --unspanned { msg: "path parameter 'inputSecurityGroupId' must be non-empty" } }
  let full_url = (build-url $base ({input_security_group_id: (encode-path-segment $input_security_group_id)} | format pattern "/prod/inputSecurityGroups/{input_security_group_id}"))
  let req_body = {"tags": $tags, "whitelistRules": $whitelist_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a multiplex. The multiplex must be idle.
#
# DELETE /prod/multiplexes/{multiplexId}
# operationId: DeleteMultiplex
export def "prod-multiplexes delete-multiplex" [
  multiplex_id: string
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
]: nothing -> record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($multiplex_id | is-empty) { error make --unspanned { msg: "path parameter 'multiplexId' must be non-empty" } }
  let full_url = (build-url $base ({multiplex_id: (encode-path-segment $multiplex_id)} | format pattern "/prod/multiplexes/{multiplex_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets details about a multiplex.
#
# GET /prod/multiplexes/{multiplexId}
# operationId: DescribeMultiplex
export def "prod-multiplexes get-multiplex" [
  multiplex_id: string
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
]: nothing -> record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($multiplex_id | is-empty) { error make --unspanned { msg: "path parameter 'multiplexId' must be non-empty" } }
  let full_url = (build-url $base ({multiplex_id: (encode-path-segment $multiplex_id)} | format pattern "/prod/multiplexes/{multiplex_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a multiplex.
#
# PUT /prod/multiplexes/{multiplexId}
# operationId: UpdateMultiplex
# --multiplexSettings shape: {MaximumVideoBufferDelayMilliseconds?: any, TransportStreamBitrate?: any, TransportStreamId?: any, TransportStreamReservedBitrate?: any}
export def "prod-multiplexes update-multiplex" [
  multiplex_id: string
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
  --multiplex-settings: record # Contains configuration for a Multiplex event — shape: {MaximumVideoBufferDelayMilliseconds?: any, TransportStreamBitrate?: any, TransportStreamId?: any, TransportStreamReservedBitrate?: any}
  --name: string # Placeholder documentation for __string
]: any -> record<Multiplex: record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($multiplex_id | is-empty) { error make --unspanned { msg: "path parameter 'multiplexId' must be non-empty" } }
  let full_url = (build-url $base ({multiplex_id: (encode-path-segment $multiplex_id)} | format pattern "/prod/multiplexes/{multiplex_id}"))
  let req_body = {"multiplexSettings": $multiplex_settings, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a program from a multiplex.
#
# DELETE /prod/multiplexes/{multiplexId}/programs/{programName}
# operationId: DeleteMultiplexProgram
export def "prod-multiplexes-programs delete-multiplex" [
  multiplex_id: string
  program_name: string
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
]: nothing -> record<ChannelId: record, MultiplexProgramSettings: record<PreferredChannelPipeline: record, ProgramNumber: record, ServiceDescriptor: record<ProviderName: record, ServiceName: record>, VideoSettings: record<ConstantBitrate: record, StatmuxSettings: record>>, PacketIdentifiersMap: record<AudioPids: record, DvbSubPids: record, DvbTeletextPid: record, EtvPlatformPid: record, EtvSignalPid: record, KlvDataPids: record, PcrPid: record, PmtPid: record, PrivateMetadataPid: record, Scte27Pids: record, Scte35Pid: record, TimedMetadataPid: record, VideoPid: record>, PipelineDetails: record, ProgramName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($multiplex_id | is-empty) { error make --unspanned { msg: "path parameter 'multiplexId' must be non-empty" } }
  if ($program_name | is-empty) { error make --unspanned { msg: "path parameter 'programName' must be non-empty" } }
  let full_url = (build-url $base ({multiplex_id: (encode-path-segment $multiplex_id), program_name: (encode-path-segment $program_name)} | format pattern "/prod/multiplexes/{multiplex_id}/programs/{program_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the details for a program in a multiplex.
#
# GET /prod/multiplexes/{multiplexId}/programs/{programName}
# operationId: DescribeMultiplexProgram
export def "prod-multiplexes-programs get-multiplex" [
  multiplex_id: string
  program_name: string
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
]: nothing -> record<ChannelId: record, MultiplexProgramSettings: record<PreferredChannelPipeline: record, ProgramNumber: record, ServiceDescriptor: record<ProviderName: record, ServiceName: record>, VideoSettings: record<ConstantBitrate: record, StatmuxSettings: record>>, PacketIdentifiersMap: record<AudioPids: record, DvbSubPids: record, DvbTeletextPid: record, EtvPlatformPid: record, EtvSignalPid: record, KlvDataPids: record, PcrPid: record, PmtPid: record, PrivateMetadataPid: record, Scte27Pids: record, Scte35Pid: record, TimedMetadataPid: record, VideoPid: record>, PipelineDetails: record, ProgramName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($multiplex_id | is-empty) { error make --unspanned { msg: "path parameter 'multiplexId' must be non-empty" } }
  if ($program_name | is-empty) { error make --unspanned { msg: "path parameter 'programName' must be non-empty" } }
  let full_url = (build-url $base ({multiplex_id: (encode-path-segment $multiplex_id), program_name: (encode-path-segment $program_name)} | format pattern "/prod/multiplexes/{multiplex_id}/programs/{program_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a program in a multiplex.
#
# PUT /prod/multiplexes/{multiplexId}/programs/{programName}
# operationId: UpdateMultiplexProgram
# --multiplexProgramSettings shape: {PreferredChannelPipeline?: any, ProgramNumber?: any, ServiceDescriptor?: any, VideoSettings?: any}
export def "prod-multiplexes-programs update-multiplex" [
  multiplex_id: string
  program_name: string
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
  --multiplex-program-settings: record # Multiplex Program settings configuration. — shape: {PreferredChannelPipeline?: any, ProgramNumber?: any, ServiceDescriptor?: any, VideoSettings?: any}
]: any -> record<MultiplexProgram: record<ChannelId: record, MultiplexProgramSettings: record<PreferredChannelPipeline: record, ProgramNumber: record, ServiceDescriptor: record, VideoSettings: record>, PacketIdentifiersMap: record<AudioPids: record, DvbSubPids: record, DvbTeletextPid: record, EtvPlatformPid: record, EtvSignalPid: record, KlvDataPids: record, PcrPid: record, PmtPid: record, PrivateMetadataPid: record, Scte27Pids: record, Scte35Pid: record, TimedMetadataPid: record, VideoPid: record>, PipelineDetails: record, ProgramName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($multiplex_id | is-empty) { error make --unspanned { msg: "path parameter 'multiplexId' must be non-empty" } }
  if ($program_name | is-empty) { error make --unspanned { msg: "path parameter 'programName' must be non-empty" } }
  let full_url = (build-url $base ({multiplex_id: (encode-path-segment $multiplex_id), program_name: (encode-path-segment $program_name)} | format pattern "/prod/multiplexes/{multiplex_id}/programs/{program_name}"))
  let req_body = {"multiplexProgramSettings": $multiplex_program_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an expired reservation.
#
# DELETE /prod/reservations/{reservationId}
# operationId: DeleteReservation
export def "prod-reservations delete" [
  reservation_id: string
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
]: nothing -> record<Arn: record, Count: record, CurrencyCode: record, Duration: record, DurationUnits: record, End: record, FixedPrice: record, Name: record, OfferingDescription: record, OfferingId: record, OfferingType: record, Region: record, RenewalSettings: record<AutomaticRenewal: record, RenewalCount: record>, ReservationId: record, ResourceSpecification: record<ChannelClass: record, Codec: record, MaximumBitrate: record, MaximumFramerate: record, Resolution: record, ResourceType: record, SpecialFeature: record, VideoQuality: record>, Start: record, State: record, Tags: record, UsagePrice: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationId' must be non-empty" } }
  let full_url = (build-url $base ({reservation_id: (encode-path-segment $reservation_id)} | format pattern "/prod/reservations/{reservation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get details for a reservation.
#
# GET /prod/reservations/{reservationId}
# operationId: DescribeReservation
export def "prod-reservations get" [
  reservation_id: string
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
]: nothing -> record<Arn: record, Count: record, CurrencyCode: record, Duration: record, DurationUnits: record, End: record, FixedPrice: record, Name: record, OfferingDescription: record, OfferingId: record, OfferingType: record, Region: record, RenewalSettings: record<AutomaticRenewal: record, RenewalCount: record>, ReservationId: record, ResourceSpecification: record<ChannelClass: record, Codec: record, MaximumBitrate: record, MaximumFramerate: record, Resolution: record, ResourceType: record, SpecialFeature: record, VideoQuality: record>, Start: record, State: record, Tags: record, UsagePrice: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationId' must be non-empty" } }
  let full_url = (build-url $base ({reservation_id: (encode-path-segment $reservation_id)} | format pattern "/prod/reservations/{reservation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update reservation.
#
# PUT /prod/reservations/{reservationId}
# operationId: UpdateReservation
# --renewalSettings shape: {AutomaticRenewal?: any, RenewalCount?: any}
export def "prod-reservations update" [
  reservation_id: string
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
  --name: string # Placeholder documentation for __string
  --renewal-settings: record # The Renewal settings for Reservations — shape: {AutomaticRenewal?: any, RenewalCount?: any}
]: any -> record<Reservation: record<Arn: record, Count: record, CurrencyCode: record, Duration: record, DurationUnits: record, End: record, FixedPrice: record, Name: record, OfferingDescription: record, OfferingId: record, OfferingType: record, Region: record, RenewalSettings: record<AutomaticRenewal: record, RenewalCount: record>, ReservationId: record, ResourceSpecification: record<ChannelClass: record, Codec: record, MaximumBitrate: record, MaximumFramerate: record, Resolution: record, ResourceType: record, SpecialFeature: record, VideoQuality: record>, Start: record, State: record, Tags: record, UsagePrice: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'reservationId' must be non-empty" } }
  let full_url = (build-url $base ({reservation_id: (encode-path-segment $reservation_id)} | format pattern "/prod/reservations/{reservation_id}"))
  let req_body = {"name": $name, "renewalSettings": $renewal_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes tags for a resource
#
# DELETE /prod/tags/{resource-arn}
# operationId: DeleteTags
export def "prod-tags delete" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # An array of tag keys to delete
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resource-arn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/prod/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}

# Gets the details for the input device
#
# GET /prod/inputDevices/{inputDeviceId}
# operationId: DescribeInputDevice
export def "prod-input-devices get" [
  input_device_id: string
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
]: nothing -> record<Arn: record, ConnectionState: record, DeviceSettingsSyncState: record, DeviceUpdateStatus: record, HdDeviceSettings: record<ActiveInput: record, ConfiguredInput: record, DeviceState: record, Framerate: record, Height: record, MaxBitrate: record, ScanType: record, Width: record, LatencyMs: record>, Id: record, MacAddress: record, Name: record, NetworkSettings: record<DnsAddresses: record, Gateway: record, IpAddress: record, IpScheme: record, SubnetMask: record>, SerialNumber: record, Type: record, UhdDeviceSettings: record<ActiveInput: record, ConfiguredInput: record, DeviceState: record, Framerate: record, Height: record, MaxBitrate: record, ScanType: record, Width: record, LatencyMs: record>, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($input_device_id | is-empty) { error make --unspanned { msg: "path parameter 'inputDeviceId' must be non-empty" } }
  let full_url = (build-url $base ({input_device_id: (encode-path-segment $input_device_id)} | format pattern "/prod/inputDevices/{input_device_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the parameters for the input device.
#
# PUT /prod/inputDevices/{inputDeviceId}
# operationId: UpdateInputDevice
# --hdDeviceSettings shape: {ConfiguredInput?: any, MaxBitrate?: any, LatencyMs?: any}
# --uhdDeviceSettings shape: {ConfiguredInput?: any, MaxBitrate?: any, LatencyMs?: any}
export def "prod-input-devices update" [
  input_device_id: string
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
  --hd-device-settings: record # Configurable settings for the input device. — shape: {ConfiguredInput?: any, MaxBitrate?: any, LatencyMs?: any}
  --name: string # Placeholder documentation for __string
  --uhd-device-settings: record # Configurable settings for the input device. — shape: {ConfiguredInput?: any, MaxBitrate?: any, LatencyMs?: any}
]: any -> record<Arn: record, ConnectionState: record, DeviceSettingsSyncState: record, DeviceUpdateStatus: record, HdDeviceSettings: record<ActiveInput: record, ConfiguredInput: record, DeviceState: record, Framerate: record, Height: record, MaxBitrate: record, ScanType: record, Width: record, LatencyMs: record>, Id: record, MacAddress: record, Name: record, NetworkSettings: record<DnsAddresses: record, Gateway: record, IpAddress: record, IpScheme: record, SubnetMask: record>, SerialNumber: record, Type: record, UhdDeviceSettings: record<ActiveInput: record, ConfiguredInput: record, DeviceState: record, Framerate: record, Height: record, MaxBitrate: record, ScanType: record, Width: record, LatencyMs: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($input_device_id | is-empty) { error make --unspanned { msg: "path parameter 'inputDeviceId' must be non-empty" } }
  let full_url = (build-url $base ({input_device_id: (encode-path-segment $input_device_id)} | format pattern "/prod/inputDevices/{input_device_id}"))
  let req_body = {"hdDeviceSettings": $hd_device_settings, "name": $name, "uhdDeviceSettings": $uhd_device_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the latest thumbnail data for the input device.
#
# GET /prod/inputDevices/{inputDeviceId}/thumbnailData
# operationId: DescribeInputDeviceThumbnail
export def "prod-input-devices-thumbnail-data get" [
  input_device_id: string
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
  --hdr-accept: string@accept-completer # The HTTP Accept header. Indicates the requested type for the thumbnail.
]: nothing -> record<Body: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($input_device_id | is-empty) { error make --unspanned { msg: "path parameter 'inputDeviceId' must be non-empty" } }
  let full_url = (build-url $base ({input_device_id: (encode-path-segment $input_device_id)} | format pattern "/prod/inputDevices/{input_device_id}/thumbnailData"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get details for an offering.
#
# GET /prod/offerings/{offeringId}
# operationId: DescribeOffering
export def "prod-offerings get" [
  offering_id: string
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
]: nothing -> record<Arn: record, CurrencyCode: record, Duration: record, DurationUnits: record, FixedPrice: record, OfferingDescription: record, OfferingId: record, OfferingType: record, Region: record, ResourceSpecification: record<ChannelClass: record, Codec: record, MaximumBitrate: record, MaximumFramerate: record, Resolution: record, ResourceType: record, SpecialFeature: record, VideoQuality: record>, UsagePrice: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($offering_id | is-empty) { error make --unspanned { msg: "path parameter 'offeringId' must be non-empty" } }
  let full_url = (build-url $base ({offering_id: (encode-path-segment $offering_id)} | format pattern "/prod/offerings/{offering_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List input devices that are currently being transferred. List input devices that you are transferring from your AWS account or input devices that another AWS account is transferring to you.
#
# GET /prod/inputDeviceTransfers
# operationId: ListInputDeviceTransfers
export def "prod-input-device-transfers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --transfer-type: string
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<InputDeviceTransfers: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "transferType" $transfer_type "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/inputDeviceTransfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "transferType": $transfer_type, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# List input devices
#
# GET /prod/inputDevices
# operationId: ListInputDevices
export def "prod-input-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int
  --next-token: string
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<InputDevices: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/inputDevices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# List offerings available for purchase.
#
# GET /prod/offerings
# operationId: ListOfferings
export def "prod-offerings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-class: string # Filter by channel class, 'STANDARD' or 'SINGLE_PIPELINE'
  --channel-configuration: string # Filter to offerings that match the configuration of an existing channel, e.g. '2345678' (a channel ID)
  --codec: string # Filter by codec, 'AVC', 'HEVC', 'MPEG2', 'AUDIO', or 'LINK'
  --duration: string # Filter by offering duration, e.g. '12'
  --max-results: int
  --maximum-bitrate: string # Filter by bitrate, 'MAX_10_MBPS', 'MAX_20_MBPS', or 'MAX_50_MBPS'
  --maximum-framerate: string # Filter by framerate, 'MAX_30_FPS' or 'MAX_60_FPS'
  --next-token: string
  --resolution: string # Filter by resolution, 'SD', 'HD', 'FHD', or 'UHD'
  --resource-type: string # Filter by resource type, 'INPUT', 'OUTPUT', 'MULTIPLEX', or 'CHANNEL'
  --special-feature: string # Filter by special feature, 'ADVANCED_AUDIO' or 'AUDIO_NORMALIZATION'
  --video-quality: string # Filter by video quality, 'STANDARD', 'ENHANCED', or 'PREMIUM'
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, Offerings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channelClass" $channel_class "scalar") (serialize-qp "channelConfiguration" $channel_configuration "scalar") (serialize-qp "codec" $codec "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "maximumBitrate" $maximum_bitrate "scalar") (serialize-qp "maximumFramerate" $maximum_framerate "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "resourceType" $resource_type "scalar") (serialize-qp "specialFeature" $special_feature "scalar") (serialize-qp "videoQuality" $video_quality "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/offerings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"channelClass": $channel_class, "channelConfiguration": $channel_configuration, "codec": $codec, "duration": $duration, "maxResults": $max_results, "maximumBitrate": $maximum_bitrate, "maximumFramerate": $maximum_framerate, "nextToken": $next_token, "resolution": $resolution, "resourceType": $resource_type, "specialFeature": $special_feature, "videoQuality": $video_quality, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# List purchased reservations.
#
# GET /prod/reservations
# operationId: ListReservations
export def "prod-reservations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-class: string # Filter by channel class, 'STANDARD' or 'SINGLE_PIPELINE'
  --codec: string # Filter by codec, 'AVC', 'HEVC', 'MPEG2', 'AUDIO', or 'LINK'
  --max-results: int
  --maximum-bitrate: string # Filter by bitrate, 'MAX_10_MBPS', 'MAX_20_MBPS', or 'MAX_50_MBPS'
  --maximum-framerate: string # Filter by framerate, 'MAX_30_FPS' or 'MAX_60_FPS'
  --next-token: string
  --resolution: string # Filter by resolution, 'SD', 'HD', 'FHD', or 'UHD'
  --resource-type: string # Filter by resource type, 'INPUT', 'OUTPUT', 'MULTIPLEX', or 'CHANNEL'
  --special-feature: string # Filter by special feature, 'ADVANCED_AUDIO' or 'AUDIO_NORMALIZATION'
  --video-quality: string # Filter by video quality, 'STANDARD', 'ENHANCED', or 'PREMIUM'
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token-2: string # Pagination token (disambiguated-2)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, Reservations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channelClass" $channel_class "scalar") (serialize-qp "codec" $codec "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "maximumBitrate" $maximum_bitrate "scalar") (serialize-qp "maximumFramerate" $maximum_framerate "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "resourceType" $resource_type "scalar") (serialize-qp "specialFeature" $special_feature "scalar") (serialize-qp "videoQuality" $video_quality "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/reservations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"channelClass": $channel_class, "codec": $codec, "maxResults": $max_results, "maximumBitrate": $maximum_bitrate, "maximumFramerate": $maximum_framerate, "nextToken": $next_token, "resolution": $resolution, "resourceType": $resource_type, "specialFeature": $special_feature, "videoQuality": $video_quality, "MaxResults": $max_results_2, "NextToken": $next_token_2} | compact), body: null}
}

# Purchase an offering and create a reservation.
#
# POST /prod/offerings/{offeringId}/purchase
# operationId: PurchaseOffering
# --renewalSettings shape: {AutomaticRenewal?: any, RenewalCount?: any}
export def "prod-offerings-purchase create" [
  offering_id: string
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
  count: int # Placeholder documentation for __integerMin1
  --name: string # Placeholder documentation for __string
  --renewal-settings: record # The Renewal settings for Reservations — shape: {AutomaticRenewal?: any, RenewalCount?: any}
  --request-id: string # Placeholder documentation for __string
  --start: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
]: any -> record<Reservation: record<Arn: record, Count: record, CurrencyCode: record, Duration: record, DurationUnits: record, End: record, FixedPrice: record, Name: record, OfferingDescription: record, OfferingId: record, OfferingType: record, Region: record, RenewalSettings: record<AutomaticRenewal: record, RenewalCount: record>, ReservationId: record, ResourceSpecification: record<ChannelClass: record, Codec: record, MaximumBitrate: record, MaximumFramerate: record, Resolution: record, ResourceType: record, SpecialFeature: record, VideoQuality: record>, Start: record, State: record, Tags: record, UsagePrice: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($offering_id | is-empty) { error make --unspanned { msg: "path parameter 'offeringId' must be non-empty" } }
  let full_url = (build-url $base ({offering_id: (encode-path-segment $offering_id)} | format pattern "/prod/offerings/{offering_id}/purchase"))
  let req_body = {"count": $count, "name": $name, "renewalSettings": $renewal_settings, "requestId": $request_id, "start": $start, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Send a reboot command to the specified input device. The device will begin rebooting within a few seconds of sending the command. When the reboot is complete, the device’s connection status will change to connected.
#
# POST /prod/inputDevices/{inputDeviceId}/reboot
# operationId: RebootInputDevice
export def "prod-input-devices-reboot create" [
  input_device_id: string
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
  --force: string@force-completer # Whether or not to force reboot the input device.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($input_device_id | is-empty) { error make --unspanned { msg: "path parameter 'inputDeviceId' must be non-empty" } }
  let full_url = (build-url $base ({input_device_id: (encode-path-segment $input_device_id)} | format pattern "/prod/inputDevices/{input_device_id}/reboot"))
  let req_body = {"force": $force} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reject the transfer of the specified input device to your AWS account.
#
# POST /prod/inputDevices/{inputDeviceId}/reject
# operationId: RejectInputDeviceTransfer
export def "prod-input-devices-reject reject-transfer" [
  input_device_id: string
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
  if ($input_device_id | is-empty) { error make --unspanned { msg: "path parameter 'inputDeviceId' must be non-empty" } }
  let full_url = (build-url $base ({input_device_id: (encode-path-segment $input_device_id)} | format pattern "/prod/inputDevices/{input_device_id}/reject"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Starts an existing channel
#
# POST /prod/channels/{channelId}/start
# operationId: StartChannel
export def "prod-channels-start start" [
  channel_id: string
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
]: nothing -> record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record<AvailBlankingImage: record, State: record>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: record, NetworkEndBlackoutImage: record, NetworkId: record, State: record>, CaptionDescriptions: record, FeatureActivations: record<InputPrepareScheduleActions: record>, GlobalConfiguration: record<InitialAudioGain: record, InputEndAction: record, InputLossBehavior: record, OutputLockingMode: record, OutputTimingSource: record, SupportLowFramerateInputs: record>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: record, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: record, NielsenPcmToId3Tagging: record>, OutputGroups: record, TimecodeConfig: record<Source: record, SyncThreshold: record>, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/prod/channels/{channel_id}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Start a maintenance window for the specified input device. Starting a maintenance window will give the device up to two hours to install software. If the device was streaming prior to the maintenance, it will resume streaming when the software is fully installed. Devices automatically install updates while they are powered on and their MediaLive channels are stopped. A maintenance window allows you to update a device without having to stop MediaLive channels that use the device. The device must remain powered on and connected to the internet for the duration of the maintenance.
#
# POST /prod/inputDevices/{inputDeviceId}/startInputDeviceMaintenanceWindow
# operationId: StartInputDeviceMaintenanceWindow
export def "prod-input-devices-start-input-device-maintenance-window start" [
  input_device_id: string
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
  if ($input_device_id | is-empty) { error make --unspanned { msg: "path parameter 'inputDeviceId' must be non-empty" } }
  let full_url = (build-url $base ({input_device_id: (encode-path-segment $input_device_id)} | format pattern "/prod/inputDevices/{input_device_id}/startInputDeviceMaintenanceWindow"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
#
# POST /prod/multiplexes/{multiplexId}/start
# operationId: StartMultiplex
export def "prod-multiplexes-start start-multiplex" [
  multiplex_id: string
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
]: nothing -> record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($multiplex_id | is-empty) { error make --unspanned { msg: "path parameter 'multiplexId' must be non-empty" } }
  let full_url = (build-url $base ({multiplex_id: (encode-path-segment $multiplex_id)} | format pattern "/prod/multiplexes/{multiplex_id}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stops a running channel
#
# POST /prod/channels/{channelId}/stop
# operationId: StopChannel
export def "prod-channels-stop stop" [
  channel_id: string
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
]: nothing -> record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record<AvailBlankingImage: record, State: record>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: record, NetworkEndBlackoutImage: record, NetworkId: record, State: record>, CaptionDescriptions: record, FeatureActivations: record<InputPrepareScheduleActions: record>, GlobalConfiguration: record<InitialAudioGain: record, InputEndAction: record, InputLossBehavior: record, OutputLockingMode: record, OutputTimingSource: record, SupportLowFramerateInputs: record>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: record, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: record, NielsenPcmToId3Tagging: record>, OutputGroups: record, TimecodeConfig: record<Source: record, SyncThreshold: record>, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/prod/channels/{channel_id}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stops a running multiplex. If the multiplex isn't running, this action has no effect.
#
# POST /prod/multiplexes/{multiplexId}/stop
# operationId: StopMultiplex
export def "prod-multiplexes-stop stop-multiplex" [
  multiplex_id: string
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
]: nothing -> record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($multiplex_id | is-empty) { error make --unspanned { msg: "path parameter 'multiplexId' must be non-empty" } }
  let full_url = (build-url $base ({multiplex_id: (encode-path-segment $multiplex_id)} | format pattern "/prod/multiplexes/{multiplex_id}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Start an input device transfer to another AWS account. After you make the request, the other account must accept or reject the transfer.
#
# POST /prod/inputDevices/{inputDeviceId}/transfer
# operationId: TransferInputDevice
export def "prod-input-devices-transfer create" [
  input_device_id: string
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
  --target-customer-id: string # Placeholder documentation for __string
  --target-region: string # Placeholder documentation for __string
  --transfer-message: string # Placeholder documentation for __string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($input_device_id | is-empty) { error make --unspanned { msg: "path parameter 'inputDeviceId' must be non-empty" } }
  let full_url = (build-url $base ({input_device_id: (encode-path-segment $input_device_id)} | format pattern "/prod/inputDevices/{input_device_id}/transfer"))
  let req_body = {"targetCustomerId": $target_customer_id, "targetRegion": $target_region, "transferMessage": $transfer_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Changes the class of the channel.
#
# PUT /prod/channels/{channelId}/channelClass
# operationId: UpdateChannelClass
# --destinations item shape: {Id?: any, MediaPackageSettings?: any, MultiplexSettings?: any, Settings?: any}
export def "prod-channels-channel-class update" [
  channel_id: string
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
  channel_class: string@channel-class-completer # A standard channel has two encoding pipelines and a single pipeline channel only has one.
  --destinations: list # Placeholder documentation for __listOfOutputDestination — item shape: {Id?: any, MediaPackageSettings?: any, MultiplexSettings?: any, Settings?: any}
]: any -> record<Channel: record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: record, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: record, TimecodeConfig: record, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/prod/channels/{channel_id}/channelClass"))
  let req_body = {"channelClass": $channel_class, "destinations": $destinations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
