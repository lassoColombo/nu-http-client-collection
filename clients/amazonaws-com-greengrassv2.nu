# Auto-generated client for AWS IoT Greengrass V2 v2020-11-30
# Source: https://api.apis.guru/v2/specs/amazonaws.com/greengrassv2/2020-11-30/openapi.json
# Auth: --token flag or $env.AWS_IOT_GREENGRASS_V2_TOKEN

const BASE_URL = "http://greengrass.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_IOT_GREENGRASS_V2_TOKEN | default "" }
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

def base-url-completer [] { ["http://greengrass.us-east-1.amazonaws.com" "http://greengrass.us-east-2.amazonaws.com" "http://greengrass.us-west-1.amazonaws.com" "http://greengrass.us-west-2.amazonaws.com" "http://greengrass.us-gov-west-1.amazonaws.com" "http://greengrass.us-gov-east-1.amazonaws.com" "http://greengrass.ca-central-1.amazonaws.com" "http://greengrass.eu-north-1.amazonaws.com" "http://greengrass.eu-west-1.amazonaws.com" "http://greengrass.eu-west-2.amazonaws.com" "http://greengrass.eu-west-3.amazonaws.com" "http://greengrass.eu-central-1.amazonaws.com" "http://greengrass.eu-south-1.amazonaws.com" "http://greengrass.af-south-1.amazonaws.com" "http://greengrass.ap-northeast-1.amazonaws.com" "http://greengrass.ap-northeast-2.amazonaws.com" "http://greengrass.ap-northeast-3.amazonaws.com" "http://greengrass.ap-southeast-1.amazonaws.com" "http://greengrass.ap-southeast-2.amazonaws.com" "http://greengrass.ap-east-1.amazonaws.com" "http://greengrass.ap-south-1.amazonaws.com" "http://greengrass.sa-east-1.amazonaws.com" "http://greengrass.me-south-1.amazonaws.com" "https://greengrass.us-east-1.amazonaws.com" "https://greengrass.us-east-2.amazonaws.com" "https://greengrass.us-west-1.amazonaws.com" "https://greengrass.us-west-2.amazonaws.com" "https://greengrass.us-gov-west-1.amazonaws.com" "https://greengrass.us-gov-east-1.amazonaws.com" "https://greengrass.ca-central-1.amazonaws.com" "https://greengrass.eu-north-1.amazonaws.com" "https://greengrass.eu-west-1.amazonaws.com" "https://greengrass.eu-west-2.amazonaws.com" "https://greengrass.eu-west-3.amazonaws.com" "https://greengrass.eu-central-1.amazonaws.com" "https://greengrass.eu-south-1.amazonaws.com" "https://greengrass.af-south-1.amazonaws.com" "https://greengrass.ap-northeast-1.amazonaws.com" "https://greengrass.ap-northeast-2.amazonaws.com" "https://greengrass.ap-northeast-3.amazonaws.com" "https://greengrass.ap-southeast-1.amazonaws.com" "https://greengrass.ap-southeast-2.amazonaws.com" "https://greengrass.ap-east-1.amazonaws.com" "https://greengrass.ap-south-1.amazonaws.com" "https://greengrass.sa-east-1.amazonaws.com" "https://greengrass.me-south-1.amazonaws.com" "http://greengrass.cn-north-1.amazonaws.com.cn" "http://greengrass.cn-northwest-1.amazonaws.com.cn" "https://greengrass.cn-north-1.amazonaws.com.cn" "https://greengrass.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def history-filter-completer [] { ["ALL" "LATEST_ONLY"] }
def recipe-output-format-completer [] { ["JSON" "YAML"] }
def scope-completer [] { ["PRIVATE" "PUBLIC"] }
def status-completer [] { ["HEALTHY" "UNHEALTHY"] }
def topology-filter-completer [] { ["ALL" "ROOT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "greengrass-servicerole update-associate-service-role-to-account" } } | get name | first)
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

# Associates a Greengrass service role with IoT Greengrass for your Amazon Web Services account in this Amazon Web Services Region. IoT Greengrass uses this role to verify the identity of client devices and manage core device connectivity information. The role must include the AWSGreengrassResourceAccessRolePolicy (https://console.aws.amazon.com/iam/home#/policies/arn:awsiam::aws:policy/service-role/AWSGreengrassResourceAccessRolePolicy) managed policy or a custom policy that defines equivalent permissions for the IoT Greengrass features that you use. For more information, see Greengrass service role (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-service-role.html) in the IoT Greengrass Version 2 Developer Guide.
#
# PUT /greengrass/servicerole
# operationId: AssociateServiceRoleToAccount
export def "greengrass-servicerole update-associate-service-role-to-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  role_arn: string # The Amazon Resource Name (ARN) of the service role to associate with IoT Greengrass for your Amazon Web Services account in this Amazon Web Services Region.
]: any -> record<associatedAt: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/greengrass/servicerole")
  let req_body = {"RoleArn": $role_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disassociates the Greengrass service role from IoT Greengrass for your Amazon Web Services account in this Amazon Web Services Region. Without a service role, IoT Greengrass can't verify the identity of client devices or manage core device connectivity information. For more information, see Greengrass service role (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-service-role.html) in the IoT Greengrass Version 2 Developer Guide.
#
# DELETE /greengrass/servicerole
# operationId: DisassociateServiceRoleFromAccount
export def "greengrass-servicerole delete-disassociate-service-role-from-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<disassociatedAt: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/greengrass/servicerole")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the service role associated with IoT Greengrass for your Amazon Web Services account in this Amazon Web Services Region. IoT Greengrass uses this role to verify the identity of client devices and manage core device connectivity information. For more information, see Greengrass service role (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-service-role.html) in the IoT Greengrass Version 2 Developer Guide.
#
# GET /greengrass/servicerole
# operationId: GetServiceRoleForAccount
export def "greengrass-servicerole get-service-role-for-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<associatedAt: record, roleArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/greengrass/servicerole")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associates a list of client devices with a core device. Use this API operation to specify which client devices can discover a core device through cloud discovery. With cloud discovery, client devices connect to IoT Greengrass to retrieve associated core devices' connectivity information and certificates. For more information, see Configure cloud discovery (https://docs.aws.amazon.com/greengrass/v2/developerguide/configure-cloud-discovery.html) in the IoT Greengrass V2 Developer Guide. Client devices are local IoT devices that connect to and communicate with an IoT Greengrass core device over MQTT. You can connect client devices to a core device to sync MQTT messages and data to Amazon Web Services IoT Core and interact with client devices in Greengrass components. For more information, see Interact with local IoT devices (https://docs.aws.amazon.com/greengrass/v2/developerguide/interact-with-local-iot-devices.html) in the IoT Greengrass V2 Developer Guide.
#
# POST /greengrass/v2/coreDevices/{coreDeviceThingName}/associateClientDevices
# operationId: BatchAssociateClientDeviceWithCoreDevice
# --entries item shape: {thingName: any}
export def "greengrass-core-devices-associate-client-devices create-batch" [
  core_device_thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --entries: list # The list of client devices to associate. — item shape: {thingName: any}
]: any -> record<errorEntries: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({core_device_thing_name: (encode-path-segment $core_device_thing_name)} | format pattern "/greengrass/v2/coreDevices/{core_device_thing_name}/associateClientDevices"))
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disassociates a list of client devices from a core device. After you disassociate a client device from a core device, the client device won't be able to use cloud discovery to retrieve the core device's connectivity information and certificates.
#
# POST /greengrass/v2/coreDevices/{coreDeviceThingName}/disassociateClientDevices
# operationId: BatchDisassociateClientDeviceFromCoreDevice
# --entries item shape: {thingName: any}
export def "greengrass-core-devices-disassociate-client-devices create-batch" [
  core_device_thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --entries: list # The list of client devices to disassociate. — item shape: {thingName: any}
]: any -> record<errorEntries: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({core_device_thing_name: (encode-path-segment $core_device_thing_name)} | format pattern "/greengrass/v2/coreDevices/{core_device_thing_name}/disassociateClientDevices"))
  let req_body = {"entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Cancels a deployment. This operation cancels the deployment for devices that haven't yet received it. If a device already received the deployment, this operation doesn't change anything for that device.
#
# POST /greengrass/v2/deployments/{deploymentId}/cancel
# operationId: CancelDeployment
export def "greengrass-deployments-cancel cancel" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<message: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({deployment_id: (encode-path-segment $deployment_id)} | format pattern "/greengrass/v2/deployments/{deployment_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a component. Components are software that run on Greengrass core devices. After you develop and test a component on your core device, you can use this operation to upload your component to IoT Greengrass. Then, you can deploy the component to other core devices. You can use this operation to do the following: Create components from recipes Create a component from a recipe, which is a file that defines the component's metadata, parameters, dependencies, lifecycle, artifacts, and platform capability. For more information, see IoT Greengrass component recipe reference (https://docs.aws.amazon.com/greengrass/v2/developerguide/component-recipe-reference.html) in the IoT Greengrass V2 Developer Guide. To create a component from a recipe, specify inlineRecipe when you call this operation. Create components from Lambda functions Create a component from an Lambda function that runs on IoT Greengrass. This creates a recipe and artifacts from the Lambda function's deployment package. You can use this operation to migrate Lambda functions from IoT Greengrass V1 to IoT Greengrass V2. This function only accepts Lambda functions that use the following runtimes: Python 2.7 – python2.7 Python 3.7 – python3.7 Python 3.8 – python3.8 Python 3.9 – python3.9 Java 8 – java8 Java 11 – java11 Node.js 10 – nodejs10.x Node.js 12 – nodejs12.x Node.js 14 – nodejs14.x To create a component from a Lambda function, specify lambdaFunction when you call this operation. IoT Greengrass currently supports Lambda functions on only Linux core devices.
#
# POST /greengrass/v2/createComponentVersion
# operationId: CreateComponentVersion
# --lambdaFunction shape: {lambdaArn?: any, componentName?: any, componentVersion?: any, componentPlatforms?: any, componentDependencies?: any, componentLambdaParameters?: any}
export def "greengrass-create-component-version create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --inline-recipe: string # The recipe to use to create the component. The recipe defines the component's metadata, parameters, dependencies, lifecycle, artifacts, and platform compatibility. You must specify either inlineRecipe or lambdaFunction.
  --lambda-function: record # Contains information about an Lambda function to import to create a component. — shape: {lambdaArn?: any, componentName?: any, componentVersion?: any, componentPlatforms?: any, componentDependencies?: any, componentLambdaParameters?: any}
  --tags: record # A list of key-value pairs that contain metadata for the resource. For more information, see Tag your resources (https://docs.aws.amazon.com/greengrass/v2/developerguide/tag-resources.html) in the IoT Greengrass V2 Developer Guide.
  --client-token: string # A unique, case-sensitive identifier that you can provide to ensure that the request is idempotent. Idempotency means that the request is successfully processed only once, even if you send the request multiple times. When a request succeeds, and you specify the same client token for subsequent successful requests, the IoT Greengrass V2 service returns the successful response that it caches from the previous request. IoT Greengrass V2 caches successful responses for idempotent requests for up to 8 hours.
]: any -> record<arn: record, componentName: record, componentVersion: record, creationTimestamp: record, status: record<componentState: record, message: record, errors: record, vendorGuidance: record, vendorGuidanceMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/greengrass/v2/createComponentVersion")
  let req_body = {"inlineRecipe": $inline_recipe, "lambdaFunction": $lambda_function, "tags": $tags, "clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a continuous deployment for a target, which is a Greengrass core device or group of core devices. When you add a new core device to a group of core devices that has a deployment, IoT Greengrass deploys that group's deployment to the new device. You can define one deployment for each target. When you create a new deployment for a target that has an existing deployment, you replace the previous deployment. IoT Greengrass applies the new deployment to the target devices. Every deployment has a revision number that indicates how many deployment revisions you define for a target. Use this operation to create a new revision of an existing deployment. For more information, see the Create deployments (https://docs.aws.amazon.com/greengrass/v2/developerguide/create-deployments.html) in the IoT Greengrass V2 Developer Guide.
#
# POST /greengrass/v2/deployments
# operationId: CreateDeployment
# --iotJobConfiguration shape: {jobExecutionsRolloutConfig?: any, abortConfig?: any, timeoutConfig?: any}
# --deploymentPolicies shape: {failureHandlingPolicy?: any, componentUpdatePolicy?: any, configurationValidationPolicy?: any}
export def "greengrass-deployments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  target_arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the target IoT thing or thing group. When creating a subdeployment, the targetARN can only be a thing group.
  --deployment-name: string # The name of the deployment.
  --components: record # The components to deploy. This is a dictionary, where each key is the name of a component, and each key's value is the version and configuration to deploy for that component.
  --iot-job-configuration: record # Contains information about an IoT job configuration. — shape: {jobExecutionsRolloutConfig?: any, abortConfig?: any, timeoutConfig?: any}
  --deployment-policies: record # Contains information about policies that define how a deployment updates components and handles failure. — shape: {failureHandlingPolicy?: any, componentUpdatePolicy?: any, configurationValidationPolicy?: any}
  --parent-target-arn: string # The parent deployment's target ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) within a subdeployment.
  --tags: record # A list of key-value pairs that contain metadata for the resource. For more information, see Tag your resources (https://docs.aws.amazon.com/greengrass/v2/developerguide/tag-resources.html) in the IoT Greengrass V2 Developer Guide.
  --client-token: string # A unique, case-sensitive identifier that you can provide to ensure that the request is idempotent. Idempotency means that the request is successfully processed only once, even if you send the request multiple times. When a request succeeds, and you specify the same client token for subsequent successful requests, the IoT Greengrass V2 service returns the successful response that it caches from the previous request. IoT Greengrass V2 caches successful responses for idempotent requests for up to 8 hours.
]: any -> record<deploymentId: record, iotJobId: record, iotJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/greengrass/v2/deployments")
  let req_body = {"targetArn": $target_arn, "deploymentName": $deployment_name, "components": $components, "iotJobConfiguration": $iot_job_configuration, "deploymentPolicies": $deployment_policies, "parentTargetArn": $parent_target_arn, "tags": $tags, "clientToken": $client_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a paginated list of deployments.
#
# GET /greengrass/v2/deployments
# operationId: ListDeployments
export def "greengrass-deployments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the target IoT thing or thing group.
  --history-filter: string@history-filter-completer # The filter for the list of deployments. Choose one of the following options: ALL – The list includes all deployments. LATEST_ONLY – The list includes only the latest revision of each deployment. Default: LATEST_ONLY
  --parent-target-arn: string # The parent deployment's target ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) within a subdeployment.
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<deployments: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetArn" $target_arn "scalar") (serialize-qp "historyFilter" $history_filter "scalar") (serialize-qp "parentTargetArn" $parent_target_arn "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/greengrass/v2/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a version of a component from IoT Greengrass. This operation deletes the component's recipe and artifacts. As a result, deployments that refer to this component version will fail. If you have deployments that use this component version, you can remove the component from the deployment or update the deployment to use a valid version.
#
# DELETE /greengrass/v2/components/{arn}
# operationId: DeleteComponent
export def "greengrass-components delete" [
  arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
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
  let full_url = (build-url $base ({arn: (encode-path-segment $arn)} | format pattern "/greengrass/v2/components/{arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the recipe for a version of a component.
#
# GET /greengrass/v2/components/{arn}
# operationId: GetComponent
export def "greengrass-components get" [
  arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recipe-output-format: string@recipe-output-format-completer # The format of the recipe.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<recipeOutputFormat: record, recipe: record, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recipeOutputFormat" $recipe_output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({arn: (encode-path-segment $arn)} | format pattern "/greengrass/v2/components/{arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Greengrass core device, which is an IoT thing. This operation removes the core device from the list of core devices. This operation doesn't delete the IoT thing. For more information about how to delete the IoT thing, see DeleteThing (https://docs.aws.amazon.com/iot/latest/apireference/API_DeleteThing.html) in the IoT API Reference.
#
# DELETE /greengrass/v2/coreDevices/{coreDeviceThingName}
# operationId: DeleteCoreDevice
export def "greengrass-core-devices delete" [
  core_device_thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
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
  let full_url = (build-url $base ({core_device_thing_name: (encode-path-segment $core_device_thing_name)} | format pattern "/greengrass/v2/coreDevices/{core_device_thing_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves metadata for a Greengrass core device. IoT Greengrass relies on individual devices to send status updates to the Amazon Web Services Cloud. If the IoT Greengrass Core software isn't running on the device, or if device isn't connected to the Amazon Web Services Cloud, then the reported status of that device might not reflect its current status. The status timestamp indicates when the device status was last updated. Core devices send status updates at the following times: When the IoT Greengrass Core software starts When the core device receives a deployment from the Amazon Web Services Cloud When the status of any component on the core device becomes BROKEN At a regular interval that you can configure (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-nucleus-component.html#greengrass-nucleus-component-configuration-fss), which defaults to 24 hours For IoT Greengrass Core v2.7.0, the core device sends status updates upon local deployment and cloud deployment
#
# GET /greengrass/v2/coreDevices/{coreDeviceThingName}
# operationId: GetCoreDevice
export def "greengrass-core-devices get" [
  core_device_thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<coreDeviceThingName: record, coreVersion: record, platform: record, architecture: record, status: record, lastStatusUpdateTimestamp: record, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({core_device_thing_name: (encode-path-segment $core_device_thing_name)} | format pattern "/greengrass/v2/coreDevices/{core_device_thing_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a deployment. To delete an active deployment, you must first cancel it. For more information, see CancelDeployment (https://docs.aws.amazon.com/iot/latest/apireference/API_CancelDeployment.html). Deleting a deployment doesn't affect core devices that run that deployment, because core devices store the deployment's configuration on the device. Additionally, core devices can roll back to a previous deployment that has been deleted.
#
# DELETE /greengrass/v2/deployments/{deploymentId}
# operationId: DeleteDeployment
export def "greengrass-deployments delete" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
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
  let full_url = (build-url $base ({deployment_id: (encode-path-segment $deployment_id)} | format pattern "/greengrass/v2/deployments/{deployment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a deployment. Deployments define the components that run on Greengrass core devices.
#
# GET /greengrass/v2/deployments/{deploymentId}
# operationId: GetDeployment
export def "greengrass-deployments get" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<targetArn: record, revisionId: record, deploymentId: record, deploymentName: record, deploymentStatus: record, iotJobId: record, iotJobArn: record, components: record, deploymentPolicies: record<failureHandlingPolicy: record, componentUpdatePolicy: record<timeoutInSeconds: record, action: record>, configurationValidationPolicy: record<timeoutInSeconds: record>>, iotJobConfiguration: record<jobExecutionsRolloutConfig: record<exponentialRate: record, maximumPerMinute: record>, abortConfig: record<criteriaList: record>, timeoutConfig: record<inProgressTimeoutInMinutes: record>>, creationTimestamp: record, isLatestForTarget: record, parentTargetArn: record, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({deployment_id: (encode-path-segment $deployment_id)} | format pattern "/greengrass/v2/deployments/{deployment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves metadata for a version of a component.
#
# GET /greengrass/v2/components/{arn}/metadata
# operationId: DescribeComponent
export def "greengrass-components-metadata get" [
  arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<arn: record, componentName: record, componentVersion: record, creationTimestamp: record, publisher: record, description: record, status: record<componentState: record, message: record, errors: record, vendorGuidance: record, vendorGuidanceMessage: record>, platforms: record, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({arn: (encode-path-segment $arn)} | format pattern "/greengrass/v2/components/{arn}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pre-signed URL to download a public or a Lambda component artifact. Core devices call this operation to identify the URL that they can use to download an artifact to install.
#
# GET /greengrass/v2/components/{arn}/artifacts/{artifactName}
# operationId: GetComponentVersionArtifact
export def "greengrass-components-artifacts get-version" [
  arn: string
  artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<preSignedUrl: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({arn: (encode-path-segment $arn), artifact_name: (encode-path-segment $artifact_name)} | format pattern "/greengrass/v2/components/{arn}/artifacts/{artifact_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves connectivity information for a Greengrass core device. Connectivity information includes endpoints and ports where client devices can connect to an MQTT broker on the core device. When a client device calls the IoT Greengrass discovery API (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-discover-api.html), IoT Greengrass returns connectivity information for all of the core devices where the client device can connect. For more information, see Connect client devices to core devices (https://docs.aws.amazon.com/greengrass/v2/developerguide/connect-client-devices.html) in the IoT Greengrass Version 2 Developer Guide.
#
# GET /greengrass/things/{thingName}/connectivityInfo
# operationId: GetConnectivityInfo
export def "greengrass-things-connectivity-info get" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<connectivityInfo: record, message: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({thing_name: (encode-path-segment $thing_name)} | format pattern "/greengrass/things/{thing_name}/connectivityInfo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates connectivity information for a Greengrass core device. Connectivity information includes endpoints and ports where client devices can connect to an MQTT broker on the core device. When a client device calls the IoT Greengrass discovery API (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-discover-api.html), IoT Greengrass returns connectivity information for all of the core devices where the client device can connect. For more information, see Connect client devices to core devices (https://docs.aws.amazon.com/greengrass/v2/developerguide/connect-client-devices.html) in the IoT Greengrass Version 2 Developer Guide.
#
# PUT /greengrass/things/{thingName}/connectivityInfo
# operationId: UpdateConnectivityInfo
# --ConnectivityInfo item shape: {id?: any, hostAddress?: any, portNumber?: any, metadata?: any}
export def "greengrass-things-connectivity-info update" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  connectivity_info: list # The connectivity information for the core device. — item shape: {id?: any, hostAddress?: any, portNumber?: any, metadata?: any}
]: any -> record<version: record, message: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({thing_name: (encode-path-segment $thing_name)} | format pattern "/greengrass/things/{thing_name}/connectivityInfo"))
  let req_body = {"ConnectivityInfo": $connectivity_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a paginated list of client devices that are associated with a core device.
#
# GET /greengrass/v2/coreDevices/{coreDeviceThingName}/associatedClientDevices
# operationId: ListClientDevicesAssociatedWithCoreDevice
export def "greengrass-core-devices-associated-client-devices list" [
  core_device_thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<associatedClientDevices: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({core_device_thing_name: (encode-path-segment $core_device_thing_name)} | format pattern "/greengrass/v2/coreDevices/{core_device_thing_name}/associatedClientDevices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of all versions for a component. Greater versions are listed first.
#
# GET /greengrass/v2/components/{arn}/versions
# operationId: ListComponentVersions
export def "greengrass-components-versions list" [
  arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<componentVersions: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({arn: (encode-path-segment $arn)} | format pattern "/greengrass/v2/components/{arn}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of component summaries. This list includes components that you have permission to view.
#
# GET /greengrass/v2/components
# operationId: ListComponents
export def "greengrass-components list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer # The scope of the components to list. Default: PRIVATE
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<components: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/greengrass/v2/components" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of Greengrass core devices. IoT Greengrass relies on individual devices to send status updates to the Amazon Web Services Cloud. If the IoT Greengrass Core software isn't running on the device, or if device isn't connected to the Amazon Web Services Cloud, then the reported status of that device might not reflect its current status. The status timestamp indicates when the device status was last updated. Core devices send status updates at the following times: When the IoT Greengrass Core software starts When the core device receives a deployment from the Amazon Web Services Cloud When the status of any component on the core device becomes BROKEN At a regular interval that you can configure (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-nucleus-component.html#greengrass-nucleus-component-configuration-fss), which defaults to 24 hours For IoT Greengrass Core v2.7.0, the core device sends status updates upon local deployment and cloud deployment
#
# GET /greengrass/v2/coreDevices
# operationId: ListCoreDevices
export def "greengrass-core-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --thing-group-arn: string # The ARN (https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) of the IoT thing group by which to filter. If you specify this parameter, the list includes only core devices that have successfully deployed a deployment that targets the thing group. When you remove a core device from a thing group, the list continues to include that core device.
  --status: string@status-completer # The core device status by which to filter. If you specify this parameter, the list includes only core devices that have this status. Choose one of the following options: HEALTHY – The IoT Greengrass Core software and all components run on the core device without issue. UNHEALTHY – The IoT Greengrass Core software or a component is in a failed state on the core device.
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<coreDevices: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thingGroupArn" $thing_group_arn "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/greengrass/v2/coreDevices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of deployment jobs that IoT Greengrass sends to Greengrass core devices.
#
# GET /greengrass/v2/coreDevices/{coreDeviceThingName}/effectiveDeployments
# operationId: ListEffectiveDeployments
export def "greengrass-core-devices-effective-deployments list" [
  core_device_thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<effectiveDeployments: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({core_device_thing_name: (encode-path-segment $core_device_thing_name)} | format pattern "/greengrass/v2/coreDevices/{core_device_thing_name}/effectiveDeployments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a paginated list of the components that a Greengrass core device runs. By default, this list doesn't include components that are deployed as dependencies of other components. To include dependencies in the response, set the topologyFilter parameter to ALL. IoT Greengrass relies on individual devices to send status updates to the Amazon Web Services Cloud. If the IoT Greengrass Core software isn't running on the device, or if device isn't connected to the Amazon Web Services Cloud, then the reported status of that device might not reflect its current status. The status timestamp indicates when the device status was last updated. Core devices send status updates at the following times: When the IoT Greengrass Core software starts When the core device receives a deployment from the Amazon Web Services Cloud When the status of any component on the core device becomes BROKEN At a regular interval that you can configure (https://docs.aws.amazon.com/greengrass/v2/developerguide/greengrass-nucleus-component.html#greengrass-nucleus-component-configuration-fss), which defaults to 24 hours For IoT Greengrass Core v2.7.0, the core device sends status updates upon local deployment and cloud deployment
#
# GET /greengrass/v2/coreDevices/{coreDeviceThingName}/installedComponents
# operationId: ListInstalledComponents
export def "greengrass-core-devices-installed-components list" [
  core_device_thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to be returned per paginated request.
  --next-token: string # The token to be used for the next set of paginated results.
  --topology-filter: string@topology-filter-completer # The filter for the list of components. Choose from the following options: ALL – The list includes all components installed on the core device. ROOT – The list includes only root components, which are components that you specify in a deployment. When you choose this option, the list doesn't include components that the core device installs as dependencies of other components. Default: ROOT
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<installedComponents: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "topologyFilter" $topology_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({core_device_thing_name: (encode-path-segment $core_device_thing_name)} | format pattern "/greengrass/v2/coreDevices/{core_device_thing_name}/installedComponents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the list of tags for an IoT Greengrass resource.
#
# GET /tags/{resourceArn}
# operationId: ListTagsForResource
export def "tags list-for-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds tags to an IoT Greengrass resource. If a tag already exists for the resource, this operation updates the tag's value.
#
# POST /tags/{resourceArn}
# operationId: TagResource
export def "tags tag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # A list of key-value pairs that contain metadata for the resource. For more information, see Tag your resources (https://docs.aws.amazon.com/greengrass/v2/developerguide/tag-resources.html) in the IoT Greengrass V2 Developer Guide.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a list of components that meet the component, version, and platform requirements of a deployment. Greengrass core devices call this operation when they receive a deployment to identify the components to install. This operation identifies components that meet all dependency requirements for a deployment. If the requirements conflict, then this operation returns an error and the deployment fails. For example, this occurs if component A requires version >2.0.0 and component B requires version <2.0.0 of a component dependency. When you specify the component candidates to resolve, IoT Greengrass compares each component's digest from the core device with the component's digest in the Amazon Web Services Cloud. If the digests don't match, then IoT Greengrass specifies to use the version from the Amazon Web Services Cloud. To use this operation, you must use the data plane API endpoint and authenticate with an IoT device certificate. For more information, see IoT Greengrass endpoints and quotas (https://docs.aws.amazon.com/general/latest/gr/greengrass.html).
#
# POST /greengrass/v2/resolveComponentCandidates
# operationId: ResolveComponentCandidates
# --platform shape: {name?: any, attributes?: any}
# --componentCandidates item shape: {componentName?: any, componentVersion?: any, versionRequirements?: any}
export def "greengrass-resolve-component-candidates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --platform: record # Contains information about a platform that a component supports. — shape: {name?: any, attributes?: any}
  --component-candidates: list # The list of components to resolve. — item shape: {componentName?: any, componentVersion?: any, versionRequirements?: any}
]: any -> record<resolvedComponentVersions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/greengrass/v2/resolveComponentCandidates")
  let req_body = {"platform": $platform, "componentCandidates": $component_candidates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes a tag from an IoT Greengrass resource.
#
# DELETE /tags/{resourceArn}#tagKeys
# operationId: UntagResource
export def "tags untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # A list of keys for tags to remove from the resource.
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
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}#tagKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
