# Auto-generated client for Application Auto Scaling v2016-02-06
# Source: https://api.apis.guru/v2/specs/amazonaws.com/application-autoscaling/2016-02-06/openapi.json
# Auth: --token flag or $env.APPLICATION_AUTO_SCALING_TOKEN

const BASE_URL = "http://application-autoscaling.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APPLICATION_AUTO_SCALING_TOKEN | default "" }
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

def base-url-completer [] { ["http://application-autoscaling.us-east-1.amazonaws.com" "http://application-autoscaling.us-east-2.amazonaws.com" "http://application-autoscaling.us-west-1.amazonaws.com" "http://application-autoscaling.us-west-2.amazonaws.com" "http://application-autoscaling.us-gov-west-1.amazonaws.com" "http://application-autoscaling.us-gov-east-1.amazonaws.com" "http://application-autoscaling.ca-central-1.amazonaws.com" "http://application-autoscaling.eu-north-1.amazonaws.com" "http://application-autoscaling.eu-west-1.amazonaws.com" "http://application-autoscaling.eu-west-2.amazonaws.com" "http://application-autoscaling.eu-west-3.amazonaws.com" "http://application-autoscaling.eu-central-1.amazonaws.com" "http://application-autoscaling.eu-south-1.amazonaws.com" "http://application-autoscaling.af-south-1.amazonaws.com" "http://application-autoscaling.ap-northeast-1.amazonaws.com" "http://application-autoscaling.ap-northeast-2.amazonaws.com" "http://application-autoscaling.ap-northeast-3.amazonaws.com" "http://application-autoscaling.ap-southeast-1.amazonaws.com" "http://application-autoscaling.ap-southeast-2.amazonaws.com" "http://application-autoscaling.ap-east-1.amazonaws.com" "http://application-autoscaling.ap-south-1.amazonaws.com" "http://application-autoscaling.sa-east-1.amazonaws.com" "http://application-autoscaling.me-south-1.amazonaws.com" "https://application-autoscaling.us-east-1.amazonaws.com" "https://application-autoscaling.us-east-2.amazonaws.com" "https://application-autoscaling.us-west-1.amazonaws.com" "https://application-autoscaling.us-west-2.amazonaws.com" "https://application-autoscaling.us-gov-west-1.amazonaws.com" "https://application-autoscaling.us-gov-east-1.amazonaws.com" "https://application-autoscaling.ca-central-1.amazonaws.com" "https://application-autoscaling.eu-north-1.amazonaws.com" "https://application-autoscaling.eu-west-1.amazonaws.com" "https://application-autoscaling.eu-west-2.amazonaws.com" "https://application-autoscaling.eu-west-3.amazonaws.com" "https://application-autoscaling.eu-central-1.amazonaws.com" "https://application-autoscaling.eu-south-1.amazonaws.com" "https://application-autoscaling.af-south-1.amazonaws.com" "https://application-autoscaling.ap-northeast-1.amazonaws.com" "https://application-autoscaling.ap-northeast-2.amazonaws.com" "https://application-autoscaling.ap-northeast-3.amazonaws.com" "https://application-autoscaling.ap-southeast-1.amazonaws.com" "https://application-autoscaling.ap-southeast-2.amazonaws.com" "https://application-autoscaling.ap-east-1.amazonaws.com" "https://application-autoscaling.ap-south-1.amazonaws.com" "https://application-autoscaling.sa-east-1.amazonaws.com" "https://application-autoscaling.me-south-1.amazonaws.com" "http://application-autoscaling.cn-north-1.amazonaws.com.cn" "http://application-autoscaling.cn-northwest-1.amazonaws.com.cn" "https://application-autoscaling.cn-north-1.amazonaws.com.cn" "https://application-autoscaling.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AnyScaleFrontendService.DeleteScalingPolicy"] }
def x-amz-target-completer-1 [] { ["AnyScaleFrontendService.DeleteScheduledAction"] }
def x-amz-target-completer-2 [] { ["AnyScaleFrontendService.DeregisterScalableTarget"] }
def x-amz-target-completer-3 [] { ["AnyScaleFrontendService.DescribeScalableTargets"] }
def x-amz-target-completer-4 [] { ["AnyScaleFrontendService.DescribeScalingActivities"] }
def x-amz-target-completer-5 [] { ["AnyScaleFrontendService.DescribeScalingPolicies"] }
def x-amz-target-completer-6 [] { ["AnyScaleFrontendService.DescribeScheduledActions"] }
def x-amz-target-completer-7 [] { ["AnyScaleFrontendService.ListTagsForResource"] }
def x-amz-target-completer-8 [] { ["AnyScaleFrontendService.PutScalingPolicy"] }
def x-amz-target-completer-9 [] { ["AnyScaleFrontendService.PutScheduledAction"] }
def x-amz-target-completer-10 [] { ["AnyScaleFrontendService.RegisterScalableTarget"] }
def x-amz-target-completer-11 [] { ["AnyScaleFrontendService.TagResource"] }
def x-amz-target-completer-12 [] { ["AnyScaleFrontendService.UntagResource"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-any-scale-frontend-service-delete-scaling-policy delete" } } | get name | first)
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

# Deletes the specified scaling policy for an Application Auto Scaling scalable target. Deleting a step scaling policy deletes the underlying alarm action, but does not delete the CloudWatch alarm associated with the scaling policy, even if it no longer has an associated action. For more information, see Delete a step scaling policy (https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html#delete-step-scaling-policy) and Delete a target tracking scaling policy (https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html#delete-target-tracking-policy) in the Application Auto Scaling User Guide.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.DeleteScalingPolicy
# operationId: DeleteScalingPolicy
export def "x-amz-target-any-scale-frontend-service-delete-scaling-policy delete" [
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
  --x-amz-target: string@x-amz-target-completer
  policy_name: any
  service_namespace: any
  resource_id: any
  scalable_dimension: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.DeleteScalingPolicy")
  let req_body = {"PolicyName": $policy_name, "ServiceNamespace": $service_namespace, "ResourceId": $resource_id, "ScalableDimension": $scalable_dimension} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified scheduled action for an Application Auto Scaling scalable target. For more information, see Delete a scheduled action (https://docs.aws.amazon.com/autoscaling/application/userguide/scheduled-scaling-additional-cli-commands.html#delete-scheduled-action) in the Application Auto Scaling User Guide.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.DeleteScheduledAction
# operationId: DeleteScheduledAction
export def "x-amz-target-any-scale-frontend-service-delete-scheduled-action delete" [
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
  --x-amz-target: string@x-amz-target-completer-1
  service_namespace: any
  scheduled_action_name: any
  resource_id: any
  scalable_dimension: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.DeleteScheduledAction")
  let req_body = {"ServiceNamespace": $service_namespace, "ScheduledActionName": $scheduled_action_name, "ResourceId": $resource_id, "ScalableDimension": $scalable_dimension} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deregisters an Application Auto Scaling scalable target when you have finished using it. To see which resources have been registered, use DescribeScalableTargets (https://docs.aws.amazon.com/autoscaling/application/APIReference/API_DescribeScalableTargets.html). Deregistering a scalable target deletes the scaling policies and the scheduled actions that are associated with it.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.DeregisterScalableTarget
# operationId: DeregisterScalableTarget
export def "x-amz-target-any-scale-frontend-service-deregister-scalable-target create" [
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
  --x-amz-target: string@x-amz-target-completer-2
  service_namespace: any
  resource_id: any
  scalable_dimension: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.DeregisterScalableTarget")
  let req_body = {"ServiceNamespace": $service_namespace, "ResourceId": $resource_id, "ScalableDimension": $scalable_dimension} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the scalable targets in the specified namespace. You can filter the results using ResourceIds and ScalableDimension.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.DescribeScalableTargets
# operationId: DescribeScalableTargets
export def "x-amz-target-any-scale-frontend-service-describe-scalable-targets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3
  service_namespace: any
  --resource-ids: any
  --scalable-dimension: any
  --max-results: any
  --next-token: any
]: any -> record<ScalableTargets: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.DescribeScalableTargets" $qp)
  let req_body = {"ServiceNamespace": $service_namespace, "ResourceIds": $resource_ids, "ScalableDimension": $scalable_dimension, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provides descriptive information about the scaling activities in the specified namespace from the previous six weeks. You can filter the results using ResourceId and ScalableDimension. For information about viewing scaling activities using the Amazon Web Services CLI, see Scaling activities for Application Auto Scaling (https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-scaling-activities.html).
#
# POST /#X-Amz-Target=AnyScaleFrontendService.DescribeScalingActivities
# operationId: DescribeScalingActivities
export def "x-amz-target-any-scale-frontend-service-describe-scaling-activities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4
  service_namespace: any
  --resource-id: any
  --scalable-dimension: any
  --max-results: any
  --next-token: any
  --include-not-scaled-activities: any
]: any -> record<ScalingActivities: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.DescribeScalingActivities" $qp)
  let req_body = {"ServiceNamespace": $service_namespace, "ResourceId": $resource_id, "ScalableDimension": $scalable_dimension, "MaxResults": $max_results, "NextToken": $next_token, "IncludeNotScaledActivities": $include_not_scaled_activities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes the Application Auto Scaling scaling policies for the specified service namespace. You can filter the results using ResourceId, ScalableDimension, and PolicyNames. For more information, see Target tracking scaling policies (https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html) and Step scaling policies (https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html) in the Application Auto Scaling User Guide.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.DescribeScalingPolicies
# operationId: DescribeScalingPolicies
export def "x-amz-target-any-scale-frontend-service-describe-scaling-policies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5
  --policy-names: any
  service_namespace: any
  --resource-id: any
  --scalable-dimension: any
  --max-results: any
  --next-token: any
]: any -> record<ScalingPolicies: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.DescribeScalingPolicies" $qp)
  let req_body = {"PolicyNames": $policy_names, "ServiceNamespace": $service_namespace, "ResourceId": $resource_id, "ScalableDimension": $scalable_dimension, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes the Application Auto Scaling scheduled actions for the specified service namespace. You can filter the results using the ResourceId, ScalableDimension, and ScheduledActionNames parameters. For more information, see Scheduled scaling (https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-scheduled-scaling.html) and Managing scheduled scaling (https://docs.aws.amazon.com/autoscaling/application/userguide/scheduled-scaling-additional-cli-commands.html) in the Application Auto Scaling User Guide.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.DescribeScheduledActions
# operationId: DescribeScheduledActions
export def "x-amz-target-any-scale-frontend-service-describe-scheduled-actions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6
  --scheduled-action-names: any
  service_namespace: any
  --resource-id: any
  --scalable-dimension: any
  --max-results: any
  --next-token: any
]: any -> record<ScheduledActions: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.DescribeScheduledActions" $qp)
  let req_body = {"ScheduledActionNames": $scheduled_action_names, "ServiceNamespace": $service_namespace, "ResourceId": $resource_id, "ScalableDimension": $scalable_dimension, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns all the tags on the specified Application Auto Scaling scalable target. For general information about tags, including the format and syntax, see Tagging Amazon Web Services resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.ListTagsForResource
# operationId: ListTagsForResource
export def "x-amz-target-any-scale-frontend-service-list-tags-for-resource list" [
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
  --x-amz-target: string@x-amz-target-completer-7
  resource_arn: any
]: any -> record<Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.ListTagsForResource")
  let req_body = {"ResourceARN": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates or updates a scaling policy for an Application Auto Scaling scalable target. Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scaling policy applies to the scalable target identified by those three attributes. You cannot create a scaling policy until you have registered the resource as a scalable target. Multiple scaling policies can be in force at the same time for the same scalable target. You can have one or more target tracking scaling policies, one or more step scaling policies, or both. However, there is a chance that multiple policies could conflict, instructing the scalable target to scale out or in at the same time. Application Auto Scaling gives precedence to the policy that provides the largest capacity for both scale out and scale in. For example, if one policy increases capacity by 3, another policy increases capacity by 200 percent, and the current capacity is 10, Application Auto Scaling uses the policy with the highest calculated capacity (200% of 10 = 20) and scales out to 30. We recommend caution, however, when using target tracking scaling policies with step scaling policies because conflicts between these policies can cause undesirable behavior. For example, if the step scaling policy initiates a scale-in activity before the target tracking policy is ready to scale in, the scale-in activity will not be blocked. After the scale-in activity completes, the target tracking policy could instruct the scalable target to scale out again. For more information, see Target tracking scaling policies (https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html) and Step scaling policies (https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html) in the Application Auto Scaling User Guide. If a scalable target is deregistered, the scalable target is no longer available to use scaling policies. Any scaling policies that were specified for the scalable target are deleted.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.PutScalingPolicy
# operationId: PutScalingPolicy
export def "x-amz-target-any-scale-frontend-service-put-scaling-policy update" [
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
  --x-amz-target: string@x-amz-target-completer-8
  policy_name: any
  service_namespace: any
  resource_id: any
  scalable_dimension: any
  --policy-type: any
  --step-scaling-policy-configuration: any
  --target-tracking-scaling-policy-configuration: any
]: any -> record<PolicyARN: record, Alarms: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.PutScalingPolicy")
  let req_body = {"PolicyName": $policy_name, "ServiceNamespace": $service_namespace, "ResourceId": $resource_id, "ScalableDimension": $scalable_dimension, "PolicyType": $policy_type, "StepScalingPolicyConfiguration": $step_scaling_policy_configuration, "TargetTrackingScalingPolicyConfiguration": $target_tracking_scaling_policy_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates or updates a scheduled action for an Application Auto Scaling scalable target. Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scheduled action applies to the scalable target identified by those three attributes. You cannot create a scheduled action until you have registered the resource as a scalable target. When you specify start and end times with a recurring schedule using a cron expression or rates, they form the boundaries for when the recurring action starts and stops. To update a scheduled action, specify the parameters that you want to change. If you don't specify start and end times, the old values are deleted. For more information, see Scheduled scaling (https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-scheduled-scaling.html) in the Application Auto Scaling User Guide. If a scalable target is deregistered, the scalable target is no longer available to run scheduled actions. Any scheduled actions that were specified for the scalable target are deleted.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.PutScheduledAction
# operationId: PutScheduledAction
export def "x-amz-target-any-scale-frontend-service-put-scheduled-action update" [
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
  --x-amz-target: string@x-amz-target-completer-9
  service_namespace: any
  --schedule: any
  --timezone: any
  scheduled_action_name: any
  resource_id: any
  scalable_dimension: any
  --start-time: any
  --end-time: any
  --scalable-target-action: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.PutScheduledAction")
  let req_body = {"ServiceNamespace": $service_namespace, "Schedule": $schedule, "Timezone": $timezone, "ScheduledActionName": $scheduled_action_name, "ResourceId": $resource_id, "ScalableDimension": $scalable_dimension, "StartTime": $start_time, "EndTime": $end_time, "ScalableTargetAction": $scalable_target_action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Registers or updates a scalable target, which is the resource that you want to scale. Scalable targets are uniquely identified by the combination of resource ID, scalable dimension, and namespace, which represents some capacity dimension of the underlying service. When you register a new scalable target, you must specify values for the minimum and maximum capacity. If the specified resource is not active in the target service, this operation does not change the resource's current capacity. Otherwise, it changes the resource's current capacity to a value that is inside of this range. If you add a scaling policy, current capacity is adjustable within the specified range when scaling starts. Application Auto Scaling scaling policies will not scale capacity to values that are outside of the minimum and maximum range. After you register a scalable target, you do not need to register it again to use other Application Auto Scaling operations. To see which resources have been registered, use DescribeScalableTargets (https://docs.aws.amazon.com/autoscaling/application/APIReference/API_DescribeScalableTargets.html). You can also view the scaling policies for a service namespace by using DescribeScalableTargets (https://docs.aws.amazon.com/autoscaling/application/APIReference/API_DescribeScalableTargets.html). If you no longer need a scalable target, you can deregister it by using DeregisterScalableTarget (https://docs.aws.amazon.com/autoscaling/application/APIReference/API_DeregisterScalableTarget.html). To update a scalable target, specify the parameters that you want to change. Include the parameters that identify the scalable target: resource ID, scalable dimension, and namespace. Any parameters that you don't specify are not changed by this update request. If you call the RegisterScalableTarget API operation to create a scalable target, there might be a brief delay until the operation achieves eventual consistency (https://en.wikipedia.org/wiki/Eventual_consistency). You might become aware of this brief delay if you get unexpected errors when performing sequential operations. The typical strategy is to retry the request, and some Amazon Web Services SDKs include automatic backoff and retry logic. If you call the RegisterScalableTarget API operation to update an existing scalable target, Application Auto Scaling retrieves the current capacity of the resource. If it's below the minimum capacity or above the maximum capacity, Application Auto Scaling adjusts the capacity of the scalable target to place it within these bounds, even if you don't include the MinCapacity or MaxCapacity request parameters.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.RegisterScalableTarget
# operationId: RegisterScalableTarget
export def "x-amz-target-any-scale-frontend-service-register-scalable-target create" [
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
  --x-amz-target: string@x-amz-target-completer-10
  service_namespace: any
  resource_id: any
  scalable_dimension: any
  --min-capacity: any
  --max-capacity: any
  --role-arn: any
  --suspended-state: any
  --tags: any
]: any -> record<ScalableTargetARN: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.RegisterScalableTarget")
  let req_body = {"ServiceNamespace": $service_namespace, "ResourceId": $resource_id, "ScalableDimension": $scalable_dimension, "MinCapacity": $min_capacity, "MaxCapacity": $max_capacity, "RoleARN": $role_arn, "SuspendedState": $suspended_state, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Adds or edits tags on an Application Auto Scaling scalable target. Each tag consists of a tag key and a tag value, which are both case-sensitive strings. To add a tag, specify a new tag key and a tag value. To edit a tag, specify an existing tag key and a new tag value. You can use this operation to tag an Application Auto Scaling scalable target, but you cannot tag a scaling policy or scheduled action. You can also add tags to an Application Auto Scaling scalable target while creating it (RegisterScalableTarget). For general information about tags, including the format and syntax, see Tagging Amazon Web Services resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. Use tags to control access to a scalable target. For more information, see Tagging support for Application Auto Scaling (https://docs.aws.amazon.com/autoscaling/application/userguide/resource-tagging-support.html) in the Application Auto Scaling User Guide.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.TagResource
# operationId: TagResource
export def "x-amz-target-any-scale-frontend-service-tag-resource tag" [
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
  --x-amz-target: string@x-amz-target-completer-11
  resource_arn: any
  tags: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.TagResource")
  let req_body = {"ResourceARN": $resource_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes tags from an Application Auto Scaling scalable target. To delete a tag, specify the tag key and the Application Auto Scaling scalable target.
#
# POST /#X-Amz-Target=AnyScaleFrontendService.UntagResource
# operationId: UntagResource
export def "x-amz-target-any-scale-frontend-service-untag-resource untag" [
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
  --x-amz-target: string@x-amz-target-completer-12
  resource_arn: any
  tag_keys: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleFrontendService.UntagResource")
  let req_body = {"ResourceARN": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
