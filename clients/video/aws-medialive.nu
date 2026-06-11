# Auto-generated client for AWS Elemental MediaLive v2017-10-14
# Source: https://api.apis.guru/v2/specs/amazonaws.com/medialive/2017-10-14/openapi.json
# Auth: --token flag or $env.AWS_ELEMENTAL_MEDIALIVE_TOKEN

const BASE_URL = "http://medialive.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_ELEMENTAL_MEDIALIVE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://medialive.us-east-1.amazonaws.com" "http://medialive.us-east-2.amazonaws.com" "http://medialive.us-west-1.amazonaws.com" "http://medialive.us-west-2.amazonaws.com" "http://medialive.us-gov-west-1.amazonaws.com" "http://medialive.us-gov-east-1.amazonaws.com" "http://medialive.ca-central-1.amazonaws.com" "http://medialive.eu-north-1.amazonaws.com" "http://medialive.eu-west-1.amazonaws.com" "http://medialive.eu-west-2.amazonaws.com" "http://medialive.eu-west-3.amazonaws.com" "http://medialive.eu-central-1.amazonaws.com" "http://medialive.eu-south-1.amazonaws.com" "http://medialive.af-south-1.amazonaws.com" "http://medialive.ap-northeast-1.amazonaws.com" "http://medialive.ap-northeast-2.amazonaws.com" "http://medialive.ap-northeast-3.amazonaws.com" "http://medialive.ap-southeast-1.amazonaws.com" "http://medialive.ap-southeast-2.amazonaws.com" "http://medialive.ap-east-1.amazonaws.com" "http://medialive.ap-south-1.amazonaws.com" "http://medialive.sa-east-1.amazonaws.com" "http://medialive.me-south-1.amazonaws.com" "https://medialive.us-east-1.amazonaws.com" "https://medialive.us-east-2.amazonaws.com" "https://medialive.us-west-1.amazonaws.com" "https://medialive.us-west-2.amazonaws.com" "https://medialive.us-gov-west-1.amazonaws.com" "https://medialive.us-gov-east-1.amazonaws.com" "https://medialive.ca-central-1.amazonaws.com" "https://medialive.eu-north-1.amazonaws.com" "https://medialive.eu-west-1.amazonaws.com" "https://medialive.eu-west-2.amazonaws.com" "https://medialive.eu-west-3.amazonaws.com" "https://medialive.eu-central-1.amazonaws.com" "https://medialive.eu-south-1.amazonaws.com" "https://medialive.af-south-1.amazonaws.com" "https://medialive.ap-northeast-1.amazonaws.com" "https://medialive.ap-northeast-2.amazonaws.com" "https://medialive.ap-northeast-3.amazonaws.com" "https://medialive.ap-southeast-1.amazonaws.com" "https://medialive.ap-southeast-2.amazonaws.com" "https://medialive.ap-east-1.amazonaws.com" "https://medialive.ap-south-1.amazonaws.com" "https://medialive.sa-east-1.amazonaws.com" "https://medialive.me-south-1.amazonaws.com" "http://medialive.cn-north-1.amazonaws.com.cn" "http://medialive.cn-northwest-1.amazonaws.com.cn" "https://medialive.cn-north-1.amazonaws.com.cn" "https://medialive.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def channelClass-completer [] { ["SINGLE_PIPELINE" "STANDARD"] }
def logLevel-completer [] { ["DEBUG" "DISABLED" "ERROR" "INFO" "WARNING"] }
def type-completer [] { ["AWS_CDI" "INPUT_DEVICE" "MEDIACONNECT" "MP4_FILE" "RTMP_PULL" "RTMP_PUSH" "RTP_PUSH" "TS_FILE" "UDP_PUSH" "URL_PULL"] }
def accept-completer [] { ["image/jpeg"] }
def force-completer [] { ["NO" "YES"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "prod-input-devices-accept AcceptInputDeviceTransfer" } } | get name | first)
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
export def "prod-input-devices-accept AcceptInputDeviceTransfer" [
  inputDeviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputDevices/($inputDeviceId)/accept")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts delete of resources.
#
# POST /prod/batch/delete
# operationId: BatchDelete
export def "prod-batch-delete BatchDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --channelIds: list # Placeholder documentation for __listOf__string
  --inputIds: list # Placeholder documentation for __listOf__string
  --inputSecurityGroupIds: list # Placeholder documentation for __listOf__string
  --multiplexIds: list # Placeholder documentation for __listOf__string
]: any -> record<Failed: record, Successful: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/batch/delete")
  let body = {channelIds: $channelIds, inputIds: $inputIds, inputSecurityGroupIds: $inputSecurityGroupIds, multiplexIds: $multiplexIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Starts existing resources
#
# POST /prod/batch/start
# operationId: BatchStart
export def "prod-batch-start BatchStart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --channelIds: list # Placeholder documentation for __listOf__string
  --multiplexIds: list # Placeholder documentation for __listOf__string
]: any -> record<Failed: record, Successful: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/batch/start")
  let body = {channelIds: $channelIds, multiplexIds: $multiplexIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stops running resources
#
# POST /prod/batch/stop
# operationId: BatchStop
export def "prod-batch-stop BatchStop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --channelIds: list # Placeholder documentation for __listOf__string
  --multiplexIds: list # Placeholder documentation for __listOf__string
]: any -> record<Failed: record, Successful: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/batch/stop")
  let body = {channelIds: $channelIds, multiplexIds: $multiplexIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a channel schedule
#
# PUT /prod/channels/{channelId}/schedule
# operationId: BatchUpdateSchedule
# --creates shape: {ScheduleActions?: any}
# --deletes shape: {ActionNames?: any}
export def "prod-channels-schedule BatchUpdateSchedule" [
  channelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --creates: record # A list of schedule actions to create (in a request) or that have been created (in a response). — shape: {ScheduleActions?: any}
  --deletes: record # A list of schedule actions to delete. — shape: {ActionNames?: any}
]: any -> record<Creates: record<ScheduleActions: record>, Deletes: record<ScheduleActions: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/channels/($channelId)/schedule")
  let body = {creates: $creates, deletes: $deletes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all schedule actions on a channel.
#
# DELETE /prod/channels/{channelId}/schedule
# operationId: DeleteSchedule
export def "prod-channels-schedule DeleteSchedule" [
  channelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/channels/($channelId)/schedule")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a channel schedule
#
# GET /prod/channels/{channelId}/schedule
# operationId: DescribeSchedule
export def "prod-channels-schedule DescribeSchedule" [
  channelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int
  --nextToken: string
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, ScheduleActions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/prod/channels/($channelId)/schedule" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel an input device transfer that you have requested.
#
# POST /prod/inputDevices/{inputDeviceId}/cancel
# operationId: CancelInputDeviceTransfer
export def "prod-input-devices-cancel CancelInputDeviceTransfer" [
  inputDeviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputDevices/($inputDeviceId)/cancel")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a request to claim an AWS Elemental device that you have purchased from a third-party vendor. After the request succeeds, you will own the device.
#
# POST /prod/claimDevice
# operationId: ClaimDevice
export def "prod-claim-device ClaimDevice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --id: string # Placeholder documentation for __string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/claimDevice")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
export def "prod-channels CreateChannel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --cdiInputSpecification: record # Placeholder documentation for CdiInputSpecification — shape: {Resolution?: any}
  --channelClass: string@channelClass-completer # A standard channel has two encoding pipelines and a single pipeline channel only has one.
  --destinations: list # Placeholder documentation for __listOfOutputDestination — item shape: {Id?: any, MediaPackageSettings?: any, MultiplexSettings?: any, Settings?: any}
  --encoderSettings: record # Encoder Settings — shape: {AudioDescriptions?: any, AvailBlanking?: any, AvailConfiguration?: any, BlackoutSlate?: any, CaptionDescriptions?: any, FeatureActivations?: any, GlobalConfiguration?: any, MotionGraphicsConfiguration?: any, NielsenConfiguration?: any, OutputGroups?: any, TimecodeConfig?: any, VideoDescriptions?: any}
  --inputAttachments: list # Placeholder documentation for __listOfInputAttachment — item shape: {AutomaticInputFailoverSettings?: any, InputAttachmentName?: any, InputId?: any, InputSettings?: any}
  --inputSpecification: record # Placeholder documentation for InputSpecification — shape: {Codec?: any, MaximumBitrate?: any, Resolution?: any}
  --logLevel: string@logLevel-completer # The log level the user wants for their channel.
  --maintenance: record # Placeholder documentation for MaintenanceCreateSettings — shape: {MaintenanceDay?: any, MaintenanceStartTime?: any}
  --name: string # Placeholder documentation for __string
  --requestId: string # Placeholder documentation for __string
  --reserved: string # Placeholder documentation for __string
  --roleArn: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
  --vpc: record # The properties for a private VPC Output When this property is specified, the output egress addresses will be created in a user specified VPC — shape: {PublicAddressAllocationIds?: any, SecurityGroupIds?: any, SubnetIds?: any}
]: any -> record<Channel: record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: record, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: record, TimecodeConfig: record, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/channels")
  let body = {cdiInputSpecification: $cdiInputSpecification, channelClass: $channelClass, destinations: $destinations, encoderSettings: $encoderSettings, inputAttachments: $inputAttachments, inputSpecification: $inputSpecification, logLevel: $logLevel, maintenance: $maintenance, name: $name, requestId: $requestId, reserved: $reserved, roleArn: $roleArn, tags: $tags, vpc: $vpc} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Produces list of channels that have been created
#
# GET /prod/channels
# operationId: ListChannels
export def "prod-channels ListChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int
  --nextToken: string
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Channels: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/channels" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "prod-inputs CreateInput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --destinations: list # Placeholder documentation for __listOfInputDestinationRequest — item shape: {StreamName?: any}
  --inputDevices: list # Placeholder documentation for __listOfInputDeviceSettings — item shape: {Id?: any}
  --inputSecurityGroups: list # Placeholder documentation for __listOf__string
  --mediaConnectFlows: list # Placeholder documentation for __listOfMediaConnectFlowRequest — item shape: {FlowArn?: any}
  --name: string # Placeholder documentation for __string
  --requestId: string # Placeholder documentation for __string
  --roleArn: string # Placeholder documentation for __string
  --sources: list # Placeholder documentation for __listOfInputSourceRequest — item shape: {PasswordParam?: any, Url?: any, Username?: any}
  --tags: record # Placeholder documentation for Tags
  --type: string@type-completer # The different types of inputs that AWS Elemental MediaLive supports.
  --vpc: record # Settings for a private VPC Input. When this property is specified, the input destination addresses will be created in a VPC rather than with public Internet addresses. This property requires setting the roleArn property on Input creation. Not compatible with the inputSecurityGroups property. — shape: {SecurityGroupIds?: any, SubnetIds?: any}
]: any -> record<Input: record<Arn: record, AttachedChannels: record, Destinations: record, Id: record, InputClass: record, InputDevices: record, InputPartnerIds: record, InputSourceType: record, MediaConnectFlows: record, Name: record, RoleArn: record, SecurityGroups: record, Sources: record, State: record, Tags: record, Type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/inputs")
  let body = {destinations: $destinations, inputDevices: $inputDevices, inputSecurityGroups: $inputSecurityGroups, mediaConnectFlows: $mediaConnectFlows, name: $name, requestId: $requestId, roleArn: $roleArn, sources: $sources, tags: $tags, type: $type, vpc: $vpc} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Produces list of inputs that have been created
#
# GET /prod/inputs
# operationId: ListInputs
export def "prod-inputs ListInputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int
  --nextToken: string
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Inputs: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/inputs" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a Input Security Group
#
# POST /prod/inputSecurityGroups
# operationId: CreateInputSecurityGroup
# --whitelistRules item shape: {Cidr?: any}
export def "prod-input-security-groups CreateInputSecurityGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --tags: record # Placeholder documentation for Tags
  --whitelistRules: list # Placeholder documentation for __listOfInputWhitelistRuleCidr — item shape: {Cidr?: any}
]: any -> record<SecurityGroup: record<Arn: record, Id: record, Inputs: record, State: record, Tags: record, WhitelistRules: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/inputSecurityGroups")
  let body = {tags: $tags, whitelistRules: $whitelistRules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Produces a list of Input Security Groups for an account
#
# GET /prod/inputSecurityGroups
# operationId: ListInputSecurityGroups
export def "prod-input-security-groups ListInputSecurityGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int
  --nextToken: string
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<InputSecurityGroups: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/inputSecurityGroups" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new multiplex.
#
# POST /prod/multiplexes
# operationId: CreateMultiplex
# --multiplexSettings shape: {MaximumVideoBufferDelayMilliseconds?: any, TransportStreamBitrate?: any, TransportStreamId?: any, TransportStreamReservedBitrate?: any}
export def "prod-multiplexes CreateMultiplex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  availabilityZones: list # Placeholder documentation for __listOf__string
  multiplexSettings: record # Contains configuration for a Multiplex event — shape: {MaximumVideoBufferDelayMilliseconds?: any, TransportStreamBitrate?: any, TransportStreamId?: any, TransportStreamReservedBitrate?: any}
  name: string # Placeholder documentation for __string
  requestId: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
]: any -> record<Multiplex: record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prod/multiplexes")
  let body = {availabilityZones: $availabilityZones, multiplexSettings: $multiplexSettings, name: $name, requestId: $requestId, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of the existing multiplexes.
#
# GET /prod/multiplexes
# operationId: ListMultiplexes
export def "prod-multiplexes ListMultiplexes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int # The maximum number of items to return.
  --nextToken: string # The token to retrieve the next page of results.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Multiplexes: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/multiplexes" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new program in the multiplex.
#
# POST /prod/multiplexes/{multiplexId}/programs
# operationId: CreateMultiplexProgram
# --multiplexProgramSettings shape: {PreferredChannelPipeline?: any, ProgramNumber?: any, ServiceDescriptor?: any, VideoSettings?: any}
export def "prod-multiplexes-programs CreateMultiplexProgram" [
  multiplexId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  multiplexProgramSettings: record # Multiplex Program settings configuration. — shape: {PreferredChannelPipeline?: any, ProgramNumber?: any, ServiceDescriptor?: any, VideoSettings?: any}
  programName: string # Placeholder documentation for __string
  requestId: string # Placeholder documentation for __string
]: any -> record<MultiplexProgram: record<ChannelId: record, MultiplexProgramSettings: record<PreferredChannelPipeline: record, ProgramNumber: record, ServiceDescriptor: record, VideoSettings: record>, PacketIdentifiersMap: record<AudioPids: record, DvbSubPids: record, DvbTeletextPid: record, EtvPlatformPid: record, EtvSignalPid: record, KlvDataPids: record, PcrPid: record, PmtPid: record, PrivateMetadataPid: record, Scte27Pids: record, Scte35Pid: record, TimedMetadataPid: record, VideoPid: record>, PipelineDetails: record, ProgramName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/multiplexes/($multiplexId)/programs")
  let body = {multiplexProgramSettings: $multiplexProgramSettings, programName: $programName, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the programs that currently exist for a specific multiplex.
#
# GET /prod/multiplexes/{multiplexId}/programs
# operationId: ListMultiplexPrograms
export def "prod-multiplexes-programs ListMultiplexPrograms" [
  multiplexId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int # The maximum number of items to return.
  --nextToken: string # The token to retrieve the next page of results.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<MultiplexPrograms: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/prod/multiplexes/($multiplexId)/programs" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a partner input
#
# POST /prod/inputs/{inputId}/partners
# operationId: CreatePartnerInput
export def "prod-inputs-partners CreatePartnerInput" [
  inputId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --requestId: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
]: any -> record<Input: record<Arn: record, AttachedChannels: record, Destinations: record, Id: record, InputClass: record, InputDevices: record, InputPartnerIds: record, InputSourceType: record, MediaConnectFlows: record, Name: record, RoleArn: record, SecurityGroups: record, Sources: record, State: record, Tags: record, Type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputs/($inputId)/partners")
  let body = {requestId: $requestId, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create tags for a resource
#
# POST /prod/tags/{resource-arn}
# operationId: CreateTags
export def "prod-tags CreateTags" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --tags: record # Placeholder documentation for Tags
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/tags/($resource_arn)")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Produces list of tags that have been created for a resource
#
# GET /prod/tags/{resource-arn}
# operationId: ListTagsForResource
export def "prod-tags ListTagsForResource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/tags/($resource_arn)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts deletion of channel. The associated outputs are also deleted.
#
# DELETE /prod/channels/{channelId}
# operationId: DeleteChannel
export def "prod-channels DeleteChannel" [
  channelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record<AvailBlankingImage: record, State: record>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: record, NetworkEndBlackoutImage: record, NetworkId: record, State: record>, CaptionDescriptions: record, FeatureActivations: record<InputPrepareScheduleActions: record>, GlobalConfiguration: record<InitialAudioGain: record, InputEndAction: record, InputLossBehavior: record, OutputLockingMode: record, OutputTimingSource: record, SupportLowFramerateInputs: record>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: record, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: record, NielsenPcmToId3Tagging: record>, OutputGroups: record, TimecodeConfig: record<Source: record, SyncThreshold: record>, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/channels/($channelId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets details about a channel
#
# GET /prod/channels/{channelId}
# operationId: DescribeChannel
export def "prod-channels DescribeChannel" [
  channelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record<AvailBlankingImage: record, State: record>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: record, NetworkEndBlackoutImage: record, NetworkId: record, State: record>, CaptionDescriptions: record, FeatureActivations: record<InputPrepareScheduleActions: record>, GlobalConfiguration: record<InitialAudioGain: record, InputEndAction: record, InputLossBehavior: record, OutputLockingMode: record, OutputTimingSource: record, SupportLowFramerateInputs: record>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: record, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: record, NielsenPcmToId3Tagging: record>, OutputGroups: record, TimecodeConfig: record<Source: record, SyncThreshold: record>, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/channels/($channelId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "prod-channels UpdateChannel" [
  channelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --cdiInputSpecification: record # Placeholder documentation for CdiInputSpecification — shape: {Resolution?: any}
  --destinations: list # Placeholder documentation for __listOfOutputDestination — item shape: {Id?: any, MediaPackageSettings?: any, MultiplexSettings?: any, Settings?: any}
  --encoderSettings: record # Encoder Settings — shape: {AudioDescriptions?: any, AvailBlanking?: any, AvailConfiguration?: any, BlackoutSlate?: any, CaptionDescriptions?: any, FeatureActivations?: any, GlobalConfiguration?: any, MotionGraphicsConfiguration?: any, NielsenConfiguration?: any, OutputGroups?: any, TimecodeConfig?: any, VideoDescriptions?: any}
  --inputAttachments: list # Placeholder documentation for __listOfInputAttachment — item shape: {AutomaticInputFailoverSettings?: any, InputAttachmentName?: any, InputId?: any, InputSettings?: any}
  --inputSpecification: record # Placeholder documentation for InputSpecification — shape: {Codec?: any, MaximumBitrate?: any, Resolution?: any}
  --logLevel: string@logLevel-completer # The log level the user wants for their channel.
  --maintenance: record # Placeholder documentation for MaintenanceUpdateSettings — shape: {MaintenanceDay?: any, MaintenanceScheduledDate?: any, MaintenanceStartTime?: any}
  --name: string # Placeholder documentation for __string
  --roleArn: string # Placeholder documentation for __string
]: any -> record<Channel: record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: record, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: record, TimecodeConfig: record, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/channels/($channelId)")
  let body = {cdiInputSpecification: $cdiInputSpecification, destinations: $destinations, encoderSettings: $encoderSettings, inputAttachments: $inputAttachments, inputSpecification: $inputSpecification, logLevel: $logLevel, maintenance: $maintenance, name: $name, roleArn: $roleArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the input end point
#
# DELETE /prod/inputs/{inputId}
# operationId: DeleteInput
export def "prod-inputs DeleteInput" [
  inputId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputs/($inputId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Produces details about an input
#
# GET /prod/inputs/{inputId}
# operationId: DescribeInput
export def "prod-inputs DescribeInput" [
  inputId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, AttachedChannels: record, Destinations: record, Id: record, InputClass: record, InputDevices: record, InputPartnerIds: record, InputSourceType: record, MediaConnectFlows: record, Name: record, RoleArn: record, SecurityGroups: record, Sources: record, State: record, Tags: record, Type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputs/($inputId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an input.
#
# PUT /prod/inputs/{inputId}
# operationId: UpdateInput
# --destinations item shape: {StreamName?: any}
# --inputDevices item shape: {Id?: any}
# --mediaConnectFlows item shape: {FlowArn?: any}
# --sources item shape: {PasswordParam?: any, Url?: any, Username?: any}
export def "prod-inputs UpdateInput" [
  inputId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --destinations: list # Placeholder documentation for __listOfInputDestinationRequest — item shape: {StreamName?: any}
  --inputDevices: list # Placeholder documentation for __listOfInputDeviceRequest — item shape: {Id?: any}
  --inputSecurityGroups: list # Placeholder documentation for __listOf__string
  --mediaConnectFlows: list # Placeholder documentation for __listOfMediaConnectFlowRequest — item shape: {FlowArn?: any}
  --name: string # Placeholder documentation for __string
  --roleArn: string # Placeholder documentation for __string
  --sources: list # Placeholder documentation for __listOfInputSourceRequest — item shape: {PasswordParam?: any, Url?: any, Username?: any}
]: any -> record<Input: record<Arn: record, AttachedChannels: record, Destinations: record, Id: record, InputClass: record, InputDevices: record, InputPartnerIds: record, InputSourceType: record, MediaConnectFlows: record, Name: record, RoleArn: record, SecurityGroups: record, Sources: record, State: record, Tags: record, Type: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputs/($inputId)")
  let body = {destinations: $destinations, inputDevices: $inputDevices, inputSecurityGroups: $inputSecurityGroups, mediaConnectFlows: $mediaConnectFlows, name: $name, roleArn: $roleArn, sources: $sources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes an Input Security Group
#
# DELETE /prod/inputSecurityGroups/{inputSecurityGroupId}
# operationId: DeleteInputSecurityGroup
export def "prod-input-security-groups DeleteInputSecurityGroup" [
  inputSecurityGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputSecurityGroups/($inputSecurityGroupId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Produces a summary of an Input Security Group
#
# GET /prod/inputSecurityGroups/{inputSecurityGroupId}
# operationId: DescribeInputSecurityGroup
export def "prod-input-security-groups DescribeInputSecurityGroup" [
  inputSecurityGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, Id: record, Inputs: record, State: record, Tags: record, WhitelistRules: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputSecurityGroups/($inputSecurityGroupId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Input Security Group's Whilelists.
#
# PUT /prod/inputSecurityGroups/{inputSecurityGroupId}
# operationId: UpdateInputSecurityGroup
# --whitelistRules item shape: {Cidr?: any}
export def "prod-input-security-groups UpdateInputSecurityGroup" [
  inputSecurityGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --tags: record # Placeholder documentation for Tags
  --whitelistRules: list # Placeholder documentation for __listOfInputWhitelistRuleCidr — item shape: {Cidr?: any}
]: any -> record<SecurityGroup: record<Arn: record, Id: record, Inputs: record, State: record, Tags: record, WhitelistRules: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputSecurityGroups/($inputSecurityGroupId)")
  let body = {tags: $tags, whitelistRules: $whitelistRules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a multiplex. The multiplex must be idle.
#
# DELETE /prod/multiplexes/{multiplexId}
# operationId: DeleteMultiplex
export def "prod-multiplexes DeleteMultiplex" [
  multiplexId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/multiplexes/($multiplexId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets details about a multiplex.
#
# GET /prod/multiplexes/{multiplexId}
# operationId: DescribeMultiplex
export def "prod-multiplexes DescribeMultiplex" [
  multiplexId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/multiplexes/($multiplexId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a multiplex.
#
# PUT /prod/multiplexes/{multiplexId}
# operationId: UpdateMultiplex
# --multiplexSettings shape: {MaximumVideoBufferDelayMilliseconds?: any, TransportStreamBitrate?: any, TransportStreamId?: any, TransportStreamReservedBitrate?: any}
export def "prod-multiplexes UpdateMultiplex" [
  multiplexId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --multiplexSettings: record # Contains configuration for a Multiplex event — shape: {MaximumVideoBufferDelayMilliseconds?: any, TransportStreamBitrate?: any, TransportStreamId?: any, TransportStreamReservedBitrate?: any}
  --name: string # Placeholder documentation for __string
]: any -> record<Multiplex: record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/multiplexes/($multiplexId)")
  let body = {multiplexSettings: $multiplexSettings, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a program from a multiplex.
#
# DELETE /prod/multiplexes/{multiplexId}/programs/{programName}
# operationId: DeleteMultiplexProgram
export def "prod-multiplexes-programs DeleteMultiplexProgram" [
  multiplexId: string
  programName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ChannelId: record, MultiplexProgramSettings: record<PreferredChannelPipeline: record, ProgramNumber: record, ServiceDescriptor: record<ProviderName: record, ServiceName: record>, VideoSettings: record<ConstantBitrate: record, StatmuxSettings: record>>, PacketIdentifiersMap: record<AudioPids: record, DvbSubPids: record, DvbTeletextPid: record, EtvPlatformPid: record, EtvSignalPid: record, KlvDataPids: record, PcrPid: record, PmtPid: record, PrivateMetadataPid: record, Scte27Pids: record, Scte35Pid: record, TimedMetadataPid: record, VideoPid: record>, PipelineDetails: record, ProgramName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/multiplexes/($multiplexId)/programs/($programName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details for a program in a multiplex.
#
# GET /prod/multiplexes/{multiplexId}/programs/{programName}
# operationId: DescribeMultiplexProgram
export def "prod-multiplexes-programs DescribeMultiplexProgram" [
  multiplexId: string
  programName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ChannelId: record, MultiplexProgramSettings: record<PreferredChannelPipeline: record, ProgramNumber: record, ServiceDescriptor: record<ProviderName: record, ServiceName: record>, VideoSettings: record<ConstantBitrate: record, StatmuxSettings: record>>, PacketIdentifiersMap: record<AudioPids: record, DvbSubPids: record, DvbTeletextPid: record, EtvPlatformPid: record, EtvSignalPid: record, KlvDataPids: record, PcrPid: record, PmtPid: record, PrivateMetadataPid: record, Scte27Pids: record, Scte35Pid: record, TimedMetadataPid: record, VideoPid: record>, PipelineDetails: record, ProgramName: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/multiplexes/($multiplexId)/programs/($programName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a program in a multiplex.
#
# PUT /prod/multiplexes/{multiplexId}/programs/{programName}
# operationId: UpdateMultiplexProgram
# --multiplexProgramSettings shape: {PreferredChannelPipeline?: any, ProgramNumber?: any, ServiceDescriptor?: any, VideoSettings?: any}
export def "prod-multiplexes-programs UpdateMultiplexProgram" [
  multiplexId: string
  programName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --multiplexProgramSettings: record # Multiplex Program settings configuration. — shape: {PreferredChannelPipeline?: any, ProgramNumber?: any, ServiceDescriptor?: any, VideoSettings?: any}
]: any -> record<MultiplexProgram: record<ChannelId: record, MultiplexProgramSettings: record<PreferredChannelPipeline: record, ProgramNumber: record, ServiceDescriptor: record, VideoSettings: record>, PacketIdentifiersMap: record<AudioPids: record, DvbSubPids: record, DvbTeletextPid: record, EtvPlatformPid: record, EtvSignalPid: record, KlvDataPids: record, PcrPid: record, PmtPid: record, PrivateMetadataPid: record, Scte27Pids: record, Scte35Pid: record, TimedMetadataPid: record, VideoPid: record>, PipelineDetails: record, ProgramName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/multiplexes/($multiplexId)/programs/($programName)")
  let body = {multiplexProgramSettings: $multiplexProgramSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an expired reservation.
#
# DELETE /prod/reservations/{reservationId}
# operationId: DeleteReservation
export def "prod-reservations DeleteReservation" [
  reservationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, Count: record, CurrencyCode: record, Duration: record, DurationUnits: record, End: record, FixedPrice: record, Name: record, OfferingDescription: record, OfferingId: record, OfferingType: record, Region: record, RenewalSettings: record<AutomaticRenewal: record, RenewalCount: record>, ReservationId: record, ResourceSpecification: record<ChannelClass: record, Codec: record, MaximumBitrate: record, MaximumFramerate: record, Resolution: record, ResourceType: record, SpecialFeature: record, VideoQuality: record>, Start: record, State: record, Tags: record, UsagePrice: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/reservations/($reservationId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details for a reservation.
#
# GET /prod/reservations/{reservationId}
# operationId: DescribeReservation
export def "prod-reservations DescribeReservation" [
  reservationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, Count: record, CurrencyCode: record, Duration: record, DurationUnits: record, End: record, FixedPrice: record, Name: record, OfferingDescription: record, OfferingId: record, OfferingType: record, Region: record, RenewalSettings: record<AutomaticRenewal: record, RenewalCount: record>, ReservationId: record, ResourceSpecification: record<ChannelClass: record, Codec: record, MaximumBitrate: record, MaximumFramerate: record, Resolution: record, ResourceType: record, SpecialFeature: record, VideoQuality: record>, Start: record, State: record, Tags: record, UsagePrice: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/reservations/($reservationId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update reservation.
#
# PUT /prod/reservations/{reservationId}
# operationId: UpdateReservation
# --renewalSettings shape: {AutomaticRenewal?: any, RenewalCount?: any}
export def "prod-reservations UpdateReservation" [
  reservationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --name: string # Placeholder documentation for __string
  --renewalSettings: record # The Renewal settings for Reservations — shape: {AutomaticRenewal?: any, RenewalCount?: any}
]: any -> record<Reservation: record<Arn: record, Count: record, CurrencyCode: record, Duration: record, DurationUnits: record, End: record, FixedPrice: record, Name: record, OfferingDescription: record, OfferingId: record, OfferingType: record, Region: record, RenewalSettings: record<AutomaticRenewal: record, RenewalCount: record>, ReservationId: record, ResourceSpecification: record<ChannelClass: record, Codec: record, MaximumBitrate: record, MaximumFramerate: record, Resolution: record, ResourceType: record, SpecialFeature: record, VideoQuality: record>, Start: record, State: record, Tags: record, UsagePrice: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/reservations/($reservationId)")
  let body = {name: $name, renewalSettings: $renewalSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes tags for a resource
#
# DELETE /prod/tags/{resource-arn}#tagKeys
# operationId: DeleteTags
export def "prod-tags DeleteTags" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tagKeys: list # An array of tag keys to delete
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagKeys" $tagKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/prod/tags/($resource_arn)#tagKeys" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the details for the input device
#
# GET /prod/inputDevices/{inputDeviceId}
# operationId: DescribeInputDevice
export def "prod-input-devices DescribeInputDevice" [
  inputDeviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, ConnectionState: record, DeviceSettingsSyncState: record, DeviceUpdateStatus: record, HdDeviceSettings: record<ActiveInput: record, ConfiguredInput: record, DeviceState: record, Framerate: record, Height: record, MaxBitrate: record, ScanType: record, Width: record, LatencyMs: record>, Id: record, MacAddress: record, Name: record, NetworkSettings: record<DnsAddresses: record, Gateway: record, IpAddress: record, IpScheme: record, SubnetMask: record>, SerialNumber: record, Type: record, UhdDeviceSettings: record<ActiveInput: record, ConfiguredInput: record, DeviceState: record, Framerate: record, Height: record, MaxBitrate: record, ScanType: record, Width: record, LatencyMs: record>, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputDevices/($inputDeviceId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the parameters for the input device.
#
# PUT /prod/inputDevices/{inputDeviceId}
# operationId: UpdateInputDevice
# --hdDeviceSettings shape: {ConfiguredInput?: any, MaxBitrate?: any, LatencyMs?: any}
# --uhdDeviceSettings shape: {ConfiguredInput?: any, MaxBitrate?: any, LatencyMs?: any}
export def "prod-input-devices UpdateInputDevice" [
  inputDeviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --hdDeviceSettings: record # Configurable settings for the input device. — shape: {ConfiguredInput?: any, MaxBitrate?: any, LatencyMs?: any}
  --name: string # Placeholder documentation for __string
  --uhdDeviceSettings: record # Configurable settings for the input device. — shape: {ConfiguredInput?: any, MaxBitrate?: any, LatencyMs?: any}
]: any -> record<Arn: record, ConnectionState: record, DeviceSettingsSyncState: record, DeviceUpdateStatus: record, HdDeviceSettings: record<ActiveInput: record, ConfiguredInput: record, DeviceState: record, Framerate: record, Height: record, MaxBitrate: record, ScanType: record, Width: record, LatencyMs: record>, Id: record, MacAddress: record, Name: record, NetworkSettings: record<DnsAddresses: record, Gateway: record, IpAddress: record, IpScheme: record, SubnetMask: record>, SerialNumber: record, Type: record, UhdDeviceSettings: record<ActiveInput: record, ConfiguredInput: record, DeviceState: record, Framerate: record, Height: record, MaxBitrate: record, ScanType: record, Width: record, LatencyMs: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputDevices/($inputDeviceId)")
  let body = {hdDeviceSettings: $hdDeviceSettings, name: $name, uhdDeviceSettings: $uhdDeviceSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the latest thumbnail data for the input device.
#
# GET /prod/inputDevices/{inputDeviceId}/thumbnailData#accept
# operationId: DescribeInputDeviceThumbnail
export def "prod-input-devices-thumbnail-dataaccept DescribeInputDeviceThumbnail" [
  inputDeviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --hdr-accept: string@accept-completer # The HTTP Accept header. Indicates the requested type for the thumbnail.
]: nothing -> record<Body: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputDevices/($inputDeviceId)/thumbnailData#accept")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details for an offering.
#
# GET /prod/offerings/{offeringId}
# operationId: DescribeOffering
export def "prod-offerings DescribeOffering" [
  offeringId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, CurrencyCode: record, Duration: record, DurationUnits: record, FixedPrice: record, OfferingDescription: record, OfferingId: record, OfferingType: record, Region: record, ResourceSpecification: record<ChannelClass: record, Codec: record, MaximumBitrate: record, MaximumFramerate: record, Resolution: record, ResourceType: record, SpecialFeature: record, VideoQuality: record>, UsagePrice: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/offerings/($offeringId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List input devices that are currently being transferred. List input devices that you are transferring from your AWS account or input devices that another AWS account is transferring to you.
#
# GET /prod/inputDeviceTransfers#transferType
# operationId: ListInputDeviceTransfers
export def "prod-input-device-transferstransfer-type ListInputDeviceTransfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int
  --nextToken: string
  --transferType: string
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<InputDeviceTransfers: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "transferType" $transferType "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/inputDeviceTransfers#transferType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List input devices
#
# GET /prod/inputDevices
# operationId: ListInputDevices
export def "prod-input-devices ListInputDevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int
  --nextToken: string
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<InputDevices: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/inputDevices" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List offerings available for purchase.
#
# GET /prod/offerings
# operationId: ListOfferings
export def "prod-offerings ListOfferings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channelClass: string # Filter by channel class, 'STANDARD' or 'SINGLE_PIPELINE'
  --channelConfiguration: string # Filter to offerings that match the configuration of an existing channel, e.g. '2345678' (a channel ID)
  --codec: string # Filter by codec, 'AVC', 'HEVC', 'MPEG2', 'AUDIO', or 'LINK'
  --duration: string # Filter by offering duration, e.g. '12'
  --maxResults: int
  --maximumBitrate: string # Filter by bitrate, 'MAX_10_MBPS', 'MAX_20_MBPS', or 'MAX_50_MBPS'
  --maximumFramerate: string # Filter by framerate, 'MAX_30_FPS' or 'MAX_60_FPS'
  --nextToken: string
  --resolution: string # Filter by resolution, 'SD', 'HD', 'FHD', or 'UHD'
  --resourceType: string # Filter by resource type, 'INPUT', 'OUTPUT', 'MULTIPLEX', or 'CHANNEL'
  --specialFeature: string # Filter by special feature, 'ADVANCED_AUDIO' or 'AUDIO_NORMALIZATION'
  --videoQuality: string # Filter by video quality, 'STANDARD', 'ENHANCED', or 'PREMIUM'
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, Offerings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channelClass" $channelClass "scalar") (serialize-qp "channelConfiguration" $channelConfiguration "scalar") (serialize-qp "codec" $codec "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "maximumBitrate" $maximumBitrate "scalar") (serialize-qp "maximumFramerate" $maximumFramerate "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "resourceType" $resourceType "scalar") (serialize-qp "specialFeature" $specialFeature "scalar") (serialize-qp "videoQuality" $videoQuality "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/offerings" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List purchased reservations.
#
# GET /prod/reservations
# operationId: ListReservations
export def "prod-reservations ListReservations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channelClass: string # Filter by channel class, 'STANDARD' or 'SINGLE_PIPELINE'
  --codec: string # Filter by codec, 'AVC', 'HEVC', 'MPEG2', 'AUDIO', or 'LINK'
  --maxResults: int
  --maximumBitrate: string # Filter by bitrate, 'MAX_10_MBPS', 'MAX_20_MBPS', or 'MAX_50_MBPS'
  --maximumFramerate: string # Filter by framerate, 'MAX_30_FPS' or 'MAX_60_FPS'
  --nextToken: string
  --resolution: string # Filter by resolution, 'SD', 'HD', 'FHD', or 'UHD'
  --resourceType: string # Filter by resource type, 'INPUT', 'OUTPUT', 'MULTIPLEX', or 'CHANNEL'
  --specialFeature: string # Filter by special feature, 'ADVANCED_AUDIO' or 'AUDIO_NORMALIZATION'
  --videoQuality: string # Filter by video quality, 'STANDARD', 'ENHANCED', or 'PREMIUM'
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, Reservations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channelClass" $channelClass "scalar") (serialize-qp "codec" $codec "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "maximumBitrate" $maximumBitrate "scalar") (serialize-qp "maximumFramerate" $maximumFramerate "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "resourceType" $resourceType "scalar") (serialize-qp "specialFeature" $specialFeature "scalar") (serialize-qp "videoQuality" $videoQuality "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prod/reservations" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Purchase an offering and create a reservation.
#
# POST /prod/offerings/{offeringId}/purchase
# operationId: PurchaseOffering
# --renewalSettings shape: {AutomaticRenewal?: any, RenewalCount?: any}
export def "prod-offerings-purchase PurchaseOffering" [
  offeringId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  count: int # Placeholder documentation for __integerMin1
  --name: string # Placeholder documentation for __string
  --renewalSettings: record # The Renewal settings for Reservations — shape: {AutomaticRenewal?: any, RenewalCount?: any}
  --requestId: string # Placeholder documentation for __string
  --start: string # Placeholder documentation for __string
  --tags: record # Placeholder documentation for Tags
]: any -> record<Reservation: record<Arn: record, Count: record, CurrencyCode: record, Duration: record, DurationUnits: record, End: record, FixedPrice: record, Name: record, OfferingDescription: record, OfferingId: record, OfferingType: record, Region: record, RenewalSettings: record<AutomaticRenewal: record, RenewalCount: record>, ReservationId: record, ResourceSpecification: record<ChannelClass: record, Codec: record, MaximumBitrate: record, MaximumFramerate: record, Resolution: record, ResourceType: record, SpecialFeature: record, VideoQuality: record>, Start: record, State: record, Tags: record, UsagePrice: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/offerings/($offeringId)/purchase")
  let body = {count: $count, name: $name, renewalSettings: $renewalSettings, requestId: $requestId, start: $start, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a reboot command to the specified input device. The device will begin rebooting within a few seconds of sending the command. When the reboot is complete, the device’s connection status will change to connected.
#
# POST /prod/inputDevices/{inputDeviceId}/reboot
# operationId: RebootInputDevice
export def "prod-input-devices-reboot RebootInputDevice" [
  inputDeviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --force: string@force-completer # Whether or not to force reboot the input device.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputDevices/($inputDeviceId)/reboot")
  let body = {force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reject the transfer of the specified input device to your AWS account.
#
# POST /prod/inputDevices/{inputDeviceId}/reject
# operationId: RejectInputDeviceTransfer
export def "prod-input-devices-reject RejectInputDeviceTransfer" [
  inputDeviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputDevices/($inputDeviceId)/reject")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts an existing channel
#
# POST /prod/channels/{channelId}/start
# operationId: StartChannel
export def "prod-channels-start StartChannel" [
  channelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record<AvailBlankingImage: record, State: record>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: record, NetworkEndBlackoutImage: record, NetworkId: record, State: record>, CaptionDescriptions: record, FeatureActivations: record<InputPrepareScheduleActions: record>, GlobalConfiguration: record<InitialAudioGain: record, InputEndAction: record, InputLossBehavior: record, OutputLockingMode: record, OutputTimingSource: record, SupportLowFramerateInputs: record>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: record, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: record, NielsenPcmToId3Tagging: record>, OutputGroups: record, TimecodeConfig: record<Source: record, SyncThreshold: record>, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/channels/($channelId)/start")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a maintenance window for the specified input device. Starting a maintenance window will give the device up to two hours to install software. If the device was streaming prior to the maintenance, it will resume streaming when the software is fully installed. Devices automatically install updates while they are powered on and their MediaLive channels are stopped. A maintenance window allows you to update a device without having to stop MediaLive channels that use the device. The device must remain powered on and connected to the internet for the duration of the maintenance.
#
# POST /prod/inputDevices/{inputDeviceId}/startInputDeviceMaintenanceWindow
# operationId: StartInputDeviceMaintenanceWindow
export def "prod-input-devices-start-input-device-maintenance-window StartInputDeviceMaintenanceWindow" [
  inputDeviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputDevices/($inputDeviceId)/startInputDeviceMaintenanceWindow")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
#
# POST /prod/multiplexes/{multiplexId}/start
# operationId: StartMultiplex
export def "prod-multiplexes-start StartMultiplex" [
  multiplexId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/multiplexes/($multiplexId)/start")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stops a running channel
#
# POST /prod/channels/{channelId}/stop
# operationId: StopChannel
export def "prod-channels-stop StopChannel" [
  channelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record<AvailBlankingImage: record, State: record>, AvailConfiguration: record<AvailSettings: record>, BlackoutSlate: record<BlackoutSlateImage: record, NetworkEndBlackout: record, NetworkEndBlackoutImage: record, NetworkId: record, State: record>, CaptionDescriptions: record, FeatureActivations: record<InputPrepareScheduleActions: record>, GlobalConfiguration: record<InitialAudioGain: record, InputEndAction: record, InputLossBehavior: record, OutputLockingMode: record, OutputTimingSource: record, SupportLowFramerateInputs: record>, MotionGraphicsConfiguration: record<MotionGraphicsInsertion: record, MotionGraphicsSettings: record>, NielsenConfiguration: record<DistributorId: record, NielsenPcmToId3Tagging: record>, OutputGroups: record, TimecodeConfig: record<Source: record, SyncThreshold: record>, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/channels/($channelId)/stop")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stops a running multiplex. If the multiplex isn't running, this action has no effect.
#
# POST /prod/multiplexes/{multiplexId}/stop
# operationId: StopMultiplex
export def "prod-multiplexes-stop StopMultiplex" [
  multiplexId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, AvailabilityZones: record, Destinations: record, Id: record, MultiplexSettings: record<MaximumVideoBufferDelayMilliseconds: record, TransportStreamBitrate: record, TransportStreamId: record, TransportStreamReservedBitrate: record>, Name: record, PipelinesRunningCount: record, ProgramCount: record, State: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/multiplexes/($multiplexId)/stop")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start an input device transfer to another AWS account. After you make the request, the other account must accept or reject the transfer.
#
# POST /prod/inputDevices/{inputDeviceId}/transfer
# operationId: TransferInputDevice
export def "prod-input-devices-transfer TransferInputDevice" [
  inputDeviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --targetCustomerId: string # Placeholder documentation for __string
  --targetRegion: string # Placeholder documentation for __string
  --transferMessage: string # Placeholder documentation for __string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/inputDevices/($inputDeviceId)/transfer")
  let body = {targetCustomerId: $targetCustomerId, targetRegion: $targetRegion, transferMessage: $transferMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Changes the class of the channel.
#
# PUT /prod/channels/{channelId}/channelClass
# operationId: UpdateChannelClass
# --destinations item shape: {Id?: any, MediaPackageSettings?: any, MultiplexSettings?: any, Settings?: any}
export def "prod-channels-channel-class UpdateChannelClass" [
  channelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  channelClass: string@channelClass-completer # A standard channel has two encoding pipelines and a single pipeline channel only has one.
  --destinations: list # Placeholder documentation for __listOfOutputDestination — item shape: {Id?: any, MediaPackageSettings?: any, MultiplexSettings?: any, Settings?: any}
]: any -> record<Channel: record<Arn: record, CdiInputSpecification: record<Resolution: record>, ChannelClass: record, Destinations: record, EgressEndpoints: record, EncoderSettings: record<AudioDescriptions: record, AvailBlanking: record, AvailConfiguration: record, BlackoutSlate: record, CaptionDescriptions: record, FeatureActivations: record, GlobalConfiguration: record, MotionGraphicsConfiguration: record, NielsenConfiguration: record, OutputGroups: record, TimecodeConfig: record, VideoDescriptions: record>, Id: record, InputAttachments: record, InputSpecification: record<Codec: record, MaximumBitrate: record, Resolution: record>, LogLevel: record, Maintenance: record<MaintenanceDay: record, MaintenanceDeadline: record, MaintenanceScheduledDate: record, MaintenanceStartTime: record>, Name: record, PipelineDetails: record, PipelinesRunningCount: record, RoleArn: record, State: record, Tags: record, Vpc: record<AvailabilityZones: record, NetworkInterfaceIds: record, SecurityGroupIds: record, SubnetIds: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prod/channels/($channelId)/channelClass")
  let body = {channelClass: $channelClass, destinations: $destinations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
