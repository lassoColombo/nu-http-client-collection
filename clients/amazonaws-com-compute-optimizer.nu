# Auto-generated client for AWS Compute Optimizer v2019-11-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/compute-optimizer/2019-11-01/openapi.json
# Auth: --token flag or $env.AWS_COMPUTE_OPTIMIZER_TOKEN

const BASE_URL = "http://compute-optimizer.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_COMPUTE_OPTIMIZER_TOKEN | default "" }
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

def base-url-completer [] { ["http://compute-optimizer.us-east-1.amazonaws.com" "http://compute-optimizer.us-east-2.amazonaws.com" "http://compute-optimizer.us-west-1.amazonaws.com" "http://compute-optimizer.us-west-2.amazonaws.com" "http://compute-optimizer.us-gov-west-1.amazonaws.com" "http://compute-optimizer.us-gov-east-1.amazonaws.com" "http://compute-optimizer.ca-central-1.amazonaws.com" "http://compute-optimizer.eu-north-1.amazonaws.com" "http://compute-optimizer.eu-west-1.amazonaws.com" "http://compute-optimizer.eu-west-2.amazonaws.com" "http://compute-optimizer.eu-west-3.amazonaws.com" "http://compute-optimizer.eu-central-1.amazonaws.com" "http://compute-optimizer.eu-south-1.amazonaws.com" "http://compute-optimizer.af-south-1.amazonaws.com" "http://compute-optimizer.ap-northeast-1.amazonaws.com" "http://compute-optimizer.ap-northeast-2.amazonaws.com" "http://compute-optimizer.ap-northeast-3.amazonaws.com" "http://compute-optimizer.ap-southeast-1.amazonaws.com" "http://compute-optimizer.ap-southeast-2.amazonaws.com" "http://compute-optimizer.ap-east-1.amazonaws.com" "http://compute-optimizer.ap-south-1.amazonaws.com" "http://compute-optimizer.sa-east-1.amazonaws.com" "http://compute-optimizer.me-south-1.amazonaws.com" "https://compute-optimizer.us-east-1.amazonaws.com" "https://compute-optimizer.us-east-2.amazonaws.com" "https://compute-optimizer.us-west-1.amazonaws.com" "https://compute-optimizer.us-west-2.amazonaws.com" "https://compute-optimizer.us-gov-west-1.amazonaws.com" "https://compute-optimizer.us-gov-east-1.amazonaws.com" "https://compute-optimizer.ca-central-1.amazonaws.com" "https://compute-optimizer.eu-north-1.amazonaws.com" "https://compute-optimizer.eu-west-1.amazonaws.com" "https://compute-optimizer.eu-west-2.amazonaws.com" "https://compute-optimizer.eu-west-3.amazonaws.com" "https://compute-optimizer.eu-central-1.amazonaws.com" "https://compute-optimizer.eu-south-1.amazonaws.com" "https://compute-optimizer.af-south-1.amazonaws.com" "https://compute-optimizer.ap-northeast-1.amazonaws.com" "https://compute-optimizer.ap-northeast-2.amazonaws.com" "https://compute-optimizer.ap-northeast-3.amazonaws.com" "https://compute-optimizer.ap-southeast-1.amazonaws.com" "https://compute-optimizer.ap-southeast-2.amazonaws.com" "https://compute-optimizer.ap-east-1.amazonaws.com" "https://compute-optimizer.ap-south-1.amazonaws.com" "https://compute-optimizer.sa-east-1.amazonaws.com" "https://compute-optimizer.me-south-1.amazonaws.com" "http://compute-optimizer.cn-north-1.amazonaws.com.cn" "http://compute-optimizer.cn-northwest-1.amazonaws.com.cn" "https://compute-optimizer.cn-north-1.amazonaws.com.cn" "https://compute-optimizer.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["ComputeOptimizerService.DeleteRecommendationPreferences"] }
def x-amz-target-completer-1 [] { ["ComputeOptimizerService.DescribeRecommendationExportJobs"] }
def x-amz-target-completer-2 [] { ["ComputeOptimizerService.ExportAutoScalingGroupRecommendations"] }
def x-amz-target-completer-3 [] { ["ComputeOptimizerService.ExportEBSVolumeRecommendations"] }
def x-amz-target-completer-4 [] { ["ComputeOptimizerService.ExportEC2InstanceRecommendations"] }
def x-amz-target-completer-5 [] { ["ComputeOptimizerService.ExportECSServiceRecommendations"] }
def x-amz-target-completer-6 [] { ["ComputeOptimizerService.ExportLambdaFunctionRecommendations"] }
def x-amz-target-completer-7 [] { ["ComputeOptimizerService.GetAutoScalingGroupRecommendations"] }
def x-amz-target-completer-8 [] { ["ComputeOptimizerService.GetEBSVolumeRecommendations"] }
def x-amz-target-completer-9 [] { ["ComputeOptimizerService.GetEC2InstanceRecommendations"] }
def x-amz-target-completer-10 [] { ["ComputeOptimizerService.GetEC2RecommendationProjectedMetrics"] }
def x-amz-target-completer-11 [] { ["ComputeOptimizerService.GetECSServiceRecommendationProjectedMetrics"] }
def x-amz-target-completer-12 [] { ["ComputeOptimizerService.GetECSServiceRecommendations"] }
def x-amz-target-completer-13 [] { ["ComputeOptimizerService.GetEffectiveRecommendationPreferences"] }
def x-amz-target-completer-14 [] { ["ComputeOptimizerService.GetEnrollmentStatus"] }
def x-amz-target-completer-15 [] { ["ComputeOptimizerService.GetEnrollmentStatusesForOrganization"] }
def x-amz-target-completer-16 [] { ["ComputeOptimizerService.GetLambdaFunctionRecommendations"] }
def x-amz-target-completer-17 [] { ["ComputeOptimizerService.GetRecommendationPreferences"] }
def x-amz-target-completer-18 [] { ["ComputeOptimizerService.GetRecommendationSummaries"] }
def x-amz-target-completer-19 [] { ["ComputeOptimizerService.PutRecommendationPreferences"] }
def x-amz-target-completer-20 [] { ["ComputeOptimizerService.UpdateEnrollmentStatus"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-compute-optimizer-service-delete-recommendation-preferences delete" } } | get name | first)
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

# Deletes a recommendation preference, such as enhanced infrastructure metrics. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide.
#
# POST /#X-Amz-Target=ComputeOptimizerService.DeleteRecommendationPreferences
# operationId: DeleteRecommendationPreferences
export def "x-amz-target-compute-optimizer-service-delete-recommendation-preferences delete" [
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
  resource_type: any
  --scope: any
  recommendation_preference_names: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.DeleteRecommendationPreferences")
  let req_body = {"resourceType": $resource_type, "scope": $scope, "recommendationPreferenceNames": $recommendation_preference_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes recommendation export jobs created in the last seven days. Use the ExportAutoScalingGroupRecommendations or ExportEC2InstanceRecommendations actions to request an export of your recommendations. Then use the DescribeRecommendationExportJobs action to view your export jobs.
#
# POST /#X-Amz-Target=ComputeOptimizerService.DescribeRecommendationExportJobs
# operationId: DescribeRecommendationExportJobs
export def "x-amz-target-compute-optimizer-service-describe-recommendation-export-jobs get" [
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
  --x-amz-target: string@x-amz-target-completer-1
  --job-ids: any
  --filters: any
  --next-token: any
  --max-results: any
]: any -> record<recommendationExportJobs: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.DescribeRecommendationExportJobs" $qp)
  let req_body = {"jobIds": $job_ids, "filters": $filters, "nextToken": $next_token, "maxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Exports optimization recommendations for Auto Scaling groups. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Auto Scaling group export job in progress per Amazon Web Services Region.
#
# POST /#X-Amz-Target=ComputeOptimizerService.ExportAutoScalingGroupRecommendations
# operationId: ExportAutoScalingGroupRecommendations
export def "x-amz-target-compute-optimizer-service-export-auto-scaling-group-recommendations export" [
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
  --account-ids: any
  --filters: any
  --fields-to-export: any
  s3_destination_config: any
  --file-format: any
  --include-member-accounts: any
  --recommendation-preferences: any
]: any -> record<jobId: record, s3Destination: record<bucket: record, key: record, metadataKey: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.ExportAutoScalingGroupRecommendations")
  let req_body = {"accountIds": $account_ids, "filters": $filters, "fieldsToExport": $fields_to_export, "s3DestinationConfig": $s3_destination_config, "fileFormat": $file_format, "includeMemberAccounts": $include_member_accounts, "recommendationPreferences": $recommendation_preferences} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Exports optimization recommendations for Amazon EBS volumes. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Amazon EBS volume export job in progress per Amazon Web Services Region.
#
# POST /#X-Amz-Target=ComputeOptimizerService.ExportEBSVolumeRecommendations
# operationId: ExportEBSVolumeRecommendations
# --s3DestinationConfig shape: {bucket?: any, keyPrefix?: any}
export def "x-amz-target-compute-optimizer-service-export-ebs-volume-recommendations export" [
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
  --account-ids: any
  --filters: any
  --fields-to-export: any
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: any, keyPrefix?: any}
  --file-format: any
  --include-member-accounts: any
]: any -> record<jobId: record, s3Destination: record<bucket: record, key: record, metadataKey: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.ExportEBSVolumeRecommendations")
  let req_body = {"accountIds": $account_ids, "filters": $filters, "fieldsToExport": $fields_to_export, "s3DestinationConfig": $s3_destination_config, "fileFormat": $file_format, "includeMemberAccounts": $include_member_accounts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Exports optimization recommendations for Amazon EC2 instances. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Amazon EC2 instance export job in progress per Amazon Web Services Region.
#
# POST /#X-Amz-Target=ComputeOptimizerService.ExportEC2InstanceRecommendations
# operationId: ExportEC2InstanceRecommendations
export def "x-amz-target-compute-optimizer-service-export-ec2-instance-recommendations export" [
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
  --account-ids: any
  --filters: any
  --fields-to-export: any
  s3_destination_config: any
  --file-format: any
  --include-member-accounts: any
  --recommendation-preferences: any
]: any -> record<jobId: record, s3Destination: record<bucket: record, key: record, metadataKey: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.ExportEC2InstanceRecommendations")
  let req_body = {"accountIds": $account_ids, "filters": $filters, "fieldsToExport": $fields_to_export, "s3DestinationConfig": $s3_destination_config, "fileFormat": $file_format, "includeMemberAccounts": $include_member_accounts, "recommendationPreferences": $recommendation_preferences} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Exports optimization recommendations for Amazon ECS services on Fargate. Recommendations are exported in a CSV file, and its metadata in a JSON file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can only have one Amazon ECS service export job in progress per Amazon Web Services Region.
#
# POST /#X-Amz-Target=ComputeOptimizerService.ExportECSServiceRecommendations
# operationId: ExportECSServiceRecommendations
# --s3DestinationConfig shape: {bucket?: any, keyPrefix?: any}
export def "x-amz-target-compute-optimizer-service-export-ecs-service-recommendations export" [
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
  --account-ids: any
  --filters: any
  --fields-to-export: any
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: any, keyPrefix?: any}
  --file-format: any
  --include-member-accounts: any
]: any -> record<jobId: record, s3Destination: record<bucket: record, key: record, metadataKey: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.ExportECSServiceRecommendations")
  let req_body = {"accountIds": $account_ids, "filters": $filters, "fieldsToExport": $fields_to_export, "s3DestinationConfig": $s3_destination_config, "fileFormat": $file_format, "includeMemberAccounts": $include_member_accounts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Exports optimization recommendations for Lambda functions. Recommendations are exported in a comma-separated values (.csv) file, and its metadata in a JavaScript Object Notation (JSON) (.json) file, to an existing Amazon Simple Storage Service (Amazon S3) bucket that you specify. For more information, see Exporting Recommendations (https://docs.aws.amazon.com/compute-optimizer/latest/ug/exporting-recommendations.html) in the Compute Optimizer User Guide. You can have only one Lambda function export job in progress per Amazon Web Services Region.
#
# POST /#X-Amz-Target=ComputeOptimizerService.ExportLambdaFunctionRecommendations
# operationId: ExportLambdaFunctionRecommendations
# --s3DestinationConfig shape: {bucket?: any, keyPrefix?: any}
export def "x-amz-target-compute-optimizer-service-export-lambda-function-recommendations export" [
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
  --account-ids: any
  --filters: any
  --fields-to-export: any
  s3_destination_config: record # Describes the destination Amazon Simple Storage Service (Amazon S3) bucket name and key prefix for a recommendations export job. You must create the destination Amazon S3 bucket for your recommendations export before you create the export job. Compute Optimizer does not create the S3 bucket for you. After you create the S3 bucket, ensure that it has the required permission policy to allow Compute Optimizer to write the export file to it. If you plan to specify an object prefix when you create the export job, you must include the object prefix in the policy that you add to the S3 bucket. For more information, see Amazon S3 Bucket Policy for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/create-s3-bucket-policy-for-compute-optimizer.html) in the Compute Optimizer User Guide. — shape: {bucket?: any, keyPrefix?: any}
  --file-format: any
  --include-member-accounts: any
]: any -> record<jobId: record, s3Destination: record<bucket: record, key: record, metadataKey: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.ExportLambdaFunctionRecommendations")
  let req_body = {"accountIds": $account_ids, "filters": $filters, "fieldsToExport": $fields_to_export, "s3DestinationConfig": $s3_destination_config, "fileFormat": $file_format, "includeMemberAccounts": $include_member_accounts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns Auto Scaling group recommendations. Compute Optimizer generates recommendations for Amazon EC2 Auto Scaling groups that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetAutoScalingGroupRecommendations
# operationId: GetAutoScalingGroupRecommendations
export def "x-amz-target-compute-optimizer-service-get-auto-scaling-group-recommendations get" [
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
  --account-ids: any
  --auto-scaling-group-arns: any
  --next-token: any
  --max-results: any
  --filters: any
  --recommendation-preferences: any
]: any -> record<nextToken: record, autoScalingGroupRecommendations: record, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetAutoScalingGroupRecommendations")
  let req_body = {"accountIds": $account_ids, "autoScalingGroupArns": $auto_scaling_group_arns, "nextToken": $next_token, "maxResults": $max_results, "filters": $filters, "recommendationPreferences": $recommendation_preferences} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns Amazon Elastic Block Store (Amazon EBS) volume recommendations. Compute Optimizer generates recommendations for Amazon EBS volumes that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetEBSVolumeRecommendations
# operationId: GetEBSVolumeRecommendations
export def "x-amz-target-compute-optimizer-service-get-ebs-volume-recommendations get" [
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
  --volume-arns: any
  --next-token: any
  --max-results: any
  --filters: any
  --account-ids: any
]: any -> record<nextToken: record, volumeRecommendations: record, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetEBSVolumeRecommendations")
  let req_body = {"volumeArns": $volume_arns, "nextToken": $next_token, "maxResults": $max_results, "filters": $filters, "accountIds": $account_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns Amazon EC2 instance recommendations. Compute Optimizer generates recommendations for Amazon Elastic Compute Cloud (Amazon EC2) instances that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetEC2InstanceRecommendations
# operationId: GetEC2InstanceRecommendations
export def "x-amz-target-compute-optimizer-service-get-ec2-instance-recommendations get" [
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
  --instance-arns: any
  --next-token: any
  --max-results: any
  --filters: any
  --account-ids: any
  --recommendation-preferences: any
]: any -> record<nextToken: record, instanceRecommendations: record, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetEC2InstanceRecommendations")
  let req_body = {"instanceArns": $instance_arns, "nextToken": $next_token, "maxResults": $max_results, "filters": $filters, "accountIds": $account_ids, "recommendationPreferences": $recommendation_preferences} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the projected utilization metrics of Amazon EC2 instance recommendations. The Cpu and Memory metrics are the only projected utilization metrics returned when you run this action. Additionally, the Memory metric is returned only for resources that have the unified CloudWatch agent installed on them. For more information, see Enabling Memory Utilization with the CloudWatch Agent (https://docs.aws.amazon.com/compute-optimizer/latest/ug/metrics.html#cw-agent).
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetEC2RecommendationProjectedMetrics
# operationId: GetEC2RecommendationProjectedMetrics
export def "x-amz-target-compute-optimizer-service-get-ec2-recommendation-projected-metrics get" [
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
  instance_arn: any
  stat: any
  period: any
  start_time: any
  end_time: any
  --recommendation-preferences: any
]: any -> record<recommendedOptionProjectedMetrics: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetEC2RecommendationProjectedMetrics")
  let req_body = {"instanceArn": $instance_arn, "stat": $stat, "period": $period, "startTime": $start_time, "endTime": $end_time, "recommendationPreferences": $recommendation_preferences} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the projected metrics of Amazon ECS service recommendations.
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetECSServiceRecommendationProjectedMetrics
# operationId: GetECSServiceRecommendationProjectedMetrics
export def "x-amz-target-compute-optimizer-service-get-ecs-service-recommendation-projected-metrics get" [
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
  service_arn: any
  stat: any
  period: any
  start_time: any
  end_time: any
]: any -> record<recommendedOptionProjectedMetrics: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetECSServiceRecommendationProjectedMetrics")
  let req_body = {"serviceArn": $service_arn, "stat": $stat, "period": $period, "startTime": $start_time, "endTime": $end_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns Amazon ECS service recommendations. Compute Optimizer generates recommendations for Amazon ECS services on Fargate that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetECSServiceRecommendations
# operationId: GetECSServiceRecommendations
export def "x-amz-target-compute-optimizer-service-get-ecs-service-recommendations get" [
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
  --service-arns: any
  --next-token: any
  --max-results: any
  --filters: any
  --account-ids: any
]: any -> record<nextToken: record, ecsServiceRecommendations: record, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetECSServiceRecommendations")
  let req_body = {"serviceArns": $service_arns, "nextToken": $next_token, "maxResults": $max_results, "filters": $filters, "accountIds": $account_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the recommendation preferences that are in effect for a given resource, such as enhanced infrastructure metrics. Considers all applicable preferences that you might have set at the resource, account, and organization level. When you create a recommendation preference, you can set its status to Active or Inactive. Use this action to view the recommendation preferences that are in effect, or Active.
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetEffectiveRecommendationPreferences
# operationId: GetEffectiveRecommendationPreferences
export def "x-amz-target-compute-optimizer-service-get-effective-recommendation-preferences get" [
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
  resource_arn: any
]: any -> record<enhancedInfrastructureMetrics: record, externalMetricsPreference: record<source: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetEffectiveRecommendationPreferences")
  let req_body = {"resourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the enrollment (opt in) status of an account to the Compute Optimizer service. If the account is the management account of an organization, this action also confirms the enrollment status of member accounts of the organization. Use the GetEnrollmentStatusesForOrganization action to get detailed information about the enrollment status of member accounts of an organization.
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetEnrollmentStatus
# operationId: GetEnrollmentStatus
export def "x-amz-target-compute-optimizer-service-get-enrollment-status get" [
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
  --body: record
]: any -> record<status: record, statusReason: record, memberAccountsEnrolled: record, lastUpdatedTimestamp: record, numberOfMemberAccountsOptedIn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetEnrollmentStatus")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the Compute Optimizer enrollment (opt-in) status of organization member accounts, if your account is an organization management account. To get the enrollment status of standalone accounts, use the GetEnrollmentStatus action.
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetEnrollmentStatusesForOrganization
# operationId: GetEnrollmentStatusesForOrganization
export def "x-amz-target-compute-optimizer-service-get-enrollment-statuses-for-organization get" [
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
  --x-amz-target: string@x-amz-target-completer-15
  --filters: any
  --next-token: any
  --max-results: any
]: any -> record<accountEnrollmentStatuses: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetEnrollmentStatusesForOrganization" $qp)
  let req_body = {"filters": $filters, "nextToken": $next_token, "maxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns Lambda function recommendations. Compute Optimizer generates recommendations for functions that meet a specific set of requirements. For more information, see the Supported resources and requirements (https://docs.aws.amazon.com/compute-optimizer/latest/ug/requirements.html) in the Compute Optimizer User Guide.
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetLambdaFunctionRecommendations
# operationId: GetLambdaFunctionRecommendations
export def "x-amz-target-compute-optimizer-service-get-lambda-function-recommendations get" [
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
  --x-amz-target: string@x-amz-target-completer-16
  --function-arns: any
  --account-ids: any
  --filters: any
  --next-token: any
  --max-results: any
]: any -> record<nextToken: record, lambdaFunctionRecommendations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetLambdaFunctionRecommendations" $qp)
  let req_body = {"functionArns": $function_arns, "accountIds": $account_ids, "filters": $filters, "nextToken": $next_token, "maxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns existing recommendation preferences, such as enhanced infrastructure metrics. Use the scope parameter to specify which preferences to return. You can specify to return preferences for an organization, a specific account ID, or a specific EC2 instance or Auto Scaling group Amazon Resource Name (ARN). For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide.
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetRecommendationPreferences
# operationId: GetRecommendationPreferences
export def "x-amz-target-compute-optimizer-service-get-recommendation-preferences get" [
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
  --x-amz-target: string@x-amz-target-completer-17
  resource_type: any
  --scope: any
  --next-token: any
  --max-results: any
]: any -> record<nextToken: record, recommendationPreferencesDetails: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetRecommendationPreferences" $qp)
  let req_body = {"resourceType": $resource_type, "scope": $scope, "nextToken": $next_token, "maxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the optimization findings for an account. It returns the number of: Amazon EC2 instances in an account that are Underprovisioned, Overprovisioned, or Optimized. Auto Scaling groups in an account that are NotOptimized, or Optimized. Amazon EBS volumes in an account that are NotOptimized, or Optimized. Lambda functions in an account that are NotOptimized, or Optimized. Amazon ECS services in an account that are Underprovisioned, Overprovisioned, or Optimized.
#
# POST /#X-Amz-Target=ComputeOptimizerService.GetRecommendationSummaries
# operationId: GetRecommendationSummaries
export def "x-amz-target-compute-optimizer-service-get-recommendation-summaries get" [
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
  --x-amz-target: string@x-amz-target-completer-18
  --account-ids: any
  --next-token: any
  --max-results: any
]: any -> record<nextToken: record, recommendationSummaries: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.GetRecommendationSummaries" $qp)
  let req_body = {"accountIds": $account_ids, "nextToken": $next_token, "maxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new recommendation preference or updates an existing recommendation preference, such as enhanced infrastructure metrics. For more information, see Activating enhanced infrastructure metrics (https://docs.aws.amazon.com/compute-optimizer/latest/ug/enhanced-infrastructure-metrics.html) in the Compute Optimizer User Guide.
#
# POST /#X-Amz-Target=ComputeOptimizerService.PutRecommendationPreferences
# operationId: PutRecommendationPreferences
export def "x-amz-target-compute-optimizer-service-put-recommendation-preferences update" [
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
  resource_type: any
  --scope: any
  --enhanced-infrastructure-metrics: any
  --inferred-workload-types: any
  --external-metrics-preference: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.PutRecommendationPreferences")
  let req_body = {"resourceType": $resource_type, "scope": $scope, "enhancedInfrastructureMetrics": $enhanced_infrastructure_metrics, "inferredWorkloadTypes": $inferred_workload_types, "externalMetricsPreference": $external_metrics_preference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the enrollment (opt in and opt out) status of an account to the Compute Optimizer service. If the account is a management account of an organization, this action can also be used to enroll member accounts of the organization. You must have the appropriate permissions to opt in to Compute Optimizer, to view its recommendations, and to opt out. For more information, see Controlling access with Amazon Web Services Identity and Access Management (https://docs.aws.amazon.com/compute-optimizer/latest/ug/security-iam.html) in the Compute Optimizer User Guide. When you opt in, Compute Optimizer automatically creates a service-linked role in your account to access its data. For more information, see Using Service-Linked Roles for Compute Optimizer (https://docs.aws.amazon.com/compute-optimizer/latest/ug/using-service-linked-roles.html) in the Compute Optimizer User Guide.
#
# POST /#X-Amz-Target=ComputeOptimizerService.UpdateEnrollmentStatus
# operationId: UpdateEnrollmentStatus
export def "x-amz-target-compute-optimizer-service-update-enrollment-status update" [
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
  status: any
  --include-member-accounts: any
]: any -> record<status: record, statusReason: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=ComputeOptimizerService.UpdateEnrollmentStatus")
  let req_body = {"status": $status, "includeMemberAccounts": $include_member_accounts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
