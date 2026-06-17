# Auto-generated client for AWS Cost Explorer Service v2017-10-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/ce/2017-10-25/openapi.json
# Auth: --token flag or $env.AWS_COST_EXPLORER_SERVICE_TOKEN

const BASE_URL = "http://ce.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_COST_EXPLORER_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://ce.us-east-1.amazonaws.com" "http://ce.us-east-2.amazonaws.com" "http://ce.us-west-1.amazonaws.com" "http://ce.us-west-2.amazonaws.com" "http://ce.us-gov-west-1.amazonaws.com" "http://ce.us-gov-east-1.amazonaws.com" "http://ce.ca-central-1.amazonaws.com" "http://ce.eu-north-1.amazonaws.com" "http://ce.eu-west-1.amazonaws.com" "http://ce.eu-west-2.amazonaws.com" "http://ce.eu-west-3.amazonaws.com" "http://ce.eu-central-1.amazonaws.com" "http://ce.eu-south-1.amazonaws.com" "http://ce.af-south-1.amazonaws.com" "http://ce.ap-northeast-1.amazonaws.com" "http://ce.ap-northeast-2.amazonaws.com" "http://ce.ap-northeast-3.amazonaws.com" "http://ce.ap-southeast-1.amazonaws.com" "http://ce.ap-southeast-2.amazonaws.com" "http://ce.ap-east-1.amazonaws.com" "http://ce.ap-south-1.amazonaws.com" "http://ce.sa-east-1.amazonaws.com" "http://ce.me-south-1.amazonaws.com" "https://ce.us-east-1.amazonaws.com" "https://ce.us-east-2.amazonaws.com" "https://ce.us-west-1.amazonaws.com" "https://ce.us-west-2.amazonaws.com" "https://ce.us-gov-west-1.amazonaws.com" "https://ce.us-gov-east-1.amazonaws.com" "https://ce.ca-central-1.amazonaws.com" "https://ce.eu-north-1.amazonaws.com" "https://ce.eu-west-1.amazonaws.com" "https://ce.eu-west-2.amazonaws.com" "https://ce.eu-west-3.amazonaws.com" "https://ce.eu-central-1.amazonaws.com" "https://ce.eu-south-1.amazonaws.com" "https://ce.af-south-1.amazonaws.com" "https://ce.ap-northeast-1.amazonaws.com" "https://ce.ap-northeast-2.amazonaws.com" "https://ce.ap-northeast-3.amazonaws.com" "https://ce.ap-southeast-1.amazonaws.com" "https://ce.ap-southeast-2.amazonaws.com" "https://ce.ap-east-1.amazonaws.com" "https://ce.ap-south-1.amazonaws.com" "https://ce.sa-east-1.amazonaws.com" "https://ce.me-south-1.amazonaws.com" "http://ce.cn-north-1.amazonaws.com.cn" "http://ce.cn-northwest-1.amazonaws.com.cn" "https://ce.cn-north-1.amazonaws.com.cn" "https://ce.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSInsightsIndexService.CreateAnomalyMonitor"] }
def x-amz-target-completer-1 [] { ["AWSInsightsIndexService.CreateAnomalySubscription"] }
def rule-version-completer [] { ["CostCategoryExpression.v1"] }
def x-amz-target-completer-2 [] { ["AWSInsightsIndexService.CreateCostCategoryDefinition"] }
def x-amz-target-completer-3 [] { ["AWSInsightsIndexService.DeleteAnomalyMonitor"] }
def x-amz-target-completer-4 [] { ["AWSInsightsIndexService.DeleteAnomalySubscription"] }
def x-amz-target-completer-5 [] { ["AWSInsightsIndexService.DeleteCostCategoryDefinition"] }
def x-amz-target-completer-6 [] { ["AWSInsightsIndexService.DescribeCostCategoryDefinition"] }
def x-amz-target-completer-7 [] { ["AWSInsightsIndexService.GetAnomalies"] }
def x-amz-target-completer-8 [] { ["AWSInsightsIndexService.GetAnomalyMonitors"] }
def x-amz-target-completer-9 [] { ["AWSInsightsIndexService.GetAnomalySubscriptions"] }
def x-amz-target-completer-10 [] { ["AWSInsightsIndexService.GetCostAndUsage"] }
def x-amz-target-completer-11 [] { ["AWSInsightsIndexService.GetCostAndUsageWithResources"] }
def x-amz-target-completer-12 [] { ["AWSInsightsIndexService.GetCostCategories"] }
def x-amz-target-completer-13 [] { ["AWSInsightsIndexService.GetCostForecast"] }
def x-amz-target-completer-14 [] { ["AWSInsightsIndexService.GetDimensionValues"] }
def x-amz-target-completer-15 [] { ["AWSInsightsIndexService.GetReservationCoverage"] }
def x-amz-target-completer-16 [] { ["AWSInsightsIndexService.GetReservationPurchaseRecommendation"] }
def x-amz-target-completer-17 [] { ["AWSInsightsIndexService.GetReservationUtilization"] }
def x-amz-target-completer-18 [] { ["AWSInsightsIndexService.GetRightsizingRecommendation"] }
def x-amz-target-completer-19 [] { ["AWSInsightsIndexService.GetSavingsPlansCoverage"] }
def x-amz-target-completer-20 [] { ["AWSInsightsIndexService.GetSavingsPlansPurchaseRecommendation"] }
def x-amz-target-completer-21 [] { ["AWSInsightsIndexService.GetSavingsPlansUtilization"] }
def x-amz-target-completer-22 [] { ["AWSInsightsIndexService.GetSavingsPlansUtilizationDetails"] }
def x-amz-target-completer-23 [] { ["AWSInsightsIndexService.GetTags"] }
def x-amz-target-completer-24 [] { ["AWSInsightsIndexService.GetUsageForecast"] }
def x-amz-target-completer-25 [] { ["AWSInsightsIndexService.ListCostAllocationTags"] }
def x-amz-target-completer-26 [] { ["AWSInsightsIndexService.ListCostCategoryDefinitions"] }
def x-amz-target-completer-27 [] { ["AWSInsightsIndexService.ListSavingsPlansPurchaseRecommendationGeneration"] }
def x-amz-target-completer-28 [] { ["AWSInsightsIndexService.ListTagsForResource"] }
def x-amz-target-completer-29 [] { ["AWSInsightsIndexService.ProvideAnomalyFeedback"] }
def x-amz-target-completer-30 [] { ["AWSInsightsIndexService.StartSavingsPlansPurchaseRecommendationGeneration"] }
def x-amz-target-completer-31 [] { ["AWSInsightsIndexService.TagResource"] }
def x-amz-target-completer-32 [] { ["AWSInsightsIndexService.UntagResource"] }
def x-amz-target-completer-33 [] { ["AWSInsightsIndexService.UpdateAnomalyMonitor"] }
def x-amz-target-completer-34 [] { ["AWSInsightsIndexService.UpdateAnomalySubscription"] }
def x-amz-target-completer-35 [] { ["AWSInsightsIndexService.UpdateCostAllocationTagsStatus"] }
def x-amz-target-completer-36 [] { ["AWSInsightsIndexService.UpdateCostCategoryDefinition"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-aws-insights-index-service-create-anomaly-monitor create" } } | get name | first)
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

# Creates a new cost anomaly detection monitor with the requested type and monitor specification. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.CreateAnomalyMonitor
# operationId: CreateAnomalyMonitor
export def "x-amz-target-aws-insights-index-service-create-anomaly-monitor create" [
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
  anomaly_monitor: any
  --resource-tags: any
]: any -> record<MonitorArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.CreateAnomalyMonitor")
  let body = {"AnomalyMonitor": $anomaly_monitor, "ResourceTags": $resource_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds an alert subscription to a cost anomaly detection monitor. You can use each subscription to define subscribers with email or SNS notifications. Email subscribers can set an absolute or percentage threshold and a time frequency for receiving notifications. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.CreateAnomalySubscription
# operationId: CreateAnomalySubscription
export def "x-amz-target-aws-insights-index-service-create-anomaly-subscription create" [
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
  anomaly_subscription: any
  --resource-tags: any
]: any -> record<SubscriptionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.CreateAnomalySubscription")
  let body = {"AnomalySubscription": $anomaly_subscription, "ResourceTags": $resource_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new Cost Category with the requested name and rules.
#
# POST /#X-Amz-Target=AWSInsightsIndexService.CreateCostCategoryDefinition
# operationId: CreateCostCategoryDefinition
export def "x-amz-target-aws-insights-index-service-create-cost-category-definition create" [
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
  name: string # The unique name of the Cost Category.
  --effective-start: any
  rule_version: string@rule-version-completer # The rule schema version in this particular Cost Category.
  rules: any
  --default-value: string # The default value for the cost category.
  --split-charge-rules: any
  --resource-tags: any
]: any -> record<CostCategoryArn: record, EffectiveStart: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.CreateCostCategoryDefinition")
  let body = {"Name": $name, "EffectiveStart": $effective_start, "RuleVersion": $rule_version, "Rules": $rules, "DefaultValue": $default_value, "SplitChargeRules": $split_charge_rules, "ResourceTags": $resource_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a cost anomaly monitor. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.DeleteAnomalyMonitor
# operationId: DeleteAnomalyMonitor
export def "x-amz-target-aws-insights-index-service-delete-anomaly-monitor delete" [
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
  monitor_arn: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.DeleteAnomalyMonitor")
  let body = {"MonitorArn": $monitor_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a cost anomaly subscription. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.DeleteAnomalySubscription
# operationId: DeleteAnomalySubscription
export def "x-amz-target-aws-insights-index-service-delete-anomaly-subscription delete" [
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
  subscription_arn: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.DeleteAnomalySubscription")
  let body = {"SubscriptionArn": $subscription_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a Cost Category. Expenses from this month going forward will no longer be categorized with this Cost Category.
#
# POST /#X-Amz-Target=AWSInsightsIndexService.DeleteCostCategoryDefinition
# operationId: DeleteCostCategoryDefinition
export def "x-amz-target-aws-insights-index-service-delete-cost-category-definition delete" [
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
  cost_category_arn: any
]: any -> record<CostCategoryArn: record, EffectiveEnd: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.DeleteCostCategoryDefinition")
  let body = {"CostCategoryArn": $cost_category_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns the name, Amazon Resource Name (ARN), rules, definition, and effective dates of a Cost Category that's defined in the account.</p> <p>You have the option to use <code>EffectiveOn</code> to return a Cost Category that's active on a specific date. If there's no <code>EffectiveOn</code> specified, you see a Cost Category that's effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. </p>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.DescribeCostCategoryDefinition
# operationId: DescribeCostCategoryDefinition
export def "x-amz-target-aws-insights-index-service-describe-cost-category-definition post" [
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
  cost_category_arn: any
  --effective-on: any
]: any -> record<CostCategory: record<CostCategoryArn: record, EffectiveStart: record, EffectiveEnd: record, Name: string, RuleVersion: string, Rules: record, SplitChargeRules: record, ProcessingStatus: record, DefaultValue: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.DescribeCostCategoryDefinition")
  let body = {"CostCategoryArn": $cost_category_arn, "EffectiveOn": $effective_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves all of the cost anomalies detected on your account during the time period that's specified by the <code>DateInterval</code> object. Anomalies are available for up to 90 days.
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetAnomalies
# operationId: GetAnomalies
export def "x-amz-target-aws-insights-index-service-get-anomalies get" [
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
  --monitor-arn: any
  date_interval: any
  --feedback: any
  --total-impact: any
  --next-page-token: any
  --max-results: any
]: any -> record<Anomalies: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetAnomalies")
  let body = {"MonitorArn": $monitor_arn, "DateInterval": $date_interval, "Feedback": $feedback, "TotalImpact": $total_impact, "NextPageToken": $next_page_token, "MaxResults": $max_results} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the cost anomaly monitor definitions for your account. You can filter using a list of cost anomaly monitor Amazon Resource Names (ARNs). 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetAnomalyMonitors
# operationId: GetAnomalyMonitors
export def "x-amz-target-aws-insights-index-service-get-anomaly-monitors get" [
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
  --monitor-arn-list: any
  --next-page-token: any
  --max-results: any
]: any -> record<AnomalyMonitors: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetAnomalyMonitors")
  let body = {"MonitorArnList": $monitor_arn_list, "NextPageToken": $next_page_token, "MaxResults": $max_results} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the cost anomaly subscription objects for your account. You can filter using a list of cost anomaly monitor Amazon Resource Names (ARNs). 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetAnomalySubscriptions
# operationId: GetAnomalySubscriptions
export def "x-amz-target-aws-insights-index-service-get-anomaly-subscriptions get" [
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
  --subscription-arn-list: any
  --monitor-arn: any
  --next-page-token: any
  --max-results: any
]: any -> record<AnomalySubscriptions: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetAnomalySubscriptions")
  let body = {"SubscriptionArnList": $subscription_arn_list, "MonitorArn": $monitor_arn, "NextPageToken": $next_page_token, "MaxResults": $max_results} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Retrieves cost and usage metrics for your account. You can specify which cost and usage-related metric that you want the request to return. For example, you can specify <code>BlendedCosts</code> or <code>UsageQuantity</code>. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Management account in an organization in Organizations have access to all member accounts.</p> <p>For information about filter limitations, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-limits.html">Quotas and restrictions</a> in the <i>Billing and Cost Management User Guide</i>.</p>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetCostAndUsage
# operationId: GetCostAndUsage
export def "x-amz-target-aws-insights-index-service-get-cost-and-usage get" [
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
  time_period: any
  granularity: any
  --filter: any
  metrics: any
  --group-by: any
  --next-page-token: any
]: any -> record<NextPageToken: record, GroupDefinitions: record, ResultsByTime: record, DimensionValueAttributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetCostAndUsage")
  let body = {"TimePeriod": $time_period, "Granularity": $granularity, "Filter": $filter, "Metrics": $metrics, "GroupBy": $group_by, "NextPageToken": $next_page_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Retrieves cost and usage metrics with resources for your account. You can specify which cost and usage-related metric, such as <code>BlendedCosts</code> or <code>UsageQuantity</code>, that you want the request to return. You can also filter and group your data by various dimensions, such as <code>SERVICE</code> or <code>AZ</code>, in a specific time range. For a complete list of valid dimensions, see the <a href="https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html">GetDimensionValues</a> operation. Management account in an organization in Organizations have access to all member accounts. This API is currently available for the Amazon Elastic Compute Cloud – Compute service only.</p> <note> <p>This is an opt-in only feature. You can enable this feature from the Cost Explorer Settings page. For information about how to access the Settings page, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-access.html">Controlling Access for Cost Explorer</a> in the <i>Billing and Cost Management User Guide</i>.</p> </note>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetCostAndUsageWithResources
# operationId: GetCostAndUsageWithResources
export def "x-amz-target-aws-insights-index-service-get-cost-and-usage-with-resources get" [
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
  time_period: any
  granularity: any
  filter: any
  --metrics: any
  --group-by: any
  --next-page-token: any
]: any -> record<NextPageToken: record, GroupDefinitions: record, ResultsByTime: record, DimensionValueAttributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetCostAndUsageWithResources")
  let body = {"TimePeriod": $time_period, "Granularity": $granularity, "Filter": $filter, "Metrics": $metrics, "GroupBy": $group_by, "NextPageToken": $next_page_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Retrieves an array of Cost Category names and values incurred cost.</p> <note> <p>If some Cost Category names and values are not associated with any cost, they will not be returned by this API.</p> </note>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetCostCategories
# operationId: GetCostCategories
# --TimePeriod shape: {Start: any, End: any}
# --Filter shape: {Or?: any, And?: any, Not?: any, Dimensions?: any, Tags?: any, CostCategories?: any}
export def "x-amz-target-aws-insights-index-service-get-cost-categories get" [
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
  --search-string: any
  time_period: record # The time period of the request.  — shape: {Start: any, End: any}
  --cost-category-name: string # The unique name of the Cost Category.
  --filter: record # <p>Use <code>Expression</code> to filter in various Cost Explorer APIs.</p> <p>Not all <code>Expression</code> types are supported in each API. Refer to the documentation for each specific API to see what is supported.</p> <p>There are two patterns:</p> <ul> <li> <p>Simple dimension values.</p> <ul> <li> <p>There are three types of simple dimension values: <code>CostCategories</code>, <code>Tags</code>, and <code>Dimensions</code>.</p> <ul> <li> <p>Specify the <code>CostCategories</code> field to define a filter that acts on Cost Categories.</p> </li> <li> <p>Specify the <code>Tags</code> field to define a filter that acts on Cost Allocation Tags.</p> </li> <li> <p>Specify the <code>Dimensions</code> field to define a filter that acts on the <a href="https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html"> <code>DimensionValues</code> </a>.</p> </li> </ul> </li> <li> <p>For each filter type, you can set the dimension name and values for the filters that you plan to use.</p> <ul> <li> <p>For example, you can filter for <code>REGION==us-east-1 OR REGION==us-west-1</code>. For <code>GetRightsizingRecommendation</code>, the Region is a full name (for example, <code>REGION==US East (N. Virginia)</code>.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } }</code> </p> </li> <li> <p>As shown in the previous example, lists of dimension values are combined with <code>OR</code> when applying the filter.</p> </li> </ul> </li> <li> <p>You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported.</p> <ul> <li> <p>For example, you can filter for linked account names that start with “a”.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } }</code> </p> </li> </ul> </li> </ul> </li> <li> <p>Compound <code>Expression</code> types with logical operations.</p> <ul> <li> <p>You can use multiple <code>Expression</code> types and the logical operators <code>AND/OR/NOT</code> to create a list of one or more <code>Expression</code> objects. By doing this, you can filter by more advanced options.</p> </li> <li> <p>For example, you can filter by <code>((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer)</code>.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } </code> </p> </li> </ul> <note> <p>Because each <code>Expression</code> can have only one operator, the service returns an error if more than one is specified. The following example shows an <code>Expression</code> object that creates an error: <code> { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } </code> </p> <p>The following is an example of the corresponding error message: <code>"Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories"</code> </p> </note> </li> </ul> <note> <p>For the <code>GetRightsizingRecommendation</code> action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to <code>LINKED_ACCOUNT</code>, <code>REGION</code>, or <code>RIGHTSIZING_TYPE</code>.</p> <p>For the <code>GetReservationPurchaseRecommendation</code> action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to <code>LINKED_ACCOUNT</code>.</p> </note> — shape: {Or?: any, And?: any, Not?: any, Dimensions?: any, Tags?: any, CostCategories?: any}
  --sort-by: any
  --max-results: any
  --next-page-token: any
]: any -> record<NextPageToken: record, CostCategoryNames: record, CostCategoryValues: record, ReturnSize: record, TotalSize: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetCostCategories")
  let body = {"SearchString": $search_string, "TimePeriod": $time_period, "CostCategoryName": $cost_category_name, "Filter": $filter, "SortBy": $sort_by, "MaxResults": $max_results, "NextPageToken": $next_page_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a forecast for how much Amazon Web Services predicts that you will spend over the forecast time period that you select, based on your past costs. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetCostForecast
# operationId: GetCostForecast
export def "x-amz-target-aws-insights-index-service-get-cost-forecast get" [
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
  time_period: any
  metric: any
  granularity: any
  --filter: any
  --prediction-interval-level: any
]: any -> record<Total: record<Amount: record, Unit: record>, ForecastResultsByTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetCostForecast")
  let body = {"TimePeriod": $time_period, "Metric": $metric, "Granularity": $granularity, "Filter": $filter, "PredictionIntervalLevel": $prediction_interval_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves all available filter values for a specified filter over a period of time. You can search the dimension values for an arbitrary string. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetDimensionValues
# operationId: GetDimensionValues
# --Filter shape: {Or?: any, And?: any, Not?: any, Dimensions?: any, Tags?: any, CostCategories?: any}
export def "x-amz-target-aws-insights-index-service-get-dimension-values get" [
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
  --search-string: any
  time_period: any
  dimension: any
  --context: any
  --filter: record # <p>Use <code>Expression</code> to filter in various Cost Explorer APIs.</p> <p>Not all <code>Expression</code> types are supported in each API. Refer to the documentation for each specific API to see what is supported.</p> <p>There are two patterns:</p> <ul> <li> <p>Simple dimension values.</p> <ul> <li> <p>There are three types of simple dimension values: <code>CostCategories</code>, <code>Tags</code>, and <code>Dimensions</code>.</p> <ul> <li> <p>Specify the <code>CostCategories</code> field to define a filter that acts on Cost Categories.</p> </li> <li> <p>Specify the <code>Tags</code> field to define a filter that acts on Cost Allocation Tags.</p> </li> <li> <p>Specify the <code>Dimensions</code> field to define a filter that acts on the <a href="https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html"> <code>DimensionValues</code> </a>.</p> </li> </ul> </li> <li> <p>For each filter type, you can set the dimension name and values for the filters that you plan to use.</p> <ul> <li> <p>For example, you can filter for <code>REGION==us-east-1 OR REGION==us-west-1</code>. For <code>GetRightsizingRecommendation</code>, the Region is a full name (for example, <code>REGION==US East (N. Virginia)</code>.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } }</code> </p> </li> <li> <p>As shown in the previous example, lists of dimension values are combined with <code>OR</code> when applying the filter.</p> </li> </ul> </li> <li> <p>You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported.</p> <ul> <li> <p>For example, you can filter for linked account names that start with “a”.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } }</code> </p> </li> </ul> </li> </ul> </li> <li> <p>Compound <code>Expression</code> types with logical operations.</p> <ul> <li> <p>You can use multiple <code>Expression</code> types and the logical operators <code>AND/OR/NOT</code> to create a list of one or more <code>Expression</code> objects. By doing this, you can filter by more advanced options.</p> </li> <li> <p>For example, you can filter by <code>((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer)</code>.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } </code> </p> </li> </ul> <note> <p>Because each <code>Expression</code> can have only one operator, the service returns an error if more than one is specified. The following example shows an <code>Expression</code> object that creates an error: <code> { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } </code> </p> <p>The following is an example of the corresponding error message: <code>"Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories"</code> </p> </note> </li> </ul> <note> <p>For the <code>GetRightsizingRecommendation</code> action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to <code>LINKED_ACCOUNT</code>, <code>REGION</code>, or <code>RIGHTSIZING_TYPE</code>.</p> <p>For the <code>GetReservationPurchaseRecommendation</code> action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to <code>LINKED_ACCOUNT</code>.</p> </note> — shape: {Or?: any, And?: any, Not?: any, Dimensions?: any, Tags?: any, CostCategories?: any}
  --sort-by: any
  --max-results: any
  --next-page-token: any
]: any -> record<DimensionValues: record, ReturnSize: record, TotalSize: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetDimensionValues")
  let body = {"SearchString": $search_string, "TimePeriod": $time_period, "Dimension": $dimension, "Context": $context, "Filter": $filter, "SortBy": $sort_by, "MaxResults": $max_results, "NextPageToken": $next_page_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Retrieves the reservation coverage for your account, which you can use to see how much of your Amazon Elastic Compute Cloud, Amazon ElastiCache, Amazon Relational Database Service, or Amazon Redshift usage is covered by a reservation. An organization's management account can see the coverage of the associated member accounts. This supports dimensions, Cost Categories, and nested expressions. For any time period, you can filter data about reservation usage by the following dimensions:</p> <ul> <li> <p>AZ</p> </li> <li> <p>CACHE_ENGINE</p> </li> <li> <p>DATABASE_ENGINE</p> </li> <li> <p>DEPLOYMENT_OPTION</p> </li> <li> <p>INSTANCE_TYPE</p> </li> <li> <p>LINKED_ACCOUNT</p> </li> <li> <p>OPERATING_SYSTEM</p> </li> <li> <p>PLATFORM</p> </li> <li> <p>REGION</p> </li> <li> <p>SERVICE</p> </li> <li> <p>TAG</p> </li> <li> <p>TENANCY</p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation. </p>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetReservationCoverage
# operationId: GetReservationCoverage
export def "x-amz-target-aws-insights-index-service-get-reservation-coverage get" [
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
  time_period: any
  --group-by: any
  --granularity: any
  --filter: any
  --metrics: any
  --next-page-token: any
  --sort-by: any
  --max-results: any
]: any -> record<CoveragesByTime: record, Total: record<CoverageHours: record<OnDemandHours: record, ReservedHours: record, TotalRunningHours: record, CoverageHoursPercentage: record>, CoverageNormalizedUnits: record<OnDemandNormalizedUnits: record, ReservedNormalizedUnits: record, TotalRunningNormalizedUnits: record, CoverageNormalizedUnitsPercentage: record>, CoverageCost: record<OnDemandCost: record>>, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetReservationCoverage")
  let body = {"TimePeriod": $time_period, "GroupBy": $group_by, "Granularity": $granularity, "Filter": $filter, "Metrics": $metrics, "NextPageToken": $next_page_token, "SortBy": $sort_by, "MaxResults": $max_results} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Gets recommendations for reservation purchases. These recommendations might help you to reduce your costs. Reservations provide a discounted hourly rate (up to 75%) compared to On-Demand pricing.</p> <p>Amazon Web Services generates your recommendations by identifying your On-Demand usage during a specific time period and collecting your usage into categories that are eligible for a reservation. After Amazon Web Services has these categories, it simulates every combination of reservations in each category of usage to identify the best number of each type of Reserved Instance (RI) to purchase to maximize your estimated savings. </p> <p>For example, Amazon Web Services automatically aggregates your Amazon EC2 Linux, shared tenancy, and c4 family usage in the US West (Oregon) Region and recommends that you buy size-flexible regional reservations to apply to the c4 family usage. Amazon Web Services recommends the smallest size instance in an instance family. This makes it easier to purchase a size-flexible Reserved Instance (RI). Amazon Web Services also shows the equal number of normalized units. This way, you can purchase any instance size that you want. For this example, your RI recommendation is for <code>c4.large</code> because that is the smallest size instance in the c4 instance family.</p>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetReservationPurchaseRecommendation
# operationId: GetReservationPurchaseRecommendation
# --Filter shape: {Or?: any, And?: any, Not?: any, Dimensions?: any, Tags?: any, CostCategories?: any}
export def "x-amz-target-aws-insights-index-service-get-reservation-purchase-recommendation get" [
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
  --account-id: any
  service: any
  --filter: record # <p>Use <code>Expression</code> to filter in various Cost Explorer APIs.</p> <p>Not all <code>Expression</code> types are supported in each API. Refer to the documentation for each specific API to see what is supported.</p> <p>There are two patterns:</p> <ul> <li> <p>Simple dimension values.</p> <ul> <li> <p>There are three types of simple dimension values: <code>CostCategories</code>, <code>Tags</code>, and <code>Dimensions</code>.</p> <ul> <li> <p>Specify the <code>CostCategories</code> field to define a filter that acts on Cost Categories.</p> </li> <li> <p>Specify the <code>Tags</code> field to define a filter that acts on Cost Allocation Tags.</p> </li> <li> <p>Specify the <code>Dimensions</code> field to define a filter that acts on the <a href="https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html"> <code>DimensionValues</code> </a>.</p> </li> </ul> </li> <li> <p>For each filter type, you can set the dimension name and values for the filters that you plan to use.</p> <ul> <li> <p>For example, you can filter for <code>REGION==us-east-1 OR REGION==us-west-1</code>. For <code>GetRightsizingRecommendation</code>, the Region is a full name (for example, <code>REGION==US East (N. Virginia)</code>.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } }</code> </p> </li> <li> <p>As shown in the previous example, lists of dimension values are combined with <code>OR</code> when applying the filter.</p> </li> </ul> </li> <li> <p>You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported.</p> <ul> <li> <p>For example, you can filter for linked account names that start with “a”.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } }</code> </p> </li> </ul> </li> </ul> </li> <li> <p>Compound <code>Expression</code> types with logical operations.</p> <ul> <li> <p>You can use multiple <code>Expression</code> types and the logical operators <code>AND/OR/NOT</code> to create a list of one or more <code>Expression</code> objects. By doing this, you can filter by more advanced options.</p> </li> <li> <p>For example, you can filter by <code>((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer)</code>.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } </code> </p> </li> </ul> <note> <p>Because each <code>Expression</code> can have only one operator, the service returns an error if more than one is specified. The following example shows an <code>Expression</code> object that creates an error: <code> { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } </code> </p> <p>The following is an example of the corresponding error message: <code>"Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories"</code> </p> </note> </li> </ul> <note> <p>For the <code>GetRightsizingRecommendation</code> action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to <code>LINKED_ACCOUNT</code>, <code>REGION</code>, or <code>RIGHTSIZING_TYPE</code>.</p> <p>For the <code>GetReservationPurchaseRecommendation</code> action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to <code>LINKED_ACCOUNT</code>.</p> </note> — shape: {Or?: any, And?: any, Not?: any, Dimensions?: any, Tags?: any, CostCategories?: any}
  --account-scope: any
  --lookback-period-in-days: any
  --term-in-years: any
  --payment-option: any
  --service-specification: any
  --page-size: any
  --next-page-token: any
]: any -> record<Metadata: record<RecommendationId: record, GenerationTimestamp: record>, Recommendations: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetReservationPurchaseRecommendation")
  let body = {"AccountId": $account_id, "Service": $service, "Filter": $filter, "AccountScope": $account_scope, "LookbackPeriodInDays": $lookback_period_in_days, "TermInYears": $term_in_years, "PaymentOption": $payment_option, "ServiceSpecification": $service_specification, "PageSize": $page_size, "NextPageToken": $next_page_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the reservation utilization for your account. Management account in an organization have access to member accounts. You can filter data by dimensions in a time period. You can use <code>GetDimensionValues</code> to determine the possible dimension values. Currently, you can group only by <code>SUBSCRIPTION_ID</code>. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetReservationUtilization
# operationId: GetReservationUtilization
export def "x-amz-target-aws-insights-index-service-get-reservation-utilization get" [
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
  time_period: any
  --group-by: any
  --granularity: any
  --filter: any
  --sort-by: any
  --next-page-token: any
  --max-results: any
]: any -> record<UtilizationsByTime: record, Total: record<UtilizationPercentage: record, UtilizationPercentageInUnits: record, PurchasedHours: record, PurchasedUnits: record, TotalActualHours: record, TotalActualUnits: record, UnusedHours: record, UnusedUnits: record, OnDemandCostOfRIHoursUsed: record, NetRISavings: record, TotalPotentialRISavings: record, AmortizedUpfrontFee: record, AmortizedRecurringFee: record, TotalAmortizedFee: record, RICostForUnusedHours: record, RealizedSavings: record, UnrealizedSavings: record>, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetReservationUtilization")
  let body = {"TimePeriod": $time_period, "GroupBy": $group_by, "Granularity": $granularity, "Filter": $filter, "SortBy": $sort_by, "NextPageToken": $next_page_token, "MaxResults": $max_results} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates recommendations that help you save cost by identifying idle and underutilized Amazon EC2 instances.</p> <p>Recommendations are generated to either downsize or terminate instances, along with providing savings detail and metrics. For more information about calculation and function, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-rightsizing.html">Optimizing Your Cost with Rightsizing Recommendations</a> in the <i>Billing and Cost Management User Guide</i>.</p>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetRightsizingRecommendation
# operationId: GetRightsizingRecommendation
# --Filter shape: {Or?: any, And?: any, Not?: any, Dimensions?: any, Tags?: any, CostCategories?: any}
export def "x-amz-target-aws-insights-index-service-get-rightsizing-recommendation get" [
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
  --filter: record # <p>Use <code>Expression</code> to filter in various Cost Explorer APIs.</p> <p>Not all <code>Expression</code> types are supported in each API. Refer to the documentation for each specific API to see what is supported.</p> <p>There are two patterns:</p> <ul> <li> <p>Simple dimension values.</p> <ul> <li> <p>There are three types of simple dimension values: <code>CostCategories</code>, <code>Tags</code>, and <code>Dimensions</code>.</p> <ul> <li> <p>Specify the <code>CostCategories</code> field to define a filter that acts on Cost Categories.</p> </li> <li> <p>Specify the <code>Tags</code> field to define a filter that acts on Cost Allocation Tags.</p> </li> <li> <p>Specify the <code>Dimensions</code> field to define a filter that acts on the <a href="https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html"> <code>DimensionValues</code> </a>.</p> </li> </ul> </li> <li> <p>For each filter type, you can set the dimension name and values for the filters that you plan to use.</p> <ul> <li> <p>For example, you can filter for <code>REGION==us-east-1 OR REGION==us-west-1</code>. For <code>GetRightsizingRecommendation</code>, the Region is a full name (for example, <code>REGION==US East (N. Virginia)</code>.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } }</code> </p> </li> <li> <p>As shown in the previous example, lists of dimension values are combined with <code>OR</code> when applying the filter.</p> </li> </ul> </li> <li> <p>You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported.</p> <ul> <li> <p>For example, you can filter for linked account names that start with “a”.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } }</code> </p> </li> </ul> </li> </ul> </li> <li> <p>Compound <code>Expression</code> types with logical operations.</p> <ul> <li> <p>You can use multiple <code>Expression</code> types and the logical operators <code>AND/OR/NOT</code> to create a list of one or more <code>Expression</code> objects. By doing this, you can filter by more advanced options.</p> </li> <li> <p>For example, you can filter by <code>((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer)</code>.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } </code> </p> </li> </ul> <note> <p>Because each <code>Expression</code> can have only one operator, the service returns an error if more than one is specified. The following example shows an <code>Expression</code> object that creates an error: <code> { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } </code> </p> <p>The following is an example of the corresponding error message: <code>"Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories"</code> </p> </note> </li> </ul> <note> <p>For the <code>GetRightsizingRecommendation</code> action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to <code>LINKED_ACCOUNT</code>, <code>REGION</code>, or <code>RIGHTSIZING_TYPE</code>.</p> <p>For the <code>GetReservationPurchaseRecommendation</code> action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to <code>LINKED_ACCOUNT</code>.</p> </note> — shape: {Or?: any, And?: any, Not?: any, Dimensions?: any, Tags?: any, CostCategories?: any}
  --configuration: any
  service: any
  --page-size: any
  --next-page-token: any
]: any -> record<Metadata: record<RecommendationId: record, GenerationTimestamp: record, LookbackPeriodInDays: record, AdditionalMetadata: record>, Summary: record<TotalRecommendationCount: record, EstimatedTotalMonthlySavingsAmount: record, SavingsCurrencyCode: record, SavingsPercentage: record>, RightsizingRecommendations: record, NextPageToken: record, Configuration: record<RecommendationTarget: record, BenefitsConsidered: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetRightsizingRecommendation")
  let body = {"Filter": $filter, "Configuration": $configuration, "Service": $service, "PageSize": $page_size, "NextPageToken": $next_page_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Retrieves the Savings Plans covered for your account. This enables you to see how much of your cost is covered by a Savings Plan. An organization’s management account can see the coverage of the associated member accounts. This supports dimensions, Cost Categories, and nested expressions. For any time period, you can filter data for Savings Plans usage with the following dimensions:</p> <ul> <li> <p> <code>LINKED_ACCOUNT</code> </p> </li> <li> <p> <code>REGION</code> </p> </li> <li> <p> <code>SERVICE</code> </p> </li> <li> <p> <code>INSTANCE_FAMILY</code> </p> </li> </ul> <p>To determine valid values for a dimension, use the <code>GetDimensionValues</code> operation.</p>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansCoverage
# operationId: GetSavingsPlansCoverage
export def "x-amz-target-aws-insights-index-service-get-savings-plans-coverage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --x-amz-target: string@x-amz-target-completer-19
  time_period: any
  --group-by: any
  --granularity: any
  --filter: any
  --metrics: any
  --next-token: any
  --max-results: any
  --sort-by: any
]: any -> record<SavingsPlansCoverages: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansCoverage" $qp)
  let body = {"TimePeriod": $time_period, "GroupBy": $group_by, "Granularity": $granularity, "Filter": $filter, "Metrics": $metrics, "NextToken": $next_token, "MaxResults": $max_results, "SortBy": $sort_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the Savings Plans recommendations for your account. First use <code>StartSavingsPlansPurchaseRecommendationGeneration</code> to generate a new set of recommendations, and then use <code>GetSavingsPlansPurchaseRecommendation</code> to retrieve them.
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansPurchaseRecommendation
# operationId: GetSavingsPlansPurchaseRecommendation
export def "x-amz-target-aws-insights-index-service-get-savings-plans-purchase-recommendation get" [
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
  --x-amz-target: string@x-amz-target-completer-20
  savings_plans_type: any
  term_in_years: any
  payment_option: any
  --account-scope: any
  --next-page-token: any
  --page-size: any
  lookback_period_in_days: any
  --filter: any
]: any -> record<Metadata: record<RecommendationId: record, GenerationTimestamp: record, AdditionalMetadata: record>, SavingsPlansPurchaseRecommendation: record<AccountScope: record, SavingsPlansType: record, TermInYears: record, PaymentOption: record, LookbackPeriodInDays: record, SavingsPlansPurchaseRecommendationDetails: record, SavingsPlansPurchaseRecommendationSummary: record<EstimatedROI: record, CurrencyCode: record, EstimatedTotalCost: record, CurrentOnDemandSpend: record, EstimatedSavingsAmount: record, TotalRecommendationCount: record, DailyCommitmentToPurchase: record, HourlyCommitmentToPurchase: record, EstimatedSavingsPercentage: record, EstimatedMonthlySavingsAmount: record, EstimatedOnDemandCostWithCurrentCommitment: record>>, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansPurchaseRecommendation")
  let body = {"SavingsPlansType": $savings_plans_type, "TermInYears": $term_in_years, "PaymentOption": $payment_option, "AccountScope": $account_scope, "NextPageToken": $next_page_token, "PageSize": $page_size, "LookbackPeriodInDays": $lookback_period_in_days, "Filter": $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Retrieves the Savings Plans utilization for your account across date ranges with daily or monthly granularity. Management account in an organization have access to member accounts. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p>You can't group by any dimension values for <code>GetSavingsPlansUtilization</code>.</p> </note>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansUtilization
# operationId: GetSavingsPlansUtilization
export def "x-amz-target-aws-insights-index-service-get-savings-plans-utilization get" [
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
  --x-amz-target: string@x-amz-target-completer-21
  time_period: any
  --granularity: any
  --filter: any
  --sort-by: any
]: any -> record<SavingsPlansUtilizationsByTime: record, Total: record<Utilization: record<TotalCommitment: record, UsedCommitment: record, UnusedCommitment: record, UtilizationPercentage: record>, Savings: record<NetSavings: record, OnDemandCostEquivalent: record>, AmortizedCommitment: record<AmortizedRecurringCommitment: record, AmortizedUpfrontCommitment: record, TotalAmortizedCommitment: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansUtilization")
  let body = {"TimePeriod": $time_period, "Granularity": $granularity, "Filter": $filter, "SortBy": $sort_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Retrieves attribute data along with aggregate utilization and savings data for a given time period. This doesn't support granular or grouped data (daily/monthly) in response. You can't retrieve data by dates in a single response similar to <code>GetSavingsPlanUtilization</code>, but you have the option to make multiple calls to <code>GetSavingsPlanUtilizationDetails</code> by providing individual dates. You can use <code>GetDimensionValues</code> in <code>SAVINGS_PLANS</code> to determine the possible dimension values.</p> <note> <p> <code>GetSavingsPlanUtilizationDetails</code> internally groups data by <code>SavingsPlansArn</code>.</p> </note>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansUtilizationDetails
# operationId: GetSavingsPlansUtilizationDetails
export def "x-amz-target-aws-insights-index-service-get-savings-plans-utilization-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --x-amz-target: string@x-amz-target-completer-22
  time_period: any
  --filter: any
  --data-type: any
  --next-token: any
  --max-results: any
  --sort-by: any
]: any -> record<SavingsPlansUtilizationDetails: record, Total: record<Utilization: record<TotalCommitment: record, UsedCommitment: record, UnusedCommitment: record, UtilizationPercentage: record>, Savings: record<NetSavings: record, OnDemandCostEquivalent: record>, AmortizedCommitment: record<AmortizedRecurringCommitment: record, AmortizedUpfrontCommitment: record, TotalAmortizedCommitment: record>>, TimePeriod: record<Start: record, End: record>, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetSavingsPlansUtilizationDetails" $qp)
  let body = {"TimePeriod": $time_period, "Filter": $filter, "DataType": $data_type, "NextToken": $next_token, "MaxResults": $max_results, "SortBy": $sort_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Queries for available tag keys and tag values for a specified period. You can search the tag values for an arbitrary string. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetTags
# operationId: GetTags
# --Filter shape: {Or?: any, And?: any, Not?: any, Dimensions?: any, Tags?: any, CostCategories?: any}
export def "x-amz-target-aws-insights-index-service-get-tags get" [
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
  --x-amz-target: string@x-amz-target-completer-23
  --search-string: any
  time_period: any
  --tag-key: any
  --filter: record # <p>Use <code>Expression</code> to filter in various Cost Explorer APIs.</p> <p>Not all <code>Expression</code> types are supported in each API. Refer to the documentation for each specific API to see what is supported.</p> <p>There are two patterns:</p> <ul> <li> <p>Simple dimension values.</p> <ul> <li> <p>There are three types of simple dimension values: <code>CostCategories</code>, <code>Tags</code>, and <code>Dimensions</code>.</p> <ul> <li> <p>Specify the <code>CostCategories</code> field to define a filter that acts on Cost Categories.</p> </li> <li> <p>Specify the <code>Tags</code> field to define a filter that acts on Cost Allocation Tags.</p> </li> <li> <p>Specify the <code>Dimensions</code> field to define a filter that acts on the <a href="https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html"> <code>DimensionValues</code> </a>.</p> </li> </ul> </li> <li> <p>For each filter type, you can set the dimension name and values for the filters that you plan to use.</p> <ul> <li> <p>For example, you can filter for <code>REGION==us-east-1 OR REGION==us-west-1</code>. For <code>GetRightsizingRecommendation</code>, the Region is a full name (for example, <code>REGION==US East (N. Virginia)</code>.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } }</code> </p> </li> <li> <p>As shown in the previous example, lists of dimension values are combined with <code>OR</code> when applying the filter.</p> </li> </ul> </li> <li> <p>You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported.</p> <ul> <li> <p>For example, you can filter for linked account names that start with “a”.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } }</code> </p> </li> </ul> </li> </ul> </li> <li> <p>Compound <code>Expression</code> types with logical operations.</p> <ul> <li> <p>You can use multiple <code>Expression</code> types and the logical operators <code>AND/OR/NOT</code> to create a list of one or more <code>Expression</code> objects. By doing this, you can filter by more advanced options.</p> </li> <li> <p>For example, you can filter by <code>((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer)</code>.</p> </li> <li> <p>The corresponding <code>Expression</code> for this example is as follows: <code>{ "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } </code> </p> </li> </ul> <note> <p>Because each <code>Expression</code> can have only one operator, the service returns an error if more than one is specified. The following example shows an <code>Expression</code> object that creates an error: <code> { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } </code> </p> <p>The following is an example of the corresponding error message: <code>"Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories"</code> </p> </note> </li> </ul> <note> <p>For the <code>GetRightsizingRecommendation</code> action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to <code>LINKED_ACCOUNT</code>, <code>REGION</code>, or <code>RIGHTSIZING_TYPE</code>.</p> <p>For the <code>GetReservationPurchaseRecommendation</code> action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to <code>LINKED_ACCOUNT</code>.</p> </note> — shape: {Or?: any, And?: any, Not?: any, Dimensions?: any, Tags?: any, CostCategories?: any}
  --sort-by: any
  --max-results: any
  --next-page-token: any
]: any -> record<NextPageToken: record, Tags: record, ReturnSize: record, TotalSize: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetTags")
  let body = {"SearchString": $search_string, "TimePeriod": $time_period, "TagKey": $tag_key, "Filter": $filter, "SortBy": $sort_by, "MaxResults": $max_results, "NextPageToken": $next_page_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a forecast for how much Amazon Web Services predicts that you will use over the forecast time period that you select, based on your past usage. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.GetUsageForecast
# operationId: GetUsageForecast
export def "x-amz-target-aws-insights-index-service-get-usage-forecast get" [
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
  --x-amz-target: string@x-amz-target-completer-24
  time_period: any
  metric: any
  granularity: any
  --filter: any
  --prediction-interval-level: any
]: any -> record<Total: record<Amount: record, Unit: record>, ForecastResultsByTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.GetUsageForecast")
  let body = {"TimePeriod": $time_period, "Metric": $metric, "Granularity": $granularity, "Filter": $filter, "PredictionIntervalLevel": $prediction_interval_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of cost allocation tags. All inputs in the API are optional and serve as filters. By default, all cost allocation tags are returned. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.ListCostAllocationTags
# operationId: ListCostAllocationTags
export def "x-amz-target-aws-insights-index-service-list-cost-allocation-tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --x-amz-target: string@x-amz-target-completer-25
  --status: any
  --tag-keys: any
  --type: any
  --next-token: any
  --max-results: any
]: any -> record<CostAllocationTags: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.ListCostAllocationTags" $qp)
  let body = {"Status": $status, "TagKeys": $tag_keys, "Type": $type, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the name, Amazon Resource Name (ARN), <code>NumberOfRules</code> and effective dates of all Cost Categories defined in the account. You have the option to use <code>EffectiveOn</code> to return a list of Cost Categories that were active on a specific date. If there is no <code>EffectiveOn</code> specified, you’ll see Cost Categories that are effective on the current date. If Cost Category is still effective, <code>EffectiveEnd</code> is omitted in the response. <code>ListCostCategoryDefinitions</code> supports pagination. The request can have a <code>MaxResults</code> range up to 100.
#
# POST /#X-Amz-Target=AWSInsightsIndexService.ListCostCategoryDefinitions
# operationId: ListCostCategoryDefinitions
export def "x-amz-target-aws-insights-index-service-list-cost-category-definitions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --x-amz-target: string@x-amz-target-completer-26
  --effective-on: any
  --next-token: any
  --max-results: any
]: any -> record<CostCategoryReferences: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.ListCostCategoryDefinitions" $qp)
  let body = {"EffectiveOn": $effective_on, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of your historical recommendation generations within the past 30 days.
#
# POST /#X-Amz-Target=AWSInsightsIndexService.ListSavingsPlansPurchaseRecommendationGeneration
# operationId: ListSavingsPlansPurchaseRecommendationGeneration
export def "x-amz-target-aws-insights-index-service-list-savings-plans-purchase-recommendation-generation list" [
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
  --x-amz-target: string@x-amz-target-completer-27
  --generation-status: any
  --recommendation-ids: any
  --page-size: any
  --next-page-token: any
]: any -> record<GenerationSummaryList: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.ListSavingsPlansPurchaseRecommendationGeneration")
  let body = {"GenerationStatus": $generation_status, "RecommendationIds": $recommendation_ids, "PageSize": $page_size, "NextPageToken": $next_page_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of resource tags associated with the resource specified by the Amazon Resource Name (ARN). 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.ListTagsForResource
# operationId: ListTagsForResource
export def "x-amz-target-aws-insights-index-service-list-tags-for-resource list" [
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
  --x-amz-target: string@x-amz-target-completer-28
  resource_arn: any
]: any -> record<ResourceTags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.ListTagsForResource")
  let body = {"ResourceArn": $resource_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Modifies the feedback property of a given cost anomaly. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.ProvideAnomalyFeedback
# operationId: ProvideAnomalyFeedback
export def "x-amz-target-aws-insights-index-service-provide-anomaly-feedback post" [
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
  --x-amz-target: string@x-amz-target-completer-29
  anomaly_id: any
  feedback: any
]: any -> record<AnomalyId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.ProvideAnomalyFeedback")
  let body = {"AnomalyId": $anomaly_id, "Feedback": $feedback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Requests a Savings Plans recommendation generation. This enables you to calculate a fresh set of Savings Plans recommendations that takes your latest usage data and current Savings Plans inventory into account. You can refresh Savings Plans recommendations up to three times daily for a consolidated billing family.</p> <note> <p> <code>StartSavingsPlansPurchaseRecommendationGeneration</code> has no request syntax because no input parameters are needed to support this operation.</p> </note>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.StartSavingsPlansPurchaseRecommendationGeneration
# operationId: StartSavingsPlansPurchaseRecommendationGeneration
export def "x-amz-target-aws-insights-index-service-start-savings-plans-purchase-recommendation-generation start" [
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
  --x-amz-target: string@x-amz-target-completer-30
  --body: record
]: any -> record<RecommendationId: record, GenerationStartedTime: record, EstimatedCompletionTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.StartSavingsPlansPurchaseRecommendationGeneration")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>An API operation for adding one or more tags (key-value pairs) to a resource.</p> <p>You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value you specify replaces the previous value for that tag.</p> <p>Although the maximum number of array members is 200, user-tag maximum is 50. The remaining are reserved for Amazon Web Services use.</p>
#
# POST /#X-Amz-Target=AWSInsightsIndexService.TagResource
# operationId: TagResource
export def "x-amz-target-aws-insights-index-service-tag-resource tag" [
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
  --x-amz-target: string@x-amz-target-completer-31
  resource_arn: any
  resource_tags: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.TagResource")
  let body = {"ResourceArn": $resource_arn, "ResourceTags": $resource_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes one or more tags from a resource. Specify only tag keys in your request. Don't specify the value. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.UntagResource
# operationId: UntagResource
export def "x-amz-target-aws-insights-index-service-untag-resource untag" [
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
  --x-amz-target: string@x-amz-target-completer-32
  resource_arn: any
  resource_tag_keys: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.UntagResource")
  let body = {"ResourceArn": $resource_arn, "ResourceTagKeys": $resource_tag_keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing cost anomaly monitor. The changes made are applied going forward, and doesn't change anomalies detected in the past. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.UpdateAnomalyMonitor
# operationId: UpdateAnomalyMonitor
export def "x-amz-target-aws-insights-index-service-update-anomaly-monitor update" [
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
  --x-amz-target: string@x-amz-target-completer-33
  monitor_arn: any
  --monitor-name: any
]: any -> record<MonitorArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.UpdateAnomalyMonitor")
  let body = {"MonitorArn": $monitor_arn, "MonitorName": $monitor_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing cost anomaly monitor subscription. 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.UpdateAnomalySubscription
# operationId: UpdateAnomalySubscription
export def "x-amz-target-aws-insights-index-service-update-anomaly-subscription update" [
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
  --x-amz-target: string@x-amz-target-completer-34
  subscription_arn: any
  --threshold: any
  --frequency: any
  --monitor-arn-list: any
  --subscribers: any
  --subscription-name: any
  --threshold-expression: any
]: any -> record<SubscriptionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.UpdateAnomalySubscription")
  let body = {"SubscriptionArn": $subscription_arn, "Threshold": $threshold, "Frequency": $frequency, "MonitorArnList": $monitor_arn_list, "Subscribers": $subscribers, "SubscriptionName": $subscription_name, "ThresholdExpression": $threshold_expression} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates status for cost allocation tags in bulk, with maximum batch size of 20. If the tag status that's updated is the same as the existing tag status, the request doesn't fail. Instead, it doesn't have any effect on the tag status (for example, activating the active tag). 
#
# POST /#X-Amz-Target=AWSInsightsIndexService.UpdateCostAllocationTagsStatus
# operationId: UpdateCostAllocationTagsStatus
export def "x-amz-target-aws-insights-index-service-update-cost-allocation-tags-status update" [
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
  --x-amz-target: string@x-amz-target-completer-35
  cost_allocation_tags_status: any
]: any -> record<Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.UpdateCostAllocationTagsStatus")
  let body = {"CostAllocationTagsStatus": $cost_allocation_tags_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing Cost Category. Changes made to the Cost Category rules will be used to categorize the current month’s expenses and future expenses. This won’t change categorization for the previous months.
#
# POST /#X-Amz-Target=AWSInsightsIndexService.UpdateCostCategoryDefinition
# operationId: UpdateCostCategoryDefinition
export def "x-amz-target-aws-insights-index-service-update-cost-category-definition update" [
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
  --x-amz-target: string@x-amz-target-completer-36
  cost_category_arn: any
  --effective-start: any
  rule_version: string@rule-version-completer # The rule schema version in this particular Cost Category.
  rules: any
  --default-value: string # The default value for the cost category.
  --split-charge-rules: any
]: any -> record<CostCategoryArn: record, EffectiveStart: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSInsightsIndexService.UpdateCostCategoryDefinition")
  let body = {"CostCategoryArn": $cost_category_arn, "EffectiveStart": $effective_start, "RuleVersion": $rule_version, "Rules": $rules, "DefaultValue": $default_value, "SplitChargeRules": $split_charge_rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
