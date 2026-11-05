# Auto-generated client for AWS Compute Optimizer v2019-11-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/compute-optimizer/2019-11-01/openapi.json
# Auth: --token flag or $env.AWS_COMPUTE_OPTIMIZER_TOKEN

const BASE_URL = "http://compute-optimizer.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_COMPUTE_OPTIMIZER_TOKEN | default "" }
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

def base-url-completer [] { ["http://compute-optimizer.us-east-1.amazonaws.com" "http://compute-optimizer.us-east-2.amazonaws.com" "http://compute-optimizer.us-west-1.amazonaws.com" "http://compute-optimizer.us-west-2.amazonaws.com" "http://compute-optimizer.us-gov-west-1.amazonaws.com" "http://compute-optimizer.us-gov-east-1.amazonaws.com" "http://compute-optimizer.ca-central-1.amazonaws.com" "http://compute-optimizer.eu-north-1.amazonaws.com" "http://compute-optimizer.eu-west-1.amazonaws.com" "http://compute-optimizer.eu-west-2.amazonaws.com" "http://compute-optimizer.eu-west-3.amazonaws.com" "http://compute-optimizer.eu-central-1.amazonaws.com" "http://compute-optimizer.eu-south-1.amazonaws.com" "http://compute-optimizer.af-south-1.amazonaws.com" "http://compute-optimizer.ap-northeast-1.amazonaws.com" "http://compute-optimizer.ap-northeast-2.amazonaws.com" "http://compute-optimizer.ap-northeast-3.amazonaws.com" "http://compute-optimizer.ap-southeast-1.amazonaws.com" "http://compute-optimizer.ap-southeast-2.amazonaws.com" "http://compute-optimizer.ap-east-1.amazonaws.com" "http://compute-optimizer.ap-south-1.amazonaws.com" "http://compute-optimizer.sa-east-1.amazonaws.com" "http://compute-optimizer.me-south-1.amazonaws.com" "https://compute-optimizer.us-east-1.amazonaws.com" "https://compute-optimizer.us-east-2.amazonaws.com" "https://compute-optimizer.us-west-1.amazonaws.com" "https://compute-optimizer.us-west-2.amazonaws.com" "https://compute-optimizer.us-gov-west-1.amazonaws.com" "https://compute-optimizer.us-gov-east-1.amazonaws.com" "https://compute-optimizer.ca-central-1.amazonaws.com" "https://compute-optimizer.eu-north-1.amazonaws.com" "https://compute-optimizer.eu-west-1.amazonaws.com" "https://compute-optimizer.eu-west-2.amazonaws.com" "https://compute-optimizer.eu-west-3.amazonaws.com" "https://compute-optimizer.eu-central-1.amazonaws.com" "https://compute-optimizer.eu-south-1.amazonaws.com" "https://compute-optimizer.af-south-1.amazonaws.com" "https://compute-optimizer.ap-northeast-1.amazonaws.com" "https://compute-optimizer.ap-northeast-2.amazonaws.com" "https://compute-optimizer.ap-northeast-3.amazonaws.com" "https://compute-optimizer.ap-southeast-1.amazonaws.com" "https://compute-optimizer.ap-southeast-2.amazonaws.com" "https://compute-optimizer.ap-east-1.amazonaws.com" "https://compute-optimizer.ap-south-1.amazonaws.com" "https://compute-optimizer.sa-east-1.amazonaws.com" "https://compute-optimizer.me-south-1.amazonaws.com" "http://compute-optimizer.cn-north-1.amazonaws.com.cn" "http://compute-optimizer.cn-northwest-1.amazonaws.com.cn" "https://compute-optimizer.cn-north-1.amazonaws.com.cn" "https://compute-optimizer.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-type-completer [] { ["AutoScalingGroup" "EbsVolume" "Ec2Instance" "EcsService" "LambdaFunction" "NotApplicable"] }
def x-amz-target-completer [] { ["ComputeOptimizerService.DeleteRecommendationPreferences"] }
def x-amz-target-completer-1 [] { ["ComputeOptimizerService.DescribeRecommendationExportJobs"] }
def file-format-completer [] { ["Csv"] }
def x-amz-target-completer-2 [] { ["ComputeOptimizerService.ExportAutoScalingGroupRecommendations"] }
def x-amz-target-completer-3 [] { ["ComputeOptimizerService.ExportEBSVolumeRecommendations"] }
def x-amz-target-completer-4 [] { ["ComputeOptimizerService.ExportEC2InstanceRecommendations"] }
def x-amz-target-completer-5 [] { ["ComputeOptimizerService.ExportECSServiceRecommendations"] }
def x-amz-target-completer-6 [] { ["ComputeOptimizerService.ExportLambdaFunctionRecommendations"] }
def x-amz-target-completer-7 [] { ["ComputeOptimizerService.GetAutoScalingGroupRecommendations"] }
def x-amz-target-completer-8 [] { ["ComputeOptimizerService.GetEBSVolumeRecommendations"] }
def x-amz-target-completer-9 [] { ["ComputeOptimizerService.GetEC2InstanceRecommendations"] }
def stat-completer [] { ["Average" "Maximum"] }
def x-amz-target-completer-10 [] { ["ComputeOptimizerService.GetEC2RecommendationProjectedMetrics"] }
def x-amz-target-completer-11 [] { ["ComputeOptimizerService.GetECSServiceRecommendationProjectedMetrics"] }
def x-amz-target-completer-12 [] { ["ComputeOptimizerService.GetECSServiceRecommendations"] }
def x-amz-target-completer-13 [] { ["ComputeOptimizerService.GetEffectiveRecommendationPreferences"] }
def x-amz-target-completer-14 [] { ["ComputeOptimizerService.GetEnrollmentStatus"] }
def x-amz-target-completer-15 [] { ["ComputeOptimizerService.GetEnrollmentStatusesForOrganization"] }
def x-amz-target-completer-16 [] { ["ComputeOptimizerService.GetLambdaFunctionRecommendations"] }
def x-amz-target-completer-17 [] { ["ComputeOptimizerService.GetRecommendationPreferences"] }
def x-amz-target-completer-18 [] { ["ComputeOptimizerService.GetRecommendationSummaries"] }
def enhanced-infrastructure-metrics-completer [] { ["Active" "Inactive"] }
def inferred-workload-types-completer [] { ["Active" "Inactive"] }
def x-amz-target-completer-19 [] { ["ComputeOptimizerService.PutRecommendationPreferences"] }
def status-completer [] { ["Active" "Failed" "Inactive" "Pending"] }
def x-amz-target-completer-20 [] { ["ComputeOptimizerService.UpdateEnrollmentStatus"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-recommendation-preferences" "describe-recommendation-export-jobs" "export-auto-scaling-group-recommendations" "export-ebs-volume-recommendations" "export-ec2-instance-recommendations" "export-ecs-service-recommendations" "export-lambda-function-recommendations" "get-auto-scaling-group-recommendations" "get-ebs-volume-recommendations" "get-ec2-instance-recommendations" "get-ec2-recommendation-projected-metrics" "get-ecs-service-recommendation-projected-metrics" "get-ecs-service-recommendations" "get-effective-recommendation-preferences" "get-enrollment-status" "get-enrollment-statuses-for-organization" "get-lambda-function-recommendations" "get-recommendation-preferences" "get-recommendation-summaries" "put-recommendation-preferences" "update-enrollment-status" "commands"] | sort) } | get name | first)
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

# Deletes a recommendation preference, such as enhanced infrastructure metrics. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide.
#
# POST /
# operationId: DeleteRecommendationPreferences
export def "delete-recommendation-preferences" [
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
  resource_type: string@resource-type-completer # The target resource type of the recommendation preference to delete. The Ec2Instance option encompasses standalone instances and instances that are part of Auto Scaling groups. The AutoScalingGroup option encompasses only instances that are part of an Auto Scaling group. The valid values for this parameter are Ec2Instance and AutoScalingGroup.
  --scope: record # Describes the scope of a recommendation preference. Recommendation preferences can be created at the organization level (for management accounts of an organization only), account level, and resource level. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide. You cannot create recommendation preferences for Auto Scaling groups at the organization and account levels. You can create recommendation preferences for Auto Scaling groups only at the resource level by specifying a scope name of ResourceArn and a scope value of the Auto Scaling group Amazon Resource Name (ARN). This will configure the preference for all instances that are part of the specified Auto Scaling group. You also cannot create recommendation preferences at the resource level for instances that are part of an Auto Scaling group. You can create recommendation preferences at the resource level only for standalone instances. — shape: {name?: "Organization"|"AccountId"|"ResourceArn", value?: string}
  recommendation_preference_names: list<string> # The name of the recommendation preference to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.DeleteRecommendationPreferences")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"resourceType": $resource_type, "scope": $scope, "recommendationPreferenceNames": $recommendation_preference_names} | compact
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

# Describes recommendation export jobs created in the last seven days. Use the ExportAutoScalingGroupRecommendations or ExportEC2InstanceRecommendations actions to request an export of your recommendations. Then use the DescribeRecommendationExportJobs action to view your export jobs.
#
# POST /
# operationId: DescribeRecommendationExportJobs
export def "describe-recommendation-export-jobs" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  --job-ids: list<string> # The identification numbers of the export jobs to return. An export job ID is returned when you create an export using the ExportAutoScalingGroupRecommendations or ExportEC2InstanceRecommendations actions. All export jobs created in the last seven days are returned if this parameter is omitted.
  --filters: list # An array of objects to specify a filter that returns a more specific list of export jobs. — item shape: {name?: "ResourceType"|"JobStatus", values?: list<string>}
  --next-token-body: string # The token to advance to the next page of export jobs. (body field)
  --max-results-body: int # The maximum number of export jobs to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value. (body field)
]: any -> oneof<record<recommendationExportJobs: table<jobId: string, destination: record, resourceType: string, status: string, creationTimestamp: string, lastUpdatedTimestamp: string, failureReason: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.DescribeRecommendationExportJobs")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"jobIds": $job_ids, "filters": $filters, "nextToken": $next_token_body, "maxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Exports optimization recommendations for Auto Scaling groups. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Auto Scaling group export job in progress per Amazon Web Services Region.
#
# POST /
# operationId: ExportAutoScalingGroupRecommendations
export def "export-auto-scaling-group-recommendations" [
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
  --account-ids: list<string> # The IDs of the Amazon Web Services accounts for which to export Auto Scaling group recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to export recommendations. This parameter cannot be specified together with the include member accounts parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the include member accounts parameter, is omitted. You can specify multiple account IDs per request.
  --filters: list # An array of objects to specify a filter that exports a more specific set of Auto Scaling group recommendations. — item shape: {name?: "Finding"|"FindingReasonCodes"|"RecommendationSourceType", values?: list<string>}
  --fields-to-export: list<string> # The recommendations data to include in the export file. For more information about the fields that can be exported, see Exported files (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html#exported-files) in the Compute Optimizer User Guide.
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: string, keyPrefix?: string}
  --file-format: string@file-format-completer # The format of the export file. The only export file format currently supported is Csv.
  --include-member-accounts: oneof<nothing, bool> # Indicates whether to include recommendations for resources in all member accounts of the organization if your account is the management account of an organization. The member accounts must also be opted in to Compute Optimizer, and trusted access for Compute Optimizer must be enabled in the organization account. For more information, see Compute Optimizer and Amazon Web Services Organizations trusted access (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html#trusted-service-access) in the Compute Optimizer User Guide. Recommendations for member accounts of the organization are not included in the export file if this parameter is omitted. This parameter cannot be specified together with the account IDs parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the account IDs parameter, is omitted.
  --recommendation-preferences: record # Describes the recommendation preferences to return in the response of a GetAutoScalingGroupRecommendations, GetEC2InstanceRecommendations, and GetEC2RecommendationProjectedMetrics request. — shape: {cpuVendorArchitectures?: list<string>}
]: any -> oneof<record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.ExportAutoScalingGroupRecommendations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"accountIds": $account_ids, "filters": $filters, "fieldsToExport": $fields_to_export, "s3DestinationConfig": $s3_destination_config, "fileFormat": $file_format, "includeMemberAccounts": $include_member_accounts, "recommendationPreferences": $recommendation_preferences} | compact
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

# Exports optimization recommendations for Amazon EBS volumes. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Amazon EBS volume export job in progress per Amazon Web Services Region.
#
# POST /
# operationId: ExportEBSVolumeRecommendations
export def "export-ebs-volume-recommendations" [
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
  --account-ids: list<string> # The IDs of the Amazon Web Services accounts for which to export Amazon EBS volume recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to export recommendations. This parameter cannot be specified together with the include member accounts parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the include member accounts parameter, is omitted. You can specify multiple account IDs per request.
  --filters: list # An array of objects to specify a filter that exports a more specific set of Amazon EBS volume recommendations. — item shape: {name?: "Finding", values?: list<string>}
  --fields-to-export: list<string> # The recommendations data to include in the export file. For more information about the fields that can be exported, see Exported files (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html#exported-files) in the Compute Optimizer User Guide.
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: string, keyPrefix?: string}
  --file-format: string@file-format-completer # The format of the export file. The only export file format currently supported is Csv.
  --include-member-accounts: oneof<nothing, bool> # Indicates whether to include recommendations for resources in all member accounts of the organization if your account is the management account of an organization. The member accounts must also be opted in to Compute Optimizer, and trusted access for Compute Optimizer must be enabled in the organization account. For more information, see Compute Optimizer and Amazon Web Services Organizations trusted access (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html#trusted-service-access) in the Compute Optimizer User Guide. Recommendations for member accounts of the organization are not included in the export file if this parameter is omitted. This parameter cannot be specified together with the account IDs parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the account IDs parameter, is omitted.
]: any -> oneof<record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.ExportEBSVolumeRecommendations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"accountIds": $account_ids, "filters": $filters, "fieldsToExport": $fields_to_export, "s3DestinationConfig": $s3_destination_config, "fileFormat": $file_format, "includeMemberAccounts": $include_member_accounts} | compact
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

# Exports optimization recommendations for Amazon EC2 instances. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Amazon EC2 instance export job in progress per Amazon Web Services Region.
#
# POST /
# operationId: ExportEC2InstanceRecommendations
export def "export-ec2-instance-recommendations" [
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
  --account-ids: list<string> # The IDs of the Amazon Web Services accounts for which to export instance recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to export recommendations. This parameter cannot be specified together with the include member accounts parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the include member accounts parameter, is omitted. You can specify multiple account IDs per request.
  --filters: list # An array of objects to specify a filter that exports a more specific set of instance recommendations. — item shape: {name?: "Finding"|"FindingReasonCodes"|"RecommendationSourceType", values?: list<string>}
  --fields-to-export: list<string> # The recommendations data to include in the export file. For more information about the fields that can be exported, see Exported files (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html#exported-files) in the Compute Optimizer User Guide.
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: string, keyPrefix?: string}
  --file-format: string@file-format-completer # The format of the export file. The only export file format currently supported is Csv.
  --include-member-accounts: oneof<nothing, bool> # Indicates whether to include recommendations for resources in all member accounts of the organization if your account is the management account of an organization. The member accounts must also be opted in to Compute Optimizer, and trusted access for Compute Optimizer must be enabled in the organization account. For more information, see Compute Optimizer and Amazon Web Services Organizations trusted access (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html#trusted-service-access) in the Compute Optimizer User Guide. Recommendations for member accounts of the organization are not included in the export file if this parameter is omitted. Recommendations for member accounts are not included in the export if this parameter, or the account IDs parameter, is omitted.
  --recommendation-preferences: record # Describes the recommendation preferences to return in the response of a GetAutoScalingGroupRecommendations, GetEC2InstanceRecommendations, and GetEC2RecommendationProjectedMetrics request. — shape: {cpuVendorArchitectures?: list<string>}
]: any -> oneof<record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.ExportEC2InstanceRecommendations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"accountIds": $account_ids, "filters": $filters, "fieldsToExport": $fields_to_export, "s3DestinationConfig": $s3_destination_config, "fileFormat": $file_format, "includeMemberAccounts": $include_member_accounts, "recommendationPreferences": $recommendation_preferences} | compact
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

# Exports optimization recommendations for Amazon ECS services on Fargate. Recommendations are exported in a CSV file, and its metadata in a JSON file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can only have one Amazon ECS service export job in progress per Amazon Web Services Region.
#
# POST /
# operationId: ExportECSServiceRecommendations
export def "export-ecs-service-recommendations" [
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
  --account-ids: list<string> # The Amazon Web Services account IDs for the export Amazon ECS service recommendations. If your account is the management account or the delegated administrator of an organization, use this parameter to specify the member account you want to export recommendations to. This parameter can't be specified together with the include member accounts parameter. The parameters are mutually exclusive. If this parameter or the include member accounts parameter is omitted, the recommendations for member accounts aren't included in the export. You can specify multiple account IDs per request.
  --filters: list # An array of objects to specify a filter that exports a more specific set of Amazon ECS service recommendations. — item shape: {name?: "Finding"|"FindingReasonCode", values?: list<string>}
  --fields-to-export: list<string> # The recommendations data to include in the export file. For more information about the fields that can be exported, see Exported files (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html#exported-files) in the Compute Optimizer User Guide.
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: string, keyPrefix?: string}
  --file-format: string@file-format-completer # The format of the export file. The CSV file is the only export file format currently supported.
  --include-member-accounts: oneof<nothing, bool> # If your account is the management account or the delegated administrator of an organization, this parameter indicates whether to include recommendations for resources in all member accounts of the organization. The member accounts must also be opted in to Compute Optimizer, and trusted access for Compute Optimizer must be enabled in the organization account. For more information, see Compute Optimizer and Amazon Web Services Organizations trusted access (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html#trusted-service-access) in the Compute Optimizer User Guide. If this parameter is omitted, recommendations for member accounts of the organization aren't included in the export file. If this parameter or the account ID parameter is omitted, recommendations for member accounts aren't included in the export.
]: any -> oneof<record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.ExportECSServiceRecommendations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"accountIds": $account_ids, "filters": $filters, "fieldsToExport": $fields_to_export, "s3DestinationConfig": $s3_destination_config, "fileFormat": $file_format, "includeMemberAccounts": $include_member_accounts} | compact
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

# Exports optimization recommendations for Lambda functions. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Lambda function export job in progress per Amazon Web Services Region.
#
# POST /
# operationId: ExportLambdaFunctionRecommendations
export def "export-lambda-function-recommendations" [
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
  --account-ids: list<string> # The IDs of the Amazon Web Services accounts for which to export Lambda function recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to export recommendations. This parameter cannot be specified together with the include member accounts parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the include member accounts parameter, is omitted. You can specify multiple account IDs per request.
  --filters: list # An array of objects to specify a filter that exports a more specific set of Lambda function recommendations. — item shape: {name?: "Finding"|"FindingReasonCode", values?: list<string>}
  --fields-to-export: list<string> # The recommendations data to include in the export file. For more information about the fields that can be exported, see Exported files (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html#exported-files) in the Compute Optimizer User Guide.
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: string, keyPrefix?: string}
  --file-format: string@file-format-completer # The format of the export file. The only export file format currently supported is Csv.
  --include-member-accounts: oneof<nothing, bool> # Indicates whether to include recommendations for resources in all member accounts of the organization if your account is the management account of an organization. The member accounts must also be opted in to Compute Optimizer, and trusted access for Compute Optimizer must be enabled in the organization account. For more information, see Compute Optimizer and Amazon Web Services Organizations trusted access (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html#trusted-service-access) in the Compute Optimizer User Guide. Recommendations for member accounts of the organization are not included in the export file if this parameter is omitted. This parameter cannot be specified together with the account IDs parameter. The parameters are mutually exclusive. Recommendations for member accounts are not included in the export if this parameter, or the account IDs parameter, is omitted.
]: any -> oneof<record<jobId: string, s3Destination: record<bucket: string, key: string, metadataKey: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.ExportLambdaFunctionRecommendations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"accountIds": $account_ids, "filters": $filters, "fieldsToExport": $fields_to_export, "s3DestinationConfig": $s3_destination_config, "fileFormat": $file_format, "includeMemberAccounts": $include_member_accounts} | compact
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

# Returns Auto Scaling group recommendations. Compute Optimizer generates recommendations for Amazon EC2 Auto Scaling groups that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /
# operationId: GetAutoScalingGroupRecommendations
export def "get-auto-scaling-group-recommendations" [
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
  --account-ids: list<string> # The ID of the Amazon Web Services account for which to return Auto Scaling group recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to return Auto Scaling group recommendations. Only one account ID can be specified per request.
  --auto-scaling-group-arns: list<string> # The Amazon Resource Name (ARN) of the Auto Scaling groups for which to return recommendations.
  --next-token: string # The token to advance to the next page of Auto Scaling group recommendations.
  --max-results: int # The maximum number of Auto Scaling group recommendations to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value.
  --filters: list # An array of objects to specify a filter that returns a more specific list of Auto Scaling group recommendations. — item shape: {name?: "Finding"|"FindingReasonCodes"|"RecommendationSourceType", values?: list<string>}
  --recommendation-preferences: record # Describes the recommendation preferences to return in the response of a GetAutoScalingGroupRecommendations, GetEC2InstanceRecommendations, and GetEC2RecommendationProjectedMetrics request. — shape: {cpuVendorArchitectures?: list<string>}
]: any -> oneof<record<nextToken: string, autoScalingGroupRecommendations: table<accountId: string, autoScalingGroupArn: string, autoScalingGroupName: string, finding: string, utilizationMetrics: list, lookBackPeriodInDays: float, currentConfiguration: record, recommendationOptions: list, lastRefreshTimestamp: string, currentPerformanceRisk: string, effectiveRecommendationPreferences: record, inferredWorkloadTypes: list>, errors: table<identifier: string, code: string, message: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetAutoScalingGroupRecommendations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"accountIds": $account_ids, "autoScalingGroupArns": $auto_scaling_group_arns, "nextToken": $next_token, "maxResults": $max_results, "filters": $filters, "recommendationPreferences": $recommendation_preferences} | compact
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

# Returns Amazon Elastic Block Store (Amazon EBS) volume recommendations. Compute Optimizer generates recommendations for Amazon EBS volumes that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /
# operationId: GetEBSVolumeRecommendations
export def "get-ebs-volume-recommendations" [
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
  --volume-arns: list<string> # The Amazon Resource Name (ARN) of the volumes for which to return recommendations.
  --next-token: string # The token to advance to the next page of volume recommendations.
  --max-results: int # The maximum number of volume recommendations to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value.
  --filters: list # An array of objects to specify a filter that returns a more specific list of volume recommendations. — item shape: {name?: "Finding", values?: list<string>}
  --account-ids: list<string> # The ID of the Amazon Web Services account for which to return volume recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to return volume recommendations. Only one account ID can be specified per request.
]: any -> oneof<record<nextToken: string, volumeRecommendations: table<volumeArn: string, accountId: string, currentConfiguration: record, finding: string, utilizationMetrics: list, lookBackPeriodInDays: float, volumeRecommendationOptions: list, lastRefreshTimestamp: string, currentPerformanceRisk: string>, errors: table<identifier: string, code: string, message: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetEBSVolumeRecommendations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"volumeArns": $volume_arns, "nextToken": $next_token, "maxResults": $max_results, "filters": $filters, "accountIds": $account_ids} | compact
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

# Returns Amazon EC2 instance recommendations. Compute Optimizer generates recommendations for Amazon Elastic Compute Cloud (Amazon EC2) instances that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /
# operationId: GetEC2InstanceRecommendations
export def "get-ec2-instance-recommendations" [
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
  --instance-arns: list<string> # The Amazon Resource Name (ARN) of the instances for which to return recommendations.
  --next-token: string # The token to advance to the next page of instance recommendations.
  --max-results: int # The maximum number of instance recommendations to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value.
  --filters: list # An array of objects to specify a filter that returns a more specific list of instance recommendations. — item shape: {name?: "Finding"|"FindingReasonCodes"|"RecommendationSourceType", values?: list<string>}
  --account-ids: list<string> # The ID of the Amazon Web Services account for which to return instance recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to return instance recommendations. Only one account ID can be specified per request.
  --recommendation-preferences: record # Describes the recommendation preferences to return in the response of a GetAutoScalingGroupRecommendations, GetEC2InstanceRecommendations, and GetEC2RecommendationProjectedMetrics request. — shape: {cpuVendorArchitectures?: list<string>}
]: any -> oneof<record<nextToken: string, instanceRecommendations: table<instanceArn: string, accountId: string, instanceName: string, currentInstanceType: string, finding: string, findingReasonCodes: list, utilizationMetrics: list, lookBackPeriodInDays: float, recommendationOptions: list, recommendationSources: list, lastRefreshTimestamp: string, currentPerformanceRisk: string, effectiveRecommendationPreferences: record, inferredWorkloadTypes: list, instanceState: string>, errors: table<identifier: string, code: string, message: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetEC2InstanceRecommendations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"instanceArns": $instance_arns, "nextToken": $next_token, "maxResults": $max_results, "filters": $filters, "accountIds": $account_ids, "recommendationPreferences": $recommendation_preferences} | compact
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

# Returns the projected utilization metrics of Amazon EC2 instance recommendations. The Cpu and Memory metrics are the only projected utilization metrics returned when you run this action. Additionally, the Memory metric is returned only for resources that have the unified CloudWatch agent installed on them. For more information, see Enabling Memory Utilization with the CloudWatch Agent (https://docs.aws.amazon.com/compute-optimizer/latest/ug/metrics.html#cw-agent).
#
# POST /
# operationId: GetEC2RecommendationProjectedMetrics
export def "get-ec2-recommendation-projected-metrics" [
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
  instance_arn: string # The Amazon Resource Name (ARN) of the instances for which to return recommendation projected metrics.
  stat: string@stat-completer # The statistic of the projected metrics.
  period: int # The granularity, in seconds, of the projected metrics data points.
  start_time: string # The timestamp of the first projected metrics data point to return. (format: date-time)
  end_time: string # The timestamp of the last projected metrics data point to return. (format: date-time)
  --recommendation-preferences: record # Describes the recommendation preferences to return in the response of a GetAutoScalingGroupRecommendations, GetEC2InstanceRecommendations, and GetEC2RecommendationProjectedMetrics request. — shape: {cpuVendorArchitectures?: list<string>}
]: any -> oneof<record<recommendedOptionProjectedMetrics: table<recommendedInstanceType: string, rank: int, projectedMetrics: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetEC2RecommendationProjectedMetrics")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"instanceArn": $instance_arn, "stat": $stat, "period": $period, "startTime": $start_time, "endTime": $end_time, "recommendationPreferences": $recommendation_preferences} | compact
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

# Returns the projected metrics of Amazon ECS service recommendations.
#
# POST /
# operationId: GetECSServiceRecommendationProjectedMetrics
export def "get-ecs-service-recommendation-projected-metrics" [
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
  service_arn: string # The ARN that identifies the Amazon ECS service. The following is the format of the ARN: arn:aws:ecs:region:aws_account_id:service/cluster-name/service-name
  stat: string@stat-completer # The statistic of the projected metrics.
  period: int # The granularity, in seconds, of the projected metrics data points.
  start_time: string # The timestamp of the first projected metrics data point to return. (format: date-time)
  end_time: string # The timestamp of the last projected metrics data point to return. (format: date-time)
]: any -> oneof<record<recommendedOptionProjectedMetrics: table<recommendedCpuUnits: int, recommendedMemorySize: int, projectedMetrics: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetECSServiceRecommendationProjectedMetrics")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"serviceArn": $service_arn, "stat": $stat, "period": $period, "startTime": $start_time, "endTime": $end_time} | compact
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

# Returns Amazon ECS service recommendations. Compute Optimizer generates recommendations for Amazon ECS services on Fargate that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /
# operationId: GetECSServiceRecommendations
export def "get-ecs-service-recommendations" [
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
  --service-arns: list<string> # The ARN that identifies the Amazon ECS service. The following is the format of the ARN: arn:aws:ecs:region:aws_account_id:service/cluster-name/service-name
  --next-token: string # The token to advance to the next page of Amazon ECS service recommendations.
  --max-results: int # The maximum number of Amazon ECS service recommendations to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value.
  --filters: list # An array of objects to specify a filter that returns a more specific list of Amazon ECS service recommendations. — item shape: {name?: "Finding"|"FindingReasonCode", values?: list<string>}
  --account-ids: list<string> # Return the Amazon ECS service recommendations to the specified Amazon Web Services account IDs. If your account is the management account or the delegated administrator of an organization, use this parameter to return the Amazon ECS service recommendations to specific member accounts. You can only specify one account ID per request.
]: any -> oneof<record<nextToken: string, ecsServiceRecommendations: table<serviceArn: string, accountId: string, currentServiceConfiguration: record, utilizationMetrics: list, lookbackPeriodInDays: float, launchType: string, lastRefreshTimestamp: string, finding: string, findingReasonCodes: list, serviceRecommendationOptions: list, currentPerformanceRisk: string>, errors: table<identifier: string, code: string, message: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetECSServiceRecommendations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"serviceArns": $service_arns, "nextToken": $next_token, "maxResults": $max_results, "filters": $filters, "accountIds": $account_ids} | compact
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

# Returns the recommendation preferences that are in effect for a given resource, such as enhanced infrastructure metrics. Considers all applicable preferences that you might have set at the resource, account, and organization level. When you create a recommendation preference, you can set its status to Active or Inactive. Use this action to view the recommendation preferences that are in effect, or Active.
#
# POST /
# operationId: GetEffectiveRecommendationPreferences
export def "get-effective-recommendation-preferences" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the resource for which to confirm effective recommendation preferences. Only EC2 instance and Auto Scaling group ARNs are currently supported.
]: any -> oneof<record<enhancedInfrastructureMetrics: string, externalMetricsPreference: record<source: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetEffectiveRecommendationPreferences")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"resourceArn": $resource_arn} | compact
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

# Returns the enrollment (opt in) status of an account to the Compute Optimizer service. If the account is the management account of an organization, this action also confirms the enrollment status of member accounts of the organization. Use the GetEnrollmentStatusesForOrganization action to get detailed information about the enrollment status of member accounts of an organization.
#
# POST /
# operationId: GetEnrollmentStatus
export def "get-enrollment-status" [
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
  --body: record
]: any -> oneof<record<status: string, statusReason: string, memberAccountsEnrolled: bool, lastUpdatedTimestamp: string, numberOfMemberAccountsOptedIn: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetEnrollmentStatus")
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

# Returns the Compute Optimizer enrollment (opt-in) status of organization member accounts, if your account is an organization management account. To get the enrollment status of standalone accounts, use the GetEnrollmentStatus action.
#
# POST /
# operationId: GetEnrollmentStatusesForOrganization
export def "get-enrollment-statuses-for-organization" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  --filters: list # An array of objects to specify a filter that returns a more specific list of account enrollment statuses. — item shape: {name?: "Status", values?: list<string>}
  --next-token-body: string # The token to advance to the next page of account enrollment statuses. (body field)
  --max-results-body: int # The maximum number of account enrollment statuses to return with a single request. You can specify up to 100 statuses to return with each request. To retrieve the remaining results, make another request with the returned nextToken value. (body field)
]: any -> oneof<record<accountEnrollmentStatuses: table<accountId: string, status: string, statusReason: string, lastUpdatedTimestamp: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetEnrollmentStatusesForOrganization")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"filters": $filters, "nextToken": $next_token_body, "maxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns Lambda function recommendations. Compute Optimizer generates recommendations for functions that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /
# operationId: GetLambdaFunctionRecommendations
export def "get-lambda-function-recommendations" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  --function-arns: list<string> # The Amazon Resource Name (ARN) of the functions for which to return recommendations. You can specify a qualified or unqualified ARN. If you specify an unqualified ARN without a function version suffix, Compute Optimizer will return recommendations for the latest ($LATEST) version of the function. If you specify a qualified ARN with a version suffix, Compute Optimizer will return recommendations for the specified function version. For more information about using function versions, see Using versions (https://docs.aws.amazon.com/lambda/latest/dg/configuration-versions.html#versioning-versions-using) in the Lambda Developer Guide.
  --account-ids: list<string> # The ID of the Amazon Web Services account for which to return function recommendations. If your account is the management account of an organization, use this parameter to specify the member account for which you want to return function recommendations. Only one account ID can be specified per request.
  --filters: list # An array of objects to specify a filter that returns a more specific list of function recommendations. — item shape: {name?: "Finding"|"FindingReasonCode", values?: list<string>}
  --next-token-body: string # The token to advance to the next page of function recommendations. (body field)
  --max-results-body: int # The maximum number of function recommendations to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value. (body field)
]: any -> oneof<record<nextToken: string, lambdaFunctionRecommendations: table<functionArn: string, functionVersion: string, accountId: string, currentMemorySize: int, numberOfInvocations: int, utilizationMetrics: list, lookbackPeriodInDays: float, lastRefreshTimestamp: string, finding: string, findingReasonCodes: list, memorySizeRecommendationOptions: list, currentPerformanceRisk: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetLambdaFunctionRecommendations")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"functionArns": $function_arns, "accountIds": $account_ids, "filters": $filters, "nextToken": $next_token_body, "maxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns existing recommendation preferences, such as enhanced infrastructure metrics. Use the scope parameter to specify which preferences to return. You can specify to return preferences for an organization, a specific account ID, or a specific EC2 instance or Auto Scaling group Amazon Resource Name (ARN). For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide.
#
# POST /
# operationId: GetRecommendationPreferences
export def "get-recommendation-preferences" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  resource_type: string@resource-type-completer # The target resource type of the recommendation preference for which to return preferences. The Ec2Instance option encompasses standalone instances and instances that are part of Auto Scaling groups. The AutoScalingGroup option encompasses only instances that are part of an Auto Scaling group. The valid values for this parameter are Ec2Instance and AutoScalingGroup.
  --scope: record # Describes the scope of a recommendation preference. Recommendation preferences can be created at the organization level (for management accounts of an organization only), account level, and resource level. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide. You cannot create recommendation preferences for Auto Scaling groups at the organization and account levels. You can create recommendation preferences for Auto Scaling groups only at the resource level by specifying a scope name of ResourceArn and a scope value of the Auto Scaling group Amazon Resource Name (ARN). This will configure the preference for all instances that are part of the specified Auto Scaling group. You also cannot create recommendation preferences at the resource level for instances that are part of an Auto Scaling group. You can create recommendation preferences at the resource level only for standalone instances. — shape: {name?: "Organization"|"AccountId"|"ResourceArn", value?: string}
  --next-token-body: string # The token to advance to the next page of recommendation preferences. (body field)
  --max-results-body: int # The maximum number of recommendation preferences to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value. (body field)
]: any -> oneof<record<nextToken: string, recommendationPreferencesDetails: table<scope: record, resourceType: string, enhancedInfrastructureMetrics: string, inferredWorkloadTypes: string, externalMetricsPreference: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetRecommendationPreferences")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"resourceType": $resource_type, "scope": $scope, "nextToken": $next_token_body, "maxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the optimization findings for an account. It returns the number of: Amazon EC2 instances in an account that are Underprovisioned, Overprovisioned, or Optimized. Auto Scaling groups in an account that are NotOptimized, or Optimized. Amazon EBS volumes in an account that are NotOptimized, or Optimized. Lambda functions in an account that are NotOptimized, or Optimized. Amazon ECS services in an account that are Underprovisioned, Overprovisioned, or Optimized.
#
# POST /
# operationId: GetRecommendationSummaries
export def "get-recommendation-summaries" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  --account-ids: list<string> # The ID of the Amazon Web Services account for which to return recommendation summaries. If your account is the management account of an organization, use this parameter to specify the member account for which you want to return recommendation summaries. Only one account ID can be specified per request.
  --next-token-body: string # The token to advance to the next page of recommendation summaries. (body field)
  --max-results-body: int # The maximum number of recommendation summaries to return with a single request. To retrieve the remaining results, make another request with the returned nextToken value. (body field)
]: any -> oneof<record<nextToken: string, recommendationSummaries: table<summaries: list, recommendationResourceType: string, accountId: string, savingsOpportunity: record, currentPerformanceRiskRatings: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.GetRecommendationSummaries")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"accountIds": $account_ids, "nextToken": $next_token_body, "maxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new recommendation preference or updates an existing recommendation preference, such as enhanced infrastructure metrics. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide.
#
# POST /
# operationId: PutRecommendationPreferences
export def "put-recommendation-preferences" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  resource_type: string@resource-type-completer # The target resource type of the recommendation preference to create. The Ec2Instance option encompasses standalone instances and instances that are part of Auto Scaling groups. The AutoScalingGroup option encompasses only instances that are part of an Auto Scaling group. The valid values for this parameter are Ec2Instance and AutoScalingGroup.
  --scope: record # Describes the scope of a recommendation preference. Recommendation preferences can be created at the organization level (for management accounts of an organization only), account level, and resource level. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide. You cannot create recommendation preferences for Auto Scaling groups at the organization and account levels. You can create recommendation preferences for Auto Scaling groups only at the resource level by specifying a scope name of ResourceArn and a scope value of the Auto Scaling group Amazon Resource Name (ARN). This will configure the preference for all instances that are part of the specified Auto Scaling group. You also cannot create recommendation preferences at the resource level for instances that are part of an Auto Scaling group. You can create recommendation preferences at the resource level only for standalone instances. — shape: {name?: "Organization"|"AccountId"|"ResourceArn", value?: string}
  --enhanced-infrastructure-metrics: string@enhanced-infrastructure-metrics-completer # The status of the enhanced infrastructure metrics recommendation preference to create or update. Specify the Active status to activate the preference, or specify Inactive to deactivate the preference. For more information, see Enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide.
  --inferred-workload-types: string@inferred-workload-types-completer # The status of the inferred workload types recommendation preference to create or update. The inferred workload type feature is active by default. To deactivate it, create a recommendation preference. Specify the Inactive status to deactivate the feature, or specify Active to activate it. For more information, see Inferred workload types (https://docs.aws.amazon.com/compute-optimizer/latest/ug/inferred-workload-types.html) in the Compute Optimizer User Guide.
  --external-metrics-preference: record # Describes the external metrics preferences for EC2 rightsizing recommendations. — shape: {source?: "Datadog"|"Dynatrace"|"NewRelic"|"Instana"}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.PutRecommendationPreferences")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"resourceType": $resource_type, "scope": $scope, "enhancedInfrastructureMetrics": $enhanced_infrastructure_metrics, "inferredWorkloadTypes": $inferred_workload_types, "externalMetricsPreference": $external_metrics_preference} | compact
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

# Updates the enrollment (opt in and opt out) status of an account to the Compute Optimizer service. If the account is a management account of an organization, this action can also be used to enroll member accounts of the organization. You must have the appropriate permissions to opt in to Compute Optimizer, to view its recommendations, and to opt out. For more information, see Controlling access with Amazon Web Services Identity and Access Management (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html) in the Compute Optimizer User Guide. When you opt in, Compute Optimizer automatically creates a service-linked role in your account to access its data. For more information, see Using Service-Linked Roles for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/using-service-linked-roles.html) in the Compute Optimizer User Guide.
#
# POST /
# operationId: UpdateEnrollmentStatus
export def "update-enrollment-status" [
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
  status: string@status-completer # The new enrollment status of the account. The following status options are available: Active - Opts in your account to the Compute Optimizer service. Compute Optimizer begins analyzing the configuration and utilization metrics of your Amazon Web Services resources after you opt in. For more information, see Metrics analyzed by Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/metrics.html) in the Compute Optimizer User Guide. Inactive - Opts out your account from the Compute Optimizer service. Your account's recommendations and related metrics data will be deleted from Compute Optimizer after you opt out. The Pending and Failed options cannot be used to update the enrollment status of an account. They are returned in the response of a request to update the enrollment status of an account.
  --include-member-accounts: oneof<nothing, bool> # Indicates whether to enroll member accounts of the organization if the account is the management account of an organization.
]: any -> oneof<record<status: string, statusReason: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "ComputeOptimizerService.UpdateEnrollmentStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"status": $status, "includeMemberAccounts": $include_member_accounts} | compact
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
