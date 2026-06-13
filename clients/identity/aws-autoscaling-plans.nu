# Auto-generated client for AWS Auto Scaling Plans v2018-01-06
# Source: https://api.apis.guru/v2/specs/amazonaws.com/autoscaling-plans/2018-01-06/openapi.json
# Auth: --token flag or $env.AWS_AUTO_SCALING_PLANS_TOKEN

const BASE_URL = "http://autoscaling-plans.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_AUTO_SCALING_PLANS_TOKEN | default "" }
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

def base-url-completer [] { ["http://autoscaling-plans.us-east-1.amazonaws.com" "http://autoscaling-plans.us-east-2.amazonaws.com" "http://autoscaling-plans.us-west-1.amazonaws.com" "http://autoscaling-plans.us-west-2.amazonaws.com" "http://autoscaling-plans.us-gov-west-1.amazonaws.com" "http://autoscaling-plans.us-gov-east-1.amazonaws.com" "http://autoscaling-plans.ca-central-1.amazonaws.com" "http://autoscaling-plans.eu-north-1.amazonaws.com" "http://autoscaling-plans.eu-west-1.amazonaws.com" "http://autoscaling-plans.eu-west-2.amazonaws.com" "http://autoscaling-plans.eu-west-3.amazonaws.com" "http://autoscaling-plans.eu-central-1.amazonaws.com" "http://autoscaling-plans.eu-south-1.amazonaws.com" "http://autoscaling-plans.af-south-1.amazonaws.com" "http://autoscaling-plans.ap-northeast-1.amazonaws.com" "http://autoscaling-plans.ap-northeast-2.amazonaws.com" "http://autoscaling-plans.ap-northeast-3.amazonaws.com" "http://autoscaling-plans.ap-southeast-1.amazonaws.com" "http://autoscaling-plans.ap-southeast-2.amazonaws.com" "http://autoscaling-plans.ap-east-1.amazonaws.com" "http://autoscaling-plans.ap-south-1.amazonaws.com" "http://autoscaling-plans.sa-east-1.amazonaws.com" "http://autoscaling-plans.me-south-1.amazonaws.com" "https://autoscaling-plans.us-east-1.amazonaws.com" "https://autoscaling-plans.us-east-2.amazonaws.com" "https://autoscaling-plans.us-west-1.amazonaws.com" "https://autoscaling-plans.us-west-2.amazonaws.com" "https://autoscaling-plans.us-gov-west-1.amazonaws.com" "https://autoscaling-plans.us-gov-east-1.amazonaws.com" "https://autoscaling-plans.ca-central-1.amazonaws.com" "https://autoscaling-plans.eu-north-1.amazonaws.com" "https://autoscaling-plans.eu-west-1.amazonaws.com" "https://autoscaling-plans.eu-west-2.amazonaws.com" "https://autoscaling-plans.eu-west-3.amazonaws.com" "https://autoscaling-plans.eu-central-1.amazonaws.com" "https://autoscaling-plans.eu-south-1.amazonaws.com" "https://autoscaling-plans.af-south-1.amazonaws.com" "https://autoscaling-plans.ap-northeast-1.amazonaws.com" "https://autoscaling-plans.ap-northeast-2.amazonaws.com" "https://autoscaling-plans.ap-northeast-3.amazonaws.com" "https://autoscaling-plans.ap-southeast-1.amazonaws.com" "https://autoscaling-plans.ap-southeast-2.amazonaws.com" "https://autoscaling-plans.ap-east-1.amazonaws.com" "https://autoscaling-plans.ap-south-1.amazonaws.com" "https://autoscaling-plans.sa-east-1.amazonaws.com" "https://autoscaling-plans.me-south-1.amazonaws.com" "http://autoscaling-plans.cn-north-1.amazonaws.com.cn" "http://autoscaling-plans.cn-northwest-1.amazonaws.com.cn" "https://autoscaling-plans.cn-north-1.amazonaws.com.cn" "https://autoscaling-plans.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def X-Amz-Target-completer [] { ["AnyScaleScalingPlannerFrontendService.CreateScalingPlan"] }
def X-Amz-Target-completer-1 [] { ["AnyScaleScalingPlannerFrontendService.DeleteScalingPlan"] }
def X-Amz-Target-completer-2 [] { ["AnyScaleScalingPlannerFrontendService.DescribeScalingPlanResources"] }
def X-Amz-Target-completer-3 [] { ["AnyScaleScalingPlannerFrontendService.DescribeScalingPlans"] }
def X-Amz-Target-completer-4 [] { ["AnyScaleScalingPlannerFrontendService.GetScalingPlanResourceForecastData"] }
def X-Amz-Target-completer-5 [] { ["AnyScaleScalingPlannerFrontendService.UpdateScalingPlan"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-any-scale-scaling-planner-frontend-service-create-scaling-plan CreateScalingPlan" } } | get name | first)
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

# Creates a scaling plan. 
#
# POST /#X-Amz-Target=AnyScaleScalingPlannerFrontendService.CreateScalingPlan
# operationId: CreateScalingPlan
export def "x-amz-target-any-scale-scaling-planner-frontend-service-create-scaling-plan CreateScalingPlan" [
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
  --X-Amz-Target: string@X-Amz-Target-completer
  ScalingPlanName: any
  ApplicationSource: any
  ScalingInstructions: any
]: any -> record<ScalingPlanVersion: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.CreateScalingPlan")
  let body = {ScalingPlanName: $ScalingPlanName, ApplicationSource: $ApplicationSource, ScalingInstructions: $ScalingInstructions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes the specified scaling plan.</p> <p>Deleting a scaling plan deletes the underlying <a>ScalingInstruction</a> for all of the scalable resources that are covered by the plan.</p> <p>If the plan has launched resources or has scaling activities in progress, you must delete those resources separately.</p>
#
# POST /#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DeleteScalingPlan
# operationId: DeleteScalingPlan
export def "x-amz-target-any-scale-scaling-planner-frontend-service-delete-scaling-plan DeleteScalingPlan" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-1
  ScalingPlanName: any
  ScalingPlanVersion: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DeleteScalingPlan")
  let body = {ScalingPlanName: $ScalingPlanName, ScalingPlanVersion: $ScalingPlanVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the scalable resources in the specified scaling plan.
#
# POST /#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DescribeScalingPlanResources
# operationId: DescribeScalingPlanResources
export def "x-amz-target-any-scale-scaling-planner-frontend-service-describe-scaling-plan-resources DescribeScalingPlanResources" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-2
  ScalingPlanName: any
  ScalingPlanVersion: any
  --MaxResults: any
  --NextToken: any
]: any -> record<ScalingPlanResources: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DescribeScalingPlanResources")
  let body = {ScalingPlanName: $ScalingPlanName, ScalingPlanVersion: $ScalingPlanVersion, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes one or more of your scaling plans.
#
# POST /#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DescribeScalingPlans
# operationId: DescribeScalingPlans
export def "x-amz-target-any-scale-scaling-planner-frontend-service-describe-scaling-plans DescribeScalingPlans" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-3
  --ScalingPlanNames: any
  --ScalingPlanVersion: any
  --ApplicationSources: any
  --MaxResults: any
  --NextToken: any
]: any -> record<ScalingPlans: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DescribeScalingPlans")
  let body = {ScalingPlanNames: $ScalingPlanNames, ScalingPlanVersion: $ScalingPlanVersion, ApplicationSources: $ApplicationSources, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Retrieves the forecast data for a scalable resource.</p> <p>Capacity forecasts are represented as predicted values, or data points, that are calculated using historical data points from a specified CloudWatch load metric. Data points are available for up to 56 days. </p>
#
# POST /#X-Amz-Target=AnyScaleScalingPlannerFrontendService.GetScalingPlanResourceForecastData
# operationId: GetScalingPlanResourceForecastData
export def "x-amz-target-any-scale-scaling-planner-frontend-service-get-scaling-plan-resource-forecast-data GetScalingPlanResourceForecastData" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-4
  ScalingPlanName: any
  ScalingPlanVersion: any
  ServiceNamespace: any
  ResourceId: any
  ScalableDimension: any
  ForecastDataType: any
  StartTime: any
  EndTime: any
]: any -> record<Datapoints: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.GetScalingPlanResourceForecastData")
  let body = {ScalingPlanName: $ScalingPlanName, ScalingPlanVersion: $ScalingPlanVersion, ServiceNamespace: $ServiceNamespace, ResourceId: $ResourceId, ScalableDimension: $ScalableDimension, ForecastDataType: $ForecastDataType, StartTime: $StartTime, EndTime: $EndTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Updates the specified scaling plan.</p> <p>You cannot update a scaling plan if it is in the process of being created, updated, or deleted.</p>
#
# POST /#X-Amz-Target=AnyScaleScalingPlannerFrontendService.UpdateScalingPlan
# operationId: UpdateScalingPlan
export def "x-amz-target-any-scale-scaling-planner-frontend-service-update-scaling-plan UpdateScalingPlan" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-5
  ScalingPlanName: any
  ScalingPlanVersion: any
  --ApplicationSource: any
  --ScalingInstructions: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.UpdateScalingPlan")
  let body = {ScalingPlanName: $ScalingPlanName, ScalingPlanVersion: $ScalingPlanVersion, ApplicationSource: $ApplicationSource, ScalingInstructions: $ScalingInstructions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
