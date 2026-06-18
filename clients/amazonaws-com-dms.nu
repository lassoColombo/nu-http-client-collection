# Auto-generated client for AWS Database Migration Service v2016-01-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/dms/2016-01-01/openapi.json
# Auth: --token flag or $env.AWS_DATABASE_MIGRATION_SERVICE_TOKEN

const BASE_URL = "http://dms.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_DATABASE_MIGRATION_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://dms.us-east-1.amazonaws.com" "http://dms.us-east-2.amazonaws.com" "http://dms.us-west-1.amazonaws.com" "http://dms.us-west-2.amazonaws.com" "http://dms.us-gov-west-1.amazonaws.com" "http://dms.us-gov-east-1.amazonaws.com" "http://dms.ca-central-1.amazonaws.com" "http://dms.eu-north-1.amazonaws.com" "http://dms.eu-west-1.amazonaws.com" "http://dms.eu-west-2.amazonaws.com" "http://dms.eu-west-3.amazonaws.com" "http://dms.eu-central-1.amazonaws.com" "http://dms.eu-south-1.amazonaws.com" "http://dms.af-south-1.amazonaws.com" "http://dms.ap-northeast-1.amazonaws.com" "http://dms.ap-northeast-2.amazonaws.com" "http://dms.ap-northeast-3.amazonaws.com" "http://dms.ap-southeast-1.amazonaws.com" "http://dms.ap-southeast-2.amazonaws.com" "http://dms.ap-east-1.amazonaws.com" "http://dms.ap-south-1.amazonaws.com" "http://dms.sa-east-1.amazonaws.com" "http://dms.me-south-1.amazonaws.com" "https://dms.us-east-1.amazonaws.com" "https://dms.us-east-2.amazonaws.com" "https://dms.us-west-1.amazonaws.com" "https://dms.us-west-2.amazonaws.com" "https://dms.us-gov-west-1.amazonaws.com" "https://dms.us-gov-east-1.amazonaws.com" "https://dms.ca-central-1.amazonaws.com" "https://dms.eu-north-1.amazonaws.com" "https://dms.eu-west-1.amazonaws.com" "https://dms.eu-west-2.amazonaws.com" "https://dms.eu-west-3.amazonaws.com" "https://dms.eu-central-1.amazonaws.com" "https://dms.eu-south-1.amazonaws.com" "https://dms.af-south-1.amazonaws.com" "https://dms.ap-northeast-1.amazonaws.com" "https://dms.ap-northeast-2.amazonaws.com" "https://dms.ap-northeast-3.amazonaws.com" "https://dms.ap-southeast-1.amazonaws.com" "https://dms.ap-southeast-2.amazonaws.com" "https://dms.ap-east-1.amazonaws.com" "https://dms.ap-south-1.amazonaws.com" "https://dms.sa-east-1.amazonaws.com" "https://dms.me-south-1.amazonaws.com" "http://dms.cn-north-1.amazonaws.com.cn" "http://dms.cn-northwest-1.amazonaws.com.cn" "https://dms.cn-north-1.amazonaws.com.cn" "https://dms.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AmazonDMSv20160101.AddTagsToResource"] }
def x-amz-target-completer-1 [] { ["AmazonDMSv20160101.ApplyPendingMaintenanceAction"] }
def x-amz-target-completer-2 [] { ["AmazonDMSv20160101.BatchStartRecommendations"] }
def x-amz-target-completer-3 [] { ["AmazonDMSv20160101.CancelReplicationTaskAssessmentRun"] }
def x-amz-target-completer-4 [] { ["AmazonDMSv20160101.CreateEndpoint"] }
def x-amz-target-completer-5 [] { ["AmazonDMSv20160101.CreateEventSubscription"] }
def x-amz-target-completer-6 [] { ["AmazonDMSv20160101.CreateFleetAdvisorCollector"] }
def x-amz-target-completer-7 [] { ["AmazonDMSv20160101.CreateReplicationInstance"] }
def x-amz-target-completer-8 [] { ["AmazonDMSv20160101.CreateReplicationSubnetGroup"] }
def x-amz-target-completer-9 [] { ["AmazonDMSv20160101.CreateReplicationTask"] }
def x-amz-target-completer-10 [] { ["AmazonDMSv20160101.DeleteCertificate"] }
def x-amz-target-completer-11 [] { ["AmazonDMSv20160101.DeleteConnection"] }
def x-amz-target-completer-12 [] { ["AmazonDMSv20160101.DeleteEndpoint"] }
def x-amz-target-completer-13 [] { ["AmazonDMSv20160101.DeleteEventSubscription"] }
def x-amz-target-completer-14 [] { ["AmazonDMSv20160101.DeleteFleetAdvisorCollector"] }
def x-amz-target-completer-15 [] { ["AmazonDMSv20160101.DeleteFleetAdvisorDatabases"] }
def x-amz-target-completer-16 [] { ["AmazonDMSv20160101.DeleteReplicationInstance"] }
def x-amz-target-completer-17 [] { ["AmazonDMSv20160101.DeleteReplicationSubnetGroup"] }
def x-amz-target-completer-18 [] { ["AmazonDMSv20160101.DeleteReplicationTask"] }
def x-amz-target-completer-19 [] { ["AmazonDMSv20160101.DeleteReplicationTaskAssessmentRun"] }
def x-amz-target-completer-20 [] { ["AmazonDMSv20160101.DescribeAccountAttributes"] }
def x-amz-target-completer-21 [] { ["AmazonDMSv20160101.DescribeApplicableIndividualAssessments"] }
def x-amz-target-completer-22 [] { ["AmazonDMSv20160101.DescribeCertificates"] }
def x-amz-target-completer-23 [] { ["AmazonDMSv20160101.DescribeConnections"] }
def x-amz-target-completer-24 [] { ["AmazonDMSv20160101.DescribeEndpointSettings"] }
def x-amz-target-completer-25 [] { ["AmazonDMSv20160101.DescribeEndpointTypes"] }
def x-amz-target-completer-26 [] { ["AmazonDMSv20160101.DescribeEndpoints"] }
def x-amz-target-completer-27 [] { ["AmazonDMSv20160101.DescribeEventCategories"] }
def x-amz-target-completer-28 [] { ["AmazonDMSv20160101.DescribeEventSubscriptions"] }
def x-amz-target-completer-29 [] { ["AmazonDMSv20160101.DescribeEvents"] }
def x-amz-target-completer-30 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorCollectors"] }
def x-amz-target-completer-31 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorDatabases"] }
def x-amz-target-completer-32 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorLsaAnalysis"] }
def x-amz-target-completer-33 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorSchemaObjectSummary"] }
def x-amz-target-completer-34 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorSchemas"] }
def x-amz-target-completer-35 [] { ["AmazonDMSv20160101.DescribeOrderableReplicationInstances"] }
def x-amz-target-completer-36 [] { ["AmazonDMSv20160101.DescribePendingMaintenanceActions"] }
def x-amz-target-completer-37 [] { ["AmazonDMSv20160101.DescribeRecommendationLimitations"] }
def x-amz-target-completer-38 [] { ["AmazonDMSv20160101.DescribeRecommendations"] }
def x-amz-target-completer-39 [] { ["AmazonDMSv20160101.DescribeRefreshSchemasStatus"] }
def x-amz-target-completer-40 [] { ["AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs"] }
def x-amz-target-completer-41 [] { ["AmazonDMSv20160101.DescribeReplicationInstances"] }
def x-amz-target-completer-42 [] { ["AmazonDMSv20160101.DescribeReplicationSubnetGroups"] }
def x-amz-target-completer-43 [] { ["AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults"] }
def x-amz-target-completer-44 [] { ["AmazonDMSv20160101.DescribeReplicationTaskAssessmentRuns"] }
def x-amz-target-completer-45 [] { ["AmazonDMSv20160101.DescribeReplicationTaskIndividualAssessments"] }
def x-amz-target-completer-46 [] { ["AmazonDMSv20160101.DescribeReplicationTasks"] }
def x-amz-target-completer-47 [] { ["AmazonDMSv20160101.DescribeSchemas"] }
def x-amz-target-completer-48 [] { ["AmazonDMSv20160101.DescribeTableStatistics"] }
def x-amz-target-completer-49 [] { ["AmazonDMSv20160101.ImportCertificate"] }
def x-amz-target-completer-50 [] { ["AmazonDMSv20160101.ListTagsForResource"] }
def x-amz-target-completer-51 [] { ["AmazonDMSv20160101.ModifyEndpoint"] }
def x-amz-target-completer-52 [] { ["AmazonDMSv20160101.ModifyEventSubscription"] }
def x-amz-target-completer-53 [] { ["AmazonDMSv20160101.ModifyReplicationInstance"] }
def x-amz-target-completer-54 [] { ["AmazonDMSv20160101.ModifyReplicationSubnetGroup"] }
def x-amz-target-completer-55 [] { ["AmazonDMSv20160101.ModifyReplicationTask"] }
def x-amz-target-completer-56 [] { ["AmazonDMSv20160101.MoveReplicationTask"] }
def x-amz-target-completer-57 [] { ["AmazonDMSv20160101.RebootReplicationInstance"] }
def x-amz-target-completer-58 [] { ["AmazonDMSv20160101.RefreshSchemas"] }
def x-amz-target-completer-59 [] { ["AmazonDMSv20160101.ReloadTables"] }
def x-amz-target-completer-60 [] { ["AmazonDMSv20160101.RemoveTagsFromResource"] }
def x-amz-target-completer-61 [] { ["AmazonDMSv20160101.RunFleetAdvisorLsaAnalysis"] }
def x-amz-target-completer-62 [] { ["AmazonDMSv20160101.StartRecommendations"] }
def x-amz-target-completer-63 [] { ["AmazonDMSv20160101.StartReplicationTask"] }
def x-amz-target-completer-64 [] { ["AmazonDMSv20160101.StartReplicationTaskAssessment"] }
def x-amz-target-completer-65 [] { ["AmazonDMSv20160101.StartReplicationTaskAssessmentRun"] }
def x-amz-target-completer-66 [] { ["AmazonDMSv20160101.StopReplicationTask"] }
def x-amz-target-completer-67 [] { ["AmazonDMSv20160101.TestConnection"] }
def x-amz-target-completer-68 [] { ["AmazonDMSv20160101.UpdateSubscriptionsToEventBridge"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-amazon-dm-sv20160101-add-tags-to-resource create" } } | get name | first)
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

# Adds metadata tags to an DMS resource, including replication instance, endpoint, subnet group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS. For more information, see Tag (https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html) data type description.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.AddTagsToResource
# operationId: AddTagsToResource
export def "x-amz-target-amazon-dm-sv20160101-add-tags-to-resource create" [
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
  resource_arn: any
  tags: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.AddTagsToResource")
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Applies a pending maintenance action to a resource (for example, to a replication instance).
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ApplyPendingMaintenanceAction
# operationId: ApplyPendingMaintenanceAction
export def "x-amz-target-amazon-dm-sv20160101-apply-pending-maintenance-action create" [
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
  replication_instance_arn: any
  apply_action: any
  opt_in_type: any
]: any -> record<ResourcePendingMaintenanceActions: record<ResourceIdentifier: record, PendingMaintenanceActionDetails: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ApplyPendingMaintenanceAction")
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "ApplyAction": $apply_action, "OptInType": $opt_in_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Starts the analysis of up to 20 source databases to recommend target engines for each source database. This is a batch version of StartRecommendations (https://docs.aws.amazon.com/dms/latest/APIReference/API_StartRecommendations.html). The result of analysis of each source database is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of 200.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.BatchStartRecommendations
# operationId: BatchStartRecommendations
export def "x-amz-target-amazon-dm-sv20160101-batch-start-recommendations start" [
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
  --data: any
]: any -> record<ErrorEntries: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.BatchStartRecommendations")
  let req_body = {"Data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Cancels a single premigration assessment run. This operation prevents any individual assessments from running if they haven't started running. It also attempts to cancel any individual assessments that are currently running.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CancelReplicationTaskAssessmentRun
# operationId: CancelReplicationTaskAssessmentRun
export def "x-amz-target-amazon-dm-sv20160101-cancel-replication-task-assessment-run cancel" [
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
  --x-amz-target: string@x-amz-target-completer-3
  replication_task_assessment_run_arn: any
]: any -> record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: record, ReplicationTaskArn: record, Status: record, ReplicationTaskAssessmentRunCreationDate: record, AssessmentProgress: record<IndividualAssessmentCount: record, IndividualAssessmentCompletedCount: record>, LastFailureMessage: record, ServiceAccessRoleArn: record, ResultLocationBucket: record, ResultLocationFolder: record, ResultEncryptionMode: record, ResultKmsKeyArn: record, AssessmentRunName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CancelReplicationTaskAssessmentRun")
  let req_body = {"ReplicationTaskAssessmentRunArn": $replication_task_assessment_run_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates an endpoint using the provided settings. For a MySQL source or target endpoint, don't explicitly specify the database using the DatabaseName request parameter on the CreateEndpoint API call. Specifying DatabaseName when you create a MySQL endpoint replicates all the task tables to this single database. For MySQL endpoints, you specify the database only when you specify the schema in the table-mapping rules of the DMS task.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateEndpoint
# operationId: CreateEndpoint
# --RedshiftSettings shape: {AcceptAnyDate?: any, AfterConnectScript?: any, BucketFolder?: any, BucketName?: any, CaseSensitiveNames?: any, CompUpdate?: any, ConnectionTimeout?: any, DatabaseName?: any, DateFormat?: any, EmptyAsNull?: any, EncryptionMode?: any, ExplicitIds?: any, FileTransferUploadStreams?: any, LoadTimeout?: any, MaxFileSize?: any, Password?: any, Port?: any, RemoveQuotes?: any, ReplaceInvalidChars?: any, ReplaceChars?: any, ServerName?: any, ServiceAccessRoleArn?: any, ServerSideEncryptionKmsKeyId?: any, ... (8 more fields)}
# --DocDbSettings shape: {Username?: any, Password?: any, ServerName?: any, Port?: any, DatabaseName?: any, NestingLevel?: any, ExtractDocId?: any, DocsToInvestigate?: any, KmsKeyId?: any, SecretsManagerAccessRoleArn?: any, SecretsManagerSecretId?: any}
export def "x-amz-target-amazon-dm-sv20160101-create-endpoint create" [
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
  --x-amz-target: string@x-amz-target-completer-4
  endpoint_identifier: any
  endpoint_type: any
  engine_name: any
  --username: any
  --password: any
  --server-name: any
  --port: any
  --database-name: any
  --extra-connection-attributes: any
  --kms-key-id: any
  --tags: any
  --certificate-arn: any
  --ssl-mode: any
  --service-access-role-arn: any
  --external-table-definition: any
  --dynamo-db-settings: any
  --s3-settings: any
  --dms-transfer-settings: any
  --mongo-db-settings: any
  --kinesis-settings: any
  --kafka-settings: any
  --elasticsearch-settings: any
  --neptune-settings: any
  --redshift-settings: record # Provides information that defines an Amazon Redshift endpoint. — shape: {AcceptAnyDate?: any, AfterConnectScript?: any, BucketFolder?: any, BucketName?: any, CaseSensitiveNames?: any, CompUpdate?: any, ConnectionTimeout?: any, DatabaseName?: any, DateFormat?: any, EmptyAsNull?: any, EncryptionMode?: any, ExplicitIds?: any, FileTransferUploadStreams?: any, LoadTimeout?: any, MaxFileSize?: any, Password?: any, Port?: any, RemoveQuotes?: any, ReplaceInvalidChars?: any, ReplaceChars?: any, ServerName?: any, ServiceAccessRoleArn?: any, ServerSideEncryptionKmsKeyId?: any, ... (8 more fields)}
  --postgre-sql-settings: any
  --my-sql-settings: any
  --oracle-settings: any
  --sybase-settings: any
  --microsoft-sql-server-settings: any
  --ibm-db2-settings: any
  --resource-identifier: any
  --doc-db-settings: record # Provides information that defines a DocumentDB endpoint. — shape: {Username?: any, Password?: any, ServerName?: any, Port?: any, DatabaseName?: any, NestingLevel?: any, ExtractDocId?: any, DocsToInvestigate?: any, KmsKeyId?: any, SecretsManagerAccessRoleArn?: any, SecretsManagerSecretId?: any}
  --redis-settings: any
  --gcp-my-sql-settings: any
]: any -> record<Endpoint: record<EndpointIdentifier: record, EndpointType: record, EngineName: record, EngineDisplayName: record, Username: record, ServerName: record, Port: record, DatabaseName: record, ExtraConnectionAttributes: record, Status: record, KmsKeyId: record, EndpointArn: record, CertificateArn: record, SslMode: record, ServiceAccessRoleArn: record, ExternalTableDefinition: record, ExternalId: record, DynamoDbSettings: record<ServiceAccessRoleArn: record>, S3Settings: record<ServiceAccessRoleArn: record, ExternalTableDefinition: record, CsvRowDelimiter: record, CsvDelimiter: record, BucketFolder: record, BucketName: record, CompressionType: record, EncryptionMode: record, ServerSideEncryptionKmsKeyId: record, DataFormat: record, EncodingType: record, DictPageSizeLimit: record, RowGroupLength: record, DataPageSize: record, ParquetVersion: record, EnableStatistics: record, IncludeOpForFullLoad: record, CdcInsertsOnly: record, TimestampColumnName: record, ParquetTimestampInMillisecond: record, CdcInsertsAndUpdates: record, DatePartitionEnabled: record, DatePartitionSequence: record, DatePartitionDelimiter: record, UseCsvNoSupValue: record, CsvNoSupValue: record, PreserveTransactions: record, CdcPath: record, UseTaskStartTimeForFullLoadTimestamp: record, CannedAclForObjects: record, AddColumnName: record, CdcMaxBatchInterval: record, CdcMinFileSize: record, CsvNullValue: record, IgnoreHeaderRows: record, MaxFileSize: record, Rfc4180: record, DatePartitionTimezone: record, AddTrailingPaddingCharacter: record, ExpectedBucketOwner: record, GlueCatalogGeneration: record>, DmsTransferSettings: record<ServiceAccessRoleArn: record, BucketName: record>, MongoDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, AuthType: record, AuthMechanism: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, AuthSource: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, KinesisSettings: record<StreamArn: record, MessageFormat: record, ServiceAccessRoleArn: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, IncludeNullAndEmpty: record, NoHexPrefix: record>, KafkaSettings: record<Broker: record, Topic: record, MessageFormat: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, MessageMaxBytes: record, IncludeNullAndEmpty: record, SecurityProtocol: record, SslClientCertificateArn: record, SslClientKeyArn: record, SslClientKeyPassword: record, SslCaCertificateArn: record, SaslUsername: record, SaslPassword: record, NoHexPrefix: record, SaslMechanism: record>, ElasticsearchSettings: record<ServiceAccessRoleArn: record, EndpointUri: record, FullLoadErrorPercentage: record, ErrorRetryDuration: record, UseNewMappingType: record>, NeptuneSettings: record<ServiceAccessRoleArn: record, S3BucketName: record, S3BucketFolder: record, ErrorRetryDuration: record, MaxFileSize: record, MaxRetryCount: record, IamAuthEnabled: record>, RedshiftSettings: record<AcceptAnyDate: record, AfterConnectScript: record, BucketFolder: record, BucketName: record, CaseSensitiveNames: record, CompUpdate: record, ConnectionTimeout: record, DatabaseName: record, DateFormat: record, EmptyAsNull: record, EncryptionMode: record, ExplicitIds: record, FileTransferUploadStreams: record, LoadTimeout: record, MaxFileSize: record, Password: record, Port: record, RemoveQuotes: record, ReplaceInvalidChars: record, ReplaceChars: record, ServerName: record, ServiceAccessRoleArn: record, ServerSideEncryptionKmsKeyId: record, TimeFormat: record, TrimBlanks: record, TruncateColumns: record, Username: record, WriteBufferSize: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, MapBooleanAsBoolean: record>, PostgreSQLSettings: record<AfterConnectScript: record, CaptureDdls: record, MaxFileSize: record, DatabaseName: record, DdlArtifactsSchema: record, ExecuteTimeout: record, FailTasksOnLobTruncation: record, HeartbeatEnable: record, HeartbeatSchema: record, HeartbeatFrequency: record, Password: record, Port: record, ServerName: record, Username: record, SlotName: record, PluginName: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, MapBooleanAsBoolean: record>, MySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, OracleSettings: record<AddSupplementalLogging: record, ArchivedLogDestId: record, AdditionalArchivedLogDestId: record, ExtraArchivedLogDestIds: record, AllowSelectNestedTables: record, ParallelAsmReadThreads: record, ReadAheadBlocks: record, AccessAlternateDirectly: record, UseAlternateFolderForOnline: record, OraclePathPrefix: record, UsePathPrefix: record, ReplacePathPrefix: record, EnableHomogenousTablespace: record, DirectPathNoLog: record, ArchivedLogsOnly: record, AsmPassword: record, AsmServer: record, AsmUser: record, CharLengthSemantics: record, DatabaseName: record, DirectPathParallelLoad: record, FailTasksOnLobTruncation: record, NumberDatatypeScale: record, Password: record, Port: record, ReadTableSpaceName: record, RetryInterval: record, SecurityDbEncryption: record, SecurityDbEncryptionName: record, ServerName: record, SpatialDataOptionToGeoJsonFunctionName: record, StandbyDelayTime: record, Username: record, UseBFile: record, UseDirectPathFullLoad: record, UseLogminerReader: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, SecretsManagerOracleAsmAccessRoleArn: record, SecretsManagerOracleAsmSecretId: record, TrimSpaceInChar: record, ConvertTimestampWithZoneToUTC: record>, SybaseSettings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, MicrosoftSQLServerSettings: record<Port: record, BcpPacketSize: record, DatabaseName: record, ControlTablesFileGroup: record, Password: record, QuerySingleAlwaysOnNode: record, ReadBackupOnly: record, SafeguardPolicy: record, ServerName: record, Username: record, UseBcpFullLoad: record, UseThirdPartyBackupDevice: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, TlogAccessMode: record, ForceLobLookup: record>, IBMDb2Settings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, SetDataCaptureChanges: record, CurrentLsn: record, MaxKBytesPerRead: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, DocDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, RedisSettings: record<ServerName: record, Port: record, SslSecurityProtocol: record, AuthType: record, AuthUserName: record, AuthPassword: record, SslCaCertificateArn: record>, GcpMySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateEndpoint")
  let req_body = {"EndpointIdentifier": $endpoint_identifier, "EndpointType": $endpoint_type, "EngineName": $engine_name, "Username": $username, "Password": $password, "ServerName": $server_name, "Port": $port, "DatabaseName": $database_name, "ExtraConnectionAttributes": $extra_connection_attributes, "KmsKeyId": $kms_key_id, "Tags": $tags, "CertificateArn": $certificate_arn, "SslMode": $ssl_mode, "ServiceAccessRoleArn": $service_access_role_arn, "ExternalTableDefinition": $external_table_definition, "DynamoDbSettings": $dynamo_db_settings, "S3Settings": $s3_settings, "DmsTransferSettings": $dms_transfer_settings, "MongoDbSettings": $mongo_db_settings, "KinesisSettings": $kinesis_settings, "KafkaSettings": $kafka_settings, "ElasticsearchSettings": $elasticsearch_settings, "NeptuneSettings": $neptune_settings, "RedshiftSettings": $redshift_settings, "PostgreSQLSettings": $postgre_sql_settings, "MySQLSettings": $my_sql_settings, "OracleSettings": $oracle_settings, "SybaseSettings": $sybase_settings, "MicrosoftSQLServerSettings": $microsoft_sql_server_settings, "IBMDb2Settings": $ibm_db2_settings, "ResourceIdentifier": $resource_identifier, "DocDbSettings": $doc_db_settings, "RedisSettings": $redis_settings, "GcpMySQLSettings": $gcp_my_sql_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates an DMS event notification subscription. You can specify the type of source (SourceType) you want to be notified of, provide a list of DMS source IDs (SourceIds) that triggers the events, and provide a list of event categories (EventCategories) for events you want to be notified of. If you specify both the SourceType and SourceIds, such as SourceType = replication-instance and SourceIdentifier = my-replinstance, you will be notified of all the replication instance events for the specified source. If you specify a SourceType but don't specify a SourceIdentifier, you receive notice of the events for that source type for all your DMS sources. If you don't specify either SourceType nor SourceIdentifier, you will be notified of events generated from all DMS sources belonging to your customer account. For more information about DMS events, see Working with Events and Notifications (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) in the Database Migration Service User Guide.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateEventSubscription
# operationId: CreateEventSubscription
export def "x-amz-target-amazon-dm-sv20160101-create-event-subscription create" [
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
  --x-amz-target: string@x-amz-target-completer-5
  subscription_name: any
  sns_topic_arn: any
  --source-type: any
  --event-categories: any
  --source-ids: any
  --enabled: any
  --tags: any
]: any -> record<EventSubscription: record<CustomerAwsId: record, CustSubscriptionId: record, SnsTopicArn: record, Status: record, SubscriptionCreationTime: record, SourceType: record, SourceIdsList: record, EventCategoriesList: record, Enabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateEventSubscription")
  let req_body = {"SubscriptionName": $subscription_name, "SnsTopicArn": $sns_topic_arn, "SourceType": $source_type, "EventCategories": $event_categories, "SourceIds": $source_ids, "Enabled": $enabled, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a Fleet Advisor collector using the specified parameters.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateFleetAdvisorCollector
# operationId: CreateFleetAdvisorCollector
export def "x-amz-target-amazon-dm-sv20160101-create-fleet-advisor-collector create" [
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
  --x-amz-target: string@x-amz-target-completer-6
  collector_name: any
  --description: any
  service_access_role_arn: any
  s3_bucket_name: any
]: any -> record<CollectorReferencedId: record, CollectorName: record, Description: record, ServiceAccessRoleArn: record, S3BucketName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateFleetAdvisorCollector")
  let req_body = {"CollectorName": $collector_name, "Description": $description, "ServiceAccessRoleArn": $service_access_role_arn, "S3BucketName": $s3_bucket_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates the replication instance using the specified parameters. DMS requires that your account have certain roles with appropriate permissions before you can create a replication instance. For information on the required roles, see Creating the IAM Roles to Use With the CLI and DMS API (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.APIRole). For information on the required permissions, see IAM Permissions Needed to Use DMS (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.IAMPermissions).
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateReplicationInstance
# operationId: CreateReplicationInstance
export def "x-amz-target-amazon-dm-sv20160101-create-replication-instance create" [
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
  replication_instance_identifier: any
  --allocated-storage: any
  replication_instance_class: any
  --vpc-security-group-ids: any
  --availability-zone: any
  --replication-subnet-group-identifier: any
  --preferred-maintenance-window: any
  --multi-az: any
  --engine-version: any
  --auto-minor-version-upgrade: any
  --tags: any
  --kms-key-id: any
  --publicly-accessible: any
  --dns-name-servers: any
  --resource-identifier: any
  --network-type: any
]: any -> record<ReplicationInstance: record<ReplicationInstanceIdentifier: record, ReplicationInstanceClass: record, ReplicationInstanceStatus: record, AllocatedStorage: record, InstanceCreateTime: record, VpcSecurityGroups: record, AvailabilityZone: record, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>, PreferredMaintenanceWindow: record, PendingModifiedValues: record<ReplicationInstanceClass: record, AllocatedStorage: record, MultiAZ: record, EngineVersion: record, NetworkType: record>, MultiAZ: record, EngineVersion: record, AutoMinorVersionUpgrade: record, KmsKeyId: record, ReplicationInstanceArn: record, ReplicationInstancePublicIpAddress: record, ReplicationInstancePrivateIpAddress: record, ReplicationInstancePublicIpAddresses: record, ReplicationInstancePrivateIpAddresses: record, ReplicationInstanceIpv6Addresses: record, PubliclyAccessible: record, SecondaryAvailabilityZone: record, FreeUntil: record, DnsNameServers: record, NetworkType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationInstance")
  let req_body = {"ReplicationInstanceIdentifier": $replication_instance_identifier, "AllocatedStorage": $allocated_storage, "ReplicationInstanceClass": $replication_instance_class, "VpcSecurityGroupIds": $vpc_security_group_ids, "AvailabilityZone": $availability_zone, "ReplicationSubnetGroupIdentifier": $replication_subnet_group_identifier, "PreferredMaintenanceWindow": $preferred_maintenance_window, "MultiAZ": $multi_az, "EngineVersion": $engine_version, "AutoMinorVersionUpgrade": $auto_minor_version_upgrade, "Tags": $tags, "KmsKeyId": $kms_key_id, "PubliclyAccessible": $publicly_accessible, "DnsNameServers": $dns_name_servers, "ResourceIdentifier": $resource_identifier, "NetworkType": $network_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a replication subnet group given a list of the subnet IDs in a VPC. The VPC needs to have at least one subnet in at least two availability zones in the Amazon Web Services Region, otherwise the service will throw a ReplicationSubnetGroupDoesNotCoverEnoughAZs exception.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateReplicationSubnetGroup
# operationId: CreateReplicationSubnetGroup
export def "x-amz-target-amazon-dm-sv20160101-create-replication-subnet-group create" [
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
  replication_subnet_group_identifier: any
  replication_subnet_group_description: any
  subnet_ids: any
  --tags: any
]: any -> record<ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationSubnetGroup")
  let req_body = {"ReplicationSubnetGroupIdentifier": $replication_subnet_group_identifier, "ReplicationSubnetGroupDescription": $replication_subnet_group_description, "SubnetIds": $subnet_ids, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a replication task using the specified parameters.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateReplicationTask
# operationId: CreateReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-create-replication-task create" [
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
  replication_task_identifier: any
  source_endpoint_arn: any
  target_endpoint_arn: any
  replication_instance_arn: any
  migration_type: any
  table_mappings: any
  --replication-task-settings: any
  --cdc-start-time: any
  --cdc-start-position: any
  --cdc-stop-position: any
  --tags: any
  --task-data: any
  --resource-identifier: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationTask")
  let req_body = {"ReplicationTaskIdentifier": $replication_task_identifier, "SourceEndpointArn": $source_endpoint_arn, "TargetEndpointArn": $target_endpoint_arn, "ReplicationInstanceArn": $replication_instance_arn, "MigrationType": $migration_type, "TableMappings": $table_mappings, "ReplicationTaskSettings": $replication_task_settings, "CdcStartTime": $cdc_start_time, "CdcStartPosition": $cdc_start_position, "CdcStopPosition": $cdc_stop_position, "Tags": $tags, "TaskData": $task_data, "ResourceIdentifier": $resource_identifier} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified certificate.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteCertificate
# operationId: DeleteCertificate
export def "x-amz-target-amazon-dm-sv20160101-delete-certificate delete" [
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
  certificate_arn: any
]: any -> record<Certificate: record<CertificateIdentifier: record, CertificateCreationDate: record, CertificatePem: record, CertificateWallet: record, CertificateArn: record, CertificateOwner: record, ValidFromDate: record, ValidToDate: record, SigningAlgorithm: record, KeyLength: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteCertificate")
  let req_body = {"CertificateArn": $certificate_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the connection between a replication instance and an endpoint.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteConnection
# operationId: DeleteConnection
export def "x-amz-target-amazon-dm-sv20160101-delete-connection delete" [
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
  endpoint_arn: any
  replication_instance_arn: any
]: any -> record<Connection: record<ReplicationInstanceArn: record, EndpointArn: record, Status: record, LastFailureMessage: record, EndpointIdentifier: record, ReplicationInstanceIdentifier: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteConnection")
  let req_body = {"EndpointArn": $endpoint_arn, "ReplicationInstanceArn": $replication_instance_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified endpoint. All tasks associated with the endpoint must be deleted before you can delete the endpoint.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteEndpoint
# operationId: DeleteEndpoint
export def "x-amz-target-amazon-dm-sv20160101-delete-endpoint delete" [
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
  endpoint_arn: any
]: any -> record<Endpoint: record<EndpointIdentifier: record, EndpointType: record, EngineName: record, EngineDisplayName: record, Username: record, ServerName: record, Port: record, DatabaseName: record, ExtraConnectionAttributes: record, Status: record, KmsKeyId: record, EndpointArn: record, CertificateArn: record, SslMode: record, ServiceAccessRoleArn: record, ExternalTableDefinition: record, ExternalId: record, DynamoDbSettings: record<ServiceAccessRoleArn: record>, S3Settings: record<ServiceAccessRoleArn: record, ExternalTableDefinition: record, CsvRowDelimiter: record, CsvDelimiter: record, BucketFolder: record, BucketName: record, CompressionType: record, EncryptionMode: record, ServerSideEncryptionKmsKeyId: record, DataFormat: record, EncodingType: record, DictPageSizeLimit: record, RowGroupLength: record, DataPageSize: record, ParquetVersion: record, EnableStatistics: record, IncludeOpForFullLoad: record, CdcInsertsOnly: record, TimestampColumnName: record, ParquetTimestampInMillisecond: record, CdcInsertsAndUpdates: record, DatePartitionEnabled: record, DatePartitionSequence: record, DatePartitionDelimiter: record, UseCsvNoSupValue: record, CsvNoSupValue: record, PreserveTransactions: record, CdcPath: record, UseTaskStartTimeForFullLoadTimestamp: record, CannedAclForObjects: record, AddColumnName: record, CdcMaxBatchInterval: record, CdcMinFileSize: record, CsvNullValue: record, IgnoreHeaderRows: record, MaxFileSize: record, Rfc4180: record, DatePartitionTimezone: record, AddTrailingPaddingCharacter: record, ExpectedBucketOwner: record, GlueCatalogGeneration: record>, DmsTransferSettings: record<ServiceAccessRoleArn: record, BucketName: record>, MongoDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, AuthType: record, AuthMechanism: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, AuthSource: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, KinesisSettings: record<StreamArn: record, MessageFormat: record, ServiceAccessRoleArn: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, IncludeNullAndEmpty: record, NoHexPrefix: record>, KafkaSettings: record<Broker: record, Topic: record, MessageFormat: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, MessageMaxBytes: record, IncludeNullAndEmpty: record, SecurityProtocol: record, SslClientCertificateArn: record, SslClientKeyArn: record, SslClientKeyPassword: record, SslCaCertificateArn: record, SaslUsername: record, SaslPassword: record, NoHexPrefix: record, SaslMechanism: record>, ElasticsearchSettings: record<ServiceAccessRoleArn: record, EndpointUri: record, FullLoadErrorPercentage: record, ErrorRetryDuration: record, UseNewMappingType: record>, NeptuneSettings: record<ServiceAccessRoleArn: record, S3BucketName: record, S3BucketFolder: record, ErrorRetryDuration: record, MaxFileSize: record, MaxRetryCount: record, IamAuthEnabled: record>, RedshiftSettings: record<AcceptAnyDate: record, AfterConnectScript: record, BucketFolder: record, BucketName: record, CaseSensitiveNames: record, CompUpdate: record, ConnectionTimeout: record, DatabaseName: record, DateFormat: record, EmptyAsNull: record, EncryptionMode: record, ExplicitIds: record, FileTransferUploadStreams: record, LoadTimeout: record, MaxFileSize: record, Password: record, Port: record, RemoveQuotes: record, ReplaceInvalidChars: record, ReplaceChars: record, ServerName: record, ServiceAccessRoleArn: record, ServerSideEncryptionKmsKeyId: record, TimeFormat: record, TrimBlanks: record, TruncateColumns: record, Username: record, WriteBufferSize: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, MapBooleanAsBoolean: record>, PostgreSQLSettings: record<AfterConnectScript: record, CaptureDdls: record, MaxFileSize: record, DatabaseName: record, DdlArtifactsSchema: record, ExecuteTimeout: record, FailTasksOnLobTruncation: record, HeartbeatEnable: record, HeartbeatSchema: record, HeartbeatFrequency: record, Password: record, Port: record, ServerName: record, Username: record, SlotName: record, PluginName: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, MapBooleanAsBoolean: record>, MySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, OracleSettings: record<AddSupplementalLogging: record, ArchivedLogDestId: record, AdditionalArchivedLogDestId: record, ExtraArchivedLogDestIds: record, AllowSelectNestedTables: record, ParallelAsmReadThreads: record, ReadAheadBlocks: record, AccessAlternateDirectly: record, UseAlternateFolderForOnline: record, OraclePathPrefix: record, UsePathPrefix: record, ReplacePathPrefix: record, EnableHomogenousTablespace: record, DirectPathNoLog: record, ArchivedLogsOnly: record, AsmPassword: record, AsmServer: record, AsmUser: record, CharLengthSemantics: record, DatabaseName: record, DirectPathParallelLoad: record, FailTasksOnLobTruncation: record, NumberDatatypeScale: record, Password: record, Port: record, ReadTableSpaceName: record, RetryInterval: record, SecurityDbEncryption: record, SecurityDbEncryptionName: record, ServerName: record, SpatialDataOptionToGeoJsonFunctionName: record, StandbyDelayTime: record, Username: record, UseBFile: record, UseDirectPathFullLoad: record, UseLogminerReader: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, SecretsManagerOracleAsmAccessRoleArn: record, SecretsManagerOracleAsmSecretId: record, TrimSpaceInChar: record, ConvertTimestampWithZoneToUTC: record>, SybaseSettings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, MicrosoftSQLServerSettings: record<Port: record, BcpPacketSize: record, DatabaseName: record, ControlTablesFileGroup: record, Password: record, QuerySingleAlwaysOnNode: record, ReadBackupOnly: record, SafeguardPolicy: record, ServerName: record, Username: record, UseBcpFullLoad: record, UseThirdPartyBackupDevice: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, TlogAccessMode: record, ForceLobLookup: record>, IBMDb2Settings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, SetDataCaptureChanges: record, CurrentLsn: record, MaxKBytesPerRead: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, DocDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, RedisSettings: record<ServerName: record, Port: record, SslSecurityProtocol: record, AuthType: record, AuthUserName: record, AuthPassword: record, SslCaCertificateArn: record>, GcpMySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteEndpoint")
  let req_body = {"EndpointArn": $endpoint_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes an DMS event subscription.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteEventSubscription
# operationId: DeleteEventSubscription
export def "x-amz-target-amazon-dm-sv20160101-delete-event-subscription delete" [
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
  --x-amz-target: string@x-amz-target-completer-13
  subscription_name: any
]: any -> record<EventSubscription: record<CustomerAwsId: record, CustSubscriptionId: record, SnsTopicArn: record, Status: record, SubscriptionCreationTime: record, SourceType: record, SourceIdsList: record, EventCategoriesList: record, Enabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteEventSubscription")
  let req_body = {"SubscriptionName": $subscription_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified Fleet Advisor collector.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteFleetAdvisorCollector
# operationId: DeleteFleetAdvisorCollector
export def "x-amz-target-amazon-dm-sv20160101-delete-fleet-advisor-collector delete" [
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
  --x-amz-target: string@x-amz-target-completer-14
  collector_referenced_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteFleetAdvisorCollector")
  let req_body = {"CollectorReferencedId": $collector_referenced_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified Fleet Advisor collector databases.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteFleetAdvisorDatabases
# operationId: DeleteFleetAdvisorDatabases
export def "x-amz-target-amazon-dm-sv20160101-delete-fleet-advisor-databases delete" [
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
  --x-amz-target: string@x-amz-target-completer-15
  database_ids: any
]: any -> record<DatabaseIds: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteFleetAdvisorDatabases")
  let req_body = {"DatabaseIds": $database_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified replication instance. You must delete any migration tasks that are associated with the replication instance before you can delete it.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationInstance
# operationId: DeleteReplicationInstance
export def "x-amz-target-amazon-dm-sv20160101-delete-replication-instance delete" [
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
  --x-amz-target: string@x-amz-target-completer-16
  replication_instance_arn: any
]: any -> record<ReplicationInstance: record<ReplicationInstanceIdentifier: record, ReplicationInstanceClass: record, ReplicationInstanceStatus: record, AllocatedStorage: record, InstanceCreateTime: record, VpcSecurityGroups: record, AvailabilityZone: record, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>, PreferredMaintenanceWindow: record, PendingModifiedValues: record<ReplicationInstanceClass: record, AllocatedStorage: record, MultiAZ: record, EngineVersion: record, NetworkType: record>, MultiAZ: record, EngineVersion: record, AutoMinorVersionUpgrade: record, KmsKeyId: record, ReplicationInstanceArn: record, ReplicationInstancePublicIpAddress: record, ReplicationInstancePrivateIpAddress: record, ReplicationInstancePublicIpAddresses: record, ReplicationInstancePrivateIpAddresses: record, ReplicationInstanceIpv6Addresses: record, PubliclyAccessible: record, SecondaryAvailabilityZone: record, FreeUntil: record, DnsNameServers: record, NetworkType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationInstance")
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a subnet group.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationSubnetGroup
# operationId: DeleteReplicationSubnetGroup
export def "x-amz-target-amazon-dm-sv20160101-delete-replication-subnet-group delete" [
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
  --x-amz-target: string@x-amz-target-completer-17
  replication_subnet_group_identifier: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationSubnetGroup")
  let req_body = {"ReplicationSubnetGroupIdentifier": $replication_subnet_group_identifier} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified replication task.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTask
# operationId: DeleteReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-delete-replication-task delete" [
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
  --x-amz-target: string@x-amz-target-completer-18
  replication_task_arn: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTask")
  let req_body = {"ReplicationTaskArn": $replication_task_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the record of a single premigration assessment run. This operation removes all metadata that DMS maintains about this assessment run. However, the operation leaves untouched all information about this assessment run that is stored in your Amazon S3 bucket.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTaskAssessmentRun
# operationId: DeleteReplicationTaskAssessmentRun
export def "x-amz-target-amazon-dm-sv20160101-delete-replication-task-assessment-run delete" [
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
  --x-amz-target: string@x-amz-target-completer-19
  replication_task_assessment_run_arn: any
]: any -> record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: record, ReplicationTaskArn: record, Status: record, ReplicationTaskAssessmentRunCreationDate: record, AssessmentProgress: record<IndividualAssessmentCount: record, IndividualAssessmentCompletedCount: record>, LastFailureMessage: record, ServiceAccessRoleArn: record, ResultLocationBucket: record, ResultLocationFolder: record, ResultEncryptionMode: record, ResultKmsKeyArn: record, AssessmentRunName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTaskAssessmentRun")
  let req_body = {"ReplicationTaskAssessmentRunArn": $replication_task_assessment_run_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all of the DMS attributes for a customer account. These attributes include DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region. This command does not take any parameters.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeAccountAttributes
# operationId: DescribeAccountAttributes
export def "x-amz-target-amazon-dm-sv20160101-describe-account-attributes get" [
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
  --x-amz-target: string@x-amz-target-completer-20
  --body: record
]: any -> record<AccountQuotas: record, UniqueAccountIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeAccountAttributes")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provides a list of individual assessments that you can specify for a new premigration assessment run, given one or more parameters. If you specify an existing migration task, this operation provides the default individual assessments you can specify for that task. Otherwise, the specified parameters model elements of a possible migration task on which to base a premigration assessment run. To use these migration task modeling parameters, you must specify an existing replication instance, a source database engine, a target database engine, and a migration type. This combination of parameters potentially limits the default individual assessments available for an assessment run created for a corresponding migration task. If you specify no parameters, this operation provides a list of all possible individual assessments that you can specify for an assessment run. If you specify any one of the task modeling parameters, you must specify all of them or the operation cannot provide a list of individual assessments. The only parameter that you can specify alone is for an existing migration task. The specified task definition then determines the default list of individual assessments that you can specify in an assessment run for the task.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeApplicableIndividualAssessments
# operationId: DescribeApplicableIndividualAssessments
export def "x-amz-target-amazon-dm-sv20160101-describe-applicable-individual-assessments get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21
  --replication-task-arn: any
  --replication-instance-arn: any
  --source-engine-name: any
  --target-engine-name: any
  --migration-type: any
  --max-records: any
  --marker: any
]: any -> record<IndividualAssessmentNames: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeApplicableIndividualAssessments" $qp)
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "ReplicationInstanceArn": $replication_instance_arn, "SourceEngineName": $source_engine_name, "TargetEngineName": $target_engine_name, "MigrationType": $migration_type, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provides a description of the certificate.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeCertificates
# operationId: DescribeCertificates
export def "x-amz-target-amazon-dm-sv20160101-describe-certificates get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22
  --filters: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, Certificates: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeCertificates" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeConnections
# operationId: DescribeConnections
export def "x-amz-target-amazon-dm-sv20160101-describe-connections get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23
  --filters: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, Connections: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeConnections" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns information about the possible endpoint settings available when you create an endpoint for a specific database engine.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointSettings
# operationId: DescribeEndpointSettings
export def "x-amz-target-amazon-dm-sv20160101-describe-endpoint-settings get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24
  engine_name: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, EndpointSettings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointSettings" $qp)
  let req_body = {"EngineName": $engine_name, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns information about the type of endpoints available.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointTypes
# operationId: DescribeEndpointTypes
export def "x-amz-target-amazon-dm-sv20160101-describe-endpoint-types get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25
  --filters: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, SupportedEndpointTypes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointTypes" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns information about the endpoints for your account in the current region.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEndpoints
# operationId: DescribeEndpoints
export def "x-amz-target-amazon-dm-sv20160101-describe-endpoints get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26
  --filters: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, Endpoints: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpoints" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in Working with Events and Notifications (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) in the Database Migration Service User Guide.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEventCategories
# operationId: DescribeEventCategories
export def "x-amz-target-amazon-dm-sv20160101-describe-event-categories get" [
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
  --x-amz-target: string@x-amz-target-completer-27
  --source-type: any
  --filters: any
]: any -> record<EventCategoryGroupList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventCategories")
  let req_body = {"SourceType": $source_type, "Filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all the event subscriptions for a customer account. The description of a subscription includes SubscriptionName, SNSTopicARN, CustomerID, SourceType, SourceID, CreationTime, and Status. If you specify SubscriptionName, this action lists the description for that subscription.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEventSubscriptions
# operationId: DescribeEventSubscriptions
export def "x-amz-target-amazon-dm-sv20160101-describe-event-subscriptions get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28
  --subscription-name: any
  --filters: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, EventSubscriptionsList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventSubscriptions" $qp)
  let req_body = {"SubscriptionName": $subscription_name, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on DMS events, see Working with Events and Notifications (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) in the Database Migration Service User Guide.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEvents
# operationId: DescribeEvents
export def "x-amz-target-amazon-dm-sv20160101-describe-events get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29
  --source-identifier: any
  --source-type: any
  --start-time: any
  --end-time: any
  --duration: any
  --event-categories: any
  --filters: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, Events: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEvents" $qp)
  let req_body = {"SourceIdentifier": $source_identifier, "SourceType": $source_type, "StartTime": $start_time, "EndTime": $end_time, "Duration": $duration, "EventCategories": $event_categories, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a list of the Fleet Advisor collectors in your account.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorCollectors
# operationId: DescribeFleetAdvisorCollectors
export def "x-amz-target-amazon-dm-sv20160101-describe-fleet-advisor-collectors get" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30
  --filters: any
  --max-records: any
  --next-token: any
]: any -> record<Collectors: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorCollectors" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a list of Fleet Advisor databases in your account.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorDatabases
# operationId: DescribeFleetAdvisorDatabases
export def "x-amz-target-amazon-dm-sv20160101-describe-fleet-advisor-databases get" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31
  --filters: any
  --max-records: any
  --next-token: any
]: any -> record<Databases: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorDatabases" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provides descriptions of large-scale assessment (LSA) analyses produced by your Fleet Advisor collectors.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorLsaAnalysis
# operationId: DescribeFleetAdvisorLsaAnalysis
export def "x-amz-target-amazon-dm-sv20160101-describe-fleet-advisor-lsa-analysis get" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32
  --max-records: any
  --next-token: any
]: any -> record<Analysis: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorLsaAnalysis" $qp)
  let req_body = {"MaxRecords": $max_records, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provides descriptions of the schemas discovered by your Fleet Advisor collectors.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorSchemaObjectSummary
# operationId: DescribeFleetAdvisorSchemaObjectSummary
export def "x-amz-target-amazon-dm-sv20160101-describe-fleet-advisor-schema-object-summary get" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33
  --filters: any
  --max-records: any
  --next-token: any
]: any -> record<FleetAdvisorSchemaObjects: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorSchemaObjectSummary" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a list of schemas detected by Fleet Advisor Collectors in your account.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorSchemas
# operationId: DescribeFleetAdvisorSchemas
export def "x-amz-target-amazon-dm-sv20160101-describe-fleet-advisor-schemas get" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34
  --filters: any
  --max-records: any
  --next-token: any
]: any -> record<FleetAdvisorSchemas: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorSchemas" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns information about the replication instance types that can be created in the specified region.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeOrderableReplicationInstances
# operationId: DescribeOrderableReplicationInstances
export def "x-amz-target-amazon-dm-sv20160101-describe-orderable-replication-instances get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-35
  --max-records: any
  --marker: any
]: any -> record<OrderableReplicationInstances: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeOrderableReplicationInstances" $qp)
  let req_body = {"MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# For internal use only
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribePendingMaintenanceActions
# operationId: DescribePendingMaintenanceActions
export def "x-amz-target-amazon-dm-sv20160101-describe-pending-maintenance-actions get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-36
  --replication-instance-arn: any
  --filters: any
  --marker: any
  --max-records: any
]: any -> record<PendingMaintenanceActions: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribePendingMaintenanceActions" $qp)
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "Filters": $filters, "Marker": $marker, "MaxRecords": $max_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a paginated list of limitations for recommendations of target Amazon Web Services engines.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeRecommendationLimitations
# operationId: DescribeRecommendationLimitations
export def "x-amz-target-amazon-dm-sv20160101-describe-recommendation-limitations get" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37
  --filters: any
  --max-records: any
  --next-token: any
]: any -> record<NextToken: record, Limitations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeRecommendationLimitations" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a paginated list of target engine recommendations for your source databases.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeRecommendations
# operationId: DescribeRecommendations
export def "x-amz-target-amazon-dm-sv20160101-describe-recommendations get" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38
  --filters: any
  --max-records: any
  --next-token: any
]: any -> record<NextToken: record, Recommendations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeRecommendations" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns the status of the RefreshSchemas operation.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeRefreshSchemasStatus
# operationId: DescribeRefreshSchemasStatus
export def "x-amz-target-amazon-dm-sv20160101-describe-refresh-schemas-status get" [
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
  --x-amz-target: string@x-amz-target-completer-39
  endpoint_arn: any
]: any -> record<RefreshSchemasStatus: record<EndpointArn: record, ReplicationInstanceArn: record, Status: record, LastRefreshDate: record, LastFailureMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeRefreshSchemasStatus")
  let req_body = {"EndpointArn": $endpoint_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns information about the task logs for the specified task.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs
# operationId: DescribeReplicationInstanceTaskLogs
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-instance-task-logs get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40
  replication_instance_arn: any
  --max-records: any
  --marker: any
]: any -> record<ReplicationInstanceArn: record, ReplicationInstanceTaskLogs: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs" $qp)
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns information about replication instances for your account in the current region.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstances
# operationId: DescribeReplicationInstances
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-instances get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-41
  --filters: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, ReplicationInstances: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstances" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns information about the replication subnet groups.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationSubnetGroups
# operationId: DescribeReplicationSubnetGroups
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-subnet-groups get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42
  --filters: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, ReplicationSubnetGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationSubnetGroups" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns the task assessment results from the Amazon S3 bucket that DMS creates in your Amazon Web Services account. This action always returns the latest results. For more information about DMS task assessments, see Creating a task assessment report (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.AssessmentReport.html) in the Database Migration Service User Guide.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults
# operationId: DescribeReplicationTaskAssessmentResults
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-task-assessment-results get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43
  --replication-task-arn: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, BucketName: record, ReplicationTaskAssessmentResults: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults" $qp)
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a paginated list of premigration assessment runs based on filter settings. These filter settings can specify a combination of premigration assessment runs, migration tasks, replication instances, and assessment run status values. This operation doesn't return information about individual assessments. For this information, see the DescribeReplicationTaskIndividualAssessments operation.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentRuns
# operationId: DescribeReplicationTaskAssessmentRuns
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-task-assessment-runs get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44
  --filters: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, ReplicationTaskAssessmentRuns: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentRuns" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a paginated list of individual assessments based on filter settings. These filter settings can specify a combination of premigration assessment runs, migration tasks, and assessment status values.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskIndividualAssessments
# operationId: DescribeReplicationTaskIndividualAssessments
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-task-individual-assessments get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45
  --filters: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, ReplicationTaskIndividualAssessments: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskIndividualAssessments" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns information about replication tasks for your account in the current region.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTasks
# operationId: DescribeReplicationTasks
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-tasks get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46
  --filters: any
  --max-records: any
  --marker: any
  --without-settings: any
]: any -> record<Marker: record, ReplicationTasks: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTasks" $qp)
  let req_body = {"Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "WithoutSettings": $without_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns information about the schema for the specified endpoint.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeSchemas
# operationId: DescribeSchemas
export def "x-amz-target-amazon-dm-sv20160101-describe-schemas get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47
  endpoint_arn: any
  --max-records: any
  --marker: any
]: any -> record<Marker: record, Schemas: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeSchemas" $qp)
  let req_body = {"EndpointArn": $endpoint_arn, "MaxRecords": $max_records, "Marker": $marker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted. Note that the "last updated" column the DMS console only indicates the time that DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeTableStatistics
# operationId: DescribeTableStatistics
export def "x-amz-target-amazon-dm-sv20160101-describe-table-statistics get" [
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
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48
  replication_task_arn: any
  --max-records: any
  --marker: any
  --filters: any
]: any -> record<ReplicationTaskArn: record, TableStatistics: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeTableStatistics" $qp)
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "MaxRecords": $max_records, "Marker": $marker, "Filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Uploads the specified certificate.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ImportCertificate
# operationId: ImportCertificate
export def "x-amz-target-amazon-dm-sv20160101-import-certificate import" [
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
  --x-amz-target: string@x-amz-target-completer-49
  certificate_identifier: any
  --certificate-pem: any
  --certificate-wallet: any
  --tags: any
]: any -> record<Certificate: record<CertificateIdentifier: record, CertificateCreationDate: record, CertificatePem: record, CertificateWallet: record, CertificateArn: record, CertificateOwner: record, ValidFromDate: record, ValidToDate: record, SigningAlgorithm: record, KeyLength: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ImportCertificate")
  let req_body = {"CertificateIdentifier": $certificate_identifier, "CertificatePem": $certificate_pem, "CertificateWallet": $certificate_wallet, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all metadata tags attached to an DMS resource, including replication instance, endpoint, subnet group, and migration task. For more information, see Tag (https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html) data type description.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ListTagsForResource
# operationId: ListTagsForResource
export def "x-amz-target-amazon-dm-sv20160101-list-tags-for-resource list" [
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
  --x-amz-target: string@x-amz-target-completer-50
  --resource-arn: any
  --resource-arn-list: any
]: any -> record<TagList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ListTagsForResource")
  let req_body = {"ResourceArn": $resource_arn, "ResourceArnList": $resource_arn_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Modifies the specified endpoint. For a MySQL source or target endpoint, don't explicitly specify the database using the DatabaseName request parameter on the ModifyEndpoint API call. Specifying DatabaseName when you modify a MySQL endpoint replicates all the task tables to this single database. For MySQL endpoints, you specify the database only when you specify the schema in the table-mapping rules of the DMS task.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ModifyEndpoint
# operationId: ModifyEndpoint
# --RedshiftSettings shape: {AcceptAnyDate?: any, AfterConnectScript?: any, BucketFolder?: any, BucketName?: any, CaseSensitiveNames?: any, CompUpdate?: any, ConnectionTimeout?: any, DatabaseName?: any, DateFormat?: any, EmptyAsNull?: any, EncryptionMode?: any, ExplicitIds?: any, FileTransferUploadStreams?: any, LoadTimeout?: any, MaxFileSize?: any, Password?: any, Port?: any, RemoveQuotes?: any, ReplaceInvalidChars?: any, ReplaceChars?: any, ServerName?: any, ServiceAccessRoleArn?: any, ServerSideEncryptionKmsKeyId?: any, ... (8 more fields)}
export def "x-amz-target-amazon-dm-sv20160101-modify-endpoint create" [
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
  --x-amz-target: string@x-amz-target-completer-51
  endpoint_arn: any
  --endpoint-identifier: any
  --endpoint-type: any
  --engine-name: any
  --username: any
  --password: any
  --server-name: any
  --port: any
  --database-name: any
  --extra-connection-attributes: any
  --certificate-arn: any
  --ssl-mode: any
  --service-access-role-arn: any
  --external-table-definition: any
  --dynamo-db-settings: any
  --s3-settings: any
  --dms-transfer-settings: any
  --mongo-db-settings: any
  --kinesis-settings: any
  --kafka-settings: any
  --elasticsearch-settings: any
  --neptune-settings: any
  --redshift-settings: record # Provides information that defines an Amazon Redshift endpoint. — shape: {AcceptAnyDate?: any, AfterConnectScript?: any, BucketFolder?: any, BucketName?: any, CaseSensitiveNames?: any, CompUpdate?: any, ConnectionTimeout?: any, DatabaseName?: any, DateFormat?: any, EmptyAsNull?: any, EncryptionMode?: any, ExplicitIds?: any, FileTransferUploadStreams?: any, LoadTimeout?: any, MaxFileSize?: any, Password?: any, Port?: any, RemoveQuotes?: any, ReplaceInvalidChars?: any, ReplaceChars?: any, ServerName?: any, ServiceAccessRoleArn?: any, ServerSideEncryptionKmsKeyId?: any, ... (8 more fields)}
  --postgre-sql-settings: any
  --my-sql-settings: any
  --oracle-settings: any
  --sybase-settings: any
  --microsoft-sql-server-settings: any
  --ibm-db2-settings: any
  --doc-db-settings: any
  --redis-settings: any
  --exact-settings: any
  --gcp-my-sql-settings: any
]: any -> record<Endpoint: record<EndpointIdentifier: record, EndpointType: record, EngineName: record, EngineDisplayName: record, Username: record, ServerName: record, Port: record, DatabaseName: record, ExtraConnectionAttributes: record, Status: record, KmsKeyId: record, EndpointArn: record, CertificateArn: record, SslMode: record, ServiceAccessRoleArn: record, ExternalTableDefinition: record, ExternalId: record, DynamoDbSettings: record<ServiceAccessRoleArn: record>, S3Settings: record<ServiceAccessRoleArn: record, ExternalTableDefinition: record, CsvRowDelimiter: record, CsvDelimiter: record, BucketFolder: record, BucketName: record, CompressionType: record, EncryptionMode: record, ServerSideEncryptionKmsKeyId: record, DataFormat: record, EncodingType: record, DictPageSizeLimit: record, RowGroupLength: record, DataPageSize: record, ParquetVersion: record, EnableStatistics: record, IncludeOpForFullLoad: record, CdcInsertsOnly: record, TimestampColumnName: record, ParquetTimestampInMillisecond: record, CdcInsertsAndUpdates: record, DatePartitionEnabled: record, DatePartitionSequence: record, DatePartitionDelimiter: record, UseCsvNoSupValue: record, CsvNoSupValue: record, PreserveTransactions: record, CdcPath: record, UseTaskStartTimeForFullLoadTimestamp: record, CannedAclForObjects: record, AddColumnName: record, CdcMaxBatchInterval: record, CdcMinFileSize: record, CsvNullValue: record, IgnoreHeaderRows: record, MaxFileSize: record, Rfc4180: record, DatePartitionTimezone: record, AddTrailingPaddingCharacter: record, ExpectedBucketOwner: record, GlueCatalogGeneration: record>, DmsTransferSettings: record<ServiceAccessRoleArn: record, BucketName: record>, MongoDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, AuthType: record, AuthMechanism: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, AuthSource: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, KinesisSettings: record<StreamArn: record, MessageFormat: record, ServiceAccessRoleArn: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, IncludeNullAndEmpty: record, NoHexPrefix: record>, KafkaSettings: record<Broker: record, Topic: record, MessageFormat: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, MessageMaxBytes: record, IncludeNullAndEmpty: record, SecurityProtocol: record, SslClientCertificateArn: record, SslClientKeyArn: record, SslClientKeyPassword: record, SslCaCertificateArn: record, SaslUsername: record, SaslPassword: record, NoHexPrefix: record, SaslMechanism: record>, ElasticsearchSettings: record<ServiceAccessRoleArn: record, EndpointUri: record, FullLoadErrorPercentage: record, ErrorRetryDuration: record, UseNewMappingType: record>, NeptuneSettings: record<ServiceAccessRoleArn: record, S3BucketName: record, S3BucketFolder: record, ErrorRetryDuration: record, MaxFileSize: record, MaxRetryCount: record, IamAuthEnabled: record>, RedshiftSettings: record<AcceptAnyDate: record, AfterConnectScript: record, BucketFolder: record, BucketName: record, CaseSensitiveNames: record, CompUpdate: record, ConnectionTimeout: record, DatabaseName: record, DateFormat: record, EmptyAsNull: record, EncryptionMode: record, ExplicitIds: record, FileTransferUploadStreams: record, LoadTimeout: record, MaxFileSize: record, Password: record, Port: record, RemoveQuotes: record, ReplaceInvalidChars: record, ReplaceChars: record, ServerName: record, ServiceAccessRoleArn: record, ServerSideEncryptionKmsKeyId: record, TimeFormat: record, TrimBlanks: record, TruncateColumns: record, Username: record, WriteBufferSize: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, MapBooleanAsBoolean: record>, PostgreSQLSettings: record<AfterConnectScript: record, CaptureDdls: record, MaxFileSize: record, DatabaseName: record, DdlArtifactsSchema: record, ExecuteTimeout: record, FailTasksOnLobTruncation: record, HeartbeatEnable: record, HeartbeatSchema: record, HeartbeatFrequency: record, Password: record, Port: record, ServerName: record, Username: record, SlotName: record, PluginName: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, MapBooleanAsBoolean: record>, MySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, OracleSettings: record<AddSupplementalLogging: record, ArchivedLogDestId: record, AdditionalArchivedLogDestId: record, ExtraArchivedLogDestIds: record, AllowSelectNestedTables: record, ParallelAsmReadThreads: record, ReadAheadBlocks: record, AccessAlternateDirectly: record, UseAlternateFolderForOnline: record, OraclePathPrefix: record, UsePathPrefix: record, ReplacePathPrefix: record, EnableHomogenousTablespace: record, DirectPathNoLog: record, ArchivedLogsOnly: record, AsmPassword: record, AsmServer: record, AsmUser: record, CharLengthSemantics: record, DatabaseName: record, DirectPathParallelLoad: record, FailTasksOnLobTruncation: record, NumberDatatypeScale: record, Password: record, Port: record, ReadTableSpaceName: record, RetryInterval: record, SecurityDbEncryption: record, SecurityDbEncryptionName: record, ServerName: record, SpatialDataOptionToGeoJsonFunctionName: record, StandbyDelayTime: record, Username: record, UseBFile: record, UseDirectPathFullLoad: record, UseLogminerReader: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, SecretsManagerOracleAsmAccessRoleArn: record, SecretsManagerOracleAsmSecretId: record, TrimSpaceInChar: record, ConvertTimestampWithZoneToUTC: record>, SybaseSettings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, MicrosoftSQLServerSettings: record<Port: record, BcpPacketSize: record, DatabaseName: record, ControlTablesFileGroup: record, Password: record, QuerySingleAlwaysOnNode: record, ReadBackupOnly: record, SafeguardPolicy: record, ServerName: record, Username: record, UseBcpFullLoad: record, UseThirdPartyBackupDevice: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, TlogAccessMode: record, ForceLobLookup: record>, IBMDb2Settings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, SetDataCaptureChanges: record, CurrentLsn: record, MaxKBytesPerRead: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, DocDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, RedisSettings: record<ServerName: record, Port: record, SslSecurityProtocol: record, AuthType: record, AuthUserName: record, AuthPassword: record, SslCaCertificateArn: record>, GcpMySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ModifyEndpoint")
  let req_body = {"EndpointArn": $endpoint_arn, "EndpointIdentifier": $endpoint_identifier, "EndpointType": $endpoint_type, "EngineName": $engine_name, "Username": $username, "Password": $password, "ServerName": $server_name, "Port": $port, "DatabaseName": $database_name, "ExtraConnectionAttributes": $extra_connection_attributes, "CertificateArn": $certificate_arn, "SslMode": $ssl_mode, "ServiceAccessRoleArn": $service_access_role_arn, "ExternalTableDefinition": $external_table_definition, "DynamoDbSettings": $dynamo_db_settings, "S3Settings": $s3_settings, "DmsTransferSettings": $dms_transfer_settings, "MongoDbSettings": $mongo_db_settings, "KinesisSettings": $kinesis_settings, "KafkaSettings": $kafka_settings, "ElasticsearchSettings": $elasticsearch_settings, "NeptuneSettings": $neptune_settings, "RedshiftSettings": $redshift_settings, "PostgreSQLSettings": $postgre_sql_settings, "MySQLSettings": $my_sql_settings, "OracleSettings": $oracle_settings, "SybaseSettings": $sybase_settings, "MicrosoftSQLServerSettings": $microsoft_sql_server_settings, "IBMDb2Settings": $ibm_db2_settings, "DocDbSettings": $doc_db_settings, "RedisSettings": $redis_settings, "ExactSettings": $exact_settings, "GcpMySQLSettings": $gcp_my_sql_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Modifies an existing DMS event notification subscription.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ModifyEventSubscription
# operationId: ModifyEventSubscription
export def "x-amz-target-amazon-dm-sv20160101-modify-event-subscription create" [
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
  --x-amz-target: string@x-amz-target-completer-52
  subscription_name: any
  --sns-topic-arn: any
  --source-type: any
  --event-categories: any
  --enabled: any
]: any -> record<EventSubscription: record<CustomerAwsId: record, CustSubscriptionId: record, SnsTopicArn: record, Status: record, SubscriptionCreationTime: record, SourceType: record, SourceIdsList: record, EventCategoriesList: record, Enabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ModifyEventSubscription")
  let req_body = {"SubscriptionName": $subscription_name, "SnsTopicArn": $sns_topic_arn, "SourceType": $source_type, "EventCategories": $event_categories, "Enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request. Some settings are applied during the maintenance window.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationInstance
# operationId: ModifyReplicationInstance
export def "x-amz-target-amazon-dm-sv20160101-modify-replication-instance create" [
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
  --x-amz-target: string@x-amz-target-completer-53
  replication_instance_arn: any
  --allocated-storage: any
  --apply-immediately: any
  --replication-instance-class: any
  --vpc-security-group-ids: any
  --preferred-maintenance-window: any
  --multi-az: any
  --engine-version: any
  --allow-major-version-upgrade: any
  --auto-minor-version-upgrade: any
  --replication-instance-identifier: any
  --network-type: any
]: any -> record<ReplicationInstance: record<ReplicationInstanceIdentifier: record, ReplicationInstanceClass: record, ReplicationInstanceStatus: record, AllocatedStorage: record, InstanceCreateTime: record, VpcSecurityGroups: record, AvailabilityZone: record, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>, PreferredMaintenanceWindow: record, PendingModifiedValues: record<ReplicationInstanceClass: record, AllocatedStorage: record, MultiAZ: record, EngineVersion: record, NetworkType: record>, MultiAZ: record, EngineVersion: record, AutoMinorVersionUpgrade: record, KmsKeyId: record, ReplicationInstanceArn: record, ReplicationInstancePublicIpAddress: record, ReplicationInstancePrivateIpAddress: record, ReplicationInstancePublicIpAddresses: record, ReplicationInstancePrivateIpAddresses: record, ReplicationInstanceIpv6Addresses: record, PubliclyAccessible: record, SecondaryAvailabilityZone: record, FreeUntil: record, DnsNameServers: record, NetworkType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationInstance")
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "AllocatedStorage": $allocated_storage, "ApplyImmediately": $apply_immediately, "ReplicationInstanceClass": $replication_instance_class, "VpcSecurityGroupIds": $vpc_security_group_ids, "PreferredMaintenanceWindow": $preferred_maintenance_window, "MultiAZ": $multi_az, "EngineVersion": $engine_version, "AllowMajorVersionUpgrade": $allow_major_version_upgrade, "AutoMinorVersionUpgrade": $auto_minor_version_upgrade, "ReplicationInstanceIdentifier": $replication_instance_identifier, "NetworkType": $network_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Modifies the settings for the specified replication subnet group.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationSubnetGroup
# operationId: ModifyReplicationSubnetGroup
export def "x-amz-target-amazon-dm-sv20160101-modify-replication-subnet-group create" [
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
  --x-amz-target: string@x-amz-target-completer-54
  replication_subnet_group_identifier: any
  --replication-subnet-group-description: any
  subnet_ids: any
]: any -> record<ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationSubnetGroup")
  let req_body = {"ReplicationSubnetGroupIdentifier": $replication_subnet_group_identifier, "ReplicationSubnetGroupDescription": $replication_subnet_group_description, "SubnetIds": $subnet_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Modifies the specified replication task. You can't modify the task endpoints. The task must be stopped before you can modify it. For more information about DMS tasks, see Working with Migration Tasks (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html) in the Database Migration Service User Guide.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationTask
# operationId: ModifyReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-modify-replication-task create" [
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
  --x-amz-target: string@x-amz-target-completer-55
  replication_task_arn: any
  --replication-task-identifier: any
  --migration-type: any
  --table-mappings: any
  --replication-task-settings: any
  --cdc-start-time: any
  --cdc-start-position: any
  --cdc-stop-position: any
  --task-data: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationTask")
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "ReplicationTaskIdentifier": $replication_task_identifier, "MigrationType": $migration_type, "TableMappings": $table_mappings, "ReplicationTaskSettings": $replication_task_settings, "CdcStartTime": $cdc_start_time, "CdcStartPosition": $cdc_start_position, "CdcStopPosition": $cdc_stop_position, "TaskData": $task_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Moves a replication task from its current replication instance to a different target replication instance using the specified parameters. The target replication instance must be created with the same or later DMS version as the current replication instance.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.MoveReplicationTask
# operationId: MoveReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-move-replication-task move" [
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
  --x-amz-target: string@x-amz-target-completer-56
  replication_task_arn: any
  target_replication_instance_arn: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.MoveReplicationTask")
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "TargetReplicationInstanceArn": $target_replication_instance_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.RebootReplicationInstance
# operationId: RebootReplicationInstance
export def "x-amz-target-amazon-dm-sv20160101-reboot-replication-instance create" [
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
  --x-amz-target: string@x-amz-target-completer-57
  replication_instance_arn: any
  --force-failover: any
  --force-planned-failover: any
]: any -> record<ReplicationInstance: record<ReplicationInstanceIdentifier: record, ReplicationInstanceClass: record, ReplicationInstanceStatus: record, AllocatedStorage: record, InstanceCreateTime: record, VpcSecurityGroups: record, AvailabilityZone: record, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>, PreferredMaintenanceWindow: record, PendingModifiedValues: record<ReplicationInstanceClass: record, AllocatedStorage: record, MultiAZ: record, EngineVersion: record, NetworkType: record>, MultiAZ: record, EngineVersion: record, AutoMinorVersionUpgrade: record, KmsKeyId: record, ReplicationInstanceArn: record, ReplicationInstancePublicIpAddress: record, ReplicationInstancePrivateIpAddress: record, ReplicationInstancePublicIpAddresses: record, ReplicationInstancePrivateIpAddresses: record, ReplicationInstanceIpv6Addresses: record, PubliclyAccessible: record, SecondaryAvailabilityZone: record, FreeUntil: record, DnsNameServers: record, NetworkType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.RebootReplicationInstance")
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "ForceFailover": $force_failover, "ForcePlannedFailover": $force_planned_failover} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.RefreshSchemas
# operationId: RefreshSchemas
export def "x-amz-target-amazon-dm-sv20160101-refresh-schemas refresh" [
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
  --x-amz-target: string@x-amz-target-completer-58
  endpoint_arn: any
  replication_instance_arn: any
]: any -> record<RefreshSchemasStatus: record<EndpointArn: record, ReplicationInstanceArn: record, Status: record, LastRefreshDate: record, LastFailureMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.RefreshSchemas")
  let req_body = {"EndpointArn": $endpoint_arn, "ReplicationInstanceArn": $replication_instance_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Reloads the target database table with the source data. You can only use this operation with a task in the RUNNING state, otherwise the service will throw an InvalidResourceStateFault exception.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ReloadTables
# operationId: ReloadTables
export def "x-amz-target-amazon-dm-sv20160101-reload-tables reload" [
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
  --x-amz-target: string@x-amz-target-completer-59
  replication_task_arn: any
  tables_to_reload: any
  --reload-option: any
]: any -> record<ReplicationTaskArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ReloadTables")
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "TablesToReload": $tables_to_reload, "ReloadOption": $reload_option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Removes metadata tags from an DMS resource, including replication instance, endpoint, subnet group, and migration task. For more information, see Tag (https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html) data type description.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.RemoveTagsFromResource
# operationId: RemoveTagsFromResource
export def "x-amz-target-amazon-dm-sv20160101-remove-tags-from-resource delete" [
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
  --x-amz-target: string@x-amz-target-completer-60
  resource_arn: any
  tag_keys: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.RemoveTagsFromResource")
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Runs large-scale assessment (LSA) analysis on every Fleet Advisor collector in your account.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.RunFleetAdvisorLsaAnalysis
# operationId: RunFleetAdvisorLsaAnalysis
export def "x-amz-target-amazon-dm-sv20160101-run-fleet-advisor-lsa-analysis create" [
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
  --x-amz-target: string@x-amz-target-completer-61
]: nothing -> record<LsaAnalysisId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.RunFleetAdvisorLsaAnalysis")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Starts the analysis of your source database to provide recommendations of target engines. You can create recommendations for multiple source databases using BatchStartRecommendations (https://docs.aws.amazon.com/dms/latest/APIReference/API_BatchStartRecommendations.html).
#
# POST /#X-Amz-Target=AmazonDMSv20160101.StartRecommendations
# operationId: StartRecommendations
export def "x-amz-target-amazon-dm-sv20160101-start-recommendations start" [
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
  --x-amz-target: string@x-amz-target-completer-62
  database_id: any
  settings: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.StartRecommendations")
  let req_body = {"DatabaseId": $database_id, "Settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Starts the replication task. For more information about DMS tasks, see Working with Migration Tasks (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html) in the Database Migration Service User Guide.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.StartReplicationTask
# operationId: StartReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-start-replication-task start" [
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
  --x-amz-target: string@x-amz-target-completer-63
  replication_task_arn: any
  start_replication_task_type: any
  --cdc-start-time: any
  --cdc-start-position: any
  --cdc-stop-position: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTask")
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "StartReplicationTaskType": $start_replication_task_type, "CdcStartTime": $cdc_start_time, "CdcStartPosition": $cdc_start_position, "CdcStopPosition": $cdc_stop_position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Starts the replication task assessment for unsupported data types in the source database. You can only use this operation for a task if the following conditions are true: The task must be in the stopped state. The task must have successful connections to the source and target. If either of these conditions are not met, an InvalidResourceStateFault error will result. For information about DMS task assessments, see Creating a task assessment report (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.AssessmentReport.html) in the Database Migration Service User Guide.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessment
# operationId: StartReplicationTaskAssessment
export def "x-amz-target-amazon-dm-sv20160101-start-replication-task-assessment start" [
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
  --x-amz-target: string@x-amz-target-completer-64
  replication_task_arn: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessment")
  let req_body = {"ReplicationTaskArn": $replication_task_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Starts a new premigration assessment run for one or more individual assessments of a migration task. The assessments that you can specify depend on the source and target database engine and the migration type defined for the given task. To run this operation, your migration task must already be created. After you run this operation, you can review the status of each individual assessment. You can also run the migration task manually after the assessment run and its individual assessments complete.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessmentRun
# operationId: StartReplicationTaskAssessmentRun
export def "x-amz-target-amazon-dm-sv20160101-start-replication-task-assessment-run start" [
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
  --x-amz-target: string@x-amz-target-completer-65
  replication_task_arn: any
  service_access_role_arn: any
  result_location_bucket: any
  --result-location-folder: any
  --result-encryption-mode: any
  --result-kms-key-arn: any
  assessment_run_name: any
  --include-only: any
  --exclude: any
]: any -> record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: record, ReplicationTaskArn: record, Status: record, ReplicationTaskAssessmentRunCreationDate: record, AssessmentProgress: record<IndividualAssessmentCount: record, IndividualAssessmentCompletedCount: record>, LastFailureMessage: record, ServiceAccessRoleArn: record, ResultLocationBucket: record, ResultLocationFolder: record, ResultEncryptionMode: record, ResultKmsKeyArn: record, AssessmentRunName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessmentRun")
  let req_body = {"ReplicationTaskArn": $replication_task_arn, "ServiceAccessRoleArn": $service_access_role_arn, "ResultLocationBucket": $result_location_bucket, "ResultLocationFolder": $result_location_folder, "ResultEncryptionMode": $result_encryption_mode, "ResultKmsKeyArn": $result_kms_key_arn, "AssessmentRunName": $assessment_run_name, "IncludeOnly": $include_only, "Exclude": $exclude} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Stops the replication task.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.StopReplicationTask
# operationId: StopReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-stop-replication-task stop" [
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
  --x-amz-target: string@x-amz-target-completer-66
  replication_task_arn: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.StopReplicationTask")
  let req_body = {"ReplicationTaskArn": $replication_task_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Tests the connection between the replication instance and the endpoint.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.TestConnection
# operationId: TestConnection
export def "x-amz-target-amazon-dm-sv20160101-test-connection test" [
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
  --x-amz-target: string@x-amz-target-completer-67
  replication_instance_arn: any
  endpoint_arn: any
]: any -> record<Connection: record<ReplicationInstanceArn: record, EndpointArn: record, Status: record, LastFailureMessage: record, EndpointIdentifier: record, ReplicationInstanceIdentifier: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.TestConnection")
  let req_body = {"ReplicationInstanceArn": $replication_instance_arn, "EndpointArn": $endpoint_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Migrates 10 active and enabled Amazon SNS subscriptions at a time and converts them to corresponding Amazon EventBridge rules. By default, this operation migrates subscriptions only when all your replication instance versions are 3.4.6 or higher. If any replication instances are from versions earlier than 3.4.6, the operation raises an error and tells you to upgrade these instances to version 3.4.6 or higher. To enable migration regardless of version, set the Force option to true. However, if you don't upgrade instances earlier than version 3.4.6, some types of events might not be available when you use Amazon EventBridge. To call this operation, make sure that you have certain permissions added to your user account. For more information, see Migrating event subscriptions to Amazon EventBridge (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html#CHAP_Events-migrate-to-eventbridge) in the Amazon Web Services Database Migration Service User Guide.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.UpdateSubscriptionsToEventBridge
# operationId: UpdateSubscriptionsToEventBridge
export def "x-amz-target-amazon-dm-sv20160101-update-subscriptions-to-event-bridge update" [
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
  --x-amz-target: string@x-amz-target-completer-68
  --force-move: any
]: any -> record<Result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.UpdateSubscriptionsToEventBridge")
  let req_body = {"ForceMove": $force_move} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
