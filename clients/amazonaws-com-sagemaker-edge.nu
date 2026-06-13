# Auto-generated client for Amazon Sagemaker Edge Manager v2020-09-23
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sagemaker-edge/2020-09-23/openapi.json
# Auth: --token flag or $env.AMAZON_SAGEMAKER_EDGE_MANAGER_TOKEN

const BASE_URL = "http://edge.sagemaker.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_SAGEMAKER_EDGE_MANAGER_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["http://edge.sagemaker.us-east-1.amazonaws.com" "http://edge.sagemaker.us-east-2.amazonaws.com" "http://edge.sagemaker.us-west-1.amazonaws.com" "http://edge.sagemaker.us-west-2.amazonaws.com" "http://edge.sagemaker.us-gov-west-1.amazonaws.com" "http://edge.sagemaker.us-gov-east-1.amazonaws.com" "http://edge.sagemaker.ca-central-1.amazonaws.com" "http://edge.sagemaker.eu-north-1.amazonaws.com" "http://edge.sagemaker.eu-west-1.amazonaws.com" "http://edge.sagemaker.eu-west-2.amazonaws.com" "http://edge.sagemaker.eu-west-3.amazonaws.com" "http://edge.sagemaker.eu-central-1.amazonaws.com" "http://edge.sagemaker.eu-south-1.amazonaws.com" "http://edge.sagemaker.af-south-1.amazonaws.com" "http://edge.sagemaker.ap-northeast-1.amazonaws.com" "http://edge.sagemaker.ap-northeast-2.amazonaws.com" "http://edge.sagemaker.ap-northeast-3.amazonaws.com" "http://edge.sagemaker.ap-southeast-1.amazonaws.com" "http://edge.sagemaker.ap-southeast-2.amazonaws.com" "http://edge.sagemaker.ap-east-1.amazonaws.com" "http://edge.sagemaker.ap-south-1.amazonaws.com" "http://edge.sagemaker.sa-east-1.amazonaws.com" "http://edge.sagemaker.me-south-1.amazonaws.com" "https://edge.sagemaker.us-east-1.amazonaws.com" "https://edge.sagemaker.us-east-2.amazonaws.com" "https://edge.sagemaker.us-west-1.amazonaws.com" "https://edge.sagemaker.us-west-2.amazonaws.com" "https://edge.sagemaker.us-gov-west-1.amazonaws.com" "https://edge.sagemaker.us-gov-east-1.amazonaws.com" "https://edge.sagemaker.ca-central-1.amazonaws.com" "https://edge.sagemaker.eu-north-1.amazonaws.com" "https://edge.sagemaker.eu-west-1.amazonaws.com" "https://edge.sagemaker.eu-west-2.amazonaws.com" "https://edge.sagemaker.eu-west-3.amazonaws.com" "https://edge.sagemaker.eu-central-1.amazonaws.com" "https://edge.sagemaker.eu-south-1.amazonaws.com" "https://edge.sagemaker.af-south-1.amazonaws.com" "https://edge.sagemaker.ap-northeast-1.amazonaws.com" "https://edge.sagemaker.ap-northeast-2.amazonaws.com" "https://edge.sagemaker.ap-northeast-3.amazonaws.com" "https://edge.sagemaker.ap-southeast-1.amazonaws.com" "https://edge.sagemaker.ap-southeast-2.amazonaws.com" "https://edge.sagemaker.ap-east-1.amazonaws.com" "https://edge.sagemaker.ap-south-1.amazonaws.com" "https://edge.sagemaker.sa-east-1.amazonaws.com" "https://edge.sagemaker.me-south-1.amazonaws.com" "http://edge.sagemaker.cn-north-1.amazonaws.com.cn" "http://edge.sagemaker.cn-northwest-1.amazonaws.com.cn" "https://edge.sagemaker.cn-north-1.amazonaws.com.cn" "https://edge.sagemaker.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "get-deployments GetDeployments" } } | get name | first)
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

# Use to get the active deployments from a device.
#
# POST /GetDeployments
# operationId: GetDeployments
export def "get-deployments GetDeployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  DeviceName: string # The unique name of the device you want to get the configuration of active deployments from.
  DeviceFleetName: string # The name of the fleet that the device belongs to.
]: any -> record<Deployments: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GetDeployments")
  let body = {DeviceName: $DeviceName, DeviceFleetName: $DeviceFleetName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use to check if a device is registered with SageMaker Edge Manager.
#
# POST /GetDeviceRegistration
# operationId: GetDeviceRegistration
export def "get-device-registration GetDeviceRegistration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  DeviceName: string # The unique name of the device you want to get the registration status from.
  DeviceFleetName: string # The name of the fleet that the device belongs to.
]: any -> record<DeviceRegistration: record, CacheTTL: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GetDeviceRegistration")
  let body = {DeviceName: $DeviceName, DeviceFleetName: $DeviceFleetName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use to get the current status of devices registered on SageMaker Edge Manager.
#
# POST /SendHeartbeat
# operationId: SendHeartbeat
# --AgentMetrics item shape: {Dimension?: any, MetricName?: any, Value?: any, Timestamp?: any}
# --Models item shape: {ModelName?: any, ModelVersion?: any, LatestSampleTime?: any, LatestInference?: any, ModelMetrics?: any}
# --DeploymentResult shape: {DeploymentName?: any, DeploymentStatus?: any, DeploymentStatusMessage?: any, DeploymentStartTime?: any, DeploymentEndTime?: any, DeploymentModels?: any}
export def "send-heartbeat SendHeartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --AgentMetrics: list # For internal use. Returns a list of SageMaker Edge Manager agent operating metrics. — item shape: {Dimension?: any, MetricName?: any, Value?: any, Timestamp?: any}
  --Models: list # Returns a list of models deployed on the the device. — item shape: {ModelName?: any, ModelVersion?: any, LatestSampleTime?: any, LatestInference?: any, ModelMetrics?: any}
  AgentVersion: string # Returns the version of the agent.
  DeviceName: string # The unique name of the device.
  DeviceFleetName: string # The name of the fleet that the device belongs to.
  --DeploymentResult: record # Information about the result of a deployment on an edge device that is registered with SageMaker Edge Manager. — shape: {DeploymentName?: any, DeploymentStatus?: any, DeploymentStatusMessage?: any, DeploymentStartTime?: any, DeploymentEndTime?: any, DeploymentModels?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/SendHeartbeat")
  let body = {AgentMetrics: $AgentMetrics, Models: $Models, AgentVersion: $AgentVersion, DeviceName: $DeviceName, DeviceFleetName: $DeviceFleetName, DeploymentResult: $DeploymentResult} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
