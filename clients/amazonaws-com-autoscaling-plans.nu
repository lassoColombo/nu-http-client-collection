# Auto-generated client for AWS Auto Scaling Plans v2018-01-06
# Source: https://api.apis.guru/v2/specs/amazonaws.com/autoscaling-plans/2018-01-06/openapi.json
# Auth: --token flag or $env.AWS_AUTO_SCALING_PLANS_TOKEN

const BASE_URL = "http://autoscaling-plans.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_AUTO_SCALING_PLANS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
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

def base-url-completer [] { ["http://autoscaling-plans.us-east-1.amazonaws.com" "http://autoscaling-plans.us-east-2.amazonaws.com" "http://autoscaling-plans.us-west-1.amazonaws.com" "http://autoscaling-plans.us-west-2.amazonaws.com" "http://autoscaling-plans.us-gov-west-1.amazonaws.com" "http://autoscaling-plans.us-gov-east-1.amazonaws.com" "http://autoscaling-plans.ca-central-1.amazonaws.com" "http://autoscaling-plans.eu-north-1.amazonaws.com" "http://autoscaling-plans.eu-west-1.amazonaws.com" "http://autoscaling-plans.eu-west-2.amazonaws.com" "http://autoscaling-plans.eu-west-3.amazonaws.com" "http://autoscaling-plans.eu-central-1.amazonaws.com" "http://autoscaling-plans.eu-south-1.amazonaws.com" "http://autoscaling-plans.af-south-1.amazonaws.com" "http://autoscaling-plans.ap-northeast-1.amazonaws.com" "http://autoscaling-plans.ap-northeast-2.amazonaws.com" "http://autoscaling-plans.ap-northeast-3.amazonaws.com" "http://autoscaling-plans.ap-southeast-1.amazonaws.com" "http://autoscaling-plans.ap-southeast-2.amazonaws.com" "http://autoscaling-plans.ap-east-1.amazonaws.com" "http://autoscaling-plans.ap-south-1.amazonaws.com" "http://autoscaling-plans.sa-east-1.amazonaws.com" "http://autoscaling-plans.me-south-1.amazonaws.com" "https://autoscaling-plans.us-east-1.amazonaws.com" "https://autoscaling-plans.us-east-2.amazonaws.com" "https://autoscaling-plans.us-west-1.amazonaws.com" "https://autoscaling-plans.us-west-2.amazonaws.com" "https://autoscaling-plans.us-gov-west-1.amazonaws.com" "https://autoscaling-plans.us-gov-east-1.amazonaws.com" "https://autoscaling-plans.ca-central-1.amazonaws.com" "https://autoscaling-plans.eu-north-1.amazonaws.com" "https://autoscaling-plans.eu-west-1.amazonaws.com" "https://autoscaling-plans.eu-west-2.amazonaws.com" "https://autoscaling-plans.eu-west-3.amazonaws.com" "https://autoscaling-plans.eu-central-1.amazonaws.com" "https://autoscaling-plans.eu-south-1.amazonaws.com" "https://autoscaling-plans.af-south-1.amazonaws.com" "https://autoscaling-plans.ap-northeast-1.amazonaws.com" "https://autoscaling-plans.ap-northeast-2.amazonaws.com" "https://autoscaling-plans.ap-northeast-3.amazonaws.com" "https://autoscaling-plans.ap-southeast-1.amazonaws.com" "https://autoscaling-plans.ap-southeast-2.amazonaws.com" "https://autoscaling-plans.ap-east-1.amazonaws.com" "https://autoscaling-plans.ap-south-1.amazonaws.com" "https://autoscaling-plans.sa-east-1.amazonaws.com" "https://autoscaling-plans.me-south-1.amazonaws.com" "http://autoscaling-plans.cn-north-1.amazonaws.com.cn" "http://autoscaling-plans.cn-northwest-1.amazonaws.com.cn" "https://autoscaling-plans.cn-north-1.amazonaws.com.cn" "https://autoscaling-plans.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AnyScaleScalingPlannerFrontendService.CreateScalingPlan"] }
def x-amz-target-completer-1 [] { ["AnyScaleScalingPlannerFrontendService.DeleteScalingPlan"] }
def x-amz-target-completer-2 [] { ["AnyScaleScalingPlannerFrontendService.DescribeScalingPlanResources"] }
def x-amz-target-completer-3 [] { ["AnyScaleScalingPlannerFrontendService.DescribeScalingPlans"] }
def service-namespace-completer [] { ["autoscaling" "dynamodb" "ec2" "ecs" "rds"] }
def scalable-dimension-completer [] { ["autoscaling:autoScalingGroup:DesiredCapacity" "dynamodb:index:ReadCapacityUnits" "dynamodb:index:WriteCapacityUnits" "dynamodb:table:ReadCapacityUnits" "dynamodb:table:WriteCapacityUnits" "ec2:spot-fleet-request:TargetCapacity" "ecs:service:DesiredCount" "rds:cluster:ReadReplicaCount"] }
def forecast-data-type-completer [] { ["CapacityForecast" "LoadForecast" "ScheduledActionMaxCapacity" "ScheduledActionMinCapacity"] }
def x-amz-target-completer-4 [] { ["AnyScaleScalingPlannerFrontendService.GetScalingPlanResourceForecastData"] }
def x-amz-target-completer-5 [] { ["AnyScaleScalingPlannerFrontendService.UpdateScalingPlan"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-scaling-plan" "delete-scaling-plan" "describe-scaling-plan-resources" "describe-scaling-plans" "get-scaling-plan-resource-forecast-data" "update-scaling-plan" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
# POST /
# operationId: CreateScalingPlan
export def "create-scaling-plan" [
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
  scaling_plan_name: string # The name of the scaling plan. Names cannot contain vertical bars, colons, or forward slashes.
  application_source: record # Represents an application source. — shape: {CloudFormationStackARN?: string, TagFilters?: list}
  scaling_instructions: list # The scaling instructions. For more information, see ScalingInstruction (https://docs.aws.amazon.com/autoscaling/plans/APIReference/API_ScalingInstruction.html) in the AWS Auto Scaling API Reference. — item shape: {ServiceNamespace: "autoscaling"|"ecs"|"ec2"|"rds"|"dynamodb", ResourceId: string, ScalableDimension: "autoscaling:autoScalingGroup:DesiredCapacity"|"ecs:service:DesiredCount"|"ec2:spot-fleet-request:TargetCapacity"|"rds:cluster:ReadReplicaCount"|"dynamodb:table:ReadCapacityUnits"|"dynamodb:table:WriteCapacityUnits"|"dynamodb:index:ReadCapacityUnits"|"dynamodb:index:WriteCapacityUnits", MinCapacity: int, MaxCapacity: int, TargetTrackingConfigurations: list, ... (8 more fields)}
]: any -> oneof<record<ScalingPlanVersion: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AnyScaleScalingPlannerFrontendService.CreateScalingPlan")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScalingPlanName": $scaling_plan_name, "ApplicationSource": $application_source, "ScalingInstructions": $scaling_instructions} | compact
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

# Deletes the specified scaling plan. Deleting a scaling plan deletes the underlying ScalingInstruction for all of the scalable resources that are covered by the plan. If the plan has launched resources or has scaling activities in progress, you must delete those resources separately.
#
# POST /
# operationId: DeleteScalingPlan
export def "delete-scaling-plan" [
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
  scaling_plan_name: string # The name of the scaling plan.
  scaling_plan_version: int # The version number of the scaling plan. Currently, the only valid value is 1.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AnyScaleScalingPlannerFrontendService.DeleteScalingPlan")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScalingPlanName": $scaling_plan_name, "ScalingPlanVersion": $scaling_plan_version} | compact
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

# Describes the scalable resources in the specified scaling plan.
#
# POST /
# operationId: DescribeScalingPlanResources
export def "describe-scaling-plan-resources" [
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
  scaling_plan_name: string # The name of the scaling plan.
  scaling_plan_version: int # The version number of the scaling plan. Currently, the only valid value is 1.
  --max-results: int # The maximum number of scalable resources to return. The value must be between 1 and 50. The default value is 50.
  --next-token: string # The token for the next set of results.
]: any -> oneof<record<ScalingPlanResources: table<ScalingPlanName: string, ScalingPlanVersion: int, ServiceNamespace: string, ResourceId: string, ScalableDimension: string, ScalingPolicies: list, ScalingStatusCode: string, ScalingStatusMessage: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AnyScaleScalingPlannerFrontendService.DescribeScalingPlanResources")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScalingPlanName": $scaling_plan_name, "ScalingPlanVersion": $scaling_plan_version, "MaxResults": $max_results, "NextToken": $next_token} | compact
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

# Describes one or more of your scaling plans.
#
# POST /
# operationId: DescribeScalingPlans
export def "describe-scaling-plans" [
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
  --scaling-plan-names: list<string> # The names of the scaling plans (up to 10). If you specify application sources, you cannot specify scaling plan names.
  --scaling-plan-version: int # The version number of the scaling plan. Currently, the only valid value is 1. If you specify a scaling plan version, you must also specify a scaling plan name.
  --application-sources: list # The sources for the applications (up to 10). If you specify scaling plan names, you cannot specify application sources. — item shape: {CloudFormationStackARN?: string, TagFilters?: list}
  --max-results: int # The maximum number of scalable resources to return. This value can be between 1 and 50. The default value is 50.
  --next-token: string # The token for the next set of results.
]: any -> oneof<record<ScalingPlans: table<ScalingPlanName: string, ScalingPlanVersion: int, ApplicationSource: record, ScalingInstructions: list, StatusCode: string, StatusMessage: string, StatusStartTime: string, CreationTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AnyScaleScalingPlannerFrontendService.DescribeScalingPlans")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScalingPlanNames": $scaling_plan_names, "ScalingPlanVersion": $scaling_plan_version, "ApplicationSources": $application_sources, "MaxResults": $max_results, "NextToken": $next_token} | compact
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

# Retrieves the forecast data for a scalable resource. Capacity forecasts are represented as predicted values, or data points, that are calculated using historical data points from a specified CloudWatch load metric. Data points are available for up to 56 days.
#
# POST /
# operationId: GetScalingPlanResourceForecastData
export def "get-scaling-plan-resource-forecast-data" [
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
  scaling_plan_name: string # The name of the scaling plan.
  scaling_plan_version: int # The version number of the scaling plan. Currently, the only valid value is 1.
  service_namespace: string@service-namespace-completer # The namespace of the AWS service. The only valid value is autoscaling.
  resource_id: string # The ID of the resource. This string consists of a prefix (autoScalingGroup) followed by the name of a specified Auto Scaling group (my-asg). Example: autoScalingGroup/my-asg.
  scalable_dimension: string@scalable-dimension-completer # The scalable dimension for the resource. The only valid value is autoscaling:autoScalingGroup:DesiredCapacity.
  forecast_data_type: string@forecast-data-type-completer # The type of forecast data to get. LoadForecast: The load metric forecast. CapacityForecast: The capacity forecast. ScheduledActionMinCapacity: The minimum capacity for each scheduled scaling action. This data is calculated as the larger of two values: the capacity forecast or the minimum capacity in the scaling instruction. ScheduledActionMaxCapacity: The maximum capacity for each scheduled scaling action. The calculation used is determined by the predictive scaling maximum capacity behavior setting in the scaling instruction.
  start_time: string # The inclusive start time of the time range for the forecast data to get. The date and time can be at most 56 days before the current date and time. (format: date-time)
  end_time: string # The exclusive end time of the time range for the forecast data to get. The maximum time duration between the start and end time is seven days. Although this parameter can accept a date and time that is more than two days in the future, the availability of forecast data has limits. AWS Auto Scaling only issues forecasts for periods of two days in advance. (format: date-time)
]: any -> oneof<record<Datapoints: table<Timestamp: string, Value: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AnyScaleScalingPlannerFrontendService.GetScalingPlanResourceForecastData")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScalingPlanName": $scaling_plan_name, "ScalingPlanVersion": $scaling_plan_version, "ServiceNamespace": $service_namespace, "ResourceId": $resource_id, "ScalableDimension": $scalable_dimension, "ForecastDataType": $forecast_data_type, "StartTime": $start_time, "EndTime": $end_time} | compact
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

# Updates the specified scaling plan. You cannot update a scaling plan if it is in the process of being created, updated, or deleted.
#
# POST /
# operationId: UpdateScalingPlan
export def "update-scaling-plan" [
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
  scaling_plan_name: string # The name of the scaling plan.
  scaling_plan_version: int # The version number of the scaling plan. The only valid value is 1. Currently, you cannot have multiple scaling plan versions.
  --application-source: record # Represents an application source. — shape: {CloudFormationStackARN?: string, TagFilters?: list}
  --scaling-instructions: list # The scaling instructions. For more information, see ScalingInstruction (https://docs.aws.amazon.com/autoscaling/plans/APIReference/API_ScalingInstruction.html) in the AWS Auto Scaling API Reference. — item shape: {ServiceNamespace: "autoscaling"|"ecs"|"ec2"|"rds"|"dynamodb", ResourceId: string, ScalableDimension: "autoscaling:autoScalingGroup:DesiredCapacity"|"ecs:service:DesiredCount"|"ec2:spot-fleet-request:TargetCapacity"|"rds:cluster:ReadReplicaCount"|"dynamodb:table:ReadCapacityUnits"|"dynamodb:table:WriteCapacityUnits"|"dynamodb:index:ReadCapacityUnits"|"dynamodb:index:WriteCapacityUnits", MinCapacity: int, MaxCapacity: int, TargetTrackingConfigurations: list, ... (8 more fields)}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AnyScaleScalingPlannerFrontendService.UpdateScalingPlan")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScalingPlanName": $scaling_plan_name, "ScalingPlanVersion": $scaling_plan_version, "ApplicationSource": $application_source, "ScalingInstructions": $scaling_instructions} | compact
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
