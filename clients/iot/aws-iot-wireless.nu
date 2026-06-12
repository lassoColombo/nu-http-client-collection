# Auto-generated client for AWS IoT Wireless v2020-11-22
# Source: https://api.apis.guru/v2/specs/amazonaws.com/iotwireless/2020-11-22/openapi.json
# Auth: --token flag or $env.AWS_IOT_WIRELESS_TOKEN

const BASE_URL = "http://api.iotwireless.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_IOT_WIRELESS_TOKEN | default "" }
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

def base-url-completer [] { ["http://api.iotwireless.us-east-1.amazonaws.com" "http://api.iotwireless.us-east-2.amazonaws.com" "http://api.iotwireless.us-west-1.amazonaws.com" "http://api.iotwireless.us-west-2.amazonaws.com" "http://api.iotwireless.us-gov-west-1.amazonaws.com" "http://api.iotwireless.us-gov-east-1.amazonaws.com" "http://api.iotwireless.ca-central-1.amazonaws.com" "http://api.iotwireless.eu-north-1.amazonaws.com" "http://api.iotwireless.eu-west-1.amazonaws.com" "http://api.iotwireless.eu-west-2.amazonaws.com" "http://api.iotwireless.eu-west-3.amazonaws.com" "http://api.iotwireless.eu-central-1.amazonaws.com" "http://api.iotwireless.eu-south-1.amazonaws.com" "http://api.iotwireless.af-south-1.amazonaws.com" "http://api.iotwireless.ap-northeast-1.amazonaws.com" "http://api.iotwireless.ap-northeast-2.amazonaws.com" "http://api.iotwireless.ap-northeast-3.amazonaws.com" "http://api.iotwireless.ap-southeast-1.amazonaws.com" "http://api.iotwireless.ap-southeast-2.amazonaws.com" "http://api.iotwireless.ap-east-1.amazonaws.com" "http://api.iotwireless.ap-south-1.amazonaws.com" "http://api.iotwireless.sa-east-1.amazonaws.com" "http://api.iotwireless.me-south-1.amazonaws.com" "https://api.iotwireless.us-east-1.amazonaws.com" "https://api.iotwireless.us-east-2.amazonaws.com" "https://api.iotwireless.us-west-1.amazonaws.com" "https://api.iotwireless.us-west-2.amazonaws.com" "https://api.iotwireless.us-gov-west-1.amazonaws.com" "https://api.iotwireless.us-gov-east-1.amazonaws.com" "https://api.iotwireless.ca-central-1.amazonaws.com" "https://api.iotwireless.eu-north-1.amazonaws.com" "https://api.iotwireless.eu-west-1.amazonaws.com" "https://api.iotwireless.eu-west-2.amazonaws.com" "https://api.iotwireless.eu-west-3.amazonaws.com" "https://api.iotwireless.eu-central-1.amazonaws.com" "https://api.iotwireless.eu-south-1.amazonaws.com" "https://api.iotwireless.af-south-1.amazonaws.com" "https://api.iotwireless.ap-northeast-1.amazonaws.com" "https://api.iotwireless.ap-northeast-2.amazonaws.com" "https://api.iotwireless.ap-northeast-3.amazonaws.com" "https://api.iotwireless.ap-southeast-1.amazonaws.com" "https://api.iotwireless.ap-southeast-2.amazonaws.com" "https://api.iotwireless.ap-east-1.amazonaws.com" "https://api.iotwireless.ap-south-1.amazonaws.com" "https://api.iotwireless.sa-east-1.amazonaws.com" "https://api.iotwireless.me-south-1.amazonaws.com" "http://api.iotwireless.cn-north-1.amazonaws.com.cn" "http://api.iotwireless.cn-northwest-1.amazonaws.com.cn" "https://api.iotwireless.cn-north-1.amazonaws.com.cn" "https://api.iotwireless.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def ExpressionType-completer [] { ["MqttTopic" "RuleName"] }
def deviceProfileType-completer [] { ["LoRaWAN" "Sidewalk"] }
def Type-completer [] { ["LoRaWAN" "Sidewalk"] }
def Positioning-completer [] { ["Disabled" "Enabled"] }
def wirelessDeviceType-completer [] { ["LoRaWAN" "Sidewalk"] }
def taskDefinitionType-completer [] { ["UPDATE"] }
def WirelessDeviceType-completer [] { ["LoRaWAN" "Sidewalk"] }
def partnerType-completer [] { ["Sidewalk"] }
def DefaultLogLevel-completer [] { ["DISABLED" "ERROR" "INFO"] }
def resourceType-completer [] { ["WirelessDevice" "WirelessGateway"] }
def identifierType-completer [] { ["DevEui" "GatewayEui" "PartnerAccountId" "WirelessDeviceId" "WirelessGatewayId"] }
def LogLevel-completer [] { ["DISABLED" "ERROR" "INFO"] }
def serviceType-completer [] { ["CUPS" "LNS"] }
def identifierType-completer-1 [] { ["DevEui" "SidewalkManufacturingSn" "ThingName" "WirelessDeviceId"] }
def identifierType-completer-2 [] { ["GatewayEui" "ThingName" "WirelessGatewayId"] }
def status-completer [] { ["FAILED" "INITIALIZED" "ONBOARDED" "PENDING"] }
def resourceType-completer-1 [] { ["SidewalkAccount" "WirelessDevice" "WirelessGateway"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "partner-accounts AssociateAwsAccountWithPartnerAccount" } } | get name | first)
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

# Associates a partner account with your AWS account.
#
# POST /partner-accounts
# operationId: AssociateAwsAccountWithPartnerAccount
# --Sidewalk shape: {AmazonId?: any, AppServerPrivateKey?: any}
# --Tags item shape: {Key: any, Value: any}
export def "partner-accounts AssociateAwsAccountWithPartnerAccount" [
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
  Sidewalk: record # Information about a Sidewalk account. — shape: {AmazonId?: any, AppServerPrivateKey?: any}
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
]: any -> record<Sidewalk: record<AmazonId: record, AppServerPrivateKey: record>, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner-accounts")
  let body = {Sidewalk: $Sidewalk, ClientRequestToken: $ClientRequestToken, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the partner accounts associated with your AWS account.
#
# GET /partner-accounts
# operationId: ListPartnerAccounts
export def "partner-accounts ListPartnerAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --maxResults: int # The maximum number of results to return in this operation.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, Sidewalk: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/partner-accounts" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associate a multicast group with a FUOTA task.
#
# PUT /fuota-tasks/{Id}/multicast-group
# operationId: AssociateMulticastGroupWithFuotaTask
export def "fuota-tasks-multicast-group AssociateMulticastGroupWithFuotaTask" [
  Id: string
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
  MulticastGroupId: string # The ID of the multicast group.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fuota-tasks/($Id)/multicast-group")
  let body = {MulticastGroupId: $MulticastGroupId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Associate a wireless device with a FUOTA task.
#
# PUT /fuota-tasks/{Id}/wireless-device
# operationId: AssociateWirelessDeviceWithFuotaTask
export def "fuota-tasks-wireless-device AssociateWirelessDeviceWithFuotaTask" [
  Id: string
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
  WirelessDeviceId: string # The ID of the wireless device.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fuota-tasks/($Id)/wireless-device")
  let body = {WirelessDeviceId: $WirelessDeviceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Associates a wireless device with a multicast group.
#
# PUT /multicast-groups/{Id}/wireless-device
# operationId: AssociateWirelessDeviceWithMulticastGroup
export def "multicast-groups-wireless-device AssociateWirelessDeviceWithMulticastGroup" [
  Id: string
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
  WirelessDeviceId: string # The ID of the wireless device.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/multicast-groups/($Id)/wireless-device")
  let body = {WirelessDeviceId: $WirelessDeviceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Associates a wireless device with a thing.
#
# PUT /wireless-devices/{Id}/thing
# operationId: AssociateWirelessDeviceWithThing
export def "wireless-devices-thing AssociateWirelessDeviceWithThing" [
  Id: string
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
  ThingArn: string # The ARN of the thing to associate with the wireless device.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-devices/($Id)/thing")
  let body = {ThingArn: $ThingArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disassociates a wireless device from its currently associated thing.
#
# DELETE /wireless-devices/{Id}/thing
# operationId: DisassociateWirelessDeviceFromThing
export def "wireless-devices-thing DisassociateWirelessDeviceFromThing" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-devices/($Id)/thing")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associates a wireless gateway with a certificate.
#
# PUT /wireless-gateways/{Id}/certificate
# operationId: AssociateWirelessGatewayWithCertificate
export def "wireless-gateways-certificate AssociateWirelessGatewayWithCertificate" [
  Id: string
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
  IotCertificateId: string # The ID of the certificate to associate with the wireless gateway.
]: any -> record<IotCertificateId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)/certificate")
  let body = {IotCertificateId: $IotCertificateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disassociates a wireless gateway from its currently associated certificate.
#
# DELETE /wireless-gateways/{Id}/certificate
# operationId: DisassociateWirelessGatewayFromCertificate
export def "wireless-gateways-certificate DisassociateWirelessGatewayFromCertificate" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)/certificate")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the ID of the certificate that is currently associated with a wireless gateway.
#
# GET /wireless-gateways/{Id}/certificate
# operationId: GetWirelessGatewayCertificate
export def "wireless-gateways-certificate GetWirelessGatewayCertificate" [
  Id: string
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
]: nothing -> record<IotCertificateId: record, LoRaWANNetworkServerCertificateId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)/certificate")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associates a wireless gateway with a thing.
#
# PUT /wireless-gateways/{Id}/thing
# operationId: AssociateWirelessGatewayWithThing
export def "wireless-gateways-thing AssociateWirelessGatewayWithThing" [
  Id: string
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
  ThingArn: string # The ARN of the thing to associate with the wireless gateway.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)/thing")
  let body = {ThingArn: $ThingArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disassociates a wireless gateway from its currently associated thing.
#
# DELETE /wireless-gateways/{Id}/thing
# operationId: DisassociateWirelessGatewayFromThing
export def "wireless-gateways-thing DisassociateWirelessGatewayFromThing" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)/thing")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancels an existing multicast group session.
#
# DELETE /multicast-groups/{Id}/session
# operationId: CancelMulticastGroupSession
export def "multicast-groups-session CancelMulticastGroupSession" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/multicast-groups/($Id)/session")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a multicast group session.
#
# GET /multicast-groups/{Id}/session
# operationId: GetMulticastGroupSession
export def "multicast-groups-session GetMulticastGroupSession" [
  Id: string
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
]: nothing -> record<LoRaWAN: record<DlDr: int, DlFreq: int, SessionStartTime: string, SessionTimeout: int, PingSlotPeriod: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/multicast-groups/($Id)/session")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts a multicast group session.
#
# PUT /multicast-groups/{Id}/session
# operationId: StartMulticastGroupSession
# --LoRaWAN shape: {DlDr?: int, DlFreq?: int, SessionStartTime?: string, SessionTimeout?: int, PingSlotPeriod?: any}
export def "multicast-groups-session StartMulticastGroupSession" [
  Id: string
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
  LoRaWAN: record # The LoRaWAN information used with the multicast session. — shape: {DlDr?: int, DlFreq?: int, SessionStartTime?: string, SessionTimeout?: int, PingSlotPeriod?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/multicast-groups/($Id)/session")
  let body = {LoRaWAN: $LoRaWAN} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new destination that maps a device message to an AWS IoT rule.
#
# POST /destinations
# operationId: CreateDestination
# --Tags item shape: {Key: any, Value: any}
export def "destinations CreateDestination" [
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
  Name: string # The name of the new resource.
  ExpressionType: string@ExpressionType-completer # The type of value in <code>Expression</code>.
  Expression: string # The rule name or topic rule to send messages to.
  --Description: string # The description of the new resource.
  RoleArn: string # The ARN of the IAM Role that authorizes the destination.
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
]: any -> record<Arn: record, Name: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/destinations")
  let body = {Name: $Name, ExpressionType: $ExpressionType, Expression: $Expression, Description: $Description, RoleArn: $RoleArn, Tags: $Tags, ClientRequestToken: $ClientRequestToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the destinations registered to your AWS account.
#
# GET /destinations
# operationId: ListDestinations
export def "destinations ListDestinations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int # The maximum number of results to return in this operation.
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, DestinationList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/destinations" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new device profile.
#
# POST /device-profiles
# operationId: CreateDeviceProfile
# --LoRaWAN shape: {SupportsClassB?: any, ClassBTimeout?: any, PingSlotPeriod?: any, PingSlotDr?: any, PingSlotFreq?: any, SupportsClassC?: any, ClassCTimeout?: any, MacVersion?: any, RegParamsRevision?: any, RxDelay1?: any, RxDrOffset1?: any, RxDataRate2?: any, RxFreq2?: any, FactoryPresetFreqsList?: any, MaxEirp?: any, MaxDutyCycle?: any, RfRegion?: any, SupportsJoin?: any, Supports32BitFCnt?: any}
# --Tags item shape: {Key: any, Value: any}
export def "device-profiles CreateDeviceProfile" [
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
  --Name: string # The name of the new resource.
  --LoRaWAN: record # LoRaWANDeviceProfile object. — shape: {SupportsClassB?: any, ClassBTimeout?: any, PingSlotPeriod?: any, PingSlotDr?: any, PingSlotFreq?: any, SupportsClassC?: any, ClassCTimeout?: any, MacVersion?: any, RegParamsRevision?: any, RxDelay1?: any, RxDrOffset1?: any, RxDataRate2?: any, RxFreq2?: any, FactoryPresetFreqsList?: any, MaxEirp?: any, MaxDutyCycle?: any, RfRegion?: any, SupportsJoin?: any, Supports32BitFCnt?: any}
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
  --Sidewalk: record # Sidewalk object for creating a device profile.
]: any -> record<Arn: record, Id: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device-profiles")
  let body = {Name: $Name, LoRaWAN: $LoRaWAN, Tags: $Tags, ClientRequestToken: $ClientRequestToken, Sidewalk: $Sidewalk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the device profiles registered to your AWS account.
#
# GET /device-profiles
# operationId: ListDeviceProfiles
export def "device-profiles ListDeviceProfiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --maxResults: int # The maximum number of results to return in this operation.
  --deviceProfileType: string@deviceProfileType-completer # A filter to list only device profiles that use this type, which can be <code>LoRaWAN</code> or <code>Sidewalk</code>.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, DeviceProfileList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "deviceProfileType" $deviceProfileType "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/device-profiles" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a FUOTA task.
#
# POST /fuota-tasks
# operationId: CreateFuotaTask
# --LoRaWAN shape: {RfRegion?: "EU868"|"US915"|"AU915"|"AS923-1"|"AS923-2"|"AS923-3"|"AS923-4"|"EU433"|"CN470"|"CN779"|"RU864"|"KR920"|"IN865"}
# --Tags item shape: {Key: any, Value: any}
export def "fuota-tasks CreateFuotaTask" [
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
  --Name: string # The name of a FUOTA task.
  --Description: string # The description of the new resource.
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
  --LoRaWAN: record # The LoRaWAN information used with a FUOTA task. — shape: {RfRegion?: "EU868"|"US915"|"AU915"|"AS923-1"|"AS923-2"|"AS923-3"|"AS923-4"|"EU433"|"CN470"|"CN779"|"RU864"|"KR920"|"IN865"}
  FirmwareUpdateImage: string # The S3 URI points to a firmware update image that is to be used with a FUOTA task.
  FirmwareUpdateRole: string # The firmware update role that is to be used with a FUOTA task.
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
  --RedundancyPercent: int # The percentage of added redundant fragments. For example, if firmware file is 100 bytes and fragment size is 10 bytes, with <code>RedundancyPercent</code> set to 50(%), the final number of encoded fragments is (100 / 10) + (100 / 10 * 50%) = 15.
  --FragmentSizeBytes: int # The size of each fragment in bytes. Currently only supported in fuota tasks with multicast groups.
  --FragmentIntervalMS: int # The interval of sending fragments in milliseconds. Currently the interval will be rounded to the nearest second. Note that this interval only controls the timing when the cloud sends the fragments down. The actual delay of receiving fragments at device side depends on the device's class and the communication delay with the cloud.
]: any -> record<Arn: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fuota-tasks")
  let body = {Name: $Name, Description: $Description, ClientRequestToken: $ClientRequestToken, LoRaWAN: $LoRaWAN, FirmwareUpdateImage: $FirmwareUpdateImage, FirmwareUpdateRole: $FirmwareUpdateRole, Tags: $Tags, RedundancyPercent: $RedundancyPercent, FragmentSizeBytes: $FragmentSizeBytes, FragmentIntervalMS: $FragmentIntervalMS} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the FUOTA tasks registered to your AWS account.
#
# GET /fuota-tasks
# operationId: ListFuotaTasks
export def "fuota-tasks ListFuotaTasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --maxResults: int
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, FuotaTaskList: table<Id: string, Arn: string, Name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fuota-tasks" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a multicast group.
#
# POST /multicast-groups
# operationId: CreateMulticastGroup
# --LoRaWAN shape: {RfRegion?: "EU868"|"US915"|"AU915"|"AS923-1"|"AS923-2"|"AS923-3"|"AS923-4"|"EU433"|"CN470"|"CN779"|"RU864"|"KR920"|"IN865", DlClass?: "ClassB"|"ClassC"}
# --Tags item shape: {Key: any, Value: any}
export def "multicast-groups CreateMulticastGroup" [
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
  --Name: string # The name of the multicast group.
  --Description: string # The description of the new resource.
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
  LoRaWAN: record # The LoRaWAN information that is to be used with the multicast group. — shape: {RfRegion?: "EU868"|"US915"|"AU915"|"AS923-1"|"AS923-2"|"AS923-3"|"AS923-4"|"EU433"|"CN470"|"CN779"|"RU864"|"KR920"|"IN865", DlClass?: "ClassB"|"ClassC"}
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
]: any -> record<Arn: string, Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/multicast-groups")
  let body = {Name: $Name, Description: $Description, ClientRequestToken: $ClientRequestToken, LoRaWAN: $LoRaWAN, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the multicast groups registered to your AWS account.
#
# GET /multicast-groups
# operationId: ListMulticastGroups
export def "multicast-groups ListMulticastGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --maxResults: int
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, MulticastGroupList: table<Id: string, Arn: string, Name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/multicast-groups" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new network analyzer configuration.
#
# POST /network-analyzer-configurations
# operationId: CreateNetworkAnalyzerConfiguration
# --TraceContent shape: {WirelessDeviceFrameInfo?: "ENABLED"|"DISABLED", LogLevel?: "INFO"|"ERROR"|"DISABLED"}
# --Tags item shape: {Key: any, Value: any}
export def "network-analyzer-configurations CreateNetworkAnalyzerConfiguration" [
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
  Name: string # Name of the network analyzer configuration.
  --TraceContent: record # Trace content for your wireless gateway and wireless device resources. — shape: {WirelessDeviceFrameInfo?: "ENABLED"|"DISABLED", LogLevel?: "INFO"|"ERROR"|"DISABLED"}
  --WirelessDevices: list # Wireless device resources to add to the network analyzer configuration. Provide the <code>WirelessDeviceId</code> of the resource to add in the input array.
  --WirelessGateways: list # Wireless gateway resources to add to the network analyzer configuration. Provide the <code>WirelessGatewayId</code> of the resource to add in the input array.
  --Description: string # The description of the new resource.
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
]: any -> record<Arn: record, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/network-analyzer-configurations")
  let body = {Name: $Name, TraceContent: $TraceContent, WirelessDevices: $WirelessDevices, WirelessGateways: $WirelessGateways, Description: $Description, Tags: $Tags, ClientRequestToken: $ClientRequestToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the network analyzer configurations.
#
# GET /network-analyzer-configurations
# operationId: ListNetworkAnalyzerConfigurations
export def "network-analyzer-configurations ListNetworkAnalyzerConfigurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, NetworkAnalyzerConfigurationList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/network-analyzer-configurations" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new service profile.
#
# POST /service-profiles
# operationId: CreateServiceProfile
# --LoRaWAN shape: {AddGwMetadata?: any, DrMin?: any, DrMax?: any, PrAllowed?: any, RaAllowed?: any}
# --Tags item shape: {Key: any, Value: any}
export def "service-profiles CreateServiceProfile" [
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
  --Name: string # The name of the new resource.
  --LoRaWAN: record # LoRaWANServiceProfile object. — shape: {AddGwMetadata?: any, DrMin?: any, DrMax?: any, PrAllowed?: any, RaAllowed?: any}
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
]: any -> record<Arn: record, Id: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/service-profiles")
  let body = {Name: $Name, LoRaWAN: $LoRaWAN, Tags: $Tags, ClientRequestToken: $ClientRequestToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the service profiles registered to your AWS account.
#
# GET /service-profiles
# operationId: ListServiceProfiles
export def "service-profiles ListServiceProfiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --maxResults: int # The maximum number of results to return in this operation.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, ServiceProfileList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/service-profiles" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provisions a wireless device.
#
# POST /wireless-devices
# operationId: CreateWirelessDevice
# --LoRaWAN shape: {DevEui?: any, DeviceProfileId?: any, ServiceProfileId?: any, OtaaV1_1?: any, OtaaV1_0_x?: any, AbpV1_1?: any, AbpV1_0_x?: any, FPorts?: record}
# --Tags item shape: {Key: any, Value: any}
# --Sidewalk shape: {DeviceProfileId?: any}
export def "wireless-devices CreateWirelessDevice" [
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
  Type: string@Type-completer # The wireless device type.
  --Name: string # The name of the new resource.
  --Description: string # The description of the new resource.
  DestinationName: string # The name of the destination to assign to the new wireless device.
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
  --LoRaWAN: record # LoRaWAN object for create functions. — shape: {DevEui?: any, DeviceProfileId?: any, ServiceProfileId?: any, OtaaV1_1?: any, OtaaV1_0_x?: any, AbpV1_1?: any, AbpV1_0_x?: any, FPorts?: record}
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
  --Positioning: string@Positioning-completer # FPort values for the GNSS, stream, and ClockSync functions of the positioning information.
  --Sidewalk: record # Sidewalk object for creating a wireless device. — shape: {DeviceProfileId?: any}
]: any -> record<Arn: record, Id: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wireless-devices")
  let body = {Type: $Type, Name: $Name, Description: $Description, DestinationName: $DestinationName, ClientRequestToken: $ClientRequestToken, LoRaWAN: $LoRaWAN, Tags: $Tags, Positioning: $Positioning, Sidewalk: $Sidewalk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the wireless devices registered to your AWS account.
#
# GET /wireless-devices
# operationId: ListWirelessDevices
export def "wireless-devices ListWirelessDevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int # The maximum number of results to return in this operation.
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --destinationName: string # A filter to list only the wireless devices that use this destination.
  --deviceProfileId: string # A filter to list only the wireless devices that use this device profile.
  --serviceProfileId: string # A filter to list only the wireless devices that use this service profile.
  --wirelessDeviceType: string@wirelessDeviceType-completer # A filter to list only the wireless devices that use this wireless device type.
  --fuotaTaskId: string
  --multicastGroupId: string
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, WirelessDeviceList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "destinationName" $destinationName "scalar") (serialize-qp "deviceProfileId" $deviceProfileId "scalar") (serialize-qp "serviceProfileId" $serviceProfileId "scalar") (serialize-qp "wirelessDeviceType" $wirelessDeviceType "scalar") (serialize-qp "fuotaTaskId" $fuotaTaskId "scalar") (serialize-qp "multicastGroupId" $multicastGroupId "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless-devices" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provisions a wireless gateway.
#
# POST /wireless-gateways
# operationId: CreateWirelessGateway
# --LoRaWAN shape: {GatewayEui?: any, RfRegion?: any, JoinEuiFilters?: list, NetIdFilters?: list, SubBands?: list, Beaconing?: any, MaxEirp?: any}
# --Tags item shape: {Key: any, Value: any}
export def "wireless-gateways CreateWirelessGateway" [
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
  --Name: string # The name of the new resource.
  --Description: string # The description of the new resource.
  LoRaWAN: record # LoRaWANGateway object. — shape: {GatewayEui?: any, RfRegion?: any, JoinEuiFilters?: list, NetIdFilters?: list, SubBands?: list, Beaconing?: any, MaxEirp?: any}
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
]: any -> record<Arn: record, Id: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wireless-gateways")
  let body = {Name: $Name, Description: $Description, LoRaWAN: $LoRaWAN, Tags: $Tags, ClientRequestToken: $ClientRequestToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the wireless gateways registered to your AWS account.
#
# GET /wireless-gateways
# operationId: ListWirelessGateways
export def "wireless-gateways ListWirelessGateways" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --maxResults: int # The maximum number of results to return in this operation.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, WirelessGatewayList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless-gateways" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a task for a wireless gateway.
#
# POST /wireless-gateways/{Id}/tasks
# operationId: CreateWirelessGatewayTask
export def "wireless-gateways-tasks CreateWirelessGatewayTask" [
  Id: string
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
  WirelessGatewayTaskDefinitionId: string # The ID of the WirelessGatewayTaskDefinition.
]: any -> record<WirelessGatewayTaskDefinitionId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)/tasks")
  let body = {WirelessGatewayTaskDefinitionId: $WirelessGatewayTaskDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a wireless gateway task.
#
# DELETE /wireless-gateways/{Id}/tasks
# operationId: DeleteWirelessGatewayTask
export def "wireless-gateways-tasks DeleteWirelessGatewayTask" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)/tasks")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a wireless gateway task.
#
# GET /wireless-gateways/{Id}/tasks
# operationId: GetWirelessGatewayTask
export def "wireless-gateways-tasks GetWirelessGatewayTask" [
  Id: string
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
]: nothing -> record<WirelessGatewayId: record, WirelessGatewayTaskDefinitionId: record, LastUplinkReceivedAt: record, TaskCreatedAt: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)/tasks")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a gateway task definition.
#
# POST /wireless-gateway-task-definitions
# operationId: CreateWirelessGatewayTaskDefinition
# --Update shape: {UpdateDataSource?: any, UpdateDataRole?: any, LoRaWAN?: any}
# --Tags item shape: {Key: any, Value: any}
export def "wireless-gateway-task-definitions CreateWirelessGatewayTaskDefinition" [
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
  --AutoCreateTasks: oneof<nothing, bool> # Whether to automatically create tasks using this task definition for all gateways with the specified current version. If <code>false</code>, the task must me created by calling <code>CreateWirelessGatewayTask</code>.
  --Name: string # The name of the new resource.
  --Update: record # UpdateWirelessGatewayTaskCreate object. — shape: {UpdateDataSource?: any, UpdateDataRole?: any, LoRaWAN?: any}
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
]: any -> record<Id: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wireless-gateway-task-definitions")
  let body = {AutoCreateTasks: $AutoCreateTasks, Name: $Name, Update: $Update, ClientRequestToken: $ClientRequestToken, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the wireless gateway tasks definitions registered to your AWS account.
#
# GET /wireless-gateway-task-definitions
# operationId: ListWirelessGatewayTaskDefinitions
export def "wireless-gateway-task-definitions ListWirelessGatewayTaskDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int # The maximum number of results to return in this operation.
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --taskDefinitionType: string@taskDefinitionType-completer # A filter to list only the wireless gateway task definitions that use this task definition type.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, TaskDefinitions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "taskDefinitionType" $taskDefinitionType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless-gateway-task-definitions" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a destination.
#
# DELETE /destinations/{Name}
# operationId: DeleteDestination
export def "destinations DeleteDestination" [
  Name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/destinations/($Name)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a destination.
#
# GET /destinations/{Name}
# operationId: GetDestination
export def "destinations GetDestination" [
  Name: string
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
]: nothing -> record<Arn: record, Name: record, Expression: record, ExpressionType: record, Description: record, RoleArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/destinations/($Name)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates properties of a destination.
#
# PATCH /destinations/{Name}
# operationId: UpdateDestination
export def "destinations UpdateDestination" [
  Name: string
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
  --ExpressionType: string@ExpressionType-completer # The type of value in <code>Expression</code>.
  --Expression: string # The new rule name or topic rule to send messages to.
  --Description: string # The description of the new resource.
  --RoleArn: string # The ARN of the IAM Role that authorizes the destination.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/destinations/($Name)")
  let body = {ExpressionType: $ExpressionType, Expression: $Expression, Description: $Description, RoleArn: $RoleArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a device profile.
#
# DELETE /device-profiles/{Id}
# operationId: DeleteDeviceProfile
export def "device-profiles DeleteDeviceProfile" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/device-profiles/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a device profile.
#
# GET /device-profiles/{Id}
# operationId: GetDeviceProfile
export def "device-profiles GetDeviceProfile" [
  Id: string
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
]: nothing -> record<Arn: record, Name: record, Id: record, LoRaWAN: record<SupportsClassB: record, ClassBTimeout: record, PingSlotPeriod: record, PingSlotDr: record, PingSlotFreq: record, SupportsClassC: record, ClassCTimeout: record, MacVersion: record, RegParamsRevision: record, RxDelay1: record, RxDrOffset1: record, RxDataRate2: record, RxFreq2: record, FactoryPresetFreqsList: record, MaxEirp: record, MaxDutyCycle: record, RfRegion: record, SupportsJoin: record, Supports32BitFCnt: record>, Sidewalk: record<ApplicationServerPublicKey: record, QualificationStatus: record, DakCertificateMetadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/device-profiles/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a FUOTA task.
#
# DELETE /fuota-tasks/{Id}
# operationId: DeleteFuotaTask
export def "fuota-tasks DeleteFuotaTask" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fuota-tasks/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a FUOTA task.
#
# GET /fuota-tasks/{Id}
# operationId: GetFuotaTask
export def "fuota-tasks GetFuotaTask" [
  Id: string
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
]: nothing -> record<Arn: string, Id: string, Status: string, Name: string, Description: string, LoRaWAN: record<RfRegion: string, StartTime: string>, FirmwareUpdateImage: string, FirmwareUpdateRole: string, CreatedAt: string, RedundancyPercent: int, FragmentSizeBytes: int, FragmentIntervalMS: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fuota-tasks/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts a FUOTA task.
#
# PUT /fuota-tasks/{Id}
# operationId: StartFuotaTask
# --LoRaWAN shape: {StartTime?: string}
export def "fuota-tasks StartFuotaTask" [
  Id: string
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
  --LoRaWAN: record # The LoRaWAN information used to start a FUOTA task. — shape: {StartTime?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fuota-tasks/($Id)")
  let body = {LoRaWAN: $LoRaWAN} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates properties of a FUOTA task.
#
# PATCH /fuota-tasks/{Id}
# operationId: UpdateFuotaTask
# --LoRaWAN shape: {RfRegion?: "EU868"|"US915"|"AU915"|"AS923-1"|"AS923-2"|"AS923-3"|"AS923-4"|"EU433"|"CN470"|"CN779"|"RU864"|"KR920"|"IN865"}
export def "fuota-tasks UpdateFuotaTask" [
  Id: string
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
  --Name: string # The name of a FUOTA task.
  --Description: string # The description of the new resource.
  --LoRaWAN: record # The LoRaWAN information used with a FUOTA task. — shape: {RfRegion?: "EU868"|"US915"|"AU915"|"AS923-1"|"AS923-2"|"AS923-3"|"AS923-4"|"EU433"|"CN470"|"CN779"|"RU864"|"KR920"|"IN865"}
  --FirmwareUpdateImage: string # The S3 URI points to a firmware update image that is to be used with a FUOTA task.
  --FirmwareUpdateRole: string # The firmware update role that is to be used with a FUOTA task.
  --RedundancyPercent: int # The percentage of added redundant fragments. For example, if firmware file is 100 bytes and fragment size is 10 bytes, with <code>RedundancyPercent</code> set to 50(%), the final number of encoded fragments is (100 / 10) + (100 / 10 * 50%) = 15.
  --FragmentSizeBytes: int # The size of each fragment in bytes. Currently only supported in fuota tasks with multicast groups.
  --FragmentIntervalMS: int # The interval of sending fragments in milliseconds. Currently the interval will be rounded to the nearest second. Note that this interval only controls the timing when the cloud sends the fragments down. The actual delay of receiving fragments at device side depends on the device's class and the communication delay with the cloud.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fuota-tasks/($Id)")
  let body = {Name: $Name, Description: $Description, LoRaWAN: $LoRaWAN, FirmwareUpdateImage: $FirmwareUpdateImage, FirmwareUpdateRole: $FirmwareUpdateRole, RedundancyPercent: $RedundancyPercent, FragmentSizeBytes: $FragmentSizeBytes, FragmentIntervalMS: $FragmentIntervalMS} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a multicast group if it is not in use by a fuota task.
#
# DELETE /multicast-groups/{Id}
# operationId: DeleteMulticastGroup
export def "multicast-groups DeleteMulticastGroup" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/multicast-groups/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a multicast group.
#
# GET /multicast-groups/{Id}
# operationId: GetMulticastGroup
export def "multicast-groups GetMulticastGroup" [
  Id: string
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
]: nothing -> record<Arn: string, Id: string, Name: string, Description: string, Status: string, LoRaWAN: record<RfRegion: string, DlClass: string, NumberOfDevicesRequested: int, NumberOfDevicesInGroup: int>, CreatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/multicast-groups/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates properties of a multicast group session.
#
# PATCH /multicast-groups/{Id}
# operationId: UpdateMulticastGroup
# --LoRaWAN shape: {RfRegion?: "EU868"|"US915"|"AU915"|"AS923-1"|"AS923-2"|"AS923-3"|"AS923-4"|"EU433"|"CN470"|"CN779"|"RU864"|"KR920"|"IN865", DlClass?: "ClassB"|"ClassC"}
export def "multicast-groups UpdateMulticastGroup" [
  Id: string
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
  --Name: string # The name of the multicast group.
  --Description: string # The description of the new resource.
  --LoRaWAN: record # The LoRaWAN information that is to be used with the multicast group. — shape: {RfRegion?: "EU868"|"US915"|"AU915"|"AS923-1"|"AS923-2"|"AS923-3"|"AS923-4"|"EU433"|"CN470"|"CN779"|"RU864"|"KR920"|"IN865", DlClass?: "ClassB"|"ClassC"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/multicast-groups/($Id)")
  let body = {Name: $Name, Description: $Description, LoRaWAN: $LoRaWAN} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a network analyzer configuration.
#
# DELETE /network-analyzer-configurations/{ConfigurationName}
# operationId: DeleteNetworkAnalyzerConfiguration
export def "network-analyzer-configurations DeleteNetworkAnalyzerConfiguration" [
  ConfigurationName: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network-analyzer-configurations/($ConfigurationName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get network analyzer configuration.
#
# GET /network-analyzer-configurations/{ConfigurationName}
# operationId: GetNetworkAnalyzerConfiguration
export def "network-analyzer-configurations GetNetworkAnalyzerConfiguration" [
  ConfigurationName: string
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
]: nothing -> record<TraceContent: record<WirelessDeviceFrameInfo: string, LogLevel: string>, WirelessDevices: record, WirelessGateways: record, Description: string, Arn: record, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network-analyzer-configurations/($ConfigurationName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update network analyzer configuration.
#
# PATCH /network-analyzer-configurations/{ConfigurationName}
# operationId: UpdateNetworkAnalyzerConfiguration
# --TraceContent shape: {WirelessDeviceFrameInfo?: "ENABLED"|"DISABLED", LogLevel?: "INFO"|"ERROR"|"DISABLED"}
export def "network-analyzer-configurations UpdateNetworkAnalyzerConfiguration" [
  ConfigurationName: string
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
  --TraceContent: record # Trace content for your wireless gateway and wireless device resources. — shape: {WirelessDeviceFrameInfo?: "ENABLED"|"DISABLED", LogLevel?: "INFO"|"ERROR"|"DISABLED"}
  --WirelessDevicesToAdd: list # Wireless device resources to add to the network analyzer configuration. Provide the <code>WirelessDeviceId</code> of the resource to add in the input array.
  --WirelessDevicesToRemove: list # Wireless device resources to remove from the network analyzer configuration. Provide the <code>WirelessDeviceId</code> of the resources to remove in the input array.
  --WirelessGatewaysToAdd: list # Wireless gateway resources to add to the network analyzer configuration. Provide the <code>WirelessGatewayId</code> of the resource to add in the input array.
  --WirelessGatewaysToRemove: list # Wireless gateway resources to remove from the network analyzer configuration. Provide the <code>WirelessGatewayId</code> of the resources to remove in the input array.
  --Description: string # The description of the new resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network-analyzer-configurations/($ConfigurationName)")
  let body = {TraceContent: $TraceContent, WirelessDevicesToAdd: $WirelessDevicesToAdd, WirelessDevicesToRemove: $WirelessDevicesToRemove, WirelessGatewaysToAdd: $WirelessGatewaysToAdd, WirelessGatewaysToRemove: $WirelessGatewaysToRemove, Description: $Description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove queued messages from the downlink queue.
#
# DELETE /wireless-devices/{Id}/data#messageId
# operationId: DeleteQueuedMessages
export def "wireless-devices-datamessage-id DeleteQueuedMessages" [
  Id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --messageId: string # If message ID is <code>"*"</code>, it cleares the entire downlink queue for a given device, specified by the wireless device ID. Otherwise, the downlink message with the specified message ID will be deleted.
  --WirelessDeviceType: string@WirelessDeviceType-completer # The wireless device type, which can be either Sidewalk or LoRaWAN.
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
  let qp = [(serialize-qp "messageId" $messageId "scalar") (serialize-qp "WirelessDeviceType" $WirelessDeviceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wireless-devices/($Id)/data#messageId" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a service profile.
#
# DELETE /service-profiles/{Id}
# operationId: DeleteServiceProfile
export def "service-profiles DeleteServiceProfile" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/service-profiles/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a service profile.
#
# GET /service-profiles/{Id}
# operationId: GetServiceProfile
export def "service-profiles GetServiceProfile" [
  Id: string
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
]: nothing -> record<Arn: record, Name: record, Id: record, LoRaWAN: record<UlRate: record, UlBucketSize: record, UlRatePolicy: record, DlRate: record, DlBucketSize: record, DlRatePolicy: record, AddGwMetadata: record, DevStatusReqFreq: record, ReportDevStatusBattery: record, ReportDevStatusMargin: record, DrMin: record, DrMax: record, ChannelMask: record, PrAllowed: record, HrAllowed: record, RaAllowed: record, NwkGeoLoc: record, TargetPer: record, MinGwDiversity: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/service-profiles/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a wireless device.
#
# DELETE /wireless-devices/{Id}
# operationId: DeleteWirelessDevice
export def "wireless-devices DeleteWirelessDevice" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-devices/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates properties of a wireless device.
#
# PATCH /wireless-devices/{Id}
# operationId: UpdateWirelessDevice
# --LoRaWAN shape: {DeviceProfileId?: any, ServiceProfileId?: any, AbpV1_1?: any, AbpV1_0_x?: any, FPorts?: any}
export def "wireless-devices UpdateWirelessDevice" [
  Id: string
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
  --DestinationName: string # The name of the new destination for the device.
  --Name: string # The new name of the resource.
  --Description: string # The description of the new resource.
  --LoRaWAN: record # LoRaWAN object for update functions. — shape: {DeviceProfileId?: any, ServiceProfileId?: any, AbpV1_1?: any, AbpV1_0_x?: any, FPorts?: any}
  --Positioning: string@Positioning-completer # FPort values for the GNSS, stream, and ClockSync functions of the positioning information.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-devices/($Id)")
  let body = {DestinationName: $DestinationName, Name: $Name, Description: $Description, LoRaWAN: $LoRaWAN, Positioning: $Positioning} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an import task.
#
# DELETE /wireless_device_import_task/{Id}
# operationId: DeleteWirelessDeviceImportTask
export def "wireless-device-import-task DeleteWirelessDeviceImportTask" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless_device_import_task/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about an import task and count of device onboarding summary information for the import task.
#
# GET /wireless_device_import_task/{Id}
# operationId: GetWirelessDeviceImportTask
export def "wireless-device-import-task GetWirelessDeviceImportTask" [
  Id: string
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
]: nothing -> record<Id: record, Arn: record, DestinationName: record, Sidewalk: record<DeviceCreationFileList: record, Role: record>, CreationTime: record, Status: record, StatusReason: record, InitializedImportedDeviceCount: record, PendingImportedDeviceCount: record, OnboardedImportedDeviceCount: record, FailedImportedDeviceCount: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless_device_import_task/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an import task to add more devices to the task.
#
# PATCH /wireless_device_import_task/{Id}
# operationId: UpdateWirelessDeviceImportTask
# --Sidewalk shape: {DeviceCreationFile?: any}
export def "wireless-device-import-task UpdateWirelessDeviceImportTask" [
  Id: string
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
  Sidewalk: record # Sidewalk object information for updating an import task. — shape: {DeviceCreationFile?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless_device_import_task/($Id)")
  let body = {Sidewalk: $Sidewalk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a wireless gateway.
#
# DELETE /wireless-gateways/{Id}
# operationId: DeleteWirelessGateway
export def "wireless-gateways DeleteWirelessGateway" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates properties of a wireless gateway.
#
# PATCH /wireless-gateways/{Id}
# operationId: UpdateWirelessGateway
export def "wireless-gateways UpdateWirelessGateway" [
  Id: string
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
  --Name: string # The new name of the resource.
  --Description: string # The description of the new resource.
  --JoinEuiFilters: list # A list of JoinEuiRange used by LoRa gateways to filter LoRa frames.
  --NetIdFilters: list # A list of NetId values that are used by LoRa gateways to filter the uplink frames.
  --MaxEirp: float # The MaxEIRP value. (format: float)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)")
  let body = {Name: $Name, Description: $Description, JoinEuiFilters: $JoinEuiFilters, NetIdFilters: $NetIdFilters, MaxEirp: $MaxEirp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a wireless gateway task definition. Deleting this task definition does not affect tasks that are currently in progress.
#
# DELETE /wireless-gateway-task-definitions/{Id}
# operationId: DeleteWirelessGatewayTaskDefinition
export def "wireless-gateway-task-definitions DeleteWirelessGatewayTaskDefinition" [
  Id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateway-task-definitions/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a wireless gateway task definition.
#
# GET /wireless-gateway-task-definitions/{Id}
# operationId: GetWirelessGatewayTaskDefinition
export def "wireless-gateway-task-definitions GetWirelessGatewayTaskDefinition" [
  Id: string
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
]: nothing -> record<AutoCreateTasks: record, Name: record, Update: record<UpdateDataSource: record, UpdateDataRole: record, LoRaWAN: record<UpdateSignature: record, SigKeyCrc: record, CurrentVersion: record, UpdateVersion: record>>, Arn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateway-task-definitions/($Id)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deregister a wireless device from AWS IoT Wireless.
#
# PATCH /wireless-devices/{Identifier}/deregister
# operationId: DeregisterWirelessDevice
export def "wireless-devices-deregister DeregisterWirelessDevice" [
  Identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --WirelessDeviceType: string@WirelessDeviceType-completer # The type of wireless device to deregister from AWS IoT Wireless, which can be <code>LoRaWAN</code> or <code>Sidewalk</code>.
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
  let qp = [(serialize-qp "WirelessDeviceType" $WirelessDeviceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wireless-devices/($Identifier)/deregister" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disassociates your AWS account from a partner account. If <code>PartnerAccountId</code> and <code>PartnerType</code> are <code>null</code>, disassociates your AWS account from all partner accounts.
#
# DELETE /partner-accounts/{PartnerAccountId}#partnerType
# operationId: DisassociateAwsAccountFromPartnerAccount
export def "partner-accounts DisassociateAwsAccountFromPartnerAccount" [
  PartnerAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --partnerType: string@partnerType-completer # The partner type.
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
  let qp = [(serialize-qp "partnerType" $partnerType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/partner-accounts/($PartnerAccountId)#partnerType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a partner account. If <code>PartnerAccountId</code> and <code>PartnerType</code> are <code>null</code>, returns all partner accounts.
#
# GET /partner-accounts/{PartnerAccountId}#partnerType
# operationId: GetPartnerAccount
export def "partner-accounts GetPartnerAccount" [
  PartnerAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --partnerType: string@partnerType-completer # The partner type.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Sidewalk: record<AmazonId: record, Fingerprint: record, Arn: record>, AccountLinked: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partnerType" $partnerType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/partner-accounts/($PartnerAccountId)#partnerType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates properties of a partner account.
#
# PATCH /partner-accounts/{PartnerAccountId}#partnerType
# operationId: UpdatePartnerAccount
# --Sidewalk shape: {AppServerPrivateKey?: any}
export def "partner-accounts UpdatePartnerAccount" [
  PartnerAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --partnerType: string@partnerType-completer # The partner type.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Sidewalk: record # Sidewalk update. — shape: {AppServerPrivateKey?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partnerType" $partnerType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/partner-accounts/($PartnerAccountId)#partnerType" $qp)
  let body = {Sidewalk: $Sidewalk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disassociates a multicast group from a fuota task.
#
# DELETE /fuota-tasks/{Id}/multicast-groups/{MulticastGroupId}
# operationId: DisassociateMulticastGroupFromFuotaTask
export def "fuota-tasks-multicast-groups DisassociateMulticastGroupFromFuotaTask" [
  Id: string
  MulticastGroupId: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fuota-tasks/($Id)/multicast-groups/($MulticastGroupId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disassociates a wireless device from a FUOTA task.
#
# DELETE /fuota-tasks/{Id}/wireless-devices/{WirelessDeviceId}
# operationId: DisassociateWirelessDeviceFromFuotaTask
export def "fuota-tasks-wireless-devices DisassociateWirelessDeviceFromFuotaTask" [
  Id: string
  WirelessDeviceId: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fuota-tasks/($Id)/wireless-devices/($WirelessDeviceId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disassociates a wireless device from a multicast group.
#
# DELETE /multicast-groups/{Id}/wireless-devices/{WirelessDeviceId}
# operationId: DisassociateWirelessDeviceFromMulticastGroup
export def "multicast-groups-wireless-devices DisassociateWirelessDeviceFromMulticastGroup" [
  Id: string
  WirelessDeviceId: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/multicast-groups/($Id)/wireless-devices/($WirelessDeviceId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the event configuration based on resource types.
#
# GET /event-configurations-resource-types
# operationId: GetEventConfigurationByResourceTypes
export def "event-configurations-resource-types GetEventConfigurationByResourceTypes" [
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
]: nothing -> record<DeviceRegistrationState: record<Sidewalk: record<WirelessDeviceEventTopic: record>>, Proximity: record<Sidewalk: record<WirelessDeviceEventTopic: record>>, Join: record<LoRaWAN: record<WirelessDeviceEventTopic: record>>, ConnectionStatus: record<LoRaWAN: record<WirelessGatewayEventTopic: record>>, MessageDeliveryStatus: record<Sidewalk: record<WirelessDeviceEventTopic: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/event-configurations-resource-types")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the event configuration based on resource types.
#
# PATCH /event-configurations-resource-types
# operationId: UpdateEventConfigurationByResourceTypes
# --DeviceRegistrationState shape: {Sidewalk?: any}
# --Proximity shape: {Sidewalk?: any}
# --Join shape: {LoRaWAN?: any}
# --ConnectionStatus shape: {LoRaWAN?: any}
# --MessageDeliveryStatus shape: {Sidewalk?: record}
export def "event-configurations-resource-types UpdateEventConfigurationByResourceTypes" [
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
  --DeviceRegistrationState: record # Device registration state resource type event configuration object for enabling or disabling topic. — shape: {Sidewalk?: any}
  --Proximity: record # Proximity resource type event configuration object for enabling or disabling topic. — shape: {Sidewalk?: any}
  --Join: record # Join resource type event configuration object for enabling or disabling topic. — shape: {LoRaWAN?: any}
  --ConnectionStatus: record # Connection status resource type event configuration object for enabling or disabling topic. — shape: {LoRaWAN?: any}
  --MessageDeliveryStatus: record # Message delivery status resource type event configuration object for enabling or disabling relevant topic. — shape: {Sidewalk?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/event-configurations-resource-types")
  let body = {DeviceRegistrationState: $DeviceRegistrationState, Proximity: $Proximity, Join: $Join, ConnectionStatus: $ConnectionStatus, MessageDeliveryStatus: $MessageDeliveryStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns current default log levels or log levels by resource types. Based on resource types, log levels can be for wireless device log options or wireless gateway log options.
#
# GET /log-levels
# operationId: GetLogLevelsByResourceTypes
export def "log-levels GetLogLevelsByResourceTypes" [
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
]: nothing -> record<DefaultLogLevel: string, WirelessGatewayLogOptions: table<Type: string, LogLevel: string, Events: list>, WirelessDeviceLogOptions: table<Type: record, LogLevel: string, Events: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/log-levels")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes the log-level overrides for all resources; both wireless devices and wireless gateways.
#
# DELETE /log-levels
# operationId: ResetAllResourceLogLevels
export def "log-levels ResetAllResourceLogLevels" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/log-levels")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set default log level, or log levels by resource types. This can be for wireless device log options or wireless gateways log options and is used to control the log messages that'll be displayed in CloudWatch.
#
# POST /log-levels
# operationId: UpdateLogLevelsByResourceTypes
# --WirelessDeviceLogOptions item shape: {Type: any, LogLevel: "INFO"|"ERROR"|"DISABLED", Events?: list}
# --WirelessGatewayLogOptions item shape: {Type: "LoRaWAN", LogLevel: "INFO"|"ERROR"|"DISABLED", Events?: list}
export def "log-levels UpdateLogLevelsByResourceTypes" [
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
  --DefaultLogLevel: string@DefaultLogLevel-completer # The log level for a log message. The log levels can be disabled, or set to <code>ERROR</code> to display less verbose logs containing only error information, or to <code>INFO</code> for more detailed logs.
  --WirelessDeviceLogOptions: list # The list of wireless device log options. — item shape: {Type: any, LogLevel: "INFO"|"ERROR"|"DISABLED", Events?: list}
  --WirelessGatewayLogOptions: list # The list of wireless gateway log options. — item shape: {Type: "LoRaWAN", LogLevel: "INFO"|"ERROR"|"DISABLED", Events?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/log-levels")
  let body = {DefaultLogLevel: $DefaultLogLevel, WirelessDeviceLogOptions: $WirelessDeviceLogOptions, WirelessGatewayLogOptions: $WirelessGatewayLogOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Get the position information for a given resource.</p> <important> <p>This action is no longer supported. Calls to retrieve the position information should use the <a href="https://docs.aws.amazon.com/iot-wireless/2020-11-22/apireference/API_GetResourcePosition.html">GetResourcePosition</a> API operation instead.</p> </important>
#
# GET /positions/{ResourceIdentifier}#resourceType
# DEPRECATED
# operationId: GetPosition
@deprecated
export def "positions GetPosition" [
  ResourceIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceType: string@resourceType-completer # Resource type of the resource for which position information is retrieved.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Position: record, Accuracy: record<HorizontalAccuracy: record, VerticalAccuracy: record>, SolverType: record, SolverProvider: record, SolverVersion: record, Timestamp: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceType" $resourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/positions/($ResourceIdentifier)#resourceType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Update the position information of a resource.</p> <important> <p>This action is no longer supported. Calls to update the position information should use the <a href="https://docs.aws.amazon.com/iot-wireless/2020-11-22/apireference/API_UpdateResourcePosition.html">UpdateResourcePosition</a> API operation instead.</p> </important>
#
# PATCH /positions/{ResourceIdentifier}#resourceType
# DEPRECATED
# operationId: UpdatePosition
@deprecated
export def "positions UpdatePosition" [
  ResourceIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceType: string@resourceType-completer # Resource type of the resource for which position is updated.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Position: list # The position information of the resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceType" $resourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/positions/($ResourceIdentifier)#resourceType" $qp)
  let body = {Position: $Position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Get position configuration for a given resource.</p> <important> <p>This action is no longer supported. Calls to retrieve the position configuration should use the <a href="https://docs.aws.amazon.com/iot-wireless/2020-11-22/apireference/API_GetResourcePosition.html">GetResourcePosition</a> API operation instead.</p> </important>
#
# GET /position-configurations/{ResourceIdentifier}#resourceType
# DEPRECATED
# operationId: GetPositionConfiguration
@deprecated
export def "position-configurations GetPositionConfiguration" [
  ResourceIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceType: string@resourceType-completer # Resource type of the resource for which position configuration is retrieved.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Solvers: record<SemtechGnss: record<Provider: record, Type: record, Status: record, Fec: record>>, Destination: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceType" $resourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/position-configurations/($ResourceIdentifier)#resourceType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Put position configuration for a given resource.</p> <important> <p>This action is no longer supported. Calls to update the position configuration should use the <a href="https://docs.aws.amazon.com/iot-wireless/2020-11-22/apireference/API_UpdateResourcePosition.html">UpdateResourcePosition</a> API operation instead.</p> </important>
#
# PUT /position-configurations/{ResourceIdentifier}#resourceType
# DEPRECATED
# operationId: PutPositionConfiguration
# --Solvers shape: {SemtechGnss?: any}
@deprecated
export def "position-configurations PutPositionConfiguration" [
  ResourceIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceType: string@resourceType-completer # Resource type of the resource for which you want to update the position configuration.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --Solvers: record # The wrapper for position solver configurations. — shape: {SemtechGnss?: any}
  --Destination: string # The position data destination that describes the AWS IoT rule that processes the device's position data for use by AWS IoT Core for LoRaWAN.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceType" $resourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/position-configurations/($ResourceIdentifier)#resourceType" $qp)
  let body = {Solvers: $Solvers, Destination: $Destination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get estimated position information as a payload in GeoJSON format. The payload measurement data is resolved using solvers that are provided by third-party vendors.
#
# POST /position-estimate
# operationId: GetPositionEstimate
# --WiFiAccessPoints item shape: {MacAddress: any, Rss: any}
# --CellTowers shape: {Gsm?: any, Wcdma?: any, Tdscdma?: any, Lte?: any, Cdma?: any}
# --Ip shape: {IpAddress?: any}
# --Gnss shape: {Payload?: any, CaptureTime?: any, CaptureTimeAccuracy?: any, AssistPosition?: any, AssistAltitude?: any, Use2DSolver?: any}
export def "position-estimate GetPositionEstimate" [
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
  --WiFiAccessPoints: list # Retrieves an estimated device position by resolving WLAN measurement data. The position is resolved using HERE's Wi-Fi based solver. — item shape: {MacAddress: any, Rss: any}
  --CellTowers: record # The cell towers that were used to perform the measurements. — shape: {Gsm?: any, Wcdma?: any, Tdscdma?: any, Lte?: any, Cdma?: any}
  --Ip: record # IP address used for resolving device location. — shape: {IpAddress?: any}
  --Gnss: record # Global navigation satellite system (GNSS) object used for positioning. — shape: {Payload?: any, CaptureTime?: any, CaptureTimeAccuracy?: any, AssistPosition?: any, AssistAltitude?: any, Use2DSolver?: any}
  --Timestamp: string # Optional information that specifies the time when the position information will be resolved. It uses the Unix timestamp format. If not specified, the time at which the request was received will be used. (format: date-time)
]: any -> record<GeoJsonPayload: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/position-estimate")
  let body = {WiFiAccessPoints: $WiFiAccessPoints, CellTowers: $CellTowers, Ip: $Ip, Gnss: $Gnss, Timestamp: $Timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the event configuration for a particular resource identifier.
#
# GET /event-configurations/{Identifier}#identifierType
# operationId: GetResourceEventConfiguration
export def "event-configurations GetResourceEventConfiguration" [
  Identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Identifier type of the particular resource identifier for event configuration.
  --partnerType: string@partnerType-completer # Partner type of the resource if the identifier type is <code>PartnerAccountId</code>.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DeviceRegistrationState: record<Sidewalk: record<AmazonIdEventTopic: record>, WirelessDeviceIdEventTopic: record>, Proximity: record<Sidewalk: record<AmazonIdEventTopic: record>, WirelessDeviceIdEventTopic: record>, Join: record<LoRaWAN: record<DevEuiEventTopic: record>, WirelessDeviceIdEventTopic: record>, ConnectionStatus: record<LoRaWAN: record<GatewayEuiEventTopic: record>, WirelessGatewayIdEventTopic: record>, MessageDeliveryStatus: record<Sidewalk: record<AmazonIdEventTopic: record>, WirelessDeviceIdEventTopic: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "partnerType" $partnerType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/event-configurations/($Identifier)#identifierType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the event configuration for a particular resource identifier.
#
# PATCH /event-configurations/{Identifier}#identifierType
# operationId: UpdateResourceEventConfiguration
# --DeviceRegistrationState shape: {Sidewalk?: any, WirelessDeviceIdEventTopic?: any}
# --Proximity shape: {Sidewalk?: any, WirelessDeviceIdEventTopic?: any}
# --Join shape: {LoRaWAN?: any, WirelessDeviceIdEventTopic?: any}
# --ConnectionStatus shape: {LoRaWAN?: any, WirelessGatewayIdEventTopic?: any}
# --MessageDeliveryStatus shape: {Sidewalk?: record, WirelessDeviceIdEventTopic?: any}
export def "event-configurations UpdateResourceEventConfiguration" [
  Identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # Identifier type of the particular resource identifier for event configuration.
  --partnerType: string@partnerType-completer # Partner type of the resource if the identifier type is <code>PartnerAccountId</code> 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --DeviceRegistrationState: record # Device registration state event configuration object for enabling and disabling relevant topics. — shape: {Sidewalk?: any, WirelessDeviceIdEventTopic?: any}
  --Proximity: record # Proximity event configuration object for enabling and disabling relevant topics. — shape: {Sidewalk?: any, WirelessDeviceIdEventTopic?: any}
  --Join: record # Join event configuration object for enabling or disabling topic. — shape: {LoRaWAN?: any, WirelessDeviceIdEventTopic?: any}
  --ConnectionStatus: record # Connection status event configuration object for enabling or disabling topic. — shape: {LoRaWAN?: any, WirelessGatewayIdEventTopic?: any}
  --MessageDeliveryStatus: record # Message delivery status event configuration object for enabling and disabling relevant topics. — shape: {Sidewalk?: record, WirelessDeviceIdEventTopic?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "partnerType" $partnerType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/event-configurations/($Identifier)#identifierType" $qp)
  let body = {DeviceRegistrationState: $DeviceRegistrationState, Proximity: $Proximity, Join: $Join, ConnectionStatus: $ConnectionStatus, MessageDeliveryStatus: $MessageDeliveryStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetches the log-level override, if any, for a given resource-ID and resource-type. It can be used for a wireless device or a wireless gateway.
#
# GET /log-levels/{ResourceIdentifier}#resourceType
# operationId: GetResourceLogLevel
export def "log-levels GetResourceLogLevel" [
  ResourceIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceType: string # The type of the resource, which can be <code>WirelessDevice</code> or <code>WirelessGateway</code>.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<LogLevel: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceType" $resourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/log-levels/($ResourceIdentifier)#resourceType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sets the log-level override for a resource-ID and resource-type. This option can be specified for a wireless gateway or a wireless device. A limit of 200 log level override can be set per account.
#
# PUT /log-levels/{ResourceIdentifier}#resourceType
# operationId: PutResourceLogLevel
export def "log-levels PutResourceLogLevel" [
  ResourceIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceType: string # The type of the resource, which can be <code>WirelessDevice</code> or <code>WirelessGateway</code>.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  LogLevel: string@LogLevel-completer # The log level for a log message. The log levels can be disabled, or set to <code>ERROR</code> to display less verbose logs containing only error information, or to <code>INFO</code> for more detailed logs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceType" $resourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/log-levels/($ResourceIdentifier)#resourceType" $qp)
  let body = {LogLevel: $LogLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes the log-level override, if any, for a specific resource-ID and resource-type. It can be used for a wireless device or a wireless gateway.
#
# DELETE /log-levels/{ResourceIdentifier}#resourceType
# operationId: ResetResourceLogLevel
export def "log-levels ResetResourceLogLevel" [
  ResourceIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceType: string # The type of the resource, which can be <code>WirelessDevice</code> or <code>WirelessGateway</code>.
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
  let qp = [(serialize-qp "resourceType" $resourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/log-levels/($ResourceIdentifier)#resourceType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the position information for a given wireless device or a wireless gateway resource. The position information uses the <a href="https://gisgeography.com/wgs84-world-geodetic-system/"> World Geodetic System (WGS84)</a>.
#
# GET /resource-positions/{ResourceIdentifier}#resourceType
# operationId: GetResourcePosition
export def "resource-positions GetResourcePosition" [
  ResourceIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceType: string@resourceType-completer # The type of resource for which position information is retrieved, which can be a wireless device or a wireless gateway.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<GeoJsonPayload: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceType" $resourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/resource-positions/($ResourceIdentifier)#resourceType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the position information of a given wireless device or a wireless gateway resource. The position coordinates are based on the <a href="https://gisgeography.com/wgs84-world-geodetic-system/"> World Geodetic System (WGS84)</a>.
#
# PATCH /resource-positions/{ResourceIdentifier}#resourceType
# operationId: UpdateResourcePosition
export def "resource-positions UpdateResourcePosition" [
  ResourceIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceType: string@resourceType-completer # The type of resource for which position information is updated, which can be a wireless device or a wireless gateway.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --GeoJsonPayload: string # The position information of the resource, displayed as a JSON payload. The payload uses the GeoJSON format, which a format that's used to encode geographic data structures. For more information, see <a href="https://geojson.org/">GeoJSON</a>.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceType" $resourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/resource-positions/($ResourceIdentifier)#resourceType" $qp)
  let body = {GeoJsonPayload: $GeoJsonPayload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the account-specific endpoint for Configuration and Update Server (CUPS) protocol or LoRaWAN Network Server (LNS) connections.
#
# GET /service-endpoint
# operationId: GetServiceEndpoint
export def "service-endpoint GetServiceEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --serviceType: string@serviceType-completer # The service type for which to get endpoint information about. Can be <code>CUPS</code> for the Configuration and Update Server endpoint, or <code>LNS</code> for the LoRaWAN Network Server endpoint or <code>CLAIM</code> for the global endpoint.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ServiceType: record, ServiceEndpoint: record, ServerTrust: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceType" $serviceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/service-endpoint" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a wireless device.
#
# GET /wireless-devices/{Identifier}#identifierType
# operationId: GetWirelessDevice
export def "wireless-devices GetWirelessDevice" [
  Identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-1 # The type of identifier used in <code>identifier</code>.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Type: record, Name: record, Description: record, DestinationName: record, Id: record, Arn: record, ThingName: record, ThingArn: record, LoRaWAN: record<DevEui: record, DeviceProfileId: record, ServiceProfileId: record, OtaaV1_1: record<AppKey: record, NwkKey: record, JoinEui: record>, OtaaV1_0_x: record<AppKey: record, AppEui: record, GenAppKey: record>, AbpV1_1: record<DevAddr: record, SessionKeys: record, FCntStart: record>, AbpV1_0_x: record<DevAddr: record, SessionKeys: record, FCntStart: record>, FPorts: record<Fuota: int, Multicast: int, ClockSync: int, Positioning: record, Applications: record>>, Sidewalk: record<AmazonId: string, SidewalkId: record, SidewalkManufacturingSn: record, DeviceCertificates: record, PrivateKeys: record, DeviceProfileId: record, CertificateId: record, Status: record>, Positioning: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wireless-devices/($Identifier)#identifierType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets operating information about a wireless device.
#
# GET /wireless-devices/{Id}/statistics
# operationId: GetWirelessDeviceStatistics
export def "wireless-devices-statistics GetWirelessDeviceStatistics" [
  Id: string
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
]: nothing -> record<WirelessDeviceId: record, LastUplinkReceivedAt: record, LoRaWAN: record<DevEui: record, FPort: record, DataRate: record, Frequency: record, Timestamp: record, Gateways: record>, Sidewalk: record<Rssi: record, BatteryLevel: record, Event: record, DeviceState: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-devices/($Id)/statistics")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a wireless gateway.
#
# GET /wireless-gateways/{Identifier}#identifierType
# operationId: GetWirelessGateway
export def "wireless-gateways GetWirelessGateway" [
  Identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer-2 # The type of identifier used in <code>identifier</code>.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Name: record, Id: record, Description: record, LoRaWAN: record<GatewayEui: record, RfRegion: record, JoinEuiFilters: list<list>, NetIdFilters: list<string>, SubBands: list<int>, Beaconing: record<DataRate: record, Frequencies: record>, MaxEirp: record>, Arn: record, ThingName: record, ThingArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wireless-gateways/($Identifier)#identifierType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the firmware version and other information about a wireless gateway.
#
# GET /wireless-gateways/{Id}/firmware-information
# operationId: GetWirelessGatewayFirmwareInformation
export def "wireless-gateways-firmware-information GetWirelessGatewayFirmwareInformation" [
  Id: string
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
]: nothing -> record<LoRaWAN: record<CurrentVersion: record<PackageVersion: record, Model: record, Station: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)/firmware-information")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets operating information about a wireless gateway.
#
# GET /wireless-gateways/{Id}/statistics
# operationId: GetWirelessGatewayStatistics
export def "wireless-gateways-statistics GetWirelessGatewayStatistics" [
  Id: string
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
]: nothing -> record<WirelessGatewayId: record, LastUplinkReceivedAt: record, ConnectionStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-gateways/($Id)/statistics")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the Sidewalk devices in an import task and their onboarding status.
#
# GET /wireless_device_import_task#id
# operationId: ListDevicesForWirelessDeviceImportTask
export def "wireless-device-import-taskid ListDevicesForWirelessDeviceImportTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The identifier of the import task for which wireless devices are listed.
  --maxResults: int
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <code>null</code> to receive the first set of results.
  --status: string@status-completer # The status of the devices in the import task.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, DestinationName: record, ImportedWirelessDeviceList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless_device_import_task#id" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List event configurations where at least one event topic has been enabled.
#
# GET /event-configurations#resourceType
# operationId: ListEventConfigurations
export def "event-configurationsresource-type ListEventConfigurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceType: string@resourceType-completer-1 # Resource type to filter event configurations.
  --maxResults: int
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, EventConfigurationsList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceType" $resourceType "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/event-configurations#resourceType" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all multicast groups associated with a fuota task.
#
# GET /fuota-tasks/{Id}/multicast-groups
# operationId: ListMulticastGroupsByFuotaTask
export def "fuota-tasks-multicast-groups ListMulticastGroupsByFuotaTask" [
  Id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --maxResults: int
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, MulticastGroupList: table<Id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fuota-tasks/($Id)/multicast-groups" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>List position configurations for a given resource, such as positioning solvers.</p> <important> <p>This action is no longer supported. Calls to retrieve position information should use the <a href="https://docs.aws.amazon.com/iot-wireless/2020-11-22/apireference/API_GetResourcePosition.html">GetResourcePosition</a> API operation instead.</p> </important>
#
# GET /position-configurations
# DEPRECATED
# operationId: ListPositionConfigurations
@deprecated
export def "position-configurations ListPositionConfigurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceType: string@resourceType-completer # Resource type for which position configurations are listed.
  --maxResults: int
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<PositionConfigurationList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceType" $resourceType "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/position-configurations" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List queued messages in the downlink queue.
#
# GET /wireless-devices/{Id}/data
# operationId: ListQueuedMessages
export def "wireless-devices-data ListQueuedMessages" [
  Id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <b>null</b> to receive the first set of results.
  --maxResults: int # The maximum number of results to return in this operation.
  --WirelessDeviceType: string@WirelessDeviceType-completer # The wireless device type, whic can be either Sidewalk or LoRaWAN.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, DownlinkQueueMessagesList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "WirelessDeviceType" $WirelessDeviceType "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/wireless-devices/($Id)/data" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends a decrypted application data frame to a device.
#
# POST /wireless-devices/{Id}/data
# operationId: SendDataToWirelessDevice
# --WirelessMetadata shape: {LoRaWAN?: any, Sidewalk?: any}
export def "wireless-devices-data SendDataToWirelessDevice" [
  Id: string
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
  TransmitMode: int # The transmit mode to use to send data to the wireless device. Can be: <code>0</code> for UM (unacknowledge mode) or <code>1</code> for AM (acknowledge mode).
  PayloadData: string # The binary to be sent to the end device, encoded in base64.
  --WirelessMetadata: record # WirelessMetadata object. — shape: {LoRaWAN?: any, Sidewalk?: any}
]: any -> record<MessageId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-devices/($Id)/data")
  let body = {TransmitMode: $TransmitMode, PayloadData: $PayloadData, WirelessMetadata: $WirelessMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the tags (metadata) you have assigned to the resource.
#
# GET /tags#resourceArn
# operationId: ListTagsForResource
export def "tagsresource-arn ListTagsForResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceArn: string # The ARN of the resource for which you want to list tags.
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
  let qp = [(serialize-qp "resourceArn" $resourceArn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags#resourceArn" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a tag to a resource.
#
# POST /tags#resourceArn
# operationId: TagResource
# --Tags item shape: {Key: any, Value: any}
export def "tagsresource-arn TagResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceArn: string # The ARN of the resource to add tags to.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceArn" $resourceArn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags#resourceArn" $qp)
  let body = {Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List wireless devices that have been added to an import task.
#
# GET /wireless_device_import_tasks
# operationId: ListWirelessDeviceImportTasks
export def "wireless-device-import-tasks ListWirelessDeviceImportTasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: int
  --nextToken: string # To retrieve the next set of results, the <code>nextToken</code> value from a previous response; otherwise <code>null</code> to receive the first set of results.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<NextToken: record, WirelessDeviceImportTaskList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless_device_import_tasks" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends the specified data to a multicast group.
#
# POST /multicast-groups/{Id}/data
# operationId: SendDataToMulticastGroup
# --WirelessMetadata shape: {LoRaWAN?: record}
export def "multicast-groups-data SendDataToMulticastGroup" [
  Id: string
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
  PayloadData: string # The binary to be sent to the end device, encoded in base64.
  WirelessMetadata: record # Wireless metadata that is to be sent to multicast group. — shape: {LoRaWAN?: record}
]: any -> record<MessageId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/multicast-groups/($Id)/data")
  let body = {PayloadData: $PayloadData, WirelessMetadata: $WirelessMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Starts a bulk association of all qualifying wireless devices with a multicast group.
#
# PATCH /multicast-groups/{Id}/bulk
# operationId: StartBulkAssociateWirelessDeviceWithMulticastGroup
# --Tags item shape: {Key: any, Value: any}
export def "multicast-groups-bulk StartBulkAssociateWirelessDeviceWithMulticastGroup" [
  Id: string
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
  --QueryString: string # Query string used to search for wireless devices as part of the bulk associate and disassociate process.
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/multicast-groups/($Id)/bulk")
  let body = {QueryString: $QueryString, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Starts a bulk disassociatin of all qualifying wireless devices from a multicast group.
#
# POST /multicast-groups/{Id}/bulk
# operationId: StartBulkDisassociateWirelessDeviceFromMulticastGroup
# --Tags item shape: {Key: any, Value: any}
export def "multicast-groups-bulk StartBulkDisassociateWirelessDeviceFromMulticastGroup" [
  Id: string
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
  --QueryString: string # Query string used to search for wireless devices as part of the bulk associate and disassociate process.
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/multicast-groups/($Id)/bulk")
  let body = {QueryString: $QueryString, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start import task for a single wireless device.
#
# POST /wireless_single_device_import_task
# operationId: StartSingleWirelessDeviceImportTask
# --Tags item shape: {Key: any, Value: any}
# --Sidewalk shape: {SidewalkManufacturingSn?: any}
export def "wireless-single-device-import-task StartSingleWirelessDeviceImportTask" [
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
  DestinationName: string # The name of the Sidewalk destination that describes the IoT rule to route messages from the device in the import task that will be onboarded to AWS IoT Wireless.
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
  --DeviceName: string # The name of the wireless device for which an import task is being started.
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
  Sidewalk: record # Information about an import task created for an individual Sidewalk device. — shape: {SidewalkManufacturingSn?: any}
]: any -> record<Id: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wireless_single_device_import_task")
  let body = {DestinationName: $DestinationName, ClientRequestToken: $ClientRequestToken, DeviceName: $DeviceName, Tags: $Tags, Sidewalk: $Sidewalk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start import task for provisioning Sidewalk devices in bulk using an S3 CSV file.
#
# POST /wireless_device_import_task
# operationId: StartWirelessDeviceImportTask
# --Tags item shape: {Key: any, Value: any}
# --Sidewalk shape: {DeviceCreationFile?: any, Role?: any}
export def "wireless-device-import-task StartWirelessDeviceImportTask" [
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
  DestinationName: string # The name of the Sidewalk destination that describes the IoT rule to route messages from the devices in the import task that are onboarded to AWS IoT Wireless.
  --ClientRequestToken: string # Each resource must have a unique client request token. If you try to create a new resource with the same token as a resource that already exists, an exception occurs. If you omit this value, AWS SDKs will automatically generate a unique client request.
  --Tags: list # The tag to attach to the specified resource. Tags are metadata that you can use to manage a resource. — item shape: {Key: any, Value: any}
  Sidewalk: record # Information about an import task created for bulk provisioning. — shape: {DeviceCreationFile?: any, Role?: any}
]: any -> record<Id: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wireless_device_import_task")
  let body = {DestinationName: $DestinationName, ClientRequestToken: $ClientRequestToken, Tags: $Tags, Sidewalk: $Sidewalk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Simulates a provisioned device by sending an uplink data payload of <code>Hello</code>.
#
# POST /wireless-devices/{Id}/test
# operationId: TestWirelessDevice
export def "wireless-devices-test TestWirelessDevice" [
  Id: string
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
]: nothing -> record<Result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wireless-devices/($Id)/test")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes one or more tags from a resource.
#
# DELETE /tags#resourceArn&tagKeys
# operationId: UntagResource
export def "tagsresource-arntag-keys UntagResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceArn: string # The ARN of the resource to remove tags from.
  --tagKeys: list # A list of the keys of the tags to remove from the resource.
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
  let qp = [(serialize-qp "resourceArn" $resourceArn "scalar") (serialize-qp "tagKeys" $tagKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/tags#resourceArn&tagKeys" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
