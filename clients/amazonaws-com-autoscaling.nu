# Auto-generated client for Auto Scaling v2011-01-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/autoscaling/2011-01-01/openapi.json
# Auth: --token flag or $env.AUTO_SCALING_TOKEN

const BASE_URL = "http://autoscaling.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AUTO_SCALING_TOKEN | default "" }
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

def base-url-completer [] { ["http://autoscaling.us-east-1.amazonaws.com" "http://autoscaling.us-east-2.amazonaws.com" "http://autoscaling.us-west-1.amazonaws.com" "http://autoscaling.us-west-2.amazonaws.com" "http://autoscaling.us-gov-west-1.amazonaws.com" "http://autoscaling.us-gov-east-1.amazonaws.com" "http://autoscaling.ca-central-1.amazonaws.com" "http://autoscaling.eu-north-1.amazonaws.com" "http://autoscaling.eu-west-1.amazonaws.com" "http://autoscaling.eu-west-2.amazonaws.com" "http://autoscaling.eu-west-3.amazonaws.com" "http://autoscaling.eu-central-1.amazonaws.com" "http://autoscaling.eu-south-1.amazonaws.com" "http://autoscaling.af-south-1.amazonaws.com" "http://autoscaling.ap-northeast-1.amazonaws.com" "http://autoscaling.ap-northeast-2.amazonaws.com" "http://autoscaling.ap-northeast-3.amazonaws.com" "http://autoscaling.ap-southeast-1.amazonaws.com" "http://autoscaling.ap-southeast-2.amazonaws.com" "http://autoscaling.ap-east-1.amazonaws.com" "http://autoscaling.ap-south-1.amazonaws.com" "http://autoscaling.sa-east-1.amazonaws.com" "http://autoscaling.me-south-1.amazonaws.com" "https://autoscaling.us-east-1.amazonaws.com" "https://autoscaling.us-east-2.amazonaws.com" "https://autoscaling.us-west-1.amazonaws.com" "https://autoscaling.us-west-2.amazonaws.com" "https://autoscaling.us-gov-west-1.amazonaws.com" "https://autoscaling.us-gov-east-1.amazonaws.com" "https://autoscaling.ca-central-1.amazonaws.com" "https://autoscaling.eu-north-1.amazonaws.com" "https://autoscaling.eu-west-1.amazonaws.com" "https://autoscaling.eu-west-2.amazonaws.com" "https://autoscaling.eu-west-3.amazonaws.com" "https://autoscaling.eu-central-1.amazonaws.com" "https://autoscaling.eu-south-1.amazonaws.com" "https://autoscaling.af-south-1.amazonaws.com" "https://autoscaling.ap-northeast-1.amazonaws.com" "https://autoscaling.ap-northeast-2.amazonaws.com" "https://autoscaling.ap-northeast-3.amazonaws.com" "https://autoscaling.ap-southeast-1.amazonaws.com" "https://autoscaling.ap-southeast-2.amazonaws.com" "https://autoscaling.ap-east-1.amazonaws.com" "https://autoscaling.ap-south-1.amazonaws.com" "https://autoscaling.sa-east-1.amazonaws.com" "https://autoscaling.me-south-1.amazonaws.com" "http://autoscaling.amazonaws.com" "https://autoscaling.amazonaws.com" "http://autoscaling.cn-north-1.amazonaws.com.cn" "http://autoscaling.cn-northwest-1.amazonaws.com.cn" "https://autoscaling.cn-north-1.amazonaws.com.cn" "https://autoscaling.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["AttachInstances"] }
def version-completer [] { ["2011-01-01"] }
def action-completer-1 [] { ["AttachLoadBalancerTargetGroups"] }
def action-completer-2 [] { ["AttachLoadBalancers"] }
def action-completer-3 [] { ["AttachTrafficSources"] }
def action-completer-4 [] { ["BatchDeleteScheduledAction"] }
def action-completer-5 [] { ["BatchPutScheduledUpdateGroupAction"] }
def action-completer-6 [] { ["CancelInstanceRefresh"] }
def action-completer-7 [] { ["CompleteLifecycleAction"] }
def action-completer-8 [] { ["CreateAutoScalingGroup"] }
def action-completer-9 [] { ["CreateLaunchConfiguration"] }
def action-completer-10 [] { ["CreateOrUpdateTags"] }
def action-completer-11 [] { ["DeleteAutoScalingGroup"] }
def action-completer-12 [] { ["DeleteLaunchConfiguration"] }
def action-completer-13 [] { ["DeleteLifecycleHook"] }
def action-completer-14 [] { ["DeleteNotificationConfiguration"] }
def action-completer-15 [] { ["DeletePolicy"] }
def action-completer-16 [] { ["DeleteScheduledAction"] }
def action-completer-17 [] { ["DeleteTags"] }
def action-completer-18 [] { ["DeleteWarmPool"] }
def action-completer-19 [] { ["DescribeAccountLimits"] }
def action-completer-20 [] { ["DescribeAdjustmentTypes"] }
def action-completer-21 [] { ["DescribeAutoScalingGroups"] }
def action-completer-22 [] { ["DescribeAutoScalingInstances"] }
def action-completer-23 [] { ["DescribeAutoScalingNotificationTypes"] }
def action-completer-24 [] { ["DescribeInstanceRefreshes"] }
def action-completer-25 [] { ["DescribeLaunchConfigurations"] }
def action-completer-26 [] { ["DescribeLifecycleHookTypes"] }
def action-completer-27 [] { ["DescribeLifecycleHooks"] }
def action-completer-28 [] { ["DescribeLoadBalancerTargetGroups"] }
def action-completer-29 [] { ["DescribeLoadBalancers"] }
def action-completer-30 [] { ["DescribeMetricCollectionTypes"] }
def action-completer-31 [] { ["DescribeNotificationConfigurations"] }
def action-completer-32 [] { ["DescribePolicies"] }
def action-completer-33 [] { ["DescribeScalingActivities"] }
def action-completer-34 [] { ["DescribeScalingProcessTypes"] }
def action-completer-35 [] { ["DescribeScheduledActions"] }
def action-completer-36 [] { ["DescribeTags"] }
def action-completer-37 [] { ["DescribeTerminationPolicyTypes"] }
def action-completer-38 [] { ["DescribeTrafficSources"] }
def action-completer-39 [] { ["DescribeWarmPool"] }
def action-completer-40 [] { ["DetachInstances"] }
def action-completer-41 [] { ["DetachLoadBalancerTargetGroups"] }
def action-completer-42 [] { ["DetachLoadBalancers"] }
def action-completer-43 [] { ["DetachTrafficSources"] }
def action-completer-44 [] { ["DisableMetricsCollection"] }
def action-completer-45 [] { ["EnableMetricsCollection"] }
def action-completer-46 [] { ["EnterStandby"] }
def action-completer-47 [] { ["ExecutePolicy"] }
def action-completer-48 [] { ["ExitStandby"] }
def action-completer-49 [] { ["GetPredictiveScalingForecast"] }
def action-completer-50 [] { ["PutLifecycleHook"] }
def action-completer-51 [] { ["PutNotificationConfiguration"] }
def action-completer-52 [] { ["PutScalingPolicy"] }
def action-completer-53 [] { ["PutScheduledUpdateGroupAction"] }
def pool-state-completer [] { ["Hibernated" "Running" "Stopped"] }
def action-completer-54 [] { ["PutWarmPool"] }
def action-completer-55 [] { ["RecordLifecycleActionHeartbeat"] }
def action-completer-56 [] { ["ResumeProcesses"] }
def action-completer-57 [] { ["RollbackInstanceRefresh"] }
def action-completer-58 [] { ["SetDesiredCapacity"] }
def action-completer-59 [] { ["SetInstanceHealth"] }
def action-completer-60 [] { ["SetInstanceProtection"] }
def strategy-completer [] { ["Rolling"] }
def action-completer-61 [] { ["StartInstanceRefresh"] }
def action-completer-62 [] { ["SuspendProcesses"] }
def action-completer-63 [] { ["TerminateInstanceInAutoScalingGroup"] }
def action-completer-64 [] { ["UpdateAutoScalingGroup"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api get-attach-instances" } } | get name | first)
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

# Attaches one or more EC2 instances to the specified Auto Scaling group. When you attach instances, Amazon EC2 Auto Scaling increases the desired capacity of the group by the number of instances being attached. If the number of instances being attached plus the desired capacity of the group exceeds the maximum size of the group, the operation fails. If there is a Classic Load Balancer attached to your Auto Scaling group, the instances are also registered with the load balancer. If there are target groups attached to your Auto Scaling group, the instances are also registered with the target groups. For more information, see Attach EC2 instances to your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/attach-instance-asg.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_AttachInstances
export def "api get-attach-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list # The IDs of the instances. You can specify up to 20 instances.
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
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
  let qp = [(serialize-qp "InstanceIds" $instance_ids "multi") (serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"InstanceIds": $instance_ids, "AutoScalingGroupName": $auto_scaling_group_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Attaches one or more EC2 instances to the specified Auto Scaling group. When you attach instances, Amazon EC2 Auto Scaling increases the desired capacity of the group by the number of instances being attached. If the number of instances being attached plus the desired capacity of the group exceeds the maximum size of the group, the operation fails. If there is a Classic Load Balancer attached to your Auto Scaling group, the instances are also registered with the load balancer. If there are target groups attached to your Auto Scaling group, the instances are also registered with the target groups. For more information, see Attach EC2 instances to your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/attach-instance-asg.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_AttachInstances
export def "api create-attach-instances" [
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

# This API operation is superseded by AttachTrafficSources, which can attach multiple traffic sources types. We recommend using AttachTrafficSources to simplify how you manage traffic sources. However, we continue to support AttachLoadBalancerTargetGroups. You can use both the original AttachLoadBalancerTargetGroups API operation and AttachTrafficSources on the same Auto Scaling group. Attaches one or more target groups to the specified Auto Scaling group. This operation is used with the following load balancer types: Application Load Balancer - Operates at the application layer (layer 7) and supports HTTP and HTTPS. Network Load Balancer - Operates at the transport layer (layer 4) and supports TCP, TLS, and UDP. Gateway Load Balancer - Operates at the network layer (layer 3). To describe the target groups for an Auto Scaling group, call the DescribeLoadBalancerTargetGroups API. To detach the target group from the Auto Scaling group, call the DetachLoadBalancerTargetGroups API. This operation is additive and does not detach existing target groups or Classic Load Balancers from the Auto Scaling group. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_AttachLoadBalancerTargetGroups
export def "api get-attach-load-balancer-target-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --target-group-ar-ns: list # The Amazon Resource Names (ARNs) of the target groups. You can specify up to 10 target groups. To get the ARN of a target group, use the Elastic Load Balancing DescribeTargetGroups (https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_DescribeTargetGroups.html) API operation.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "TargetGroupARNs" $target_group_ar_ns "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "TargetGroupARNs": $target_group_ar_ns, "Action": $action, "Version": $version} | compact), body: null}
}

# This API operation is superseded by AttachTrafficSources, which can attach multiple traffic sources types. We recommend using AttachTrafficSources to simplify how you manage traffic sources. However, we continue to support AttachLoadBalancerTargetGroups. You can use both the original AttachLoadBalancerTargetGroups API operation and AttachTrafficSources on the same Auto Scaling group. Attaches one or more target groups to the specified Auto Scaling group. This operation is used with the following load balancer types: Application Load Balancer - Operates at the application layer (layer 7) and supports HTTP and HTTPS. Network Load Balancer - Operates at the transport layer (layer 4) and supports TCP, TLS, and UDP. Gateway Load Balancer - Operates at the network layer (layer 3). To describe the target groups for an Auto Scaling group, call the DescribeLoadBalancerTargetGroups API. To detach the target group from the Auto Scaling group, call the DetachLoadBalancerTargetGroups API. This operation is additive and does not detach existing target groups or Classic Load Balancers from the Auto Scaling group. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_AttachLoadBalancerTargetGroups
export def "api create-attach-load-balancer-target-groups" [
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
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# This API operation is superseded by AttachTrafficSources, which can attach multiple traffic sources types. We recommend using AttachTrafficSources to simplify how you manage traffic sources. However, we continue to support AttachLoadBalancers. You can use both the original AttachLoadBalancers API operation and AttachTrafficSources on the same Auto Scaling group. Attaches one or more Classic Load Balancers to the specified Auto Scaling group. Amazon EC2 Auto Scaling registers the running instances with these Classic Load Balancers. To describe the load balancers for an Auto Scaling group, call the DescribeLoadBalancers API. To detach a load balancer from the Auto Scaling group, call the DetachLoadBalancers API. This operation is additive and does not detach existing Classic Load Balancers or target groups from the Auto Scaling group. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_AttachLoadBalancers
export def "api get-attach-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --load-balancer-names: list # The names of the load balancers. You can specify up to 10 load balancers.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "LoadBalancerNames" $load_balancer_names "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "LoadBalancerNames": $load_balancer_names, "Action": $action, "Version": $version} | compact), body: null}
}

# This API operation is superseded by AttachTrafficSources, which can attach multiple traffic sources types. We recommend using AttachTrafficSources to simplify how you manage traffic sources. However, we continue to support AttachLoadBalancers. You can use both the original AttachLoadBalancers API operation and AttachTrafficSources on the same Auto Scaling group. Attaches one or more Classic Load Balancers to the specified Auto Scaling group. Amazon EC2 Auto Scaling registers the running instances with these Classic Load Balancers. To describe the load balancers for an Auto Scaling group, call the DescribeLoadBalancers API. To detach a load balancer from the Auto Scaling group, call the DetachLoadBalancers API. This operation is additive and does not detach existing Classic Load Balancers or target groups from the Auto Scaling group. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_AttachLoadBalancers
export def "api create-attach-load-balancers" [
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

# Attaches one or more traffic sources to the specified Auto Scaling group. You can use any of the following as traffic sources for an Auto Scaling group: Application Load Balancer Classic Load Balancer Gateway Load Balancer Network Load Balancer VPC Lattice This operation is additive and does not detach existing traffic sources from the Auto Scaling group. After the operation completes, use the DescribeTrafficSources API to return details about the state of the attachments between traffic sources and your Auto Scaling group. To detach a traffic source from the Auto Scaling group, call the DetachTrafficSources API.
#
# GET /
# operationId: GET_AttachTrafficSources
export def "api get-attach-traffic-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --traffic-sources: list # The unique identifiers of one or more traffic sources. You can specify up to 10 traffic sources.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "TrafficSources" $traffic_sources "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "TrafficSources": $traffic_sources, "Action": $action, "Version": $version} | compact), body: null}
}

# Attaches one or more traffic sources to the specified Auto Scaling group. You can use any of the following as traffic sources for an Auto Scaling group: Application Load Balancer Classic Load Balancer Gateway Load Balancer Network Load Balancer VPC Lattice This operation is additive and does not detach existing traffic sources from the Auto Scaling group. After the operation completes, use the DescribeTrafficSources API to return details about the state of the attachments between traffic sources and your Auto Scaling group. To detach a traffic source from the Auto Scaling group, call the DetachTrafficSources API.
#
# POST /
# operationId: POST_AttachTrafficSources
export def "api create-attach-traffic-sources" [
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

# Deletes one or more scheduled actions for the specified Auto Scaling group.
#
# GET /
# operationId: GET_BatchDeleteScheduledAction
export def "api get-batch-delete-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --scheduled-action-names: list # The names of the scheduled actions to delete. The maximum number allowed is 50.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ScheduledActionNames" $scheduled_action_names "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "ScheduledActionNames": $scheduled_action_names, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes one or more scheduled actions for the specified Auto Scaling group.
#
# POST /
# operationId: POST_BatchDeleteScheduledAction
export def "api create-batch-delete-scheduled-action" [
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
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates or updates one or more scheduled scaling actions for an Auto Scaling group.
#
# GET /
# operationId: GET_BatchPutScheduledUpdateGroupAction
export def "api get-batch-update-scheduled-update-group-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --scheduled-update-group-actions: list # One or more scheduled actions. The maximum number allowed is 50.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ScheduledUpdateGroupActions" $scheduled_update_group_actions "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "ScheduledUpdateGroupActions": $scheduled_update_group_actions, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates or updates one or more scheduled scaling actions for an Auto Scaling group.
#
# POST /
# operationId: POST_BatchPutScheduledUpdateGroupAction
export def "api create-batch-update-scheduled-update-group-action" [
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

# Cancels an instance refresh or rollback that is in progress. If an instance refresh or rollback is not in progress, an ActiveInstanceRefreshNotFound error occurs. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. When you cancel an instance refresh, this does not roll back any changes that it made. Use the RollbackInstanceRefresh API to roll back instead.
#
# GET /
# operationId: GET_CancelInstanceRefresh
export def "api get-cancel-instance-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Cancels an instance refresh or rollback that is in progress. If an instance refresh or rollback is not in progress, an ActiveInstanceRefreshNotFound error occurs. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. When you cancel an instance refresh, this does not roll back any changes that it made. Use the RollbackInstanceRefresh API to roll back instead.
#
# POST /
# operationId: POST_CancelInstanceRefresh
export def "api create-cancel-instance-refresh" [
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
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Completes the lifecycle action for the specified token or instance with the specified result. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_CompleteLifecycleAction
export def "api get-complete-lifecycle-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lifecycle-hook-name: string # The name of the lifecycle hook.
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --lifecycle-action-token: string # A universally unique identifier (UUID) that identifies a specific lifecycle action associated with an instance. Amazon EC2 Auto Scaling sends this token to the notification target you specified when you created the lifecycle hook.
  --lifecycle-action-result: string # The action for the group to take. You can specify either CONTINUE or ABANDON.
  --instance-id: string # The ID of the instance.
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
  let qp = [(serialize-qp "LifecycleHookName" $lifecycle_hook_name "scalar") (serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "LifecycleActionToken" $lifecycle_action_token "scalar") (serialize-qp "LifecycleActionResult" $lifecycle_action_result "scalar") (serialize-qp "InstanceId" $instance_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"LifecycleHookName": $lifecycle_hook_name, "AutoScalingGroupName": $auto_scaling_group_name, "LifecycleActionToken": $lifecycle_action_token, "LifecycleActionResult": $lifecycle_action_result, "InstanceId": $instance_id, "Action": $action, "Version": $version} | compact), body: null}
}

# Completes the lifecycle action for the specified token or instance with the specified result. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_CompleteLifecycleAction
export def "api create-complete-lifecycle-action" [
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

# We strongly recommend using a launch template when calling this operation to ensure full functionality for Amazon EC2 Auto Scaling and Amazon EC2. Creates an Auto Scaling group with the specified name and attributes. If you exceed your maximum limit of Auto Scaling groups, the call fails. To query this limit, call the DescribeAccountLimits API. For information about updating this limit, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide. For introductory exercises for creating an Auto Scaling group, see Getting started with Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/GettingStartedTutorial.html) and Tutorial: Set up a scaled and load-balanced application (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-register-lbs-with-asg.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Auto Scaling groups (https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html) in the Amazon EC2 Auto Scaling User Guide. Every Auto Scaling group has three size properties (DesiredCapacity, MaxSize, and MinSize). Usually, you set these sizes based on a specific number of instances. However, if you configure a mixed instances policy that defines weights for the instance types, you must specify these sizes with the same units that you use for weighting instances.
#
# GET /
# operationId: GET_CreateAutoScalingGroup
export def "api get-create-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. This name must be unique per Region per account. The name can contain any ASCII character 33 to 126 including most punctuation characters, digits, and upper and lowercased letters. You cannot use a colon (:) in the name.
  --launch-configuration-name: string # The name of the launch configuration to use to launch instances. Conditional: You must specify either a launch template (LaunchTemplate or MixedInstancesPolicy) or a launch configuration (LaunchConfigurationName or InstanceId).
  --launch-template: record # Information used to specify the launch template and version to use to launch instances. Conditional: You must specify either a launch template (LaunchTemplate or MixedInstancesPolicy) or a launch configuration (LaunchConfigurationName or InstanceId). The launch template that is specified must be configured for use with an Auto Scaling group. For more information, see Creating a launch template for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-launch-template.html) in the Amazon EC2 Auto Scaling User Guide.
  --mixed-instances-policy: record # The mixed instances policy. For more information, see Auto Scaling groups with multiple instance types and purchase options (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-mixed-instances-groups.html) in the Amazon EC2 Auto Scaling User Guide.
  --instance-id: string # The ID of the instance used to base the launch configuration on. If specified, Amazon EC2 Auto Scaling uses the configuration values from the specified instance to create a new launch configuration. To get the instance ID, use the Amazon EC2 DescribeInstances (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstances.html) API operation. For more information, see Creating an Auto Scaling group using an EC2 instance (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-asg-from-instance.html) in the Amazon EC2 Auto Scaling User Guide.
  --min-size: int # The minimum size of the group.
  --max-size: int # The maximum size of the group. With a mixed instances policy that uses instance weighting, Amazon EC2 Auto Scaling may need to go above MaxSize to meet your capacity requirements. In this event, Amazon EC2 Auto Scaling will never go above MaxSize by more than your largest instance weight (weights that define how many units each instance contributes to the desired capacity of the group).
  --desired-capacity: int # The desired capacity is the initial capacity of the Auto Scaling group at the time of its creation and the capacity it attempts to maintain. It can scale beyond this capacity if you configure auto scaling. This number must be greater than or equal to the minimum size of the group and less than or equal to the maximum size of the group. If you do not specify a desired capacity, the default is the minimum size of the group.
  --default-cooldown: int # Only needed if you use simple scaling policies. The amount of time, in seconds, between one scaling activity ending and another one starting due to simple scaling policies. For more information, see Scaling cooldowns for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/Cooldown.html) in the Amazon EC2 Auto Scaling User Guide. Default: 300 seconds
  --availability-zones: list # A list of Availability Zones where instances in the Auto Scaling group can be created. Used for launching into the default VPC subnet in each Availability Zone when not using the VPCZoneIdentifier property, or for attaching a network interface when an existing network interface ID is specified in a launch template.
  --load-balancer-names: list # A list of Classic Load Balancers associated with this Auto Scaling group. For Application Load Balancers, Network Load Balancers, and Gateway Load Balancers, specify the TargetGroupARNs property instead.
  --target-group-ar-ns: list # The Amazon Resource Names (ARN) of the Elastic Load Balancing target groups to associate with the Auto Scaling group. Instances are registered as targets with the target groups. The target groups receive incoming traffic and route requests to one or more registered targets. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
  --health-check-type: string # A comma-separated value string of one or more health check types. The valid values are EC2, ELB, and VPC_LATTICE. EC2 is the default health check and cannot be disabled. For more information, see Health checks for Auto Scaling instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/healthcheck.html) in the Amazon EC2 Auto Scaling User Guide. Only specify EC2 if you must clear a value that was previously set.
  --health-check-grace-period: int # The amount of time, in seconds, that Amazon EC2 Auto Scaling waits before checking the health status of an EC2 instance that has come into service and marking it unhealthy due to a failed health check. This is useful if your instances do not immediately pass their health checks after they enter the InService state. For more information, see Set the health check grace period for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/health-check-grace-period.html) in the Amazon EC2 Auto Scaling User Guide. Default: 0 seconds
  --placement-group: string # The name of the placement group into which to launch your instances. For more information, see Placement groups (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/placement-groups.html) in the Amazon EC2 User Guide for Linux Instances. A cluster placement group is a logical grouping of instances within a single Availability Zone. You cannot specify multiple Availability Zones and a cluster placement group.
  --vpc-zone-identifier: string # A comma-separated list of subnet IDs for a virtual private cloud (VPC) where instances in the Auto Scaling group can be created. If you specify VPCZoneIdentifier with AvailabilityZones, the subnets that you specify must reside in those Availability Zones.
  --termination-policies: list # A policy or a list of policies that are used to select the instance to terminate. These policies are executed in the order that you list them. For more information, see Work with Amazon EC2 Auto Scaling termination policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-termination-policies.html) in the Amazon EC2 Auto Scaling User Guide. Valid values: Default | AllocationStrategy | ClosestToNextInstanceHour | NewestInstance | OldestInstance | OldestLaunchConfiguration | OldestLaunchTemplate | arn:aws:lambda:region:account-id:function:my-function:my-alias
  --new-instances-protected-from-scale-in: oneof<nothing, bool> # Indicates whether newly launched instances are protected from termination by Amazon EC2 Auto Scaling when scaling in. For more information about preventing instances from terminating on scale in, see Using instance scale-in protection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-instance-protection.html) in the Amazon EC2 Auto Scaling User Guide.
  --capacity-rebalance: oneof<nothing, bool> # Indicates whether Capacity Rebalancing is enabled. Otherwise, Capacity Rebalancing is disabled. When you turn on Capacity Rebalancing, Amazon EC2 Auto Scaling attempts to launch a Spot Instance whenever Amazon EC2 notifies that a Spot Instance is at an elevated risk of interruption. After launching a new instance, it then terminates an old instance. For more information, see Use Capacity Rebalancing to handle Amazon EC2 Spot Interruptions (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-capacity-rebalancing.html) in the in the Amazon EC2 Auto Scaling User Guide.
  --lifecycle-hook-specification-list: list # One or more lifecycle hooks to add to the Auto Scaling group before instances are launched.
  --tags: list # One or more tags. You can tag your Auto Scaling group and propagate the tags to the Amazon EC2 instances it launches. Tags are not propagated to Amazon EBS volumes. To add tags to Amazon EBS volumes, specify the tags in a launch template but use caution. If the launch template specifies an instance tag with a key that is also specified for the Auto Scaling group, Amazon EC2 Auto Scaling overrides the value of that instance tag with the value specified by the Auto Scaling group. For more information, see Tag Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html) in the Amazon EC2 Auto Scaling User Guide.
  --service-linked-role-arn: string # The Amazon Resource Name (ARN) of the service-linked role that the Auto Scaling group uses to call other Amazon Web Services service on your behalf. By default, Amazon EC2 Auto Scaling uses a service-linked role named AWSServiceRoleForAutoScaling, which it creates if it does not exist. For more information, see Service-linked roles (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-service-linked-role.html) in the Amazon EC2 Auto Scaling User Guide.
  --max-instance-lifetime: int # The maximum amount of time, in seconds, that an instance can be in service. The default is null. If specified, the value must be either 0 or a number equal to or greater than 86,400 seconds (1 day). For more information, see Replacing Auto Scaling instances based on maximum instance lifetime (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-max-instance-lifetime.html) in the Amazon EC2 Auto Scaling User Guide.
  --context: string # Reserved.
  --desired-capacity-type: string # The unit of measurement for the value specified for desired capacity. Amazon EC2 Auto Scaling supports DesiredCapacityType for attribute-based instance type selection only. For more information, see Creating an Auto Scaling group using attribute-based instance type selection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-asg-instance-type-requirements.html) in the Amazon EC2 Auto Scaling User Guide. By default, Amazon EC2 Auto Scaling specifies units, which translates into number of instances. Valid values: units | vcpu | memory-mib
  --default-instance-warmup: int # The amount of time, in seconds, until a new instance is considered to have finished initializing and resource consumption to become stable after it enters the InService state. During an instance refresh, Amazon EC2 Auto Scaling waits for the warm-up period after it replaces an instance before it moves on to replacing the next instance. Amazon EC2 Auto Scaling also waits for the warm-up period before aggregating the metrics for new instances with existing instances in the Amazon CloudWatch metrics that are used for scaling, resulting in more reliable usage data. For more information, see Set the default instance warmup for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-default-instance-warmup.html) in the Amazon EC2 Auto Scaling User Guide. To manage various warm-up settings at the group level, we recommend that you set the default instance warmup, even if it is set to 0 seconds. To remove a value that you previously set, include the property but specify -1 for the value. However, we strongly recommend keeping the default instance warmup enabled by specifying a value of 0 or other nominal value. Default: None
  --traffic-sources: list # The list of traffic sources to attach to this Auto Scaling group. You can use any of the following as traffic sources for an Auto Scaling group: Classic Load Balancer, Application Load Balancer, Gateway Load Balancer, Network Load Balancer, and VPC Lattice.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "LaunchConfigurationName" $launch_configuration_name "scalar") (serialize-qp "LaunchTemplate" $launch_template "multi") (serialize-qp "MixedInstancesPolicy" $mixed_instances_policy "multi") (serialize-qp "InstanceId" $instance_id "scalar") (serialize-qp "MinSize" $min_size "scalar") (serialize-qp "MaxSize" $max_size "scalar") (serialize-qp "DesiredCapacity" $desired_capacity "scalar") (serialize-qp "DefaultCooldown" $default_cooldown "scalar") (serialize-qp "AvailabilityZones" $availability_zones "multi") (serialize-qp "LoadBalancerNames" $load_balancer_names "multi") (serialize-qp "TargetGroupARNs" $target_group_ar_ns "multi") (serialize-qp "HealthCheckType" $health_check_type "scalar") (serialize-qp "HealthCheckGracePeriod" $health_check_grace_period "scalar") (serialize-qp "PlacementGroup" $placement_group "scalar") (serialize-qp "VPCZoneIdentifier" $vpc_zone_identifier "scalar") (serialize-qp "TerminationPolicies" $termination_policies "multi") (serialize-qp "NewInstancesProtectedFromScaleIn" $new_instances_protected_from_scale_in "scalar") (serialize-qp "CapacityRebalance" $capacity_rebalance "scalar") (serialize-qp "LifecycleHookSpecificationList" $lifecycle_hook_specification_list "multi") (serialize-qp "Tags" $tags "multi") (serialize-qp "ServiceLinkedRoleARN" $service_linked_role_arn "scalar") (serialize-qp "MaxInstanceLifetime" $max_instance_lifetime "scalar") (serialize-qp "Context" $context "scalar") (serialize-qp "DesiredCapacityType" $desired_capacity_type "scalar") (serialize-qp "DefaultInstanceWarmup" $default_instance_warmup "scalar") (serialize-qp "TrafficSources" $traffic_sources "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "LaunchConfigurationName": $launch_configuration_name, "LaunchTemplate": $launch_template, "MixedInstancesPolicy": $mixed_instances_policy, "InstanceId": $instance_id, "MinSize": $min_size, "MaxSize": $max_size, "DesiredCapacity": $desired_capacity, "DefaultCooldown": $default_cooldown, "AvailabilityZones": $availability_zones, "LoadBalancerNames": $load_balancer_names, "TargetGroupARNs": $target_group_ar_ns, "HealthCheckType": $health_check_type, "HealthCheckGracePeriod": $health_check_grace_period, "PlacementGroup": $placement_group, "VPCZoneIdentifier": $vpc_zone_identifier, "TerminationPolicies": $termination_policies, "NewInstancesProtectedFromScaleIn": $new_instances_protected_from_scale_in, "CapacityRebalance": $capacity_rebalance, "LifecycleHookSpecificationList": $lifecycle_hook_specification_list, "Tags": $tags, "ServiceLinkedRoleARN": $service_linked_role_arn, "MaxInstanceLifetime": $max_instance_lifetime, "Context": $context, "DesiredCapacityType": $desired_capacity_type, "DefaultInstanceWarmup": $default_instance_warmup, "TrafficSources": $traffic_sources, "Action": $action, "Version": $version} | compact), body: null}
}

# We strongly recommend using a launch template when calling this operation to ensure full functionality for Amazon EC2 Auto Scaling and Amazon EC2. Creates an Auto Scaling group with the specified name and attributes. If you exceed your maximum limit of Auto Scaling groups, the call fails. To query this limit, call the DescribeAccountLimits API. For information about updating this limit, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide. For introductory exercises for creating an Auto Scaling group, see Getting started with Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/GettingStartedTutorial.html) and Tutorial: Set up a scaled and load-balanced application (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-register-lbs-with-asg.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Auto Scaling groups (https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html) in the Amazon EC2 Auto Scaling User Guide. Every Auto Scaling group has three size properties (DesiredCapacity, MaxSize, and MinSize). Usually, you set these sizes based on a specific number of instances. However, if you configure a mixed instances policy that defines weights for the instance types, you must specify these sizes with the same units that you use for weighting instances.
#
# POST /
# operationId: POST_CreateAutoScalingGroup
export def "api create-auto-scaling-group" [
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
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Creates a launch configuration. If you exceed your maximum limit of launch configurations, the call fails. To query this limit, call the DescribeAccountLimits API. For information about updating this limit, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Launch configurations (https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchConfiguration.html) in the Amazon EC2 Auto Scaling User Guide. Amazon EC2 Auto Scaling configures instances launched as part of an Auto Scaling group using either a launch template or a launch configuration. We strongly recommend that you do not use launch configurations. They do not provide full functionality for Amazon EC2 Auto Scaling or Amazon EC2. For information about using launch templates, see Launch templates (https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-templates.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_CreateLaunchConfiguration
export def "api get-create-launch-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --launch-configuration-name: string # The name of the launch configuration. This name must be unique per Region per account.
  --image-id: string # The ID of the Amazon Machine Image (AMI) that was assigned during registration. For more information, see Finding a Linux AMI (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html) in the Amazon EC2 User Guide for Linux Instances. If you specify InstanceId, an ImageId is not required.
  --key-name: string # The name of the key pair. For more information, see Amazon EC2 key pairs and Linux instances (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) in the Amazon EC2 User Guide for Linux Instances.
  --security-groups: list # A list that contains the security group IDs to assign to the instances in the Auto Scaling group. For more information, see Control traffic to resources using security groups (https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_SecurityGroups.html) in the Amazon Virtual Private Cloud User Guide.
  --classic-link-vpc-id: string # Available for backward compatibility.
  --classic-link-vpc-security-groups: list # Available for backward compatibility.
  --user-data: string # The user data to make available to the launched EC2 instances. For more information, see Instance metadata and user data (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) (Linux) and Instance metadata and user data (https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2-instance-metadata.html) (Windows). If you are using a command line tool, base64-encoding is performed for you, and you can load the text from a file. Otherwise, you must provide base64-encoded text. User data is limited to 16 KB.
  --instance-id: string # The ID of the instance to use to create the launch configuration. The new launch configuration derives attributes from the instance, except for the block device mapping. To create a launch configuration with a block device mapping or override any other instance attributes, specify them as part of the same request. For more information, see Creating a launch configuration using an EC2 instance (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-lc-with-instanceID.html) in the Amazon EC2 Auto Scaling User Guide.
  --instance-type: string # Specifies the instance type of the EC2 instance. For information about available instance types, see Available instance types (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#AvailableInstanceTypes) in the Amazon EC2 User Guide for Linux Instances. If you specify InstanceId, an InstanceType is not required.
  --kernel-id: string # The ID of the kernel associated with the AMI. We recommend that you use PV-GRUB instead of kernels and RAM disks. For more information, see User provided kernels (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/UserProvidedKernels.html) in the Amazon EC2 User Guide for Linux Instances.
  --ramdisk-id: string # The ID of the RAM disk to select. We recommend that you use PV-GRUB instead of kernels and RAM disks. For more information, see User provided kernels (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/UserProvidedKernels.html) in the Amazon EC2 User Guide for Linux Instances.
  --block-device-mappings: list # The block device mapping entries that define the block devices to attach to the instances at launch. By default, the block devices specified in the block device mapping for the AMI are used. For more information, see Block device mappings (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/block-device-mapping-concepts.html) in the Amazon EC2 User Guide for Linux Instances.
  --instance-monitoring: record # Controls whether instances in this group are launched with detailed (true) or basic (false) monitoring. The default value is true (enabled). When detailed monitoring is enabled, Amazon CloudWatch generates metrics every minute and your account is charged a fee. When you disable detailed monitoring, CloudWatch generates metrics every 5 minutes. For more information, see Configure Monitoring for Auto Scaling Instances (https://docs.aws.amazon.com/autoscaling/latest/userguide/enable-as-instance-metrics.html) in the Amazon EC2 Auto Scaling User Guide.
  --spot-price: string # The maximum hourly price to be paid for any Spot Instance launched to fulfill the request. Spot Instances are launched when the price you specify exceeds the current Spot price. For more information, see Request Spot Instances for fault-tolerant and flexible applications (https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-template-spot-instances.html) in the Amazon EC2 Auto Scaling User Guide. Valid Range: Minimum value of 0.001 When you change your maximum price by creating a new launch configuration, running instances will continue to run as long as the maximum price for those running instances is higher than the current Spot price.
  --iam-instance-profile: string # The name or the Amazon Resource Name (ARN) of the instance profile associated with the IAM role for the instance. The instance profile contains the IAM role. For more information, see IAM role for applications that run on Amazon EC2 instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/us-iam-role.html) in the Amazon EC2 Auto Scaling User Guide.
  --ebs-optimized: oneof<nothing, bool> # Specifies whether the launch configuration is optimized for EBS I/O (true) or not (false). The optimization provides dedicated throughput to Amazon EBS and an optimized configuration stack to provide optimal I/O performance. This optimization is not available with all instance types. Additional fees are incurred when you enable EBS optimization for an instance type that is not EBS-optimized by default. For more information, see Amazon EBS-optimized instances (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSOptimized.html) in the Amazon EC2 User Guide for Linux Instances. The default value is false.
  --associate-public-ip-address: oneof<nothing, bool> # Specifies whether to assign a public IPv4 address to the group's instances. If the instance is launched into a default subnet, the default is to assign a public IPv4 address, unless you disabled the option to assign a public IPv4 address on the subnet. If the instance is launched into a nondefault subnet, the default is not to assign a public IPv4 address, unless you enabled the option to assign a public IPv4 address on the subnet. If you specify true, each instance in the Auto Scaling group receives a unique public IPv4 address. For more information, see Launching Auto Scaling instances in a VPC (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-in-vpc.html) in the Amazon EC2 Auto Scaling User Guide. If you specify this property, you must specify at least one subnet for VPCZoneIdentifier when you create your group.
  --placement-tenancy: string # The tenancy of the instance, either default or dedicated. An instance with dedicated tenancy runs on isolated, single-tenant hardware and can only be launched into a VPC. To launch dedicated instances into a shared tenancy VPC (a VPC with the instance placement tenancy attribute set to default), you must set the value of this property to dedicated. For more information, see Configuring instance tenancy with Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-dedicated-instances.html) in the Amazon EC2 Auto Scaling User Guide. If you specify PlacementTenancy, you must specify at least one subnet for VPCZoneIdentifier when you create your group. Valid values: default | dedicated
  --metadata-options: record # The metadata options for the instances. For more information, see Configuring the Instance Metadata Options (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-launch-config.html#launch-configurations-imds) in the Amazon EC2 Auto Scaling User Guide.
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
  let qp = [(serialize-qp "LaunchConfigurationName" $launch_configuration_name "scalar") (serialize-qp "ImageId" $image_id "scalar") (serialize-qp "KeyName" $key_name "scalar") (serialize-qp "SecurityGroups" $security_groups "multi") (serialize-qp "ClassicLinkVPCId" $classic_link_vpc_id "scalar") (serialize-qp "ClassicLinkVPCSecurityGroups" $classic_link_vpc_security_groups "multi") (serialize-qp "UserData" $user_data "scalar") (serialize-qp "InstanceId" $instance_id "scalar") (serialize-qp "InstanceType" $instance_type "scalar") (serialize-qp "KernelId" $kernel_id "scalar") (serialize-qp "RamdiskId" $ramdisk_id "scalar") (serialize-qp "BlockDeviceMappings" $block_device_mappings "multi") (serialize-qp "InstanceMonitoring" $instance_monitoring "multi") (serialize-qp "SpotPrice" $spot_price "scalar") (serialize-qp "IamInstanceProfile" $iam_instance_profile "scalar") (serialize-qp "EbsOptimized" $ebs_optimized "scalar") (serialize-qp "AssociatePublicIpAddress" $associate_public_ip_address "scalar") (serialize-qp "PlacementTenancy" $placement_tenancy "scalar") (serialize-qp "MetadataOptions" $metadata_options "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"LaunchConfigurationName": $launch_configuration_name, "ImageId": $image_id, "KeyName": $key_name, "SecurityGroups": $security_groups, "ClassicLinkVPCId": $classic_link_vpc_id, "ClassicLinkVPCSecurityGroups": $classic_link_vpc_security_groups, "UserData": $user_data, "InstanceId": $instance_id, "InstanceType": $instance_type, "KernelId": $kernel_id, "RamdiskId": $ramdisk_id, "BlockDeviceMappings": $block_device_mappings, "InstanceMonitoring": $instance_monitoring, "SpotPrice": $spot_price, "IamInstanceProfile": $iam_instance_profile, "EbsOptimized": $ebs_optimized, "AssociatePublicIpAddress": $associate_public_ip_address, "PlacementTenancy": $placement_tenancy, "MetadataOptions": $metadata_options, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates a launch configuration. If you exceed your maximum limit of launch configurations, the call fails. To query this limit, call the DescribeAccountLimits API. For information about updating this limit, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Launch configurations (https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchConfiguration.html) in the Amazon EC2 Auto Scaling User Guide. Amazon EC2 Auto Scaling configures instances launched as part of an Auto Scaling group using either a launch template or a launch configuration. We strongly recommend that you do not use launch configurations. They do not provide full functionality for Amazon EC2 Auto Scaling or Amazon EC2. For information about using launch templates, see Launch templates (https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-templates.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_CreateLaunchConfiguration
export def "api create-launch-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
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

# Creates or updates tags for the specified Auto Scaling group. When you specify a tag with a key that already exists, the operation overwrites the previous tag definition, and you do not get an error message. For more information, see Tag Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_CreateOrUpdateTags
export def "api get-create-or-update-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: list # One or more tags.
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
  let qp = [(serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates or updates tags for the specified Auto Scaling group. When you specify a tag with a key that already exists, the operation overwrites the previous tag definition, and you do not get an error message. For more information, see Tag Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_CreateOrUpdateTags
export def "api create-or-update-tags" [
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
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes the specified Auto Scaling group. If the group has instances or scaling activities in progress, you must specify the option to force the deletion in order for it to succeed. The force delete operation will also terminate the EC2 instances. If the group has a warm pool, the force delete option also deletes the warm pool. To remove instances from the Auto Scaling group before deleting it, call the DetachInstances API with the list of instances and the option to decrement the desired capacity. This ensures that Amazon EC2 Auto Scaling does not launch replacement instances. To terminate all instances before deleting the Auto Scaling group, call the UpdateAutoScalingGroup API and set the minimum size and desired capacity of the Auto Scaling group to zero. If the group has scaling policies, deleting the group deletes the policies, the underlying alarm actions, and any alarm that no longer has an associated action. For more information, see Delete your Auto Scaling infrastructure (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-process-shutdown.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DeleteAutoScalingGroup
export def "api get-delete-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --force-delete: oneof<nothing, bool> # Specifies that the group is to be deleted along with all instances associated with the group, without waiting for all instances to be terminated. This action also deletes any outstanding lifecycle actions associated with the group.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ForceDelete" $force_delete "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "ForceDelete": $force_delete, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified Auto Scaling group. If the group has instances or scaling activities in progress, you must specify the option to force the deletion in order for it to succeed. The force delete operation will also terminate the EC2 instances. If the group has a warm pool, the force delete option also deletes the warm pool. To remove instances from the Auto Scaling group before deleting it, call the DetachInstances API with the list of instances and the option to decrement the desired capacity. This ensures that Amazon EC2 Auto Scaling does not launch replacement instances. To terminate all instances before deleting the Auto Scaling group, call the UpdateAutoScalingGroup API and set the minimum size and desired capacity of the Auto Scaling group to zero. If the group has scaling policies, deleting the group deletes the policies, the underlying alarm actions, and any alarm that no longer has an associated action. For more information, see Delete your Auto Scaling infrastructure (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-process-shutdown.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DeleteAutoScalingGroup
export def "api create-delete-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
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

# Deletes the specified launch configuration. The launch configuration must not be attached to an Auto Scaling group. When this call completes, the launch configuration is no longer available for use.
#
# GET /
# operationId: GET_DeleteLaunchConfiguration
export def "api get-delete-launch-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --launch-configuration-name: string # The name of the launch configuration.
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
  let qp = [(serialize-qp "LaunchConfigurationName" $launch_configuration_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"LaunchConfigurationName": $launch_configuration_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified launch configuration. The launch configuration must not be attached to an Auto Scaling group. When this call completes, the launch configuration is no longer available for use.
#
# POST /
# operationId: POST_DeleteLaunchConfiguration
export def "api create-delete-launch-configuration" [
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

# Deletes the specified lifecycle hook. If there are any outstanding lifecycle actions, they are completed first (ABANDON for launching instances, CONTINUE for terminating instances).
#
# GET /
# operationId: GET_DeleteLifecycleHook
export def "api get-delete-lifecycle-hook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lifecycle-hook-name: string # The name of the lifecycle hook.
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
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
  let qp = [(serialize-qp "LifecycleHookName" $lifecycle_hook_name "scalar") (serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"LifecycleHookName": $lifecycle_hook_name, "AutoScalingGroupName": $auto_scaling_group_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified lifecycle hook. If there are any outstanding lifecycle actions, they are completed first (ABANDON for launching instances, CONTINUE for terminating instances).
#
# POST /
# operationId: POST_DeleteLifecycleHook
export def "api create-delete-lifecycle-hook" [
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

# Deletes the specified notification.
#
# GET /
# operationId: GET_DeleteNotificationConfiguration
export def "api get-delete-notification-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --topic-arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "TopicARN" $topic_arn "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "TopicARN": $topic_arn, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified notification.
#
# POST /
# operationId: POST_DeleteNotificationConfiguration
export def "api create-delete-notification-configuration" [
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

# Deletes the specified scaling policy. Deleting either a step scaling policy or a simple scaling policy deletes the underlying alarm action, but does not delete the alarm, even if it no longer has an associated action. For more information, see Deleting a scaling policy (https://docs.aws.amazon.com/autoscaling/ec2/userguide/deleting-scaling-policy.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DeletePolicy
export def "api get-delete-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --policy-name: string # The name or Amazon Resource Name (ARN) of the policy.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "PolicyName" $policy_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "PolicyName": $policy_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified scaling policy. Deleting either a step scaling policy or a simple scaling policy deletes the underlying alarm action, but does not delete the alarm, even if it no longer has an associated action. For more information, see Deleting a scaling policy (https://docs.aws.amazon.com/autoscaling/ec2/userguide/deleting-scaling-policy.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DeletePolicy
export def "api create-delete-policy" [
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
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes the specified scheduled action.
#
# GET /
# operationId: GET_DeleteScheduledAction
export def "api get-delete-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --scheduled-action-name: string # The name of the action to delete.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ScheduledActionName" $scheduled_action_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "ScheduledActionName": $scheduled_action_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified scheduled action.
#
# POST /
# operationId: POST_DeleteScheduledAction
export def "api create-delete-scheduled-action" [
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
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Deletes the specified tags.
#
# GET /
# operationId: GET_DeleteTags
export def "api get-delete-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: list # One or more tags.
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
  let qp = [(serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Tags": $tags, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the specified tags.
#
# POST /
# operationId: POST_DeleteTags
export def "api create-delete-tags" [
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

# Deletes the warm pool for the specified Auto Scaling group. For more information, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DeleteWarmPool
export def "api get-delete-warm-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --force-delete: oneof<nothing, bool> # Specifies that the warm pool is to be deleted along with all of its associated instances, without waiting for all instances to be terminated. This parameter also deletes any outstanding lifecycle actions associated with the warm pool instances.
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ForceDelete" $force_delete "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "ForceDelete": $force_delete, "Action": $action, "Version": $version} | compact), body: null}
}

# Deletes the warm pool for the specified Auto Scaling group. For more information, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DeleteWarmPool
export def "api create-delete-warm-pool" [
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
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"Action": $action, "Version": $version} | compact), body: $req_body}
}

# Describes the current Amazon EC2 Auto Scaling resource quotas for your account. When you establish an Amazon Web Services account, the account has initial quotas on the maximum number of Auto Scaling groups and launch configurations that you can create in a given Region. For more information, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeAccountLimits
export def "api get-account-limits" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Describes the current Amazon EC2 Auto Scaling resource quotas for your account. When you establish an Amazon Web Services account, the account has initial quotas on the maximum number of Auto Scaling groups and launch configurations that you can create in a given Region. For more information, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeAccountLimits
export def "api create-get-account-limits" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Describes the available adjustment types for step scaling and simple scaling policies. The following adjustment types are supported: ChangeInCapacity ExactCapacity PercentChangeInCapacity
#
# GET /
# operationId: GET_DescribeAdjustmentTypes
export def "api get-adjustment-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-20
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Describes the available adjustment types for step scaling and simple scaling policies. The following adjustment types are supported: ChangeInCapacity ExactCapacity PercentChangeInCapacity
#
# POST /
# operationId: POST_DescribeAdjustmentTypes
export def "api create-get-adjustment-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-20
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the Auto Scaling groups in the account and Region. If you specify Auto Scaling group names, the output includes information for only the specified Auto Scaling groups. If you specify filters, the output includes information for only those Auto Scaling groups that meet the filter criteria. If you do not specify group names or filters, the output includes information for all Auto Scaling groups. This operation also returns information about instances in Auto Scaling groups. To retrieve information about the instances in a warm pool, you must call the DescribeWarmPool API.
#
# GET /
# operationId: GET_DescribeAutoScalingGroups
export def "api get-auto-scaling-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-names: list # The names of the Auto Scaling groups. By default, you can only specify up to 50 names. You can optionally increase this limit using the MaxRecords property. If you omit this property, all Auto Scaling groups are described.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --filters: list # One or more filters to limit the results based on specific tags.
  --action: string@action-completer-21
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
  let qp = [(serialize-qp "AutoScalingGroupNames" $auto_scaling_group_names "multi") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupNames": $auto_scaling_group_names, "NextToken": $next_token, "MaxRecords": $max_records, "Filters": $filters, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the Auto Scaling groups in the account and Region. If you specify Auto Scaling group names, the output includes information for only the specified Auto Scaling groups. If you specify filters, the output includes information for only those Auto Scaling groups that meet the filter criteria. If you do not specify group names or filters, the output includes information for all Auto Scaling groups. This operation also returns information about instances in Auto Scaling groups. To retrieve information about the instances in a warm pool, you must call the DescribeWarmPool API.
#
# POST /
# operationId: POST_DescribeAutoScalingGroups
export def "api create-get-auto-scaling-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-21
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
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Gets information about the Auto Scaling instances in the account and Region.
#
# GET /
# operationId: GET_DescribeAutoScalingInstances
export def "api get-auto-scaling-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list # The IDs of the instances. If you omit this property, all Auto Scaling instances are described. If you specify an ID that does not exist, it is ignored with no error. Array Members: Maximum number of 50 items.
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 50.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --action: string@action-completer-22
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
  let qp = [(serialize-qp "InstanceIds" $instance_ids "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"InstanceIds": $instance_ids, "MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the Auto Scaling instances in the account and Region.
#
# POST /
# operationId: POST_DescribeAutoScalingInstances
export def "api create-get-auto-scaling-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-22
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
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Describes the notification types that are supported by Amazon EC2 Auto Scaling.
#
# GET /
# operationId: GET_DescribeAutoScalingNotificationTypes
export def "api get-auto-scaling-notification-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-23
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Describes the notification types that are supported by Amazon EC2 Auto Scaling.
#
# POST /
# operationId: POST_DescribeAutoScalingNotificationTypes
export def "api create-get-auto-scaling-notification-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-23
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the instance refreshes for the specified Auto Scaling group. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. To help you determine the status of an instance refresh, Amazon EC2 Auto Scaling returns information about the instance refreshes you previously initiated, including their status, start time, end time, the percentage of the instance refresh that is complete, and the number of instances remaining to update before the instance refresh is complete. If a rollback is initiated while an instance refresh is in progress, Amazon EC2 Auto Scaling also returns information about the rollback of the instance refresh.
#
# GET /
# operationId: GET_DescribeInstanceRefreshes
export def "api get-instance-refreshes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --instance-refresh-ids: list # One or more instance refresh IDs.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-24
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "InstanceRefreshIds" $instance_refresh_ids "multi") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "InstanceRefreshIds": $instance_refresh_ids, "NextToken": $next_token, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the instance refreshes for the specified Auto Scaling group. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. To help you determine the status of an instance refresh, Amazon EC2 Auto Scaling returns information about the instance refreshes you previously initiated, including their status, start time, end time, the percentage of the instance refresh that is complete, and the number of instances remaining to update before the instance refresh is complete. If a rollback is initiated while an instance refresh is in progress, Amazon EC2 Auto Scaling also returns information about the rollback of the instance refresh.
#
# POST /
# operationId: POST_DescribeInstanceRefreshes
export def "api create-get-instance-refreshes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-24
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

# Gets information about the launch configurations in the account and Region.
#
# GET /
# operationId: GET_DescribeLaunchConfigurations
export def "api get-launch-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --launch-configuration-names: list # The launch configuration names. If you omit this property, all launch configurations are described. Array Members: Maximum number of 50 items.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-25
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
  let qp = [(serialize-qp "LaunchConfigurationNames" $launch_configuration_names "multi") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"LaunchConfigurationNames": $launch_configuration_names, "NextToken": $next_token, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the launch configurations in the account and Region.
#
# POST /
# operationId: POST_DescribeLaunchConfigurations
export def "api create-get-launch-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-25
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
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Describes the available types of lifecycle hooks. The following hook types are supported: autoscaling:EC2_INSTANCE_LAUNCHING autoscaling:EC2_INSTANCE_TERMINATING
#
# GET /
# operationId: GET_DescribeLifecycleHookTypes
export def "api get-lifecycle-hook-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-26
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Describes the available types of lifecycle hooks. The following hook types are supported: autoscaling:EC2_INSTANCE_LAUNCHING autoscaling:EC2_INSTANCE_TERMINATING
#
# POST /
# operationId: POST_DescribeLifecycleHookTypes
export def "api create-get-lifecycle-hook-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-26
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the lifecycle hooks for the specified Auto Scaling group.
#
# GET /
# operationId: GET_DescribeLifecycleHooks
export def "api get-lifecycle-hooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --lifecycle-hook-names: list # The names of one or more lifecycle hooks. If you omit this property, all lifecycle hooks are described.
  --action: string@action-completer-27
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "LifecycleHookNames" $lifecycle_hook_names "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "LifecycleHookNames": $lifecycle_hook_names, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the lifecycle hooks for the specified Auto Scaling group.
#
# POST /
# operationId: POST_DescribeLifecycleHooks
export def "api create-get-lifecycle-hooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-27
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

# This API operation is superseded by DescribeTrafficSources, which can describe multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DescribeLoadBalancerTargetGroups. You can use both the original DescribeLoadBalancerTargetGroups API operation and DescribeTrafficSources on the same Auto Scaling group. Gets information about the Elastic Load Balancing target groups for the specified Auto Scaling group. To determine the attachment status of the target group, use the State element in the response. When you attach a target group to an Auto Scaling group, the initial State value is Adding. The state transitions to Added after all Auto Scaling instances are registered with the target group. If Elastic Load Balancing health checks are enabled for the Auto Scaling group, the state transitions to InService after at least one Auto Scaling instance passes the health check. When the target group is in the InService state, Amazon EC2 Auto Scaling can terminate and replace any instances that are reported as unhealthy. If no registered instances pass the health checks, the target group doesn't enter the InService state. Target groups also have an InService state if you attach them in the CreateAutoScalingGroup API call. If your target group state is InService, but it is not working properly, check the scaling activities by calling DescribeScalingActivities and take any corrective actions necessary. For help with failed health checks, see Troubleshooting Amazon EC2 Auto Scaling: Health checks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ts-as-healthchecks.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide. You can use this operation to describe target groups that were attached by using AttachLoadBalancerTargetGroups, but not for target groups that were attached by using AttachTrafficSources.
#
# GET /
# operationId: GET_DescribeLoadBalancerTargetGroups
export def "api get-load-balancer-target-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 100 and the maximum value is 100.
  --action: string@action-completer-28
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "NextToken": $next_token, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# This API operation is superseded by DescribeTrafficSources, which can describe multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DescribeLoadBalancerTargetGroups. You can use both the original DescribeLoadBalancerTargetGroups API operation and DescribeTrafficSources on the same Auto Scaling group. Gets information about the Elastic Load Balancing target groups for the specified Auto Scaling group. To determine the attachment status of the target group, use the State element in the response. When you attach a target group to an Auto Scaling group, the initial State value is Adding. The state transitions to Added after all Auto Scaling instances are registered with the target group. If Elastic Load Balancing health checks are enabled for the Auto Scaling group, the state transitions to InService after at least one Auto Scaling instance passes the health check. When the target group is in the InService state, Amazon EC2 Auto Scaling can terminate and replace any instances that are reported as unhealthy. If no registered instances pass the health checks, the target group doesn't enter the InService state. Target groups also have an InService state if you attach them in the CreateAutoScalingGroup API call. If your target group state is InService, but it is not working properly, check the scaling activities by calling DescribeScalingActivities and take any corrective actions necessary. For help with failed health checks, see Troubleshooting Amazon EC2 Auto Scaling: Health checks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ts-as-healthchecks.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide. You can use this operation to describe target groups that were attached by using AttachLoadBalancerTargetGroups, but not for target groups that were attached by using AttachTrafficSources.
#
# POST /
# operationId: POST_DescribeLoadBalancerTargetGroups
export def "api create-get-load-balancer-target-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-28
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

# This API operation is superseded by DescribeTrafficSources, which can describe multiple traffic sources types. We recommend using DescribeTrafficSources to simplify how you manage traffic sources. However, we continue to support DescribeLoadBalancers. You can use both the original DescribeLoadBalancers API operation and DescribeTrafficSources on the same Auto Scaling group. Gets information about the load balancers for the specified Auto Scaling group. This operation describes only Classic Load Balancers. If you have Application Load Balancers, Network Load Balancers, or Gateway Load Balancers, use the DescribeLoadBalancerTargetGroups API instead. To determine the attachment status of the load balancer, use the State element in the response. When you attach a load balancer to an Auto Scaling group, the initial State value is Adding. The state transitions to Added after all Auto Scaling instances are registered with the load balancer. If Elastic Load Balancing health checks are enabled for the Auto Scaling group, the state transitions to InService after at least one Auto Scaling instance passes the health check. When the load balancer is in the InService state, Amazon EC2 Auto Scaling can terminate and replace any instances that are reported as unhealthy. If no registered instances pass the health checks, the load balancer doesn't enter the InService state. Load balancers also have an InService state if you attach them in the CreateAutoScalingGroup API call. If your load balancer state is InService, but it is not working properly, check the scaling activities by calling DescribeScalingActivities and take any corrective actions necessary. For help with failed health checks, see Troubleshooting Amazon EC2 Auto Scaling: Health checks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ts-as-healthchecks.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeLoadBalancers
export def "api get-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 100 and the maximum value is 100.
  --action: string@action-completer-29
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "NextToken": $next_token, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# This API operation is superseded by DescribeTrafficSources, which can describe multiple traffic sources types. We recommend using DescribeTrafficSources to simplify how you manage traffic sources. However, we continue to support DescribeLoadBalancers. You can use both the original DescribeLoadBalancers API operation and DescribeTrafficSources on the same Auto Scaling group. Gets information about the load balancers for the specified Auto Scaling group. This operation describes only Classic Load Balancers. If you have Application Load Balancers, Network Load Balancers, or Gateway Load Balancers, use the DescribeLoadBalancerTargetGroups API instead. To determine the attachment status of the load balancer, use the State element in the response. When you attach a load balancer to an Auto Scaling group, the initial State value is Adding. The state transitions to Added after all Auto Scaling instances are registered with the load balancer. If Elastic Load Balancing health checks are enabled for the Auto Scaling group, the state transitions to InService after at least one Auto Scaling instance passes the health check. When the load balancer is in the InService state, Amazon EC2 Auto Scaling can terminate and replace any instances that are reported as unhealthy. If no registered instances pass the health checks, the load balancer doesn't enter the InService state. Load balancers also have an InService state if you attach them in the CreateAutoScalingGroup API call. If your load balancer state is InService, but it is not working properly, check the scaling activities by calling DescribeScalingActivities and take any corrective actions necessary. For help with failed health checks, see Troubleshooting Amazon EC2 Auto Scaling: Health checks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ts-as-healthchecks.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeLoadBalancers
export def "api create-get-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-29
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

# Describes the available CloudWatch metrics for Amazon EC2 Auto Scaling.
#
# GET /
# operationId: GET_DescribeMetricCollectionTypes
export def "api get-metric-collection-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-30
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Describes the available CloudWatch metrics for Amazon EC2 Auto Scaling.
#
# POST /
# operationId: POST_DescribeMetricCollectionTypes
export def "api create-get-metric-collection-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-30
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the Amazon SNS notifications that are configured for one or more Auto Scaling groups.
#
# GET /
# operationId: GET_DescribeNotificationConfigurations
export def "api get-notification-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-names: list # The name of the Auto Scaling group.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-31
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
  let qp = [(serialize-qp "AutoScalingGroupNames" $auto_scaling_group_names "multi") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupNames": $auto_scaling_group_names, "NextToken": $next_token, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the Amazon SNS notifications that are configured for one or more Auto Scaling groups.
#
# POST /
# operationId: POST_DescribeNotificationConfigurations
export def "api create-get-notification-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-31
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
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Gets information about the scaling policies in the account and Region.
#
# GET /
# operationId: GET_DescribePolicies
export def "api get-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --policy-names: list # The names of one or more policies. If you omit this property, all policies are described. If a group name is provided, the results are limited to that group. If you specify an unknown policy name, it is ignored with no error. Array Members: Maximum number of 50 items.
  --policy-types: list # One or more policy types. The valid values are SimpleScaling, StepScaling, TargetTrackingScaling, and PredictiveScaling.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to be returned with each call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-32
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "PolicyNames" $policy_names "multi") (serialize-qp "PolicyTypes" $policy_types "multi") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "PolicyNames": $policy_names, "PolicyTypes": $policy_types, "NextToken": $next_token, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the scaling policies in the account and Region.
#
# POST /
# operationId: POST_DescribePolicies
export def "api create-get-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-32
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
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Gets information about the scaling activities in the account and Region. When scaling events occur, you see a record of the scaling activity in the scaling activities. For more information, see Verifying a scaling activity for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-verify-scaling-activity.html) in the Amazon EC2 Auto Scaling User Guide. If the scaling event succeeds, the value of the StatusCode element in the response is Successful. If an attempt to launch instances failed, the StatusCode value is Failed or Cancelled and the StatusMessage element in the response indicates the cause of the failure. For help interpreting the StatusMessage, see Troubleshooting Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/CHAP_Troubleshooting.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeScalingActivities
export def "api get-scaling-activities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-ids: list # The activity IDs of the desired scaling activities. If you omit this property, all activities for the past six weeks are described. If unknown activities are requested, they are ignored with no error. If you specify an Auto Scaling group, the results are limited to that group. Array Members: Maximum number of 50 IDs.
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --include-deleted-groups: oneof<nothing, bool> # Indicates whether to include scaling activity from deleted Auto Scaling groups.
  --max-records: int # The maximum number of items to return with this call. The default value is 100 and the maximum value is 100.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --action: string@action-completer-33
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
  let qp = [(serialize-qp "ActivityIds" $activity_ids "multi") (serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "IncludeDeletedGroups" $include_deleted_groups "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ActivityIds": $activity_ids, "AutoScalingGroupName": $auto_scaling_group_name, "IncludeDeletedGroups": $include_deleted_groups, "MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the scaling activities in the account and Region. When scaling events occur, you see a record of the scaling activity in the scaling activities. For more information, see Verifying a scaling activity for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-verify-scaling-activity.html) in the Amazon EC2 Auto Scaling User Guide. If the scaling event succeeds, the value of the StatusCode element in the response is Successful. If an attempt to launch instances failed, the StatusCode value is Failed or Cancelled and the StatusMessage element in the response indicates the cause of the failure. For help interpreting the StatusMessage, see Troubleshooting Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/CHAP_Troubleshooting.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeScalingActivities
export def "api create-get-scaling-activities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-33
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
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Describes the scaling process types for use with the ResumeProcesses and SuspendProcesses APIs.
#
# GET /
# operationId: GET_DescribeScalingProcessTypes
export def "api get-scaling-process-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-34
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Describes the scaling process types for use with the ResumeProcesses and SuspendProcesses APIs.
#
# POST /
# operationId: POST_DescribeScalingProcessTypes
export def "api create-get-scaling-process-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-34
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the scheduled actions that haven't run or that have not reached their end time. To describe the scaling activities for scheduled actions that have already run, call the DescribeScalingActivities API.
#
# GET /
# operationId: GET_DescribeScheduledActions
export def "api get-scheduled-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --scheduled-action-names: list # The names of one or more scheduled actions. If you omit this property, all scheduled actions are described. If you specify an unknown scheduled action, it is ignored with no error. Array Members: Maximum number of 50 actions.
  --start-time: string # The earliest scheduled start time to return. If scheduled action names are provided, this property is ignored. (format: date-time)
  --end-time: string # The latest scheduled start time to return. If scheduled action names are provided, this property is ignored. (format: date-time)
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-35
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ScheduledActionNames" $scheduled_action_names "multi") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "ScheduledActionNames": $scheduled_action_names, "StartTime": $start_time, "EndTime": $end_time, "NextToken": $next_token, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the scheduled actions that haven't run or that have not reached their end time. To describe the scaling activities for scheduled actions that have already run, call the DescribeScalingActivities API.
#
# POST /
# operationId: POST_DescribeScheduledActions
export def "api create-get-scheduled-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-35
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
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Describes the specified tags. You can use filters to limit the results. For example, you can query for the tags for a specific Auto Scaling group. You can specify multiple values for a filter. A tag must match at least one of the specified values for it to be included in the results. You can also specify multiple filters. The result includes information for a particular tag only if it matches all the filters. If there's no match, no special message is returned. For more information, see Tag Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeTags
export def "api get-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # One or more filters to scope the tags to return. The maximum number of filters per filter type (for example, auto-scaling-group) is 1000.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-36
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
  let qp = [(serialize-qp "Filters" $filters "multi") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Filters": $filters, "NextToken": $next_token, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# Describes the specified tags. You can use filters to limit the results. For example, you can query for the tags for a specific Auto Scaling group. You can specify multiple values for a filter. A tag must match at least one of the specified values for it to be included in the results. You can also specify multiple filters. The result includes information for a particular tag only if it matches all the filters. If there's no match, no special message is returned. For more information, see Tag Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeTags
export def "api create-get-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-36
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
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Describes the termination policies supported by Amazon EC2 Auto Scaling. For more information, see Work with Amazon EC2 Auto Scaling termination policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-termination-policies.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeTerminationPolicyTypes
export def "api get-termination-policy-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-37
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Describes the termination policies supported by Amazon EC2 Auto Scaling. For more information, see Work with Amazon EC2 Auto Scaling termination policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-termination-policies.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeTerminationPolicyTypes
export def "api create-get-termination-policy-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-37
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
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the traffic sources for the specified Auto Scaling group. You can optionally provide a traffic source type. If you provide a traffic source type, then the results only include that traffic source type. If you do not provide a traffic source type, then the results include all the traffic sources for the specified Auto Scaling group.
#
# GET /
# operationId: GET_DescribeTrafficSources
export def "api get-traffic-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --traffic-source-type: string # The traffic source type that you want to describe. The following lists the valid values: elb if the traffic source is a Classic Load Balancer. elbv2 if the traffic source is a Application Load Balancer, Gateway Load Balancer, or Network Load Balancer. vpc-lattice if the traffic source is VPC Lattice.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The maximum value is 50.
  --action: string@action-completer-38
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "TrafficSourceType" $traffic_source_type "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "TrafficSourceType": $traffic_source_type, "NextToken": $next_token, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about the traffic sources for the specified Auto Scaling group. You can optionally provide a traffic source type. If you provide a traffic source type, then the results only include that traffic source type. If you do not provide a traffic source type, then the results include all the traffic sources for the specified Auto Scaling group.
#
# POST /
# operationId: POST_DescribeTrafficSources
export def "api create-get-traffic-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-38
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
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: $req_body}
}

# Gets information about a warm pool and its instances. For more information, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeWarmPool
export def "api get-warm-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --max-records: int # The maximum number of instances to return with this call. The maximum value is 50.
  --next-token: string # The token for the next set of instances to return. (You received this token from a previous call.)
  --action: string@action-completer-39
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "MaxRecords": $max_records, "NextToken": $next_token, "Action": $action, "Version": $version} | compact), body: null}
}

# Gets information about a warm pool and its instances. For more information, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeWarmPool
export def "api create-get-warm-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-39
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

# Removes one or more instances from the specified Auto Scaling group. After the instances are detached, you can manage them independent of the Auto Scaling group. If you do not specify the option to decrement the desired capacity, Amazon EC2 Auto Scaling launches instances to replace the ones that are detached. If there is a Classic Load Balancer attached to the Auto Scaling group, the instances are deregistered from the load balancer. If there are target groups attached to the Auto Scaling group, the instances are deregistered from the target groups. For more information, see Detach EC2 instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/detach-instance-asg.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DetachInstances
export def "api get-detach-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list # The IDs of the instances. You can specify up to 20 instances.
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --should-decrement-desired-capacity: oneof<nothing, bool> # Indicates whether the Auto Scaling group decrements the desired capacity value by the number of instances detached.
  --action: string@action-completer-40
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
  let qp = [(serialize-qp "InstanceIds" $instance_ids "multi") (serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ShouldDecrementDesiredCapacity" $should_decrement_desired_capacity "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"InstanceIds": $instance_ids, "AutoScalingGroupName": $auto_scaling_group_name, "ShouldDecrementDesiredCapacity": $should_decrement_desired_capacity, "Action": $action, "Version": $version} | compact), body: null}
}

# Removes one or more instances from the specified Auto Scaling group. After the instances are detached, you can manage them independent of the Auto Scaling group. If you do not specify the option to decrement the desired capacity, Amazon EC2 Auto Scaling launches instances to replace the ones that are detached. If there is a Classic Load Balancer attached to the Auto Scaling group, the instances are deregistered from the load balancer. If there are target groups attached to the Auto Scaling group, the instances are deregistered from the target groups. For more information, see Detach EC2 instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/detach-instance-asg.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DetachInstances
export def "api create-detach-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-40
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

# This API operation is superseded by DetachTrafficSources, which can detach multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DetachLoadBalancerTargetGroups. You can use both the original DetachLoadBalancerTargetGroups API operation and DetachTrafficSources on the same Auto Scaling group. Detaches one or more target groups from the specified Auto Scaling group. When you detach a target group, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the target group using the DescribeLoadBalancerTargetGroups API call. The instances remain running. You can use this operation to detach target groups that were attached by using AttachLoadBalancerTargetGroups, but not for target groups that were attached by using AttachTrafficSources.
#
# GET /
# operationId: GET_DetachLoadBalancerTargetGroups
export def "api get-detach-load-balancer-target-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --target-group-ar-ns: list # The Amazon Resource Names (ARN) of the target groups. You can specify up to 10 target groups.
  --action: string@action-completer-41
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "TargetGroupARNs" $target_group_ar_ns "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "TargetGroupARNs": $target_group_ar_ns, "Action": $action, "Version": $version} | compact), body: null}
}

# This API operation is superseded by DetachTrafficSources, which can detach multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DetachLoadBalancerTargetGroups. You can use both the original DetachLoadBalancerTargetGroups API operation and DetachTrafficSources on the same Auto Scaling group. Detaches one or more target groups from the specified Auto Scaling group. When you detach a target group, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the target group using the DescribeLoadBalancerTargetGroups API call. The instances remain running. You can use this operation to detach target groups that were attached by using AttachLoadBalancerTargetGroups, but not for target groups that were attached by using AttachTrafficSources.
#
# POST /
# operationId: POST_DetachLoadBalancerTargetGroups
export def "api create-detach-load-balancer-target-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-41
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

# This API operation is superseded by DetachTrafficSources, which can detach multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DetachLoadBalancers. You can use both the original DetachLoadBalancers API operation and DetachTrafficSources on the same Auto Scaling group. Detaches one or more Classic Load Balancers from the specified Auto Scaling group. This operation detaches only Classic Load Balancers. If you have Application Load Balancers, Network Load Balancers, or Gateway Load Balancers, use the DetachLoadBalancerTargetGroups API instead. When you detach a load balancer, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the load balancer using the DescribeLoadBalancers API call. The instances remain running.
#
# GET /
# operationId: GET_DetachLoadBalancers
export def "api get-detach-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --load-balancer-names: list # The names of the load balancers. You can specify up to 10 load balancers.
  --action: string@action-completer-42
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "LoadBalancerNames" $load_balancer_names "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "LoadBalancerNames": $load_balancer_names, "Action": $action, "Version": $version} | compact), body: null}
}

# This API operation is superseded by DetachTrafficSources, which can detach multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DetachLoadBalancers. You can use both the original DetachLoadBalancers API operation and DetachTrafficSources on the same Auto Scaling group. Detaches one or more Classic Load Balancers from the specified Auto Scaling group. This operation detaches only Classic Load Balancers. If you have Application Load Balancers, Network Load Balancers, or Gateway Load Balancers, use the DetachLoadBalancerTargetGroups API instead. When you detach a load balancer, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the load balancer using the DescribeLoadBalancers API call. The instances remain running.
#
# POST /
# operationId: POST_DetachLoadBalancers
export def "api create-detach-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-42
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

# Detaches one or more traffic sources from the specified Auto Scaling group. When you detach a taffic, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the traffic source using the DescribeTrafficSources API call. The instances continue to run.
#
# GET /
# operationId: GET_DetachTrafficSources
export def "api get-detach-traffic-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --traffic-sources: list # The unique identifiers of one or more traffic sources. You can specify up to 10 traffic sources.
  --action: string@action-completer-43
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "TrafficSources" $traffic_sources "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "TrafficSources": $traffic_sources, "Action": $action, "Version": $version} | compact), body: null}
}

# Detaches one or more traffic sources from the specified Auto Scaling group. When you detach a taffic, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the traffic source using the DescribeTrafficSources API call. The instances continue to run.
#
# POST /
# operationId: POST_DetachTrafficSources
export def "api create-detach-traffic-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-43
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

# Disables group metrics collection for the specified Auto Scaling group.
#
# GET /
# operationId: GET_DisableMetricsCollection
export def "api get-disable-metrics-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --metrics: list # Identifies the metrics to disable. You can specify one or more of the following metrics: GroupMinSize GroupMaxSize GroupDesiredCapacity GroupInServiceInstances GroupPendingInstances GroupStandbyInstances GroupTerminatingInstances GroupTotalInstances GroupInServiceCapacity GroupPendingCapacity GroupStandbyCapacity GroupTerminatingCapacity GroupTotalCapacity WarmPoolDesiredCapacity WarmPoolWarmedCapacity WarmPoolPendingCapacity WarmPoolTerminatingCapacity WarmPoolTotalCapacity GroupAndWarmPoolDesiredCapacity GroupAndWarmPoolTotalCapacity If you omit this property, all metrics are disabled. For more information, see Auto Scaling group metrics (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-cloudwatch-monitoring.html#as-group-metrics) in the Amazon EC2 Auto Scaling User Guide.
  --action: string@action-completer-44
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "Metrics" $metrics "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "Metrics": $metrics, "Action": $action, "Version": $version} | compact), body: null}
}

# Disables group metrics collection for the specified Auto Scaling group.
#
# POST /
# operationId: POST_DisableMetricsCollection
export def "api create-disable-metrics-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-44
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

# Enables group metrics collection for the specified Auto Scaling group. You can use these metrics to track changes in an Auto Scaling group and to set alarms on threshold values. You can view group metrics using the Amazon EC2 Auto Scaling console or the CloudWatch console. For more information, see Monitor CloudWatch metrics for your Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-cloudwatch-monitoring.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_EnableMetricsCollection
export def "api get-enable-metrics-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --metrics: list # Identifies the metrics to enable. You can specify one or more of the following metrics: GroupMinSize GroupMaxSize GroupDesiredCapacity GroupInServiceInstances GroupPendingInstances GroupStandbyInstances GroupTerminatingInstances GroupTotalInstances GroupInServiceCapacity GroupPendingCapacity GroupStandbyCapacity GroupTerminatingCapacity GroupTotalCapacity WarmPoolDesiredCapacity WarmPoolWarmedCapacity WarmPoolPendingCapacity WarmPoolTerminatingCapacity WarmPoolTotalCapacity GroupAndWarmPoolDesiredCapacity GroupAndWarmPoolTotalCapacity If you specify Granularity and don't specify any metrics, all metrics are enabled. For more information, see Auto Scaling group metrics (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-cloudwatch-monitoring.html#as-group-metrics) in the Amazon EC2 Auto Scaling User Guide.
  --granularity: string # The frequency at which Amazon EC2 Auto Scaling sends aggregated data to CloudWatch. The only valid value is 1Minute.
  --action: string@action-completer-45
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "Metrics" $metrics "multi") (serialize-qp "Granularity" $granularity "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "Metrics": $metrics, "Granularity": $granularity, "Action": $action, "Version": $version} | compact), body: null}
}

# Enables group metrics collection for the specified Auto Scaling group. You can use these metrics to track changes in an Auto Scaling group and to set alarms on threshold values. You can view group metrics using the Amazon EC2 Auto Scaling console or the CloudWatch console. For more information, see Monitor CloudWatch metrics for your Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-cloudwatch-monitoring.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_EnableMetricsCollection
export def "api create-enable-metrics-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-45
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

# Moves the specified instances into the standby state. If you choose to decrement the desired capacity of the Auto Scaling group, the instances can enter standby as long as the desired capacity of the Auto Scaling group after the instances are placed into standby is equal to or greater than the minimum capacity of the group. If you choose not to decrement the desired capacity of the Auto Scaling group, the Auto Scaling group launches new instances to replace the instances on standby. For more information, see Temporarily removing instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-enter-exit-standby.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_EnterStandby
export def "api get-enter-standby" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list # The IDs of the instances. You can specify up to 20 instances.
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --should-decrement-desired-capacity: oneof<nothing, bool> # Indicates whether to decrement the desired capacity of the Auto Scaling group by the number of instances moved to Standby mode.
  --action: string@action-completer-46
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
  let qp = [(serialize-qp "InstanceIds" $instance_ids "multi") (serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ShouldDecrementDesiredCapacity" $should_decrement_desired_capacity "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"InstanceIds": $instance_ids, "AutoScalingGroupName": $auto_scaling_group_name, "ShouldDecrementDesiredCapacity": $should_decrement_desired_capacity, "Action": $action, "Version": $version} | compact), body: null}
}

# Moves the specified instances into the standby state. If you choose to decrement the desired capacity of the Auto Scaling group, the instances can enter standby as long as the desired capacity of the Auto Scaling group after the instances are placed into standby is equal to or greater than the minimum capacity of the group. If you choose not to decrement the desired capacity of the Auto Scaling group, the Auto Scaling group launches new instances to replace the instances on standby. For more information, see Temporarily removing instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-enter-exit-standby.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_EnterStandby
export def "api create-enter-standby" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-46
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

# Executes the specified policy. This can be useful for testing the design of your scaling policy.
#
# GET /
# operationId: GET_ExecutePolicy
export def "api get-execute-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --policy-name: string # The name or ARN of the policy.
  --honor-cooldown: oneof<nothing, bool> # Indicates whether Amazon EC2 Auto Scaling waits for the cooldown period to complete before executing the policy. Valid only if the policy type is SimpleScaling. For more information, see Scaling cooldowns for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/Cooldown.html) in the Amazon EC2 Auto Scaling User Guide.
  --metric-value: float # The metric value to compare to BreachThreshold. This enables you to execute a policy of type StepScaling and determine which step adjustment to use. For example, if the breach threshold is 50 and you want to use a step adjustment with a lower bound of 0 and an upper bound of 10, you can set the metric value to 59. If you specify a metric value that doesn't correspond to a step adjustment for the policy, the call returns an error. Required if the policy type is StepScaling and not supported otherwise. (format: double)
  --breach-threshold: float # The breach threshold for the alarm. Required if the policy type is StepScaling and not supported otherwise. (format: double)
  --action: string@action-completer-47
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "PolicyName" $policy_name "scalar") (serialize-qp "HonorCooldown" $honor_cooldown "scalar") (serialize-qp "MetricValue" $metric_value "scalar") (serialize-qp "BreachThreshold" $breach_threshold "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "PolicyName": $policy_name, "HonorCooldown": $honor_cooldown, "MetricValue": $metric_value, "BreachThreshold": $breach_threshold, "Action": $action, "Version": $version} | compact), body: null}
}

# Executes the specified policy. This can be useful for testing the design of your scaling policy.
#
# POST /
# operationId: POST_ExecutePolicy
export def "api create-execute-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-47
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

# Moves the specified instances out of the standby state. After you put the instances back in service, the desired capacity is incremented. For more information, see Temporarily removing instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-enter-exit-standby.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_ExitStandby
export def "api get-exit-standby" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list # The IDs of the instances. You can specify up to 20 instances.
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --action: string@action-completer-48
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
  let qp = [(serialize-qp "InstanceIds" $instance_ids "multi") (serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"InstanceIds": $instance_ids, "AutoScalingGroupName": $auto_scaling_group_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Moves the specified instances out of the standby state. After you put the instances back in service, the desired capacity is incremented. For more information, see Temporarily removing instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-enter-exit-standby.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_ExitStandby
export def "api create-exit-standby" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-48
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

# Retrieves the forecast data for a predictive scaling policy. Load forecasts are predictions of the hourly load values using historical load data from CloudWatch and an analysis of historical trends. Capacity forecasts are represented as predicted values for the minimum capacity that is needed on an hourly basis, based on the hourly load forecast. A minimum of 24 hours of data is required to create the initial forecasts. However, having a full 14 days of historical data results in more accurate forecasts. For more information, see Predictive scaling for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive-scaling.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_GetPredictiveScalingForecast
export def "api get-predictive-scaling-forecast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --policy-name: string # The name of the policy.
  --start-time: string # The inclusive start time of the time range for the forecast data to get. At most, the date and time can be one year before the current date and time. (format: date-time)
  --end-time: string # The exclusive end time of the time range for the forecast data to get. The maximum time duration between the start and end time is 30 days. Although this parameter can accept a date and time that is more than two days in the future, the availability of forecast data has limits. Amazon EC2 Auto Scaling only issues forecasts for periods of two days in advance. (format: date-time)
  --action: string@action-completer-49
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "PolicyName" $policy_name "scalar") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "PolicyName": $policy_name, "StartTime": $start_time, "EndTime": $end_time, "Action": $action, "Version": $version} | compact), body: null}
}

# Retrieves the forecast data for a predictive scaling policy. Load forecasts are predictions of the hourly load values using historical load data from CloudWatch and an analysis of historical trends. Capacity forecasts are represented as predicted values for the minimum capacity that is needed on an hourly basis, based on the hourly load forecast. A minimum of 24 hours of data is required to create the initial forecasts. However, having a full 14 days of historical data results in more accurate forecasts. For more information, see Predictive scaling for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive-scaling.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_GetPredictiveScalingForecast
export def "api create-get-predictive-scaling-forecast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-49
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

# Creates or updates a lifecycle hook for the specified Auto Scaling group. Lifecycle hooks let you create solutions that are aware of events in the Auto Scaling instance lifecycle, and then perform a custom action on instances when the corresponding lifecycle event occurs. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state using the RecordLifecycleActionHeartbeat API call. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of lifecycle hooks, which by default is 50 per Auto Scaling group, the call fails. You can view the lifecycle hooks for an Auto Scaling group using the DescribeLifecycleHooks API call. If you are no longer using a lifecycle hook, you can delete it by calling the DeleteLifecycleHook API.
#
# GET /
# operationId: GET_PutLifecycleHook
export def "api get-update-lifecycle-hook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lifecycle-hook-name: string # The name of the lifecycle hook.
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --lifecycle-transition: string # The lifecycle transition. For Auto Scaling groups, there are two major lifecycle transitions. To create a lifecycle hook for scale-out events, specify autoscaling:EC2_INSTANCE_LAUNCHING. To create a lifecycle hook for scale-in events, specify autoscaling:EC2_INSTANCE_TERMINATING. Required for new lifecycle hooks, but optional when updating existing hooks.
  --role-arn: string # The ARN of the IAM role that allows the Auto Scaling group to publish to the specified notification target. Valid only if the notification target is an Amazon SNS topic or an Amazon SQS queue. Required for new lifecycle hooks, but optional when updating existing hooks.
  --notification-target-arn: string # The Amazon Resource Name (ARN) of the notification target that Amazon EC2 Auto Scaling uses to notify you when an instance is in a wait state for the lifecycle hook. You can specify either an Amazon SNS topic or an Amazon SQS queue. If you specify an empty string, this overrides the current ARN. This operation uses the JSON format when sending notifications to an Amazon SQS queue, and an email key-value pair format when sending notifications to an Amazon SNS topic. When you specify a notification target, Amazon EC2 Auto Scaling sends it a test message. Test messages contain the following additional key-value pair: "Event": "autoscaling:TEST_NOTIFICATION".
  --notification-metadata: string # Additional information that you want to include any time Amazon EC2 Auto Scaling sends a message to the notification target.
  --heartbeat-timeout: int # The maximum time, in seconds, that can elapse before the lifecycle hook times out. The range is from 30 to 7200 seconds. The default value is 3600 seconds (1 hour).
  --default-result: string # The action the Auto Scaling group takes when the lifecycle hook timeout elapses or if an unexpected failure occurs. The default value is ABANDON. Valid values: CONTINUE | ABANDON
  --action: string@action-completer-50
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
  let qp = [(serialize-qp "LifecycleHookName" $lifecycle_hook_name "scalar") (serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "LifecycleTransition" $lifecycle_transition "scalar") (serialize-qp "RoleARN" $role_arn "scalar") (serialize-qp "NotificationTargetARN" $notification_target_arn "scalar") (serialize-qp "NotificationMetadata" $notification_metadata "scalar") (serialize-qp "HeartbeatTimeout" $heartbeat_timeout "scalar") (serialize-qp "DefaultResult" $default_result "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"LifecycleHookName": $lifecycle_hook_name, "AutoScalingGroupName": $auto_scaling_group_name, "LifecycleTransition": $lifecycle_transition, "RoleARN": $role_arn, "NotificationTargetARN": $notification_target_arn, "NotificationMetadata": $notification_metadata, "HeartbeatTimeout": $heartbeat_timeout, "DefaultResult": $default_result, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates or updates a lifecycle hook for the specified Auto Scaling group. Lifecycle hooks let you create solutions that are aware of events in the Auto Scaling instance lifecycle, and then perform a custom action on instances when the corresponding lifecycle event occurs. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state using the RecordLifecycleActionHeartbeat API call. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of lifecycle hooks, which by default is 50 per Auto Scaling group, the call fails. You can view the lifecycle hooks for an Auto Scaling group using the DescribeLifecycleHooks API call. If you are no longer using a lifecycle hook, you can delete it by calling the DeleteLifecycleHook API.
#
# POST /
# operationId: POST_PutLifecycleHook
export def "api create-update-lifecycle-hook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-50
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

# Configures an Auto Scaling group to send notifications when specified events take place. Subscribers to the specified topic can have messages delivered to an endpoint such as a web server or an email address. This configuration overwrites any existing configuration. For more information, see Getting Amazon SNS notifications when your Auto Scaling group scales (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ASGettingNotifications.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of SNS topics, which is 10 per Auto Scaling group, the call fails.
#
# GET /
# operationId: GET_PutNotificationConfiguration
export def "api get-update-notification-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --topic-arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic.
  --notification-types: list # The type of event that causes the notification to be sent. To query the notification types supported by Amazon EC2 Auto Scaling, call the DescribeAutoScalingNotificationTypes API.
  --action: string@action-completer-51
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "TopicARN" $topic_arn "scalar") (serialize-qp "NotificationTypes" $notification_types "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "TopicARN": $topic_arn, "NotificationTypes": $notification_types, "Action": $action, "Version": $version} | compact), body: null}
}

# Configures an Auto Scaling group to send notifications when specified events take place. Subscribers to the specified topic can have messages delivered to an endpoint such as a web server or an email address. This configuration overwrites any existing configuration. For more information, see Getting Amazon SNS notifications when your Auto Scaling group scales (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ASGettingNotifications.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of SNS topics, which is 10 per Auto Scaling group, the call fails.
#
# POST /
# operationId: POST_PutNotificationConfiguration
export def "api create-update-notification-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-51
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

# Creates or updates a scaling policy for an Auto Scaling group. Scaling policies are used to scale an Auto Scaling group based on configurable metrics. If no policies are defined, the dynamic scaling and predictive scaling features are not used. For more information about using dynamic scaling, see Target tracking scaling policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html) and Step and simple scaling policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html) in the Amazon EC2 Auto Scaling User Guide. For more information about using predictive scaling, see Predictive scaling for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive-scaling.html) in the Amazon EC2 Auto Scaling User Guide. You can view the scaling policies for an Auto Scaling group using the DescribePolicies API call. If you are no longer using a scaling policy, you can delete it by calling the DeletePolicy API.
#
# GET /
# operationId: GET_PutScalingPolicy
export def "api get-update-scaling-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --policy-name: string # The name of the policy.
  --policy-type: string # One of the following policy types: TargetTrackingScaling StepScaling SimpleScaling (default) PredictiveScaling
  --adjustment-type: string # Specifies how the scaling adjustment is interpreted (for example, an absolute number or a percentage). The valid values are ChangeInCapacity, ExactCapacity, and PercentChangeInCapacity. Required if the policy type is StepScaling or SimpleScaling. For more information, see Scaling adjustment types (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#as-scaling-adjustment) in the Amazon EC2 Auto Scaling User Guide.
  --min-adjustment-step: int # Available for backward compatibility. Use MinAdjustmentMagnitude instead.
  --min-adjustment-magnitude: int # The minimum value to scale by when the adjustment type is PercentChangeInCapacity. For example, suppose that you create a step scaling policy to scale out an Auto Scaling group by 25 percent and you specify a MinAdjustmentMagnitude of 2. If the group has 4 instances and the scaling policy is performed, 25 percent of 4 is 1. However, because you specified a MinAdjustmentMagnitude of 2, Amazon EC2 Auto Scaling scales out the group by 2 instances. Valid only if the policy type is StepScaling or SimpleScaling. For more information, see Scaling adjustment types (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#as-scaling-adjustment) in the Amazon EC2 Auto Scaling User Guide. Some Auto Scaling groups use instance weights. In this case, set the MinAdjustmentMagnitude to a value that is at least as large as your largest instance weight.
  --scaling-adjustment: int # The amount by which to scale, based on the specified adjustment type. A positive value adds to the current capacity while a negative number removes from the current capacity. For exact capacity, you must specify a positive value. Required if the policy type is SimpleScaling. (Not used with any other policy type.)
  --cooldown: int # A cooldown period, in seconds, that applies to a specific simple scaling policy. When a cooldown period is specified here, it overrides the default cooldown. Valid only if the policy type is SimpleScaling. For more information, see Scaling cooldowns for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/Cooldown.html) in the Amazon EC2 Auto Scaling User Guide. Default: None
  --metric-aggregation-type: string # The aggregation type for the CloudWatch metrics. The valid values are Minimum, Maximum, and Average. If the aggregation type is null, the value is treated as Average. Valid only if the policy type is StepScaling.
  --step-adjustments: list # A set of adjustments that enable you to scale based on the size of the alarm breach. Required if the policy type is StepScaling. (Not used with any other policy type.)
  --estimated-instance-warmup: int # Not needed if the default instance warmup is defined for the group. The estimated time, in seconds, until a newly launched instance can contribute to the CloudWatch metrics. This warm-up period applies to instances launched due to a specific target tracking or step scaling policy. When a warm-up period is specified here, it overrides the default instance warmup. Valid only if the policy type is TargetTrackingScaling or StepScaling. The default is to use the value for the default instance warmup defined for the group. If default instance warmup is null, then EstimatedInstanceWarmup falls back to the value of default cooldown.
  --target-tracking-configuration: record # A target tracking scaling policy. Provides support for predefined or custom metrics. The following predefined metrics are available: ASGAverageCPUUtilization ASGAverageNetworkIn ASGAverageNetworkOut ALBRequestCountPerTarget If you specify ALBRequestCountPerTarget for the metric, you must specify the ResourceLabel property with the PredefinedMetricSpecification. For more information, see TargetTrackingConfiguration (https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_TargetTrackingConfiguration.html) in the Amazon EC2 Auto Scaling API Reference. Required if the policy type is TargetTrackingScaling.
  --enabled: oneof<nothing, bool> # Indicates whether the scaling policy is enabled or disabled. The default is enabled. For more information, see Disabling a scaling policy for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-enable-disable-scaling-policy.html) in the Amazon EC2 Auto Scaling User Guide.
  --predictive-scaling-configuration: record # A predictive scaling policy. Provides support for predefined and custom metrics. Predefined metrics include CPU utilization, network in/out, and the Application Load Balancer request count. For more information, see PredictiveScalingConfiguration (https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_PredictiveScalingConfiguration.html) in the Amazon EC2 Auto Scaling API Reference. Required if the policy type is PredictiveScaling.
  --action: string@action-completer-52
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "PolicyName" $policy_name "scalar") (serialize-qp "PolicyType" $policy_type "scalar") (serialize-qp "AdjustmentType" $adjustment_type "scalar") (serialize-qp "MinAdjustmentStep" $min_adjustment_step "scalar") (serialize-qp "MinAdjustmentMagnitude" $min_adjustment_magnitude "scalar") (serialize-qp "ScalingAdjustment" $scaling_adjustment "scalar") (serialize-qp "Cooldown" $cooldown "scalar") (serialize-qp "MetricAggregationType" $metric_aggregation_type "scalar") (serialize-qp "StepAdjustments" $step_adjustments "multi") (serialize-qp "EstimatedInstanceWarmup" $estimated_instance_warmup "scalar") (serialize-qp "TargetTrackingConfiguration" $target_tracking_configuration "multi") (serialize-qp "Enabled" $enabled "scalar") (serialize-qp "PredictiveScalingConfiguration" $predictive_scaling_configuration "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "PolicyName": $policy_name, "PolicyType": $policy_type, "AdjustmentType": $adjustment_type, "MinAdjustmentStep": $min_adjustment_step, "MinAdjustmentMagnitude": $min_adjustment_magnitude, "ScalingAdjustment": $scaling_adjustment, "Cooldown": $cooldown, "MetricAggregationType": $metric_aggregation_type, "StepAdjustments": $step_adjustments, "EstimatedInstanceWarmup": $estimated_instance_warmup, "TargetTrackingConfiguration": $target_tracking_configuration, "Enabled": $enabled, "PredictiveScalingConfiguration": $predictive_scaling_configuration, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates or updates a scaling policy for an Auto Scaling group. Scaling policies are used to scale an Auto Scaling group based on configurable metrics. If no policies are defined, the dynamic scaling and predictive scaling features are not used. For more information about using dynamic scaling, see Target tracking scaling policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html) and Step and simple scaling policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html) in the Amazon EC2 Auto Scaling User Guide. For more information about using predictive scaling, see Predictive scaling for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive-scaling.html) in the Amazon EC2 Auto Scaling User Guide. You can view the scaling policies for an Auto Scaling group using the DescribePolicies API call. If you are no longer using a scaling policy, you can delete it by calling the DeletePolicy API.
#
# POST /
# operationId: POST_PutScalingPolicy
export def "api create-update-scaling-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-52
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

# Creates or updates a scheduled scaling action for an Auto Scaling group. For more information, see Scheduled scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/schedule_time.html) in the Amazon EC2 Auto Scaling User Guide. You can view the scheduled actions for an Auto Scaling group using the DescribeScheduledActions API call. If you are no longer using a scheduled action, you can delete it by calling the DeleteScheduledAction API. If you try to schedule your action in the past, Amazon EC2 Auto Scaling returns an error message.
#
# GET /
# operationId: GET_PutScheduledUpdateGroupAction
export def "api get-update-scheduled-update-group-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --scheduled-action-name: string # The name of this scaling action.
  --time: string # This property is no longer used. (format: date-time)
  --start-time: string # The date and time for this action to start, in YYYY-MM-DDThh:mm:ssZ format in UTC/GMT only and in quotes (for example, "2021-06-01T00:00:00Z"). If you specify Recurrence and StartTime, Amazon EC2 Auto Scaling performs the action at this time, and then performs the action based on the specified recurrence. (format: date-time)
  --end-time: string # The date and time for the recurring schedule to end, in UTC. For example, "2021-06-01T00:00:00Z". (format: date-time)
  --recurrence: string # The recurring schedule for this action. This format consists of five fields separated by white spaces: [Minute] [Hour] [Day_of_Month] [Month_of_Year] [Day_of_Week]. The value must be in quotes (for example, "30 0 1 1,6,12 *"). For more information about this format, see Crontab (http://crontab.org). When StartTime and EndTime are specified with Recurrence, they form the boundaries of when the recurring action starts and stops. Cron expressions use Universal Coordinated Time (UTC) by default.
  --min-size: int # The minimum size of the Auto Scaling group.
  --max-size: int # The maximum size of the Auto Scaling group.
  --desired-capacity: int # The desired capacity is the initial capacity of the Auto Scaling group after the scheduled action runs and the capacity it attempts to maintain. It can scale beyond this capacity if you add more scaling conditions. You must specify at least one of the following properties: MaxSize, MinSize, or DesiredCapacity.
  --time-zone: string # Specifies the time zone for a cron expression. If a time zone is not provided, UTC is used by default. Valid values are the canonical names of the IANA time zones, derived from the IANA Time Zone Database (such as Etc/GMT+9 or Pacific/Tahiti). For more information, see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
  --action: string@action-completer-53
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ScheduledActionName" $scheduled_action_name "scalar") (serialize-qp "Time" $time "scalar") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "Recurrence" $recurrence "scalar") (serialize-qp "MinSize" $min_size "scalar") (serialize-qp "MaxSize" $max_size "scalar") (serialize-qp "DesiredCapacity" $desired_capacity "scalar") (serialize-qp "TimeZone" $time_zone "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "ScheduledActionName": $scheduled_action_name, "Time": $time, "StartTime": $start_time, "EndTime": $end_time, "Recurrence": $recurrence, "MinSize": $min_size, "MaxSize": $max_size, "DesiredCapacity": $desired_capacity, "TimeZone": $time_zone, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates or updates a scheduled scaling action for an Auto Scaling group. For more information, see Scheduled scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/schedule_time.html) in the Amazon EC2 Auto Scaling User Guide. You can view the scheduled actions for an Auto Scaling group using the DescribeScheduledActions API call. If you are no longer using a scheduled action, you can delete it by calling the DeleteScheduledAction API. If you try to schedule your action in the past, Amazon EC2 Auto Scaling returns an error message.
#
# POST /
# operationId: POST_PutScheduledUpdateGroupAction
export def "api create-update-scheduled-update-group-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-53
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

# Creates or updates a warm pool for the specified Auto Scaling group. A warm pool is a pool of pre-initialized EC2 instances that sits alongside the Auto Scaling group. Whenever your application needs to scale out, the Auto Scaling group can draw on the warm pool to meet its new desired capacity. For more information and example configurations, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide. This operation must be called from the Region in which the Auto Scaling group was created. This operation cannot be called on an Auto Scaling group that has a mixed instances policy or a launch template or launch configuration that requests Spot Instances. You can view the instances in the warm pool using the DescribeWarmPool API call. If you are no longer using a warm pool, you can delete it by calling the DeleteWarmPool API.
#
# GET /
# operationId: GET_PutWarmPool
export def "api get-update-warm-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --max-group-prepared-capacity: int # Specifies the maximum number of instances that are allowed to be in the warm pool or in any state except Terminated for the Auto Scaling group. This is an optional property. Specify it only if you do not want the warm pool size to be determined by the difference between the group's maximum capacity and its desired capacity. If a value for MaxGroupPreparedCapacity is not specified, Amazon EC2 Auto Scaling launches and maintains the difference between the group's maximum capacity and its desired capacity. If you specify a value for MaxGroupPreparedCapacity, Amazon EC2 Auto Scaling uses the difference between the MaxGroupPreparedCapacity and the desired capacity instead. The size of the warm pool is dynamic. Only when MaxGroupPreparedCapacity and MinSize are set to the same value does the warm pool have an absolute size. If the desired capacity of the Auto Scaling group is higher than the MaxGroupPreparedCapacity, the capacity of the warm pool is 0, unless you specify a value for MinSize. To remove a value that you previously set, include the property but specify -1 for the value.
  --min-size: int # Specifies the minimum number of instances to maintain in the warm pool. This helps you to ensure that there is always a certain number of warmed instances available to handle traffic spikes. Defaults to 0 if not specified.
  --pool-state: string@pool-state-completer # Sets the instance state to transition to after the lifecycle actions are complete. Default is Stopped.
  --instance-reuse-policy: record # Indicates whether instances in the Auto Scaling group can be returned to the warm pool on scale in. The default is to terminate instances in the Auto Scaling group when the group scales in.
  --action: string@action-completer-54
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "MaxGroupPreparedCapacity" $max_group_prepared_capacity "scalar") (serialize-qp "MinSize" $min_size "scalar") (serialize-qp "PoolState" $pool_state "scalar") (serialize-qp "InstanceReusePolicy" $instance_reuse_policy "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "MaxGroupPreparedCapacity": $max_group_prepared_capacity, "MinSize": $min_size, "PoolState": $pool_state, "InstanceReusePolicy": $instance_reuse_policy, "Action": $action, "Version": $version} | compact), body: null}
}

# Creates or updates a warm pool for the specified Auto Scaling group. A warm pool is a pool of pre-initialized EC2 instances that sits alongside the Auto Scaling group. Whenever your application needs to scale out, the Auto Scaling group can draw on the warm pool to meet its new desired capacity. For more information and example configurations, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide. This operation must be called from the Region in which the Auto Scaling group was created. This operation cannot be called on an Auto Scaling group that has a mixed instances policy or a launch template or launch configuration that requests Spot Instances. You can view the instances in the warm pool using the DescribeWarmPool API call. If you are no longer using a warm pool, you can delete it by calling the DeleteWarmPool API.
#
# POST /
# operationId: POST_PutWarmPool
export def "api create-update-warm-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-54
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

# Records a heartbeat for the lifecycle action associated with the specified token or instance. This extends the timeout by the length of time defined using the PutLifecycleHook API call. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_RecordLifecycleActionHeartbeat
export def "api get-record-lifecycle-action-heartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lifecycle-hook-name: string # The name of the lifecycle hook.
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --lifecycle-action-token: string # A token that uniquely identifies a specific lifecycle action associated with an instance. Amazon EC2 Auto Scaling sends this token to the notification target that you specified when you created the lifecycle hook.
  --instance-id: string # The ID of the instance.
  --action: string@action-completer-55
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
  let qp = [(serialize-qp "LifecycleHookName" $lifecycle_hook_name "scalar") (serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "LifecycleActionToken" $lifecycle_action_token "scalar") (serialize-qp "InstanceId" $instance_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"LifecycleHookName": $lifecycle_hook_name, "AutoScalingGroupName": $auto_scaling_group_name, "LifecycleActionToken": $lifecycle_action_token, "InstanceId": $instance_id, "Action": $action, "Version": $version} | compact), body: null}
}

# Records a heartbeat for the lifecycle action associated with the specified token or instance. This extends the timeout by the length of time defined using the PutLifecycleHook API call. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_RecordLifecycleActionHeartbeat
export def "api create-record-lifecycle-action-heartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-55
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

# Resumes the specified suspended auto scaling processes, or all suspended process, for the specified Auto Scaling group. For more information, see Suspending and resuming scaling processes (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-suspend-resume-processes.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_ResumeProcesses
export def "api get-resume-processes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --scaling-processes: list # One or more of the following processes: Launch Terminate AddToLoadBalancer AlarmNotification AZRebalance HealthCheck InstanceRefresh ReplaceUnhealthy ScheduledActions If you omit this property, all processes are specified.
  --action: string@action-completer-56
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ScalingProcesses" $scaling_processes "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "ScalingProcesses": $scaling_processes, "Action": $action, "Version": $version} | compact), body: null}
}

# Resumes the specified suspended auto scaling processes, or all suspended process, for the specified Auto Scaling group. For more information, see Suspending and resuming scaling processes (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-suspend-resume-processes.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_ResumeProcesses
export def "api create-resume-processes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-56
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

# Cancels an instance refresh that is in progress and rolls back any changes that it made. Amazon EC2 Auto Scaling replaces any instances that were replaced during the instance refresh. This restores your Auto Scaling group to the configuration that it was using before the start of the instance refresh. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. A rollback is not supported in the following situations: There is no desired configuration specified for the instance refresh. The Auto Scaling group has a launch template that uses an Amazon Web Services Systems Manager parameter instead of an AMI ID for the ImageId property. The Auto Scaling group uses the launch template's $Latest or $Default version. When you receive a successful response from this operation, Amazon EC2 Auto Scaling immediately begins replacing instances. You can check the status of this operation through the DescribeInstanceRefreshes API operation.
#
# GET /
# operationId: GET_RollbackInstanceRefresh
export def "api get-rollback-instance-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --action: string@action-completer-57
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "Action": $action, "Version": $version} | compact), body: null}
}

# Cancels an instance refresh that is in progress and rolls back any changes that it made. Amazon EC2 Auto Scaling replaces any instances that were replaced during the instance refresh. This restores your Auto Scaling group to the configuration that it was using before the start of the instance refresh. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. A rollback is not supported in the following situations: There is no desired configuration specified for the instance refresh. The Auto Scaling group has a launch template that uses an Amazon Web Services Systems Manager parameter instead of an AMI ID for the ImageId property. The Auto Scaling group uses the launch template's $Latest or $Default version. When you receive a successful response from this operation, Amazon EC2 Auto Scaling immediately begins replacing instances. You can check the status of this operation through the DescribeInstanceRefreshes API operation.
#
# POST /
# operationId: POST_RollbackInstanceRefresh
export def "api create-rollback-instance-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-57
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

# Sets the size of the specified Auto Scaling group. If a scale-in activity occurs as a result of a new DesiredCapacity value that is lower than the current size of the group, the Auto Scaling group uses its termination policy to determine which instances to terminate. For more information, see Manual scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-manual-scaling.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_SetDesiredCapacity
export def "api get-update-desired-capacity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --desired-capacity: int # The desired capacity is the initial capacity of the Auto Scaling group after this operation completes and the capacity it attempts to maintain.
  --honor-cooldown: oneof<nothing, bool> # Indicates whether Amazon EC2 Auto Scaling waits for the cooldown period to complete before initiating a scaling activity to set your Auto Scaling group to its new capacity. By default, Amazon EC2 Auto Scaling does not honor the cooldown period during manual scaling activities.
  --action: string@action-completer-58
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "DesiredCapacity" $desired_capacity "scalar") (serialize-qp "HonorCooldown" $honor_cooldown "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "DesiredCapacity": $desired_capacity, "HonorCooldown": $honor_cooldown, "Action": $action, "Version": $version} | compact), body: null}
}

# Sets the size of the specified Auto Scaling group. If a scale-in activity occurs as a result of a new DesiredCapacity value that is lower than the current size of the group, the Auto Scaling group uses its termination policy to determine which instances to terminate. For more information, see Manual scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-manual-scaling.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_SetDesiredCapacity
export def "api create-update-desired-capacity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-58
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

# Sets the health status of the specified instance. For more information, see Health checks for Auto Scaling instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/healthcheck.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_SetInstanceHealth
export def "api get-update-instance-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-id: string # The ID of the instance.
  --health-status: string # The health status of the instance. Set to Healthy to have the instance remain in service. Set to Unhealthy to have the instance be out of service. Amazon EC2 Auto Scaling terminates and replaces the unhealthy instance.
  --should-respect-grace-period: oneof<nothing, bool> # If the Auto Scaling group of the specified instance has a HealthCheckGracePeriod specified for the group, by default, this call respects the grace period. Set this to False, to have the call not respect the grace period associated with the group. For more information about the health check grace period, see CreateAutoScalingGroup (https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_CreateAutoScalingGroup.html) in the Amazon EC2 Auto Scaling API Reference.
  --action: string@action-completer-59
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
  let qp = [(serialize-qp "InstanceId" $instance_id "scalar") (serialize-qp "HealthStatus" $health_status "scalar") (serialize-qp "ShouldRespectGracePeriod" $should_respect_grace_period "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"InstanceId": $instance_id, "HealthStatus": $health_status, "ShouldRespectGracePeriod": $should_respect_grace_period, "Action": $action, "Version": $version} | compact), body: null}
}

# Sets the health status of the specified instance. For more information, see Health checks for Auto Scaling instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/healthcheck.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_SetInstanceHealth
export def "api create-update-instance-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-59
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

# Updates the instance protection settings of the specified instances. This operation cannot be called on instances in a warm pool. For more information about preventing instances that are part of an Auto Scaling group from terminating on scale in, see Using instance scale-in protection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-instance-protection.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of instance IDs, which is 50 per Auto Scaling group, the call fails.
#
# GET /
# operationId: GET_SetInstanceProtection
export def "api get-update-instance-protection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list # One or more instance IDs. You can specify up to 50 instances.
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --protected-from-scale-in: oneof<nothing, bool> # Indicates whether the instance is protected from termination by Amazon EC2 Auto Scaling when scaling in.
  --action: string@action-completer-60
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
  let qp = [(serialize-qp "InstanceIds" $instance_ids "multi") (serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ProtectedFromScaleIn" $protected_from_scale_in "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"InstanceIds": $instance_ids, "AutoScalingGroupName": $auto_scaling_group_name, "ProtectedFromScaleIn": $protected_from_scale_in, "Action": $action, "Version": $version} | compact), body: null}
}

# Updates the instance protection settings of the specified instances. This operation cannot be called on instances in a warm pool. For more information about preventing instances that are part of an Auto Scaling group from terminating on scale in, see Using instance scale-in protection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-instance-protection.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of instance IDs, which is 50 per Auto Scaling group, the call fails.
#
# POST /
# operationId: POST_SetInstanceProtection
export def "api create-update-instance-protection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-60
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

# Starts an instance refresh. During an instance refresh, Amazon EC2 Auto Scaling performs a rolling update of instances in an Auto Scaling group. Instances are terminated first and then replaced, which temporarily reduces the capacity available within your Auto Scaling group. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group. This feature is helpful, for example, when you have a new AMI or a new user data script. You just need to create a new launch template that specifies the new AMI or user data script. Then start an instance refresh to immediately begin the process of updating instances in the group. If successful, the request's response contains a unique ID that you can use to track the progress of the instance refresh. To query its status, call the DescribeInstanceRefreshes API. To describe the instance refreshes that have already run, call the DescribeInstanceRefreshes API. To cancel an instance refresh that is in progress, use the CancelInstanceRefresh API. An instance refresh might fail for several reasons, such as EC2 launch failures, misconfigured health checks, or not ignoring or allowing the termination of instances that are in Standby state or protected from scale in. You can monitor for failed EC2 launches using the scaling activities. To find the scaling activities, call the DescribeScalingActivities API. If you enable auto rollback, your Auto Scaling group will be rolled back automatically when the instance refresh fails. You can enable this feature before starting an instance refresh by specifying the AutoRollback property in the instance refresh preferences. Otherwise, to roll back an instance refresh before it finishes, use the RollbackInstanceRefresh API.
#
# GET /
# operationId: GET_StartInstanceRefresh
export def "api get-start-instance-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --strategy: string@strategy-completer # The strategy to use for the instance refresh. The only valid value is Rolling.
  --desired-configuration: record # The desired configuration. For example, the desired configuration can specify a new launch template or a new version of the current launch template. Once the instance refresh succeeds, Amazon EC2 Auto Scaling updates the settings of the Auto Scaling group to reflect the new desired configuration. When you specify a new launch template or a new version of the current launch template for your desired configuration, consider enabling the SkipMatching property in preferences. If it's enabled, Amazon EC2 Auto Scaling skips replacing instances that already use the specified launch template and instance types. This can help you reduce the number of replacements that are required to apply updates.
  --preferences: record # Sets your preferences for the instance refresh so that it performs as expected when you start it. Includes the instance warmup time, the minimum healthy percentage, and the behaviors that you want Amazon EC2 Auto Scaling to use if instances that are in Standby state or protected from scale in are found. You can also choose to enable additional features, such as the following: Auto rollback Checkpoints Skip matching
  --action: string@action-completer-61
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "Strategy" $strategy "scalar") (serialize-qp "DesiredConfiguration" $desired_configuration "multi") (serialize-qp "Preferences" $preferences "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "Strategy": $strategy, "DesiredConfiguration": $desired_configuration, "Preferences": $preferences, "Action": $action, "Version": $version} | compact), body: null}
}

# Starts an instance refresh. During an instance refresh, Amazon EC2 Auto Scaling performs a rolling update of instances in an Auto Scaling group. Instances are terminated first and then replaced, which temporarily reduces the capacity available within your Auto Scaling group. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group. This feature is helpful, for example, when you have a new AMI or a new user data script. You just need to create a new launch template that specifies the new AMI or user data script. Then start an instance refresh to immediately begin the process of updating instances in the group. If successful, the request's response contains a unique ID that you can use to track the progress of the instance refresh. To query its status, call the DescribeInstanceRefreshes API. To describe the instance refreshes that have already run, call the DescribeInstanceRefreshes API. To cancel an instance refresh that is in progress, use the CancelInstanceRefresh API. An instance refresh might fail for several reasons, such as EC2 launch failures, misconfigured health checks, or not ignoring or allowing the termination of instances that are in Standby state or protected from scale in. You can monitor for failed EC2 launches using the scaling activities. To find the scaling activities, call the DescribeScalingActivities API. If you enable auto rollback, your Auto Scaling group will be rolled back automatically when the instance refresh fails. You can enable this feature before starting an instance refresh by specifying the AutoRollback property in the instance refresh preferences. Otherwise, to roll back an instance refresh before it finishes, use the RollbackInstanceRefresh API.
#
# POST /
# operationId: POST_StartInstanceRefresh
export def "api create-start-instance-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-61
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

# Suspends the specified auto scaling processes, or all processes, for the specified Auto Scaling group. If you suspend either the Launch or Terminate process types, it can prevent other process types from functioning properly. For more information, see Suspending and resuming scaling processes (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-suspend-resume-processes.html) in the Amazon EC2 Auto Scaling User Guide. To resume processes that have been suspended, call the ResumeProcesses API.
#
# GET /
# operationId: GET_SuspendProcesses
export def "api get-suspend-processes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --scaling-processes: list # One or more of the following processes: Launch Terminate AddToLoadBalancer AlarmNotification AZRebalance HealthCheck InstanceRefresh ReplaceUnhealthy ScheduledActions If you omit this property, all processes are specified.
  --action: string@action-completer-62
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "ScalingProcesses" $scaling_processes "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "ScalingProcesses": $scaling_processes, "Action": $action, "Version": $version} | compact), body: null}
}

# Suspends the specified auto scaling processes, or all processes, for the specified Auto Scaling group. If you suspend either the Launch or Terminate process types, it can prevent other process types from functioning properly. For more information, see Suspending and resuming scaling processes (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-suspend-resume-processes.html) in the Amazon EC2 Auto Scaling User Guide. To resume processes that have been suspended, call the ResumeProcesses API.
#
# POST /
# operationId: POST_SuspendProcesses
export def "api create-suspend-processes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-62
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

# Terminates the specified instance and optionally adjusts the desired group size. This operation cannot be called on instances in a warm pool. This call simply makes a termination request. The instance is not terminated immediately. When an instance is terminated, the instance status changes to terminated. You can't connect to or start an instance after you've terminated it. If you do not specify the option to decrement the desired capacity, Amazon EC2 Auto Scaling launches instances to replace the ones that are terminated. By default, Amazon EC2 Auto Scaling balances instances across all Availability Zones. If you decrement the desired capacity, your Auto Scaling group can become unbalanced between Availability Zones. Amazon EC2 Auto Scaling tries to rebalance the group, and rebalancing might terminate instances in other zones. For more information, see Rebalancing activities (https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-benefits.html#AutoScalingBehavior.InstanceUsage) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_TerminateInstanceInAutoScalingGroup
export def "api get-terminate-instance-in-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-id: string # The ID of the instance.
  --should-decrement-desired-capacity: oneof<nothing, bool> # Indicates whether terminating the instance also decrements the size of the Auto Scaling group.
  --action: string@action-completer-63
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
  let qp = [(serialize-qp "InstanceId" $instance_id "scalar") (serialize-qp "ShouldDecrementDesiredCapacity" $should_decrement_desired_capacity "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"InstanceId": $instance_id, "ShouldDecrementDesiredCapacity": $should_decrement_desired_capacity, "Action": $action, "Version": $version} | compact), body: null}
}

# Terminates the specified instance and optionally adjusts the desired group size. This operation cannot be called on instances in a warm pool. This call simply makes a termination request. The instance is not terminated immediately. When an instance is terminated, the instance status changes to terminated. You can't connect to or start an instance after you've terminated it. If you do not specify the option to decrement the desired capacity, Amazon EC2 Auto Scaling launches instances to replace the ones that are terminated. By default, Amazon EC2 Auto Scaling balances instances across all Availability Zones. If you decrement the desired capacity, your Auto Scaling group can become unbalanced between Availability Zones. Amazon EC2 Auto Scaling tries to rebalance the group, and rebalancing might terminate instances in other zones. For more information, see Rebalancing activities (https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-benefits.html#AutoScalingBehavior.InstanceUsage) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_TerminateInstanceInAutoScalingGroup
export def "api create-terminate-instance-in-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-63
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

# We strongly recommend that all Auto Scaling groups use launch templates to ensure full functionality for Amazon EC2 Auto Scaling and Amazon EC2. Updates the configuration for the specified Auto Scaling group. To update an Auto Scaling group, specify the name of the group and the property that you want to change. Any properties that you don't specify are not changed by this update request. The new settings take effect on any scaling activities after this call returns. If you associate a new launch configuration or template with an Auto Scaling group, all new instances will get the updated configuration. Existing instances continue to run with the configuration that they were originally launched with. When you update a group to specify a mixed instances policy instead of a launch configuration or template, existing instances may be replaced to match the new purchasing options that you specified in the policy. For example, if the group currently has 100% On-Demand capacity and the policy specifies 50% Spot capacity, this means that half of your instances will be gradually terminated and relaunched as Spot Instances. When replacing instances, Amazon EC2 Auto Scaling launches new instances before terminating the old ones, so that updating your group does not compromise the performance or availability of your application. Note the following about changing DesiredCapacity, MaxSize, or MinSize: If a scale-in activity occurs as a result of a new DesiredCapacity value that is lower than the current size of the group, the Auto Scaling group uses its termination policy to determine which instances to terminate. If you specify a new value for MinSize without specifying a value for DesiredCapacity, and the new MinSize is larger than the current size of the group, this sets the group's DesiredCapacity to the new MinSize value. If you specify a new value for MaxSize without specifying a value for DesiredCapacity, and the new MaxSize is smaller than the current size of the group, this sets the group's DesiredCapacity to the new MaxSize value. To see which properties have been set, call the DescribeAutoScalingGroups API. To view the scaling policies for an Auto Scaling group, call the DescribePolicies API. If the group has scaling policies, you can update them by calling the PutScalingPolicy API.
#
# GET /
# operationId: GET_UpdateAutoScalingGroup
export def "api get-update-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --launch-configuration-name: string # The name of the launch configuration. If you specify LaunchConfigurationName in your update request, you can't specify LaunchTemplate or MixedInstancesPolicy.
  --launch-template: record # The launch template and version to use to specify the updates. If you specify LaunchTemplate in your update request, you can't specify LaunchConfigurationName or MixedInstancesPolicy.
  --mixed-instances-policy: record # The mixed instances policy. For more information, see Auto Scaling groups with multiple instance types and purchase options (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-mixed-instances-groups.html) in the Amazon EC2 Auto Scaling User Guide.
  --min-size: int # The minimum size of the Auto Scaling group.
  --max-size: int # The maximum size of the Auto Scaling group. With a mixed instances policy that uses instance weighting, Amazon EC2 Auto Scaling may need to go above MaxSize to meet your capacity requirements. In this event, Amazon EC2 Auto Scaling will never go above MaxSize by more than your largest instance weight (weights that define how many units each instance contributes to the desired capacity of the group).
  --desired-capacity: int # The desired capacity is the initial capacity of the Auto Scaling group after this operation completes and the capacity it attempts to maintain. This number must be greater than or equal to the minimum size of the group and less than or equal to the maximum size of the group.
  --default-cooldown: int # Only needed if you use simple scaling policies. The amount of time, in seconds, between one scaling activity ending and another one starting due to simple scaling policies. For more information, see Scaling cooldowns for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/Cooldown.html) in the Amazon EC2 Auto Scaling User Guide.
  --availability-zones: list # One or more Availability Zones for the group.
  --health-check-type: string # A comma-separated value string of one or more health check types. The valid values are EC2, ELB, and VPC_LATTICE. EC2 is the default health check and cannot be disabled. For more information, see Health checks for Auto Scaling instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/healthcheck.html) in the Amazon EC2 Auto Scaling User Guide. Only specify EC2 if you must clear a value that was previously set.
  --health-check-grace-period: int # The amount of time, in seconds, that Amazon EC2 Auto Scaling waits before checking the health status of an EC2 instance that has come into service and marking it unhealthy due to a failed health check. This is useful if your instances do not immediately pass their health checks after they enter the InService state. For more information, see Set the health check grace period for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/health-check-grace-period.html) in the Amazon EC2 Auto Scaling User Guide.
  --placement-group: string # The name of an existing placement group into which to launch your instances. For more information, see Placement groups (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/placement-groups.html) in the Amazon EC2 User Guide for Linux Instances. A cluster placement group is a logical grouping of instances within a single Availability Zone. You cannot specify multiple Availability Zones and a cluster placement group.
  --vpc-zone-identifier: string # A comma-separated list of subnet IDs for a virtual private cloud (VPC). If you specify VPCZoneIdentifier with AvailabilityZones, the subnets that you specify must reside in those Availability Zones.
  --termination-policies: list # A policy or a list of policies that are used to select the instances to terminate. The policies are executed in the order that you list them. For more information, see Work with Amazon EC2 Auto Scaling termination policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-termination-policies.html) in the Amazon EC2 Auto Scaling User Guide. Valid values: Default | AllocationStrategy | ClosestToNextInstanceHour | NewestInstance | OldestInstance | OldestLaunchConfiguration | OldestLaunchTemplate | arn:aws:lambda:region:account-id:function:my-function:my-alias
  --new-instances-protected-from-scale-in: oneof<nothing, bool> # Indicates whether newly launched instances are protected from termination by Amazon EC2 Auto Scaling when scaling in. For more information about preventing instances from terminating on scale in, see Using instance scale-in protection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-instance-protection.html) in the Amazon EC2 Auto Scaling User Guide.
  --service-linked-role-arn: string # The Amazon Resource Name (ARN) of the service-linked role that the Auto Scaling group uses to call other Amazon Web Services on your behalf. For more information, see Service-linked roles (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-service-linked-role.html) in the Amazon EC2 Auto Scaling User Guide.
  --max-instance-lifetime: int # The maximum amount of time, in seconds, that an instance can be in service. The default is null. If specified, the value must be either 0 or a number equal to or greater than 86,400 seconds (1 day). To clear a previously set value, specify a new value of 0. For more information, see Replacing Auto Scaling instances based on maximum instance lifetime (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-max-instance-lifetime.html) in the Amazon EC2 Auto Scaling User Guide.
  --capacity-rebalance: oneof<nothing, bool> # Enables or disables Capacity Rebalancing. For more information, see Use Capacity Rebalancing to handle Amazon EC2 Spot Interruptions (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-capacity-rebalancing.html) in the Amazon EC2 Auto Scaling User Guide.
  --context: string # Reserved.
  --desired-capacity-type: string # The unit of measurement for the value specified for desired capacity. Amazon EC2 Auto Scaling supports DesiredCapacityType for attribute-based instance type selection only. For more information, see Creating an Auto Scaling group using attribute-based instance type selection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-asg-instance-type-requirements.html) in the Amazon EC2 Auto Scaling User Guide. By default, Amazon EC2 Auto Scaling specifies units, which translates into number of instances. Valid values: units | vcpu | memory-mib
  --default-instance-warmup: int # The amount of time, in seconds, until a new instance is considered to have finished initializing and resource consumption to become stable after it enters the InService state. During an instance refresh, Amazon EC2 Auto Scaling waits for the warm-up period after it replaces an instance before it moves on to replacing the next instance. Amazon EC2 Auto Scaling also waits for the warm-up period before aggregating the metrics for new instances with existing instances in the Amazon CloudWatch metrics that are used for scaling, resulting in more reliable usage data. For more information, see Set the default instance warmup for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-default-instance-warmup.html) in the Amazon EC2 Auto Scaling User Guide. To manage various warm-up settings at the group level, we recommend that you set the default instance warmup, even if it is set to 0 seconds. To remove a value that you previously set, include the property but specify -1 for the value. However, we strongly recommend keeping the default instance warmup enabled by specifying a value of 0 or other nominal value.
  --action: string@action-completer-64
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
  let qp = [(serialize-qp "AutoScalingGroupName" $auto_scaling_group_name "scalar") (serialize-qp "LaunchConfigurationName" $launch_configuration_name "scalar") (serialize-qp "LaunchTemplate" $launch_template "multi") (serialize-qp "MixedInstancesPolicy" $mixed_instances_policy "multi") (serialize-qp "MinSize" $min_size "scalar") (serialize-qp "MaxSize" $max_size "scalar") (serialize-qp "DesiredCapacity" $desired_capacity "scalar") (serialize-qp "DefaultCooldown" $default_cooldown "scalar") (serialize-qp "AvailabilityZones" $availability_zones "multi") (serialize-qp "HealthCheckType" $health_check_type "scalar") (serialize-qp "HealthCheckGracePeriod" $health_check_grace_period "scalar") (serialize-qp "PlacementGroup" $placement_group "scalar") (serialize-qp "VPCZoneIdentifier" $vpc_zone_identifier "scalar") (serialize-qp "TerminationPolicies" $termination_policies "multi") (serialize-qp "NewInstancesProtectedFromScaleIn" $new_instances_protected_from_scale_in "scalar") (serialize-qp "ServiceLinkedRoleARN" $service_linked_role_arn "scalar") (serialize-qp "MaxInstanceLifetime" $max_instance_lifetime "scalar") (serialize-qp "CapacityRebalance" $capacity_rebalance "scalar") (serialize-qp "Context" $context "scalar") (serialize-qp "DesiredCapacityType" $desired_capacity_type "scalar") (serialize-qp "DefaultInstanceWarmup" $default_instance_warmup "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AutoScalingGroupName": $auto_scaling_group_name, "LaunchConfigurationName": $launch_configuration_name, "LaunchTemplate": $launch_template, "MixedInstancesPolicy": $mixed_instances_policy, "MinSize": $min_size, "MaxSize": $max_size, "DesiredCapacity": $desired_capacity, "DefaultCooldown": $default_cooldown, "AvailabilityZones": $availability_zones, "HealthCheckType": $health_check_type, "HealthCheckGracePeriod": $health_check_grace_period, "PlacementGroup": $placement_group, "VPCZoneIdentifier": $vpc_zone_identifier, "TerminationPolicies": $termination_policies, "NewInstancesProtectedFromScaleIn": $new_instances_protected_from_scale_in, "ServiceLinkedRoleARN": $service_linked_role_arn, "MaxInstanceLifetime": $max_instance_lifetime, "CapacityRebalance": $capacity_rebalance, "Context": $context, "DesiredCapacityType": $desired_capacity_type, "DefaultInstanceWarmup": $default_instance_warmup, "Action": $action, "Version": $version} | compact), body: null}
}

# We strongly recommend that all Auto Scaling groups use launch templates to ensure full functionality for Amazon EC2 Auto Scaling and Amazon EC2. Updates the configuration for the specified Auto Scaling group. To update an Auto Scaling group, specify the name of the group and the property that you want to change. Any properties that you don't specify are not changed by this update request. The new settings take effect on any scaling activities after this call returns. If you associate a new launch configuration or template with an Auto Scaling group, all new instances will get the updated configuration. Existing instances continue to run with the configuration that they were originally launched with. When you update a group to specify a mixed instances policy instead of a launch configuration or template, existing instances may be replaced to match the new purchasing options that you specified in the policy. For example, if the group currently has 100% On-Demand capacity and the policy specifies 50% Spot capacity, this means that half of your instances will be gradually terminated and relaunched as Spot Instances. When replacing instances, Amazon EC2 Auto Scaling launches new instances before terminating the old ones, so that updating your group does not compromise the performance or availability of your application. Note the following about changing DesiredCapacity, MaxSize, or MinSize: If a scale-in activity occurs as a result of a new DesiredCapacity value that is lower than the current size of the group, the Auto Scaling group uses its termination policy to determine which instances to terminate. If you specify a new value for MinSize without specifying a value for DesiredCapacity, and the new MinSize is larger than the current size of the group, this sets the group's DesiredCapacity to the new MinSize value. If you specify a new value for MaxSize without specifying a value for DesiredCapacity, and the new MaxSize is smaller than the current size of the group, this sets the group's DesiredCapacity to the new MaxSize value. To see which properties have been set, call the DescribeAutoScalingGroups API. To view the scaling policies for an Auto Scaling group, call the DescribePolicies API. If the group has scaling policies, you can update them by calling the PutScalingPolicy API.
#
# POST /
# operationId: POST_UpdateAutoScalingGroup
export def "api create-update-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-64
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
