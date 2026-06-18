# Auto-generated client for Amazon CloudHSM v2014-05-30
# Source: https://api.apis.guru/v2/specs/amazonaws.com/cloudhsm/2014-05-30/openapi.json
# Auth: --token flag or $env.AMAZON_CLOUDHSM_TOKEN

const BASE_URL = "http://cloudhsm.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_CLOUDHSM_TOKEN | default "" }
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

def base-url-completer [] { ["http://cloudhsm.us-east-1.amazonaws.com" "http://cloudhsm.us-east-2.amazonaws.com" "http://cloudhsm.us-west-1.amazonaws.com" "http://cloudhsm.us-west-2.amazonaws.com" "http://cloudhsm.us-gov-west-1.amazonaws.com" "http://cloudhsm.us-gov-east-1.amazonaws.com" "http://cloudhsm.ca-central-1.amazonaws.com" "http://cloudhsm.eu-north-1.amazonaws.com" "http://cloudhsm.eu-west-1.amazonaws.com" "http://cloudhsm.eu-west-2.amazonaws.com" "http://cloudhsm.eu-west-3.amazonaws.com" "http://cloudhsm.eu-central-1.amazonaws.com" "http://cloudhsm.eu-south-1.amazonaws.com" "http://cloudhsm.af-south-1.amazonaws.com" "http://cloudhsm.ap-northeast-1.amazonaws.com" "http://cloudhsm.ap-northeast-2.amazonaws.com" "http://cloudhsm.ap-northeast-3.amazonaws.com" "http://cloudhsm.ap-southeast-1.amazonaws.com" "http://cloudhsm.ap-southeast-2.amazonaws.com" "http://cloudhsm.ap-east-1.amazonaws.com" "http://cloudhsm.ap-south-1.amazonaws.com" "http://cloudhsm.sa-east-1.amazonaws.com" "http://cloudhsm.me-south-1.amazonaws.com" "https://cloudhsm.us-east-1.amazonaws.com" "https://cloudhsm.us-east-2.amazonaws.com" "https://cloudhsm.us-west-1.amazonaws.com" "https://cloudhsm.us-west-2.amazonaws.com" "https://cloudhsm.us-gov-west-1.amazonaws.com" "https://cloudhsm.us-gov-east-1.amazonaws.com" "https://cloudhsm.ca-central-1.amazonaws.com" "https://cloudhsm.eu-north-1.amazonaws.com" "https://cloudhsm.eu-west-1.amazonaws.com" "https://cloudhsm.eu-west-2.amazonaws.com" "https://cloudhsm.eu-west-3.amazonaws.com" "https://cloudhsm.eu-central-1.amazonaws.com" "https://cloudhsm.eu-south-1.amazonaws.com" "https://cloudhsm.af-south-1.amazonaws.com" "https://cloudhsm.ap-northeast-1.amazonaws.com" "https://cloudhsm.ap-northeast-2.amazonaws.com" "https://cloudhsm.ap-northeast-3.amazonaws.com" "https://cloudhsm.ap-southeast-1.amazonaws.com" "https://cloudhsm.ap-southeast-2.amazonaws.com" "https://cloudhsm.ap-east-1.amazonaws.com" "https://cloudhsm.ap-south-1.amazonaws.com" "https://cloudhsm.sa-east-1.amazonaws.com" "https://cloudhsm.me-south-1.amazonaws.com" "http://cloudhsm.cn-north-1.amazonaws.com.cn" "http://cloudhsm.cn-northwest-1.amazonaws.com.cn" "https://cloudhsm.cn-north-1.amazonaws.com.cn" "https://cloudhsm.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["CloudHsmFrontendService.AddTagsToResource"] }
def x-amz-target-completer-1 [] { ["CloudHsmFrontendService.CreateHapg"] }
def subscription-type-completer [] { ["PRODUCTION"] }
def x-amz-target-completer-2 [] { ["CloudHsmFrontendService.CreateHsm"] }
def x-amz-target-completer-3 [] { ["CloudHsmFrontendService.CreateLunaClient"] }
def x-amz-target-completer-4 [] { ["CloudHsmFrontendService.DeleteHapg"] }
def x-amz-target-completer-5 [] { ["CloudHsmFrontendService.DeleteHsm"] }
def x-amz-target-completer-6 [] { ["CloudHsmFrontendService.DeleteLunaClient"] }
def x-amz-target-completer-7 [] { ["CloudHsmFrontendService.DescribeHapg"] }
def x-amz-target-completer-8 [] { ["CloudHsmFrontendService.DescribeHsm"] }
def x-amz-target-completer-9 [] { ["CloudHsmFrontendService.DescribeLunaClient"] }
def x-amz-target-completer-10 [] { ["CloudHsmFrontendService.GetConfig"] }
def x-amz-target-completer-11 [] { ["CloudHsmFrontendService.ListAvailableZones"] }
def x-amz-target-completer-12 [] { ["CloudHsmFrontendService.ListHapgs"] }
def x-amz-target-completer-13 [] { ["CloudHsmFrontendService.ListHsms"] }
def x-amz-target-completer-14 [] { ["CloudHsmFrontendService.ListLunaClients"] }
def x-amz-target-completer-15 [] { ["CloudHsmFrontendService.ListTagsForResource"] }
def x-amz-target-completer-16 [] { ["CloudHsmFrontendService.ModifyHapg"] }
def x-amz-target-completer-17 [] { ["CloudHsmFrontendService.ModifyHsm"] }
def x-amz-target-completer-18 [] { ["CloudHsmFrontendService.ModifyLunaClient"] }
def x-amz-target-completer-19 [] { ["CloudHsmFrontendService.RemoveTagsFromResource"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-cloud-hsm-frontend-service-add-tags-to-resource create" } } | get name | first)
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

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Adds or overwrites one or more tags for the specified AWS CloudHSM resource. Each tag consists of a key and a value. Tag keys must be unique to each resource.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.AddTagsToResource
# operationId: AddTagsToResource
export def "x-amz-target-cloud-hsm-frontend-service-add-tags-to-resource create" [
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
  --x-amz-target: string@x-amz-target-completer
  resource_arn: any
  tag_list: any
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.AddTagsToResource")
  let req_body = {"ResourceArn": $resource_arn, "TagList": $tag_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Creates a high-availability partition group. A high-availability partition group is a group of partitions that spans multiple physical HSMs.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.CreateHapg
# operationId: CreateHapg
export def "x-amz-target-cloud-hsm-frontend-service-create-hapg create" [
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
  --x-amz-target: string@x-amz-target-completer-1
  label: any
]: any -> record<HapgArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.CreateHapg")
  let req_body = {"Label": $label} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Creates an uninitialized HSM instance. There is an upfront fee charged for each HSM instance that you create with the CreateHsm operation. If you accidentally provision an HSM and want to request a refund, delete the instance using the DeleteHsm operation, go to the AWS Support Center (https://console.aws.amazon.com/support/home), create a new case, and select Account and Billing Support. It can take up to 20 minutes to create and provision an HSM. You can monitor the status of the HSM with the DescribeHsm operation. The HSM is ready to be initialized when the status changes to RUNNING.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.CreateHsm
# operationId: CreateHsm
export def "x-amz-target-cloud-hsm-frontend-service-create-hsm create" [
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
  --x-amz-target: string@x-amz-target-completer-2
  subnet_id: any
  ssh_key: any
  --eni-ip: any
  iam_role_arn: any
  --external-id: any
  subscription_type: string@subscription-type-completer # Specifies the type of subscription for the HSM. PRODUCTION - The HSM is being used in a production environment. TRIAL - The HSM is being used in a product trial.
  --client-token: any
  --syslog-ip: any
]: any -> record<HsmArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.CreateHsm")
  let req_body = {"SubnetId": $subnet_id, "SshKey": $ssh_key, "EniIp": $eni_ip, "IamRoleArn": $iam_role_arn, "ExternalId": $external_id, "SubscriptionType": $subscription_type, "ClientToken": $client_token, "SyslogIp": $syslog_ip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Creates an HSM client.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.CreateLunaClient
# operationId: CreateLunaClient
export def "x-amz-target-cloud-hsm-frontend-service-create-luna-client create" [
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
  --x-amz-target: string@x-amz-target-completer-3
  --label: any
  certificate: any
]: any -> record<ClientArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.CreateLunaClient")
  let req_body = {"Label": $label, "Certificate": $certificate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Deletes a high-availability partition group.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.DeleteHapg
# operationId: DeleteHapg
export def "x-amz-target-cloud-hsm-frontend-service-delete-hapg delete" [
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
  --x-amz-target: string@x-amz-target-completer-4
  hapg_arn: any
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.DeleteHapg")
  let req_body = {"HapgArn": $hapg_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Deletes an HSM. After completion, this operation cannot be undone and your key material cannot be recovered.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.DeleteHsm
# operationId: DeleteHsm
export def "x-amz-target-cloud-hsm-frontend-service-delete-hsm delete" [
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
  --x-amz-target: string@x-amz-target-completer-5
  hsm_arn: any
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.DeleteHsm")
  let req_body = {"HsmArn": $hsm_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Deletes a client.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.DeleteLunaClient
# operationId: DeleteLunaClient
export def "x-amz-target-cloud-hsm-frontend-service-delete-luna-client delete" [
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
  --x-amz-target: string@x-amz-target-completer-6
  client_arn: any
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.DeleteLunaClient")
  let req_body = {"ClientArn": $client_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Retrieves information about a high-availability partition group.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.DescribeHapg
# operationId: DescribeHapg
export def "x-amz-target-cloud-hsm-frontend-service-describe-hapg get" [
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
  --x-amz-target: string@x-amz-target-completer-7
  hapg_arn: any
]: any -> record<HapgArn: record, HapgSerial: record, HsmsLastActionFailed: record, HsmsPendingDeletion: record, HsmsPendingRegistration: record, Label: record, LastModifiedTimestamp: record, PartitionSerialList: record, State: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.DescribeHapg")
  let req_body = {"HapgArn": $hapg_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Retrieves information about an HSM. You can identify the HSM by its ARN or its serial number.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.DescribeHsm
# operationId: DescribeHsm
export def "x-amz-target-cloud-hsm-frontend-service-describe-hsm get" [
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
  --x-amz-target: string@x-amz-target-completer-8
  --hsm-arn: any
  --hsm-serial-number: any
]: any -> record<HsmArn: record, Status: record, StatusDetails: record, AvailabilityZone: record, EniId: record, EniIp: record, SubscriptionType: string, SubscriptionStartDate: record, SubscriptionEndDate: record, VpcId: record, SubnetId: record, IamRoleArn: record, SerialNumber: record, VendorName: record, HsmType: record, SoftwareVersion: record, SshPublicKey: record, SshKeyLastUpdated: record, ServerCertUri: record, ServerCertLastUpdated: record, Partitions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.DescribeHsm")
  let req_body = {"HsmArn": $hsm_arn, "HsmSerialNumber": $hsm_serial_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Retrieves information about an HSM client.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.DescribeLunaClient
# operationId: DescribeLunaClient
export def "x-amz-target-cloud-hsm-frontend-service-describe-luna-client get" [
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
  --x-amz-target: string@x-amz-target-completer-9
  --client-arn: any
  --certificate-fingerprint: any
]: any -> record<ClientArn: record, Certificate: record, CertificateFingerprint: record, LastModifiedTimestamp: record, Label: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.DescribeLunaClient")
  let req_body = {"ClientArn": $client_arn, "CertificateFingerprint": $certificate_fingerprint} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Gets the configuration files necessary to connect to all high availability partition groups the client is associated with.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.GetConfig
# operationId: GetConfig
export def "x-amz-target-cloud-hsm-frontend-service-get-config get" [
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
  --x-amz-target: string@x-amz-target-completer-10
  client_arn: any
  client_version: any
  hapg_list: any
]: any -> record<ConfigType: record, ConfigFile: record, ConfigCred: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.GetConfig")
  let req_body = {"ClientArn": $client_arn, "ClientVersion": $client_version, "HapgList": $hapg_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Lists the Availability Zones that have available AWS CloudHSM capacity.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.ListAvailableZones
# operationId: ListAvailableZones
export def "x-amz-target-cloud-hsm-frontend-service-list-available-zones list" [
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
  --x-amz-target: string@x-amz-target-completer-11
  --body: record
]: any -> record<AZList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.ListAvailableZones")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Lists the high-availability partition groups for the account. This operation supports pagination with the use of the NextToken member. If more results are available, the NextToken member of the response contains a token that you pass in the next call to ListHapgs to retrieve the next set of items.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.ListHapgs
# operationId: ListHapgs
export def "x-amz-target-cloud-hsm-frontend-service-list-hapgs list" [
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
  --x-amz-target: string@x-amz-target-completer-12
  --next-token: any
]: any -> record<HapgList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.ListHapgs")
  let req_body = {"NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Retrieves the identifiers of all of the HSMs provisioned for the current customer. This operation supports pagination with the use of the NextToken member. If more results are available, the NextToken member of the response contains a token that you pass in the next call to ListHsms to retrieve the next set of items.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.ListHsms
# operationId: ListHsms
export def "x-amz-target-cloud-hsm-frontend-service-list-hsms list" [
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
  --x-amz-target: string@x-amz-target-completer-13
  --next-token: any
]: any -> record<HsmList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.ListHsms")
  let req_body = {"NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Lists all of the clients. This operation supports pagination with the use of the NextToken member. If more results are available, the NextToken member of the response contains a token that you pass in the next call to ListLunaClients to retrieve the next set of items.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.ListLunaClients
# operationId: ListLunaClients
export def "x-amz-target-cloud-hsm-frontend-service-list-luna-clients list" [
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
  --x-amz-target: string@x-amz-target-completer-14
  --next-token: any
]: any -> record<ClientList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.ListLunaClients")
  let req_body = {"NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Returns a list of all tags for the specified AWS CloudHSM resource.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.ListTagsForResource
# operationId: ListTagsForResource
export def "x-amz-target-cloud-hsm-frontend-service-list-tags-for-resource list" [
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
  --x-amz-target: string@x-amz-target-completer-15
  resource_arn: any
]: any -> record<TagList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.ListTagsForResource")
  let req_body = {"ResourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Modifies an existing high-availability partition group.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.ModifyHapg
# operationId: ModifyHapg
export def "x-amz-target-cloud-hsm-frontend-service-modify-hapg create" [
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
  --x-amz-target: string@x-amz-target-completer-16
  hapg_arn: any
  --label: any
  --partition-serial-list: any
]: any -> record<HapgArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.ModifyHapg")
  let req_body = {"HapgArn": $hapg_arn, "Label": $label, "PartitionSerialList": $partition_serial_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Modifies an HSM. This operation can result in the HSM being offline for up to 15 minutes while the AWS CloudHSM service is reconfigured. If you are modifying a production HSM, you should ensure that your AWS CloudHSM service is configured for high availability, and consider executing this operation during a maintenance window.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.ModifyHsm
# operationId: ModifyHsm
export def "x-amz-target-cloud-hsm-frontend-service-modify-hsm create" [
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
  --x-amz-target: string@x-amz-target-completer-17
  hsm_arn: any
  --subnet-id: any
  --eni-ip: any
  --iam-role-arn: any
  --external-id: any
  --syslog-ip: any
]: any -> record<HsmArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.ModifyHsm")
  let req_body = {"HsmArn": $hsm_arn, "SubnetId": $subnet_id, "EniIp": $eni_ip, "IamRoleArn": $iam_role_arn, "ExternalId": $external_id, "SyslogIp": $syslog_ip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Modifies the certificate used by the client. This action can potentially start a workflow to install the new certificate on the client's HSMs.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.ModifyLunaClient
# operationId: ModifyLunaClient
export def "x-amz-target-cloud-hsm-frontend-service-modify-luna-client create" [
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
  --x-amz-target: string@x-amz-target-completer-18
  client_arn: any
  certificate: any
]: any -> record<ClientArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.ModifyLunaClient")
  let req_body = {"ClientArn": $client_arn, "Certificate": $certificate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This is documentation for AWS CloudHSM Classic. For more information, see AWS CloudHSM Classic FAQs (http://aws.amazon.com/cloudhsm/faqs-classic/), the AWS CloudHSM Classic User Guide (https://docs.aws.amazon.com/cloudhsm/classic/userguide/), and the AWS CloudHSM Classic API Reference (https://docs.aws.amazon.com/cloudhsm/classic/APIReference/). For information about the current version of AWS CloudHSM, see AWS CloudHSM (http://aws.amazon.com/cloudhsm/), the AWS CloudHSM User Guide (https://docs.aws.amazon.com/cloudhsm/latest/userguide/), and the AWS CloudHSM API Reference (https://docs.aws.amazon.com/cloudhsm/latest/APIReference/). Removes one or more tags from the specified AWS CloudHSM resource. To remove a tag, specify only the tag key to remove (not the value). To overwrite the value for an existing tag, use AddTagsToResource.
#
# POST /#X-Amz-Target=CloudHsmFrontendService.RemoveTagsFromResource
# operationId: RemoveTagsFromResource
export def "x-amz-target-cloud-hsm-frontend-service-remove-tags-from-resource delete" [
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
  --x-amz-target: string@x-amz-target-completer-19
  resource_arn: any
  tag_key_list: any
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CloudHsmFrontendService.RemoveTagsFromResource")
  let req_body = {"ResourceArn": $resource_arn, "TagKeyList": $tag_key_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
