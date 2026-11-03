# Auto-generated client for AWS Cost Explorer Service v2017-10-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/ce/2017-10-25/openapi.json
# Auth: --token flag or $env.AWS_COST_EXPLORER_SERVICE_TOKEN

const BASE_URL = "http://ce.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_COST_EXPLORER_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
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
def feedback-completer [] { ["NO" "PLANNED_ACTIVITY" "YES"] }
def x-amz-target-completer-7 [] { ["AWSInsightsIndexService.GetAnomalies"] }
def x-amz-target-completer-8 [] { ["AWSInsightsIndexService.GetAnomalyMonitors"] }
def x-amz-target-completer-9 [] { ["AWSInsightsIndexService.GetAnomalySubscriptions"] }
def granularity-completer [] { ["DAILY" "HOURLY" "MONTHLY"] }
def x-amz-target-completer-10 [] { ["AWSInsightsIndexService.GetCostAndUsage"] }
def x-amz-target-completer-11 [] { ["AWSInsightsIndexService.GetCostAndUsageWithResources"] }
def x-amz-target-completer-12 [] { ["AWSInsightsIndexService.GetCostCategories"] }
def metric-completer [] { ["AMORTIZED_COST" "BLENDED_COST" "NET_AMORTIZED_COST" "NET_UNBLENDED_COST" "NORMALIZED_USAGE_AMOUNT" "UNBLENDED_COST" "USAGE_QUANTITY"] }
def x-amz-target-completer-13 [] { ["AWSInsightsIndexService.GetCostForecast"] }
def dimension-completer [] { ["AGREEMENT_END_DATE_TIME_AFTER" "AGREEMENT_END_DATE_TIME_BEFORE" "ANOMALY_TOTAL_IMPACT_ABSOLUTE" "ANOMALY_TOTAL_IMPACT_PERCENTAGE" "AZ" "BILLING_ENTITY" "CACHE_ENGINE" "DATABASE_ENGINE" "DEPLOYMENT_OPTION" "INSTANCE_TYPE" "INSTANCE_TYPE_FAMILY" "INVOICING_ENTITY" "LEGAL_ENTITY_NAME" "LINKED_ACCOUNT" "LINKED_ACCOUNT_NAME" "OPERATING_SYSTEM" "OPERATION" "PAYMENT_OPTION" "PLATFORM" "PURCHASE_TYPE" "RECORD_TYPE" "REGION" "RESERVATION_ID" "RESOURCE_ID" "RIGHTSIZING_TYPE" "SAVINGS_PLANS_TYPE" "SAVINGS_PLAN_ARN" "SCOPE" "SERVICE" "SERVICE_CODE" "SUBSCRIPTION_ID" "TENANCY" "USAGE_TYPE" "USAGE_TYPE_GROUP"] }
def context-completer [] { ["COST_AND_USAGE" "RESERVATIONS" "SAVINGS_PLANS"] }
def x-amz-target-completer-14 [] { ["AWSInsightsIndexService.GetDimensionValues"] }
def x-amz-target-completer-15 [] { ["AWSInsightsIndexService.GetReservationCoverage"] }
def account-scope-completer [] { ["LINKED" "PAYER"] }
def lookback-period-in-days-completer [] { ["SEVEN_DAYS" "SIXTY_DAYS" "THIRTY_DAYS"] }
def term-in-years-completer [] { ["ONE_YEAR" "THREE_YEARS"] }
def payment-option-completer [] { ["ALL_UPFRONT" "HEAVY_UTILIZATION" "LIGHT_UTILIZATION" "MEDIUM_UTILIZATION" "NO_UPFRONT" "PARTIAL_UPFRONT"] }
def x-amz-target-completer-16 [] { ["AWSInsightsIndexService.GetReservationPurchaseRecommendation"] }
def x-amz-target-completer-17 [] { ["AWSInsightsIndexService.GetReservationUtilization"] }
def x-amz-target-completer-18 [] { ["AWSInsightsIndexService.GetRightsizingRecommendation"] }
def x-amz-target-completer-19 [] { ["AWSInsightsIndexService.GetSavingsPlansCoverage"] }
def savings-plans-type-completer [] { ["COMPUTE_SP" "EC2_INSTANCE_SP" "SAGEMAKER_SP"] }
def x-amz-target-completer-20 [] { ["AWSInsightsIndexService.GetSavingsPlansPurchaseRecommendation"] }
def x-amz-target-completer-21 [] { ["AWSInsightsIndexService.GetSavingsPlansUtilization"] }
def x-amz-target-completer-22 [] { ["AWSInsightsIndexService.GetSavingsPlansUtilizationDetails"] }
def x-amz-target-completer-23 [] { ["AWSInsightsIndexService.GetTags"] }
def x-amz-target-completer-24 [] { ["AWSInsightsIndexService.GetUsageForecast"] }
def status-completer [] { ["Active" "Inactive"] }
def type-completer [] { ["AWSGenerated" "UserDefined"] }
def x-amz-target-completer-25 [] { ["AWSInsightsIndexService.ListCostAllocationTags"] }
def x-amz-target-completer-26 [] { ["AWSInsightsIndexService.ListCostCategoryDefinitions"] }
def generation-status-completer [] { ["FAILED" "PROCESSING" "SUCCEEDED"] }
def x-amz-target-completer-27 [] { ["AWSInsightsIndexService.ListSavingsPlansPurchaseRecommendationGeneration"] }
def x-amz-target-completer-28 [] { ["AWSInsightsIndexService.ListTagsForResource"] }
def x-amz-target-completer-29 [] { ["AWSInsightsIndexService.ProvideAnomalyFeedback"] }
def x-amz-target-completer-30 [] { ["AWSInsightsIndexService.StartSavingsPlansPurchaseRecommendationGeneration"] }
def x-amz-target-completer-31 [] { ["AWSInsightsIndexService.TagResource"] }
def x-amz-target-completer-32 [] { ["AWSInsightsIndexService.UntagResource"] }
def x-amz-target-completer-33 [] { ["AWSInsightsIndexService.UpdateAnomalyMonitor"] }
def frequency-completer [] { ["DAILY" "IMMEDIATE" "WEEKLY"] }
def x-amz-target-completer-34 [] { ["AWSInsightsIndexService.UpdateAnomalySubscription"] }
def x-amz-target-completer-35 [] { ["AWSInsightsIndexService.UpdateCostAllocationTagsStatus"] }
def x-amz-target-completer-36 [] { ["AWSInsightsIndexService.UpdateCostCategoryDefinition"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "create-anomaly-monitor" } } | get name | first)
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
# POST /
# operationId: CreateAnomalyMonitor
# --AnomalyMonitor shape: {MonitorArn?: string, MonitorName: string, CreationDate?: string, LastUpdatedDate?: string, LastEvaluatedDate?: string, MonitorType: "DIMENSIONAL"|"CUSTOM", MonitorDimension?: "SERVICE", MonitorSpecification?: record, DimensionalValueCount?: int}
# --ResourceTags item shape: {Key: string, Value: string}
export def "create-anomaly-monitor" [
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
  --x-amz-target: string@x-amz-target-completer # required
  anomaly_monitor: record # This object continuously inspects your account's cost data for anomalies. It's based on MonitorType and MonitorSpecification. The content consists of detailed metadata and the current status of the monitor object. — shape: {MonitorArn?: string, MonitorName: string, CreationDate?: string, LastUpdatedDate?: string, LastEvaluatedDate?: string, MonitorType: "DIMENSIONAL"|"CUSTOM", MonitorDimension?: "SERVICE", MonitorSpecification?: record, DimensionalValueCount?: int}
  --resource-tags: list # An optional list of tags to associate with the specified AnomalyMonitor (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_AnomalyMonitor.html). You can use resource tags to control access to your monitor using IAM policies. Each tag consists of a key and a value, and each key must be unique for the resource. The following restrictions apply to resource tags: Although the maximum number of array members is 200, you can assign a maximum of 50 user-tags to one resource. The remaining are reserved for Amazon Web Services use The maximum length of a key is 128 characters The maximum length of a value is 256 characters Keys and values can only contain alphanumeric characters, spaces, and any of the following: _.:/=+@- Keys and values are case sensitive Keys and values are trimmed for any leading or trailing whitespaces Don’t use aws: as a prefix for your keys. This prefix is reserved for Amazon Web Services use — item shape: {Key: string, Value: string}
]: any -> record<MonitorArn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.CreateAnomalyMonitor")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AnomalyMonitor": $anomaly_monitor, "ResourceTags": $resource_tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Adds an alert subscription to a cost anomaly detection monitor. You can use each subscription to define subscribers with email or SNS notifications. Email subscribers can set an absolute or percentage threshold and a time frequency for receiving notifications.
#
# POST /
# operationId: CreateAnomalySubscription
# --AnomalySubscription shape: {SubscriptionArn?: string, AccountId?: string, MonitorArnList: list<string>, Subscribers: list, Threshold?: float, Frequency: "DAILY"|"IMMEDIATE"|"WEEKLY", SubscriptionName: string, ThresholdExpression?: record}
# --ResourceTags item shape: {Key: string, Value: string}
export def "create-anomaly-subscription" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  anomaly_subscription: record # The association between a monitor, threshold, and list of subscribers used to deliver notifications about anomalies detected by a monitor that exceeds a threshold. The content consists of the detailed metadata and the current status of the AnomalySubscription object. — shape: {SubscriptionArn?: string, AccountId?: string, MonitorArnList: list<string>, Subscribers: list, Threshold?: float, Frequency: "DAILY"|"IMMEDIATE"|"WEEKLY", SubscriptionName: string, ThresholdExpression?: record}
  --resource-tags: list # An optional list of tags to associate with the specified AnomalySubscription (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_AnomalySubscription.html). You can use resource tags to control access to your subscription using IAM policies. Each tag consists of a key and a value, and each key must be unique for the resource. The following restrictions apply to resource tags: Although the maximum number of array members is 200, you can assign a maximum of 50 user-tags to one resource. The remaining are reserved for Amazon Web Services use The maximum length of a key is 128 characters The maximum length of a value is 256 characters Keys and values can only contain alphanumeric characters, spaces, and any of the following: _.:/=+@- Keys and values are case sensitive Keys and values are trimmed for any leading or trailing whitespaces Don’t use aws: as a prefix for your keys. This prefix is reserved for Amazon Web Services use — item shape: {Key: string, Value: string}
]: any -> record<SubscriptionArn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.CreateAnomalySubscription")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AnomalySubscription": $anomaly_subscription, "ResourceTags": $resource_tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new Cost Category with the requested name and rules.
#
# POST /
# operationId: CreateCostCategoryDefinition
# --Rules item shape: {Value?: string, Rule?: record, InheritedValue?: record, Type?: "REGULAR"|"INHERITED_VALUE"}
# --SplitChargeRules item shape: {Source: string, Targets: list<string>, Method: "FIXED"|"PROPORTIONAL"|"EVEN", Parameters?: list}
# --ResourceTags item shape: {Key: string, Value: string}
export def "create-cost-category-definition" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  name: string # The unique name of the Cost Category.
  --effective-start: string # The period of time that you want the usage and costs for.
  rule_version: string@rule-version-completer # The rule schema version in this particular Cost Category.
  rules: list # The Cost Category rules used to categorize costs. For more information, see CostCategoryRule (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_CostCategoryRule.html). — item shape: {Value?: string, Rule?: record, InheritedValue?: record, Type?: "REGULAR"|"INHERITED_VALUE"}
  --default-value: string # The default value for the cost category.
  --split-charge-rules: list # The split charge rules used to allocate your charges between your Cost Category values. — item shape: {Source: string, Targets: list<string>, Method: "FIXED"|"PROPORTIONAL"|"EVEN", Parameters?: list}
  --resource-tags: list # An optional list of tags to associate with the specified CostCategory (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_CostCategory.html). You can use resource tags to control access to your cost category using IAM policies. Each tag consists of a key and a value, and each key must be unique for the resource. The following restrictions apply to resource tags: Although the maximum number of array members is 200, you can assign a maximum of 50 user-tags to one resource. The remaining are reserved for Amazon Web Services use The maximum length of a key is 128 characters The maximum length of a value is 256 characters Keys and values can only contain alphanumeric characters, spaces, and any of the following: _.:/=+@- Keys and values are case sensitive Keys and values are trimmed for any leading or trailing whitespaces Don’t use aws: as a prefix for your keys. This prefix is reserved for Amazon Web Services use — item shape: {Key: string, Value: string}
]: any -> record<CostCategoryArn: string, EffectiveStart: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.CreateCostCategoryDefinition")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "EffectiveStart": $effective_start, "RuleVersion": $rule_version, "Rules": $rules, "DefaultValue": $default_value, "SplitChargeRules": $split_charge_rules, "ResourceTags": $resource_tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a cost anomaly monitor.
#
# POST /
# operationId: DeleteAnomalyMonitor
export def "delete-anomaly-monitor" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  monitor_arn: string # The unique identifier of the cost anomaly monitor that you want to delete.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.DeleteAnomalyMonitor")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"MonitorArn": $monitor_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a cost anomaly subscription.
#
# POST /
# operationId: DeleteAnomalySubscription
export def "delete-anomaly-subscription" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  subscription_arn: string # The unique identifier of the cost anomaly subscription that you want to delete.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.DeleteAnomalySubscription")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SubscriptionArn": $subscription_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a Cost Category. Expenses from this month going forward will no longer be categorized with this Cost Category.
#
# POST /
# operationId: DeleteCostCategoryDefinition
export def "delete-cost-category-definition" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  cost_category_arn: string # The unique identifier for your Cost Category.
]: any -> record<CostCategoryArn: string, EffectiveEnd: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.DeleteCostCategoryDefinition")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CostCategoryArn": $cost_category_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the name, Amazon Resource Name (ARN), rules, definition, and effective dates of a Cost Category that's defined in the account. You have the option to use EffectiveOn to return a Cost Category that's active on a specific date. If there's no EffectiveOn specified, you see a Cost Category that's effective on the current date. If Cost Category is still effective, EffectiveEnd is omitted in the response.
#
# POST /
# operationId: DescribeCostCategoryDefinition
export def "describe-cost-category-definition" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  cost_category_arn: string # The unique identifier for your Cost Category.
  --effective-on: string # The period of time that you want the usage and costs for.
]: any -> record<CostCategory: record<CostCategoryArn: string, EffectiveStart: string, EffectiveEnd: string, Name: string, RuleVersion: string, Rules: list<record>, SplitChargeRules: list<record>, ProcessingStatus: list<record>, DefaultValue: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.DescribeCostCategoryDefinition")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CostCategoryArn": $cost_category_arn, "EffectiveOn": $effective_on} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves all of the cost anomalies detected on your account during the time period that's specified by the DateInterval object. Anomalies are available for up to 90 days.
#
# POST /
# operationId: GetAnomalies
# --DateInterval shape: {StartDate: string, EndDate?: string}
# --TotalImpact shape: {NumericOperator: "EQUAL"|"GREATER_THAN_OR_EQUAL"|"LESS_THAN_OR_EQUAL"|"GREATER_THAN"|"LESS_THAN"|"BETWEEN", StartValue: float, EndValue?: float}
export def "get-anomalies" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  --monitor-arn: string # Retrieves all of the cost anomalies detected for a specific cost anomaly monitor Amazon Resource Name (ARN).
  date_interval: record # The time period for an anomaly. — shape: {StartDate: string, EndDate?: string}
  --feedback: string@feedback-completer # Filters anomaly results by the feedback field on the anomaly object.
  --total-impact: record # Filters cost anomalies based on the total impact. — shape: {NumericOperator: "EQUAL"|"GREATER_THAN_OR_EQUAL"|"LESS_THAN_OR_EQUAL"|"GREATER_THAN"|"LESS_THAN"|"BETWEEN", StartValue: float, EndValue?: float}
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --max-results: int # The number of entries a paginated response contains.
]: any -> record<Anomalies: table<AnomalyId: string, AnomalyStartDate: string, AnomalyEndDate: string, DimensionValue: string, RootCauses: list, AnomalyScore: record, Impact: record, MonitorArn: string, Feedback: string>, NextPageToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetAnomalies")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"MonitorArn": $monitor_arn, "DateInterval": $date_interval, "Feedback": $feedback, "TotalImpact": $total_impact, "NextPageToken": $next_page_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the cost anomaly monitor definitions for your account. You can filter using a list of cost anomaly monitor Amazon Resource Names (ARNs).
#
# POST /
# operationId: GetAnomalyMonitors
export def "get-anomaly-monitors" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  --monitor-arn-list: list<string> # A list of cost anomaly monitor ARNs.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --max-results: int # The number of entries that a paginated response contains.
]: any -> record<AnomalyMonitors: table<MonitorArn: string, MonitorName: string, CreationDate: string, LastUpdatedDate: string, LastEvaluatedDate: string, MonitorType: string, MonitorDimension: string, MonitorSpecification: record, DimensionalValueCount: int>, NextPageToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetAnomalyMonitors")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"MonitorArnList": $monitor_arn_list, "NextPageToken": $next_page_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the cost anomaly subscription objects for your account. You can filter using a list of cost anomaly monitor Amazon Resource Names (ARNs).
#
# POST /
# operationId: GetAnomalySubscriptions
export def "get-anomaly-subscriptions" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  --subscription-arn-list: list<string> # A list of cost anomaly subscription ARNs.
  --monitor-arn: string # Cost anomaly monitor ARNs.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --max-results: int # The number of entries a paginated response contains.
]: any -> record<AnomalySubscriptions: table<SubscriptionArn: string, AccountId: string, MonitorArnList: list, Subscribers: list, Threshold: float, Frequency: string, SubscriptionName: string, ThresholdExpression: record>, NextPageToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetAnomalySubscriptions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SubscriptionArnList": $subscription_arn_list, "MonitorArn": $monitor_arn, "NextPageToken": $next_page_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves cost and usage metrics for your account. You can specify which cost and usage-related metric that you want the request to return. For example, you can specify BlendedCosts or UsageQuantity. You can also filter and group your data by various dimensions, such as SERVICE or AZ, in a specific time range. For a complete list of valid dimensions, see the GetDimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html) operation. Management account in an organization in Organizations have access to all member accounts. For information about filter limitations, see Quotas and restrictions (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-limits.html) in the Billing and Cost Management User Guide.
#
# POST /
# operationId: GetCostAndUsage
# --TimePeriod shape: {Start: string, End: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --GroupBy item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
export def "get-cost-and-usage" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  granularity: string@granularity-completer # Sets the Amazon Web Services cost granularity to MONTHLY or DAILY, or HOURLY. If Granularity isn't set, the response object doesn't include the Granularity, either MONTHLY or DAILY, or HOURLY.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  metrics: list<string> # Which metrics are returned in the query. For more information about blended and unblended rates, see Why does the "blended" annotation appear on some line items in my bill? (http://aws.amazon.com/premiumsupport/knowledge-center/blended-rates-intro/). Valid values are AmortizedCost, BlendedCost, NetAmortizedCost, NetUnblendedCost, NormalizedUsageAmount, UnblendedCost, and UsageQuantity. If you return the UsageQuantity metric, the service aggregates all usage numbers without taking into account the units. For example, if you aggregate usageQuantity across all of Amazon EC2, the results aren't meaningful because Amazon EC2 compute hours and data transfer are measured in different units (for example, hours and GB). To get more meaningful UsageQuantity metrics, filter by UsageType or UsageTypeGroups. Metrics is required for GetCostAndUsage requests.
  --group-by: list # You can group Amazon Web Services costs using up to two different groups, either dimensions, tag keys, cost categories, or any two group by types. Valid values for the DIMENSION type are AZ, INSTANCE_TYPE, LEGAL_ENTITY_NAME, INVOICING_ENTITY, LINKED_ACCOUNT, OPERATION, PLATFORM, PURCHASE_TYPE, SERVICE, TENANCY, RECORD_TYPE, and USAGE_TYPE. When you group by the TAG type and include a valid tag key, you get all tag values, including empty strings. — item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
]: any -> record<NextPageToken: string, GroupDefinitions: table<Type: string, Key: string>, ResultsByTime: table<TimePeriod: record, Total: record, Groups: list, Estimated: bool>, DimensionValueAttributes: table<Value: string, Attributes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetCostAndUsage")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TimePeriod": $time_period, "Granularity": $granularity, "Filter": $filter, "Metrics": $metrics, "GroupBy": $group_by, "NextPageToken": $next_page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves cost and usage metrics with resources for your account. You can specify which cost and usage-related metric, such as BlendedCosts or UsageQuantity, that you want the request to return. You can also filter and group your data by various dimensions, such as SERVICE or AZ, in a specific time range. For a complete list of valid dimensions, see the GetDimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetDimensionValues.html) operation. Management account in an organization in Organizations have access to all member accounts. This API is currently available for the Amazon Elastic Compute Cloud – Compute service only. This is an opt-in only feature. You can enable this feature from the Cost Explorer Settings page. For information about how to access the Settings page, see Controlling Access for Cost Explorer (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-access.html) in the Billing and Cost Management User Guide.
#
# POST /
# operationId: GetCostAndUsageWithResources
# --TimePeriod shape: {Start: string, End: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --GroupBy item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
export def "get-cost-and-usage-with-resources" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  granularity: string@granularity-completer # Sets the Amazon Web Services cost granularity to MONTHLY, DAILY, or HOURLY. If Granularity isn't set, the response object doesn't include the Granularity, MONTHLY, DAILY, or HOURLY.
  filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --metrics: list<string> # Which metrics are returned in the query. For more information about blended and unblended rates, see Why does the "blended" annotation appear on some line items in my bill? (http://aws.amazon.com/premiumsupport/knowledge-center/blended-rates-intro/). Valid values are AmortizedCost, BlendedCost, NetAmortizedCost, NetUnblendedCost, NormalizedUsageAmount, UnblendedCost, and UsageQuantity. If you return the UsageQuantity metric, the service aggregates all usage numbers without taking the units into account. For example, if you aggregate usageQuantity across all of Amazon EC2, the results aren't meaningful because Amazon EC2 compute hours and data transfer are measured in different units (for example, hour or GB). To get more meaningful UsageQuantity metrics, filter by UsageType or UsageTypeGroups. Metrics is required for GetCostAndUsageWithResources requests.
  --group-by: list # You can group Amazon Web Services costs using up to two different groups: DIMENSION, TAG, COST_CATEGORY. — item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
]: any -> record<NextPageToken: string, GroupDefinitions: table<Type: string, Key: string>, ResultsByTime: table<TimePeriod: record, Total: record, Groups: list, Estimated: bool>, DimensionValueAttributes: table<Value: string, Attributes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetCostAndUsageWithResources")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TimePeriod": $time_period, "Granularity": $granularity, "Filter": $filter, "Metrics": $metrics, "GroupBy": $group_by, "NextPageToken": $next_page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves an array of Cost Category names and values incurred cost. If some Cost Category names and values are not associated with any cost, they will not be returned by this API.
#
# POST /
# operationId: GetCostCategories
# --TimePeriod shape: {Start: string, End: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --SortBy item shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
export def "get-cost-categories" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  --search-string: string # The value that you want to search the filter values for. If you don't specify a CostCategoryName, SearchString is used to filter Cost Category names that match the SearchString pattern. If you specify a CostCategoryName, SearchString is used to filter Cost Category values that match the SearchString pattern.
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --cost-category-name: string # The unique name of the Cost Category.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --sort-by: list # The value that you sort the data by. The key represents the cost and usage metrics. The following values are supported: BlendedCost UnblendedCost AmortizedCost NetAmortizedCost NetUnblendedCost UsageQuantity NormalizedUsageAmount The supported key values for the SortOrder value are ASCENDING and DESCENDING. When you use the SortBy value, the NextPageToken and SearchString key values aren't supported. — item shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
  --max-results: int # This field is only used when the SortBy value is provided in the request. The maximum number of objects that are returned for this request. If MaxResults isn't specified with the SortBy value, the request returns 1000 results as the default value for this parameter. For GetCostCategories, MaxResults has an upper quota of 1000.
  --next-page-token: string # If the number of objects that are still available for retrieval exceeds the quota, Amazon Web Services returns a NextPageToken value in the response. To retrieve the next batch of objects, provide the NextPageToken from the previous call in your next request.
]: any -> record<NextPageToken: string, CostCategoryNames: list<string>, CostCategoryValues: list<string>, ReturnSize: int, TotalSize: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetCostCategories")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SearchString": $search_string, "TimePeriod": $time_period, "CostCategoryName": $cost_category_name, "Filter": $filter, "SortBy": $sort_by, "MaxResults": $max_results, "NextPageToken": $next_page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a forecast for how much Amazon Web Services predicts that you will spend over the forecast time period that you select, based on your past costs.
#
# POST /
# operationId: GetCostForecast
# --TimePeriod shape: {Start: string, End: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
export def "get-cost-forecast" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  metric: string@metric-completer # Which metric Cost Explorer uses to create your forecast. For more information about blended and unblended rates, see Why does the "blended" annotation appear on some line items in my bill? (http://aws.amazon.com/premiumsupport/knowledge-center/blended-rates-intro/). Valid values for a GetCostForecast call are the following: AMORTIZED_COST BLENDED_COST NET_AMORTIZED_COST NET_UNBLENDED_COST UNBLENDED_COST
  granularity: string@granularity-completer # How granular you want the forecast to be. You can get 3 months of DAILY forecasts or 12 months of MONTHLY forecasts. The GetCostForecast operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --prediction-interval-level: int # Cost Explorer always returns the mean forecast as a single point. You can request a prediction interval around the mean by specifying a confidence level. The higher the confidence level, the more confident Cost Explorer is about the actual value falling in the prediction interval. Higher confidence levels result in wider prediction intervals.
]: any -> record<Total: record<Amount: string, Unit: string>, ForecastResultsByTime: table<TimePeriod: record, MeanValue: string, PredictionIntervalLowerBound: string, PredictionIntervalUpperBound: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetCostForecast")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TimePeriod": $time_period, "Metric": $metric, "Granularity": $granularity, "Filter": $filter, "PredictionIntervalLevel": $prediction_interval_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves all available filter values for a specified filter over a period of time. You can search the dimension values for an arbitrary string.
#
# POST /
# operationId: GetDimensionValues
# --TimePeriod shape: {Start: string, End: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --SortBy item shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
export def "get-dimension-values" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  --search-string: string # The value that you want to search the filter values for.
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  dimension: string@dimension-completer # The name of the dimension. Each Dimension is available for a different Context. For more information, see Context. LINK_ACCOUNT_NAME and SERVICE_CODE can only be used in CostCategoryRule (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/AAPI_CostCategoryRule.html).
  --context: string@context-completer # The context for the call to GetDimensionValues. This can be RESERVATIONS or COST_AND_USAGE. The default value is COST_AND_USAGE. If the context is set to RESERVATIONS, the resulting dimension values can be used in the GetReservationUtilization operation. If the context is set to COST_AND_USAGE, the resulting dimension values can be used in the GetCostAndUsage operation. If you set the context to COST_AND_USAGE, you can use the following dimensions for searching: AZ - The Availability Zone. An example is us-east-1a. BILLING_ENTITY - The Amazon Web Services seller that your account is with. Possible values are the following: - Amazon Web Services(Amazon Web Services): The entity that sells Amazon Web Services. - AISPL (Amazon Internet Services Pvt. Ltd.): The local Indian entity that's an acting reseller for Amazon Web Services in India. - Amazon Web Services Marketplace: The entity that supports the sale of solutions that are built on Amazon Web Services by third-party software providers. CACHE_ENGINE - The Amazon ElastiCache operating system. Examples are Windows or Linux. DEPLOYMENT_OPTION - The scope of Amazon Relational Database Service deployments. Valid values are SingleAZ and MultiAZ. DATABASE_ENGINE - The Amazon Relational Database Service database. Examples are Aurora or MySQL. INSTANCE_TYPE - The type of Amazon EC2 instance. An example is m4.xlarge. INSTANCE_TYPE_FAMILY - A family of instance types optimized to fit different use cases. Examples are Compute Optimized (for example, C4, C5, C6g, and C7g), Memory Optimization (for example, R4, R5n, R5b, and R6g). INVOICING_ENTITY - The name of the entity that issues the Amazon Web Services invoice. LEGAL_ENTITY_NAME - The name of the organization that sells you Amazon Web Services services, such as Amazon Web Services. LINKED_ACCOUNT - The description in the attribute map that includes the full name of the member account. The value field contains the Amazon Web Services ID of the member account. OPERATING_SYSTEM - The operating system. Examples are Windows or Linux. OPERATION - The action performed. Examples include RunInstance and CreateBucket. PLATFORM - The Amazon EC2 operating system. Examples are Windows or Linux. PURCHASE_TYPE - The reservation type of the purchase that this usage is related to. Examples include On-Demand Instances and Standard Reserved Instances. RESERVATION_ID - The unique identifier for an Amazon Web Services Reservation Instance. SAVINGS_PLAN_ARN - The unique identifier for your Savings Plans. SAVINGS_PLANS_TYPE - Type of Savings Plans (EC2 Instance or Compute). SERVICE - The Amazon Web Services service such as Amazon DynamoDB. TENANCY - The tenancy of a resource. Examples are shared or dedicated. USAGE_TYPE - The type of usage. An example is DataTransfer-In-Bytes. The response for the GetDimensionValues operation includes a unit attribute. Examples include GB and Hrs. USAGE_TYPE_GROUP - The grouping of common usage types. An example is Amazon EC2: CloudWatch – Alarms. The response for this operation includes a unit attribute. REGION - The Amazon Web Services Region. RECORD_TYPE - The different types of charges such as Reserved Instance (RI) fees, usage costs, tax refunds, and credits. RESOURCE_ID - The unique identifier of the resource. ResourceId is an opt-in feature only available for last 14 days for EC2-Compute Service. If you set the context to RESERVATIONS, you can use the following dimensions for searching: AZ - The Availability Zone. An example is us-east-1a. CACHE_ENGINE - The Amazon ElastiCache operating system. Examples are Windows or Linux. DEPLOYMENT_OPTION - The scope of Amazon Relational Database Service deployments. Valid values are SingleAZ and MultiAZ. INSTANCE_TYPE - The type of Amazon EC2 instance. An example is m4.xlarge. LINKED_ACCOUNT - The description in the attribute map that includes the full name of the member account. The value field contains the Amazon Web Services ID of the member account. PLATFORM - The Amazon EC2 operating system. Examples are Windows or Linux. REGION - The Amazon Web Services Region. SCOPE (Utilization only) - The scope of a Reserved Instance (RI). Values are regional or a single Availability Zone. TAG (Coverage only) - The tags that are associated with a Reserved Instance (RI). TENANCY - The tenancy of a resource. Examples are shared or dedicated. If you set the context to SAVINGS_PLANS, you can use the following dimensions for searching: SAVINGS_PLANS_TYPE - Type of Savings Plans (EC2 Instance or Compute) PAYMENT_OPTION - The payment option for the given Savings Plans (for example, All Upfront) REGION - The Amazon Web Services Region. INSTANCE_TYPE_FAMILY - The family of instances (For example, m5) LINKED_ACCOUNT - The description in the attribute map that includes the full name of the member account. The value field contains the Amazon Web Services ID of the member account. SAVINGS_PLAN_ARN - The unique identifier for your Savings Plans.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --sort-by: list # The value that you want to sort the data by. The key represents cost and usage metrics. The following values are supported: BlendedCost UnblendedCost AmortizedCost NetAmortizedCost NetUnblendedCost UsageQuantity NormalizedUsageAmount The supported values for the SortOrder key are ASCENDING or DESCENDING. When you specify a SortBy paramater, the context must be COST_AND_USAGE. Further, when using SortBy, NextPageToken and SearchString aren't supported. — item shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
  --max-results: int # This field is only used when SortBy is provided in the request. The maximum number of objects that are returned for this request. If MaxResults isn't specified with SortBy, the request returns 1000 results as the default value for this parameter. For GetDimensionValues, MaxResults has an upper limit of 1000.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
]: any -> record<DimensionValues: table<Value: string, Attributes: record>, ReturnSize: int, TotalSize: int, NextPageToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetDimensionValues")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SearchString": $search_string, "TimePeriod": $time_period, "Dimension": $dimension, "Context": $context, "Filter": $filter, "SortBy": $sort_by, "MaxResults": $max_results, "NextPageToken": $next_page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the reservation coverage for your account, which you can use to see how much of your Amazon Elastic Compute Cloud, Amazon ElastiCache, Amazon Relational Database Service, or Amazon Redshift usage is covered by a reservation. An organization's management account can see the coverage of the associated member accounts. This supports dimensions, Cost Categories, and nested expressions. For any time period, you can filter data about reservation usage by the following dimensions: AZ CACHE_ENGINE DATABASE_ENGINE DEPLOYMENT_OPTION INSTANCE_TYPE LINKED_ACCOUNT OPERATING_SYSTEM PLATFORM REGION SERVICE TAG TENANCY To determine valid values for a dimension, use the GetDimensionValues operation.
#
# POST /
# operationId: GetReservationCoverage
# --TimePeriod shape: {Start: string, End: string}
# --GroupBy item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --SortBy shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
export def "get-reservation-coverage" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --group-by: list # You can group the data by the following attributes: AZ CACHE_ENGINE DATABASE_ENGINE DEPLOYMENT_OPTION INSTANCE_TYPE INVOICING_ENTITY LINKED_ACCOUNT OPERATING_SYSTEM PLATFORM REGION TENANCY — item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
  --granularity: string@granularity-completer # The granularity of the Amazon Web Services cost data for the reservation. Valid values are MONTHLY and DAILY. If GroupBy is set, Granularity can't be set. If Granularity isn't set, the response object doesn't include Granularity, either MONTHLY or DAILY. The GetReservationCoverage operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --metrics: list<string> # The measurement that you want your reservation coverage reported in. Valid values are Hour, Unit, and Cost. You can use multiple values in a request.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --sort-by: record # The details for how to sort the data. — shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
  --max-results: int # The maximum number of objects that you returned for this request. If more objects are available, in the response, Amazon Web Services provides a NextPageToken value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<CoveragesByTime: table<TimePeriod: record, Groups: list, Total: record>, Total: record<CoverageHours: record<OnDemandHours: string, ReservedHours: string, TotalRunningHours: string, CoverageHoursPercentage: string>, CoverageNormalizedUnits: record<OnDemandNormalizedUnits: string, ReservedNormalizedUnits: string, TotalRunningNormalizedUnits: string, CoverageNormalizedUnitsPercentage: string>, CoverageCost: record<OnDemandCost: string>>, NextPageToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetReservationCoverage")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TimePeriod": $time_period, "GroupBy": $group_by, "Granularity": $granularity, "Filter": $filter, "Metrics": $metrics, "NextPageToken": $next_page_token, "SortBy": $sort_by, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets recommendations for reservation purchases. These recommendations might help you to reduce your costs. Reservations provide a discounted hourly rate (up to 75%) compared to On-Demand pricing. Amazon Web Services generates your recommendations by identifying your On-Demand usage during a specific time period and collecting your usage into categories that are eligible for a reservation. After Amazon Web Services has these categories, it simulates every combination of reservations in each category of usage to identify the best number of each type of Reserved Instance (RI) to purchase to maximize your estimated savings. For example, Amazon Web Services automatically aggregates your Amazon EC2 Linux, shared tenancy, and c4 family usage in the US West (Oregon) Region and recommends that you buy size-flexible regional reservations to apply to the c4 family usage. Amazon Web Services recommends the smallest size instance in an instance family. This makes it easier to purchase a size-flexible Reserved Instance (RI). Amazon Web Services also shows the equal number of normalized units. This way, you can purchase any instance size that you want. For this example, your RI recommendation is for c4.large because that is the smallest size instance in the c4 instance family.
#
# POST /
# operationId: GetReservationPurchaseRecommendation
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --ServiceSpecification shape: {EC2Specification?: record}
export def "get-reservation-purchase-recommendation" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  --account-id: string # The account ID that's associated with the recommendation.
  service: string # The specific service that you want recommendations for.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --account-scope: string@account-scope-completer # The account scope that you want your recommendations for. Amazon Web Services calculates recommendations including the management account and member accounts if the value is set to PAYER. If the value is LINKED, recommendations are calculated for individual member accounts only.
  --lookback-period-in-days: string@lookback-period-in-days-completer # The number of previous days that you want Amazon Web Services to consider when it calculates your recommendations.
  --term-in-years: string@term-in-years-completer # The reservation term that you want recommendations for.
  --payment-option: string@payment-option-completer # The reservation purchase option that you want recommendations for.
  --service-specification: record # Hardware specifications for the service that you want recommendations for. — shape: {EC2Specification?: record}
  --page-size: int # The number of recommendations that you want returned in a single response object.
  --next-page-token: string # The pagination token that indicates the next set of results that you want to retrieve.
]: any -> record<Metadata: record<RecommendationId: string, GenerationTimestamp: string>, Recommendations: table<AccountScope: string, LookbackPeriodInDays: string, TermInYears: string, PaymentOption: string, ServiceSpecification: record, RecommendationDetails: list, RecommendationSummary: record>, NextPageToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetReservationPurchaseRecommendation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AccountId": $account_id, "Service": $service, "Filter": $filter, "AccountScope": $account_scope, "LookbackPeriodInDays": $lookback_period_in_days, "TermInYears": $term_in_years, "PaymentOption": $payment_option, "ServiceSpecification": $service_specification, "PageSize": $page_size, "NextPageToken": $next_page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the reservation utilization for your account. Management account in an organization have access to member accounts. You can filter data by dimensions in a time period. You can use GetDimensionValues to determine the possible dimension values. Currently, you can group only by SUBSCRIPTION_ID.
#
# POST /
# operationId: GetReservationUtilization
# --TimePeriod shape: {Start: string, End: string}
# --GroupBy item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --SortBy shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
export def "get-reservation-utilization" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --group-by: list # Groups only by SUBSCRIPTION_ID. Metadata is included. — item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
  --granularity: string@granularity-completer # If GroupBy is set, Granularity can't be set. If Granularity isn't set, the response object doesn't include Granularity, either MONTHLY or DAILY. If both GroupBy and Granularity aren't set, GetReservationUtilization defaults to DAILY. The GetReservationUtilization operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --sort-by: record # The details for how to sort the data. — shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --max-results: int # The maximum number of objects that you returned for this request. If more objects are available, in the response, Amazon Web Services provides a NextPageToken value that you can use in a subsequent call to get the next batch of objects.
]: any -> record<UtilizationsByTime: table<TimePeriod: record, Groups: list, Total: record>, Total: record<UtilizationPercentage: string, UtilizationPercentageInUnits: string, PurchasedHours: string, PurchasedUnits: string, TotalActualHours: string, TotalActualUnits: string, UnusedHours: string, UnusedUnits: string, OnDemandCostOfRIHoursUsed: string, NetRISavings: string, TotalPotentialRISavings: string, AmortizedUpfrontFee: string, AmortizedRecurringFee: string, TotalAmortizedFee: string, RICostForUnusedHours: string, RealizedSavings: string, UnrealizedSavings: string>, NextPageToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetReservationUtilization")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TimePeriod": $time_period, "GroupBy": $group_by, "Granularity": $granularity, "Filter": $filter, "SortBy": $sort_by, "NextPageToken": $next_page_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates recommendations that help you save cost by identifying idle and underutilized Amazon EC2 instances. Recommendations are generated to either downsize or terminate instances, along with providing savings detail and metrics. For more information about calculation and function, see Optimizing Your Cost with Rightsizing Recommendations (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-rightsizing.html) in the Billing and Cost Management User Guide.
#
# POST /
# operationId: GetRightsizingRecommendation
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --Configuration shape: {RecommendationTarget: "SAME_INSTANCE_FAMILY"|"CROSS_INSTANCE_FAMILY", BenefitsConsidered: bool}
export def "get-rightsizing-recommendation" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --configuration: record # You can use RightsizingRecommendationConfiguration to customize recommendations across two attributes. You can choose to view recommendations for instances within the same instance families or across different instance families. You can also choose to view your estimated savings that are associated with recommendations with consideration of existing Savings Plans or Reserved Instance (RI) benefits, or neither. — shape: {RecommendationTarget: "SAME_INSTANCE_FAMILY"|"CROSS_INSTANCE_FAMILY", BenefitsConsidered: bool}
  service: string # The specific service that you want recommendations for. The only valid value for GetRightsizingRecommendation is "AmazonEC2".
  --page-size: int # The number of recommendations that you want returned in a single response object.
  --next-page-token: string # The pagination token that indicates the next set of results that you want to retrieve.
]: any -> record<Metadata: record<RecommendationId: string, GenerationTimestamp: string, LookbackPeriodInDays: string, AdditionalMetadata: string>, Summary: record<TotalRecommendationCount: string, EstimatedTotalMonthlySavingsAmount: string, SavingsCurrencyCode: string, SavingsPercentage: string>, RightsizingRecommendations: table<AccountId: string, CurrentInstance: record, RightsizingType: string, ModifyRecommendationDetail: record, TerminateRecommendationDetail: record, FindingReasonCodes: list>, NextPageToken: string, Configuration: record<RecommendationTarget: string, BenefitsConsidered: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetRightsizingRecommendation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Filter": $filter, "Configuration": $configuration, "Service": $service, "PageSize": $page_size, "NextPageToken": $next_page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the Savings Plans covered for your account. This enables you to see how much of your cost is covered by a Savings Plan. An organization’s management account can see the coverage of the associated member accounts. This supports dimensions, Cost Categories, and nested expressions. For any time period, you can filter data for Savings Plans usage with the following dimensions: LINKED_ACCOUNT REGION SERVICE INSTANCE_FAMILY To determine valid values for a dimension, use the GetDimensionValues operation.
#
# POST /
# operationId: GetSavingsPlansCoverage
# --TimePeriod shape: {Start: string, End: string}
# --GroupBy item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --SortBy shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
export def "get-savings-plans-coverage" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --group-by: list # You can group the data using the attributes INSTANCE_FAMILY, REGION, or SERVICE. — item shape: {Type?: "DIMENSION"|"TAG"|"COST_CATEGORY", Key?: string}
  --granularity: string@granularity-completer # The granularity of the Amazon Web Services cost data for your Savings Plans. Granularity can't be set if GroupBy is set. The GetSavingsPlansCoverage operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --metrics: list<string> # The measurement that you want your Savings Plans coverage reported in. The only valid value is SpendCoveredBySavingsPlans.
  --next-token-body: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size. (body field)
  --max-results-body: int # The number of items to be returned in a response. The default is 20, with a minimum value of 1. (body field)
  --sort-by: record # The details for how to sort the data. — shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
]: any -> record<SavingsPlansCoverages: table<Attributes: record, Coverage: record, TimePeriod: record>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetSavingsPlansCoverage")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TimePeriod": $time_period, "GroupBy": $group_by, "Granularity": $granularity, "Filter": $filter, "Metrics": $metrics, "NextToken": $next_token_body, "MaxResults": $max_results_body, "SortBy": $sort_by} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the Savings Plans recommendations for your account. First use StartSavingsPlansPurchaseRecommendationGeneration to generate a new set of recommendations, and then use GetSavingsPlansPurchaseRecommendation to retrieve them.
#
# POST /
# operationId: GetSavingsPlansPurchaseRecommendation
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
export def "get-savings-plans-purchase-recommendation" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  savings_plans_type: string@savings-plans-type-completer # The Savings Plans recommendation type that's requested.
  term_in_years: string@term-in-years-completer # The savings plan recommendation term that's used to generate these recommendations.
  payment_option: string@payment-option-completer # The payment option that's used to generate these recommendations.
  --account-scope: string@account-scope-completer # The account scope that you want your recommendations for. Amazon Web Services calculates recommendations including the management account and member accounts if the value is set to PAYER. If the value is LINKED, recommendations are calculated for individual member accounts only.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
  --page-size: int # The number of recommendations that you want returned in a single response object.
  lookback_period_in_days: string@lookback-period-in-days-completer # The lookback period that's used to generate the recommendation.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
]: any -> record<Metadata: record<RecommendationId: string, GenerationTimestamp: string, AdditionalMetadata: string>, SavingsPlansPurchaseRecommendation: record<AccountScope: string, SavingsPlansType: string, TermInYears: string, PaymentOption: string, LookbackPeriodInDays: string, SavingsPlansPurchaseRecommendationDetails: list<record>, SavingsPlansPurchaseRecommendationSummary: record<EstimatedROI: string, CurrencyCode: string, EstimatedTotalCost: string, CurrentOnDemandSpend: string, EstimatedSavingsAmount: string, TotalRecommendationCount: string, DailyCommitmentToPurchase: string, HourlyCommitmentToPurchase: string, EstimatedSavingsPercentage: string, EstimatedMonthlySavingsAmount: string, EstimatedOnDemandCostWithCurrentCommitment: string>>, NextPageToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetSavingsPlansPurchaseRecommendation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SavingsPlansType": $savings_plans_type, "TermInYears": $term_in_years, "PaymentOption": $payment_option, "AccountScope": $account_scope, "NextPageToken": $next_page_token, "PageSize": $page_size, "LookbackPeriodInDays": $lookback_period_in_days, "Filter": $filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the Savings Plans utilization for your account across date ranges with daily or monthly granularity. Management account in an organization have access to member accounts. You can use GetDimensionValues in SAVINGS_PLANS to determine the possible dimension values. You can't group by any dimension values for GetSavingsPlansUtilization.
#
# POST /
# operationId: GetSavingsPlansUtilization
# --TimePeriod shape: {Start: string, End: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --SortBy shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
export def "get-savings-plans-utilization" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --granularity: string@granularity-completer # The granularity of the Amazon Web Services utillization data for your Savings Plans. The GetSavingsPlansUtilization operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --sort-by: record # The details for how to sort the data. — shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
]: any -> record<SavingsPlansUtilizationsByTime: table<TimePeriod: record, Utilization: record, Savings: record, AmortizedCommitment: record>, Total: record<Utilization: record<TotalCommitment: string, UsedCommitment: string, UnusedCommitment: string, UtilizationPercentage: string>, Savings: record<NetSavings: string, OnDemandCostEquivalent: string>, AmortizedCommitment: record<AmortizedRecurringCommitment: string, AmortizedUpfrontCommitment: string, TotalAmortizedCommitment: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetSavingsPlansUtilization")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TimePeriod": $time_period, "Granularity": $granularity, "Filter": $filter, "SortBy": $sort_by} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves attribute data along with aggregate utilization and savings data for a given time period. This doesn't support granular or grouped data (daily/monthly) in response. You can't retrieve data by dates in a single response similar to GetSavingsPlanUtilization, but you have the option to make multiple calls to GetSavingsPlanUtilizationDetails by providing individual dates. You can use GetDimensionValues in SAVINGS_PLANS to determine the possible dimension values. GetSavingsPlanUtilizationDetails internally groups data by SavingsPlansArn.
#
# POST /
# operationId: GetSavingsPlansUtilizationDetails
# --TimePeriod shape: {Start: string, End: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --SortBy shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
export def "get-savings-plans-utilization-details" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --data-type: list<string> # The data type.
  --next-token-body: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size. (body field)
  --max-results-body: int # The number of items to be returned in a response. The default is 20, with a minimum value of 1. (body field)
  --sort-by: record # The details for how to sort the data. — shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
]: any -> record<SavingsPlansUtilizationDetails: table<SavingsPlanArn: string, Attributes: record, Utilization: record, Savings: record, AmortizedCommitment: record>, Total: record<Utilization: record<TotalCommitment: string, UsedCommitment: string, UnusedCommitment: string, UtilizationPercentage: string>, Savings: record<NetSavings: string, OnDemandCostEquivalent: string>, AmortizedCommitment: record<AmortizedRecurringCommitment: string, AmortizedUpfrontCommitment: string, TotalAmortizedCommitment: string>>, TimePeriod: record<Start: string, End: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetSavingsPlansUtilizationDetails")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TimePeriod": $time_period, "Filter": $filter, "DataType": $data_type, "NextToken": $next_token_body, "MaxResults": $max_results_body, "SortBy": $sort_by} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Queries for available tag keys and tag values for a specified period. You can search the tag values for an arbitrary string.
#
# POST /
# operationId: GetTags
# --TimePeriod shape: {Start: string, End: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
# --SortBy item shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
export def "get-tags" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  --search-string: string # The value that you want to search for.
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  --tag-key: string # The key of the tag that you want to return values for.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --sort-by: list # The value that you want to sort the data by. The key represents cost and usage metrics. The following values are supported: BlendedCost UnblendedCost AmortizedCost NetAmortizedCost NetUnblendedCost UsageQuantity NormalizedUsageAmount The supported values for SortOrder are ASCENDING and DESCENDING. When you use SortBy, NextPageToken and SearchString aren't supported. — item shape: {Key: string, SortOrder?: "ASCENDING"|"DESCENDING"}
  --max-results: int # This field is only used when SortBy is provided in the request. The maximum number of objects that are returned for this request. If MaxResults isn't specified with SortBy, the request returns 1000 results as the default value for this parameter. For GetTags, MaxResults has an upper quota of 1000.
  --next-page-token: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size.
]: any -> record<NextPageToken: string, Tags: list<string>, ReturnSize: int, TotalSize: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetTags")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SearchString": $search_string, "TimePeriod": $time_period, "TagKey": $tag_key, "Filter": $filter, "SortBy": $sort_by, "MaxResults": $max_results, "NextPageToken": $next_page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a forecast for how much Amazon Web Services predicts that you will use over the forecast time period that you select, based on your past usage.
#
# POST /
# operationId: GetUsageForecast
# --TimePeriod shape: {Start: string, End: string}
# --Filter shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
export def "get-usage-forecast" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  time_period: record # The time period of the request. — shape: {Start: string, End: string}
  metric: string@metric-completer # Which metric Cost Explorer uses to create your forecast. Valid values for a GetUsageForecast call are the following: USAGE_QUANTITY NORMALIZED_USAGE_AMOUNT
  granularity: string@granularity-completer # How granular you want the forecast to be. You can get 3 months of DAILY forecasts or 12 months of MONTHLY forecasts. The GetUsageForecast operation supports only DAILY and MONTHLY granularities.
  --filter: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
  --prediction-interval-level: int # Amazon Web Services Cost Explorer always returns the mean forecast as a single point. You can request a prediction interval around the mean by specifying a confidence level. The higher the confidence level, the more confident Cost Explorer is about the actual value falling in the prediction interval. Higher confidence levels result in wider prediction intervals.
]: any -> record<Total: record<Amount: string, Unit: string>, ForecastResultsByTime: table<TimePeriod: record, MeanValue: string, PredictionIntervalLowerBound: string, PredictionIntervalUpperBound: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.GetUsageForecast")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TimePeriod": $time_period, "Metric": $metric, "Granularity": $granularity, "Filter": $filter, "PredictionIntervalLevel": $prediction_interval_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a list of cost allocation tags. All inputs in the API are optional and serve as filters. By default, all cost allocation tags are returned.
#
# POST /
# operationId: ListCostAllocationTags
export def "list-cost-allocation-tags" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  --status: string@status-completer # The status of cost allocation tag keys that are returned for this request.
  --tag-keys: list<string> # The list of cost allocation tag keys that are returned for this request.
  --type: string@type-completer # The type of CostAllocationTag object that are returned for this request. The AWSGenerated type tags are tags that Amazon Web Services defines and applies to support Amazon Web Services resources for cost allocation purposes. The UserDefined type tags are tags that you define, create, and apply to resources.
  --next-token-body: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size. (body field)
  --max-results-body: int # The maximum number of objects that are returned for this request. By default, the request returns 100 results. (body field)
]: any -> record<CostAllocationTags: table<TagKey: string, Type: string, Status: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.ListCostAllocationTags")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Status": $status, "TagKeys": $tag_keys, "Type": $type, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the name, Amazon Resource Name (ARN), NumberOfRules and effective dates of all Cost Categories defined in the account. You have the option to use EffectiveOn to return a list of Cost Categories that were active on a specific date. If there is no EffectiveOn specified, you’ll see Cost Categories that are effective on the current date. If Cost Category is still effective, EffectiveEnd is omitted in the response. ListCostCategoryDefinitions supports pagination. The request can have a MaxResults range up to 100.
#
# POST /
# operationId: ListCostCategoryDefinitions
export def "list-cost-category-definitions" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  --effective-on: string # The period of time that you want the usage and costs for.
  --next-token-body: string # The token to retrieve the next set of results. Amazon Web Services provides the token when the response from a previous call has more results than the maximum page size. (body field)
  --max-results-body: int # The number of entries a paginated response contains. (body field)
]: any -> record<CostCategoryReferences: table<CostCategoryArn: string, Name: string, EffectiveStart: string, EffectiveEnd: string, NumberOfRules: int, ProcessingStatus: list, Values: list, DefaultValue: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.ListCostCategoryDefinitions")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"EffectiveOn": $effective_on, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a list of your historical recommendation generations within the past 30 days.
#
# POST /
# operationId: ListSavingsPlansPurchaseRecommendationGeneration
export def "list-savings-plans-purchase-recommendation-generation" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  --generation-status: string@generation-status-completer # The status of the recommendation generation.
  --recommendation-ids: list<string> # The IDs for each specific recommendation.
  --page-size: int # The number of recommendations that you want returned in a single response object.
  --next-page-token: string # The token to retrieve the next set of results.
]: any -> record<GenerationSummaryList: table<RecommendationId: string, GenerationStatus: string, GenerationStartedTime: string, GenerationCompletionTime: string, EstimatedCompletionTime: string>, NextPageToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.ListSavingsPlansPurchaseRecommendationGeneration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GenerationStatus": $generation_status, "RecommendationIds": $recommendation_ids, "PageSize": $page_size, "NextPageToken": $next_page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of resource tags associated with the resource specified by the Amazon Resource Name (ARN).
#
# POST /
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. For a list of supported resources, see ResourceTag (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_ResourceTag.html).
]: any -> record<ResourceTags: table<Key: string, Value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.ListTagsForResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the feedback property of a given cost anomaly.
#
# POST /
# operationId: ProvideAnomalyFeedback
export def "provide-anomaly-feedback" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  anomaly_id: string # A cost anomaly ID.
  feedback: string@feedback-completer # Describes whether the cost anomaly was a planned activity or you considered it an anomaly.
]: any -> record<AnomalyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.ProvideAnomalyFeedback")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AnomalyId": $anomaly_id, "Feedback": $feedback} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Requests a Savings Plans recommendation generation. This enables you to calculate a fresh set of Savings Plans recommendations that takes your latest usage data and current Savings Plans inventory into account. You can refresh Savings Plans recommendations up to three times daily for a consolidated billing family. StartSavingsPlansPurchaseRecommendationGeneration has no request syntax because no input parameters are needed to support this operation.
#
# POST /
# operationId: StartSavingsPlansPurchaseRecommendationGeneration
export def "start-savings-plans-purchase-recommendation-generation" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  --body: record
]: any -> record<RecommendationId: string, GenerationStartedTime: string, EstimatedCompletionTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.StartSavingsPlansPurchaseRecommendationGeneration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# An API operation for adding one or more tags (key-value pairs) to a resource. You can use the TagResource operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value you specify replaces the previous value for that tag. Although the maximum number of array members is 200, user-tag maximum is 50. The remaining are reserved for Amazon Web Services use.
#
# POST /
# operationId: TagResource
# --ResourceTags item shape: {Key: string, Value: string}
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. For a list of supported resources, see ResourceTag (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_ResourceTag.html).
  resource_tags: list # A list of tag key-value pairs to be added to the resource. Each tag consists of a key and a value, and each key must be unique for the resource. The following restrictions apply to resource tags: Although the maximum number of array members is 200, you can assign a maximum of 50 user-tags to one resource. The remaining are reserved for Amazon Web Services use The maximum length of a key is 128 characters The maximum length of a value is 256 characters Keys and values can only contain alphanumeric characters, spaces, and any of the following: _.:/=+@- Keys and values are case sensitive Keys and values are trimmed for any leading or trailing whitespaces Don’t use aws: as a prefix for your keys. This prefix is reserved for Amazon Web Services use — item shape: {Key: string, Value: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "ResourceTags": $resource_tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes one or more tags from a resource. Specify only tag keys in your request. Don't specify the value.
#
# POST /
# operationId: UntagResource
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. For a list of supported resources, see ResourceTag (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_ResourceTag.html).
  resource_tag_keys: list<string> # A list of tag keys associated with tags that need to be removed from the resource. If you specify a tag key that doesn't exist, it's ignored. Although the maximum number of array members is 200, user-tag maximum is 50. The remaining are reserved for Amazon Web Services use.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "ResourceTagKeys": $resource_tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates an existing cost anomaly monitor. The changes made are applied going forward, and doesn't change anomalies detected in the past.
#
# POST /
# operationId: UpdateAnomalyMonitor
export def "update-anomaly-monitor" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  monitor_arn: string # Cost anomaly monitor Amazon Resource Names (ARNs).
  --monitor-name: string # The new name for the cost anomaly monitor.
]: any -> record<MonitorArn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.UpdateAnomalyMonitor")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"MonitorArn": $monitor_arn, "MonitorName": $monitor_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates an existing cost anomaly monitor subscription.
#
# POST /
# operationId: UpdateAnomalySubscription
# --Subscribers item shape: {Address?: string, Type?: "EMAIL"|"SNS", Status?: "CONFIRMED"|"DECLINED"}
# --ThresholdExpression shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
export def "update-anomaly-subscription" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  subscription_arn: string # A cost anomaly subscription Amazon Resource Name (ARN).
  --threshold: float # (deprecated) The update to the threshold value for receiving notifications. This field has been deprecated. To update a threshold, use ThresholdExpression. Continued use of Threshold will be treated as shorthand syntax for a ThresholdExpression.Threshold has been deprecated in favor of ThresholdExpression (format: double)
  --frequency: string@frequency-completer # The update to the frequency value that subscribers receive notifications.
  --monitor-arn-list: list<string> # A list of cost anomaly monitor ARNs.
  --subscribers: list # The update to the subscriber list. — item shape: {Address?: string, Type?: "EMAIL"|"SNS", Status?: "CONFIRMED"|"DECLINED"}
  --subscription-name: string # The new name of the subscription.
  --threshold-expression: record # Use Expression to filter in various Cost Explorer APIs. Not all Expression types are supported in each API. Refer to the documentation for each specific API to see what is supported. There are two patterns: Simple dimension values. There are three types of simple dimension values: CostCategories, Tags, and Dimensions. Specify the CostCategories field to define a filter that acts on Cost Categories. Specify the Tags field to define a filter that acts on Cost Allocation Tags. Specify the Dimensions field to define a filter that acts on the DimensionValues (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_DimensionValues.html). For each filter type, you can set the dimension name and values for the filters that you plan to use. For example, you can filter for REGION==us-east-1 OR REGION==us-west-1. For GetRightsizingRecommendation, the Region is a full name (for example, REGION==US East (N. Virginia). The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "REGION", "Values": [ "us-east-1", “us-west-1” ] } } As shown in the previous example, lists of dimension values are combined with OR when applying the filter. You can also set different match options to further control how the filter behaves. Not all APIs support match options. Refer to the documentation for each specific API to see what is supported. For example, you can filter for linked account names that start with “a”. The corresponding Expression for this example is as follows: { "Dimensions": { "Key": "LINKED_ACCOUNT_NAME", "MatchOptions": [ "STARTS_WITH" ], "Values": [ "a" ] } } Compound Expression types with logical operations. You can use multiple Expression types and the logical operators AND/OR/NOT to create a list of one or more Expression objects. By doing this, you can filter by more advanced options. For example, you can filter by ((REGION == us-east-1 OR REGION == us-west-1) OR (TAG.Type == Type1)) AND (USAGE_TYPE != DataTransfer). The corresponding Expression for this example is as follows: { "And": [ {"Or": [ {"Dimensions": { "Key": "REGION", "Values": [ "us-east-1", "us-west-1" ] }}, {"Tags": { "Key": "TagName", "Values": ["Value1"] } } ]}, {"Not": {"Dimensions": { "Key": "USAGE_TYPE", "Values": ["DataTransfer"] }}} ] } Because each Expression can have only one operator, the service returns an error if more than one is specified. The following example shows an Expression object that creates an error: { "And": [ ... ], "Dimensions": { "Key": "USAGE_TYPE", "Values": [ "DataTransfer" ] } } The following is an example of the corresponding error message: "Expression has more than one roots. Only one root operator is allowed for each expression: And, Or, Not, Dimensions, Tags, CostCategories" For the GetRightsizingRecommendation action, a combination of OR and NOT isn't supported. OR isn't supported between different dimensions, or dimensions and tags. NOT operators aren't supported. Dimensions are also limited to LINKED_ACCOUNT, REGION, or RIGHTSIZING_TYPE. For the GetReservationPurchaseRecommendation action, only NOT is supported. AND and OR aren't supported. Dimensions are limited to LINKED_ACCOUNT. — shape: {Or?: list, And?: list, Not?: record, Dimensions?: record, Tags?: record, CostCategories?: record}
]: any -> record<SubscriptionArn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.UpdateAnomalySubscription")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SubscriptionArn": $subscription_arn, "Threshold": $threshold, "Frequency": $frequency, "MonitorArnList": $monitor_arn_list, "Subscribers": $subscribers, "SubscriptionName": $subscription_name, "ThresholdExpression": $threshold_expression} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates status for cost allocation tags in bulk, with maximum batch size of 20. If the tag status that's updated is the same as the existing tag status, the request doesn't fail. Instead, it doesn't have any effect on the tag status (for example, activating the active tag).
#
# POST /
# operationId: UpdateCostAllocationTagsStatus
# --CostAllocationTagsStatus item shape: {TagKey: string, Status: "Active"|"Inactive"}
export def "update-cost-allocation-tags-status" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  cost_allocation_tags_status: list # The list of CostAllocationTagStatusEntry objects that are used to update cost allocation tags status for this request. — item shape: {TagKey: string, Status: "Active"|"Inactive"}
]: any -> record<Errors: table<TagKey: string, Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.UpdateCostAllocationTagsStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CostAllocationTagsStatus": $cost_allocation_tags_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates an existing Cost Category. Changes made to the Cost Category rules will be used to categorize the current month’s expenses and future expenses. This won’t change categorization for the previous months.
#
# POST /
# operationId: UpdateCostCategoryDefinition
# --Rules item shape: {Value?: string, Rule?: record, InheritedValue?: record, Type?: "REGULAR"|"INHERITED_VALUE"}
# --SplitChargeRules item shape: {Source: string, Targets: list<string>, Method: "FIXED"|"PROPORTIONAL"|"EVEN", Parameters?: list}
export def "update-cost-category-definition" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  cost_category_arn: string # The unique identifier for your Cost Category.
  --effective-start: string # The period of time that you want the usage and costs for.
  rule_version: string@rule-version-completer # The rule schema version in this particular Cost Category.
  rules: list # The Expression object used to categorize costs. For more information, see CostCategoryRule (https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_CostCategoryRule.html). — item shape: {Value?: string, Rule?: record, InheritedValue?: record, Type?: "REGULAR"|"INHERITED_VALUE"}
  --default-value: string # The default value for the cost category.
  --split-charge-rules: list # The split charge rules used to allocate your charges between your Cost Category values. — item shape: {Source: string, Targets: list<string>, Method: "FIXED"|"PROPORTIONAL"|"EVEN", Parameters?: list}
]: any -> record<CostCategoryArn: string, EffectiveStart: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSInsightsIndexService.UpdateCostCategoryDefinition")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CostCategoryArn": $cost_category_arn, "EffectiveStart": $effective_start, "RuleVersion": $rule_version, "Rules": $rules, "DefaultValue": $default_value, "SplitChargeRules": $split_charge_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
