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

def base-url-completer [] { ["http://dms.us-east-1.amazonaws.com" "http://dms.us-east-2.amazonaws.com" "http://dms.us-west-1.amazonaws.com" "http://dms.us-west-2.amazonaws.com" "http://dms.us-gov-west-1.amazonaws.com" "http://dms.us-gov-east-1.amazonaws.com" "http://dms.ca-central-1.amazonaws.com" "http://dms.eu-north-1.amazonaws.com" "http://dms.eu-west-1.amazonaws.com" "http://dms.eu-west-2.amazonaws.com" "http://dms.eu-west-3.amazonaws.com" "http://dms.eu-central-1.amazonaws.com" "http://dms.eu-south-1.amazonaws.com" "http://dms.af-south-1.amazonaws.com" "http://dms.ap-northeast-1.amazonaws.com" "http://dms.ap-northeast-2.amazonaws.com" "http://dms.ap-northeast-3.amazonaws.com" "http://dms.ap-southeast-1.amazonaws.com" "http://dms.ap-southeast-2.amazonaws.com" "http://dms.ap-east-1.amazonaws.com" "http://dms.ap-south-1.amazonaws.com" "http://dms.sa-east-1.amazonaws.com" "http://dms.me-south-1.amazonaws.com" "https://dms.us-east-1.amazonaws.com" "https://dms.us-east-2.amazonaws.com" "https://dms.us-west-1.amazonaws.com" "https://dms.us-west-2.amazonaws.com" "https://dms.us-gov-west-1.amazonaws.com" "https://dms.us-gov-east-1.amazonaws.com" "https://dms.ca-central-1.amazonaws.com" "https://dms.eu-north-1.amazonaws.com" "https://dms.eu-west-1.amazonaws.com" "https://dms.eu-west-2.amazonaws.com" "https://dms.eu-west-3.amazonaws.com" "https://dms.eu-central-1.amazonaws.com" "https://dms.eu-south-1.amazonaws.com" "https://dms.af-south-1.amazonaws.com" "https://dms.ap-northeast-1.amazonaws.com" "https://dms.ap-northeast-2.amazonaws.com" "https://dms.ap-northeast-3.amazonaws.com" "https://dms.ap-southeast-1.amazonaws.com" "https://dms.ap-southeast-2.amazonaws.com" "https://dms.ap-east-1.amazonaws.com" "https://dms.ap-south-1.amazonaws.com" "https://dms.sa-east-1.amazonaws.com" "https://dms.me-south-1.amazonaws.com" "http://dms.cn-north-1.amazonaws.com.cn" "http://dms.cn-northwest-1.amazonaws.com.cn" "https://dms.cn-north-1.amazonaws.com.cn" "https://dms.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def X-Amz-Target-completer [] { ["AmazonDMSv20160101.AddTagsToResource"] }
def X-Amz-Target-completer-1 [] { ["AmazonDMSv20160101.ApplyPendingMaintenanceAction"] }
def X-Amz-Target-completer-2 [] { ["AmazonDMSv20160101.BatchStartRecommendations"] }
def X-Amz-Target-completer-3 [] { ["AmazonDMSv20160101.CancelReplicationTaskAssessmentRun"] }
def X-Amz-Target-completer-4 [] { ["AmazonDMSv20160101.CreateEndpoint"] }
def X-Amz-Target-completer-5 [] { ["AmazonDMSv20160101.CreateEventSubscription"] }
def X-Amz-Target-completer-6 [] { ["AmazonDMSv20160101.CreateFleetAdvisorCollector"] }
def X-Amz-Target-completer-7 [] { ["AmazonDMSv20160101.CreateReplicationInstance"] }
def X-Amz-Target-completer-8 [] { ["AmazonDMSv20160101.CreateReplicationSubnetGroup"] }
def X-Amz-Target-completer-9 [] { ["AmazonDMSv20160101.CreateReplicationTask"] }
def X-Amz-Target-completer-10 [] { ["AmazonDMSv20160101.DeleteCertificate"] }
def X-Amz-Target-completer-11 [] { ["AmazonDMSv20160101.DeleteConnection"] }
def X-Amz-Target-completer-12 [] { ["AmazonDMSv20160101.DeleteEndpoint"] }
def X-Amz-Target-completer-13 [] { ["AmazonDMSv20160101.DeleteEventSubscription"] }
def X-Amz-Target-completer-14 [] { ["AmazonDMSv20160101.DeleteFleetAdvisorCollector"] }
def X-Amz-Target-completer-15 [] { ["AmazonDMSv20160101.DeleteFleetAdvisorDatabases"] }
def X-Amz-Target-completer-16 [] { ["AmazonDMSv20160101.DeleteReplicationInstance"] }
def X-Amz-Target-completer-17 [] { ["AmazonDMSv20160101.DeleteReplicationSubnetGroup"] }
def X-Amz-Target-completer-18 [] { ["AmazonDMSv20160101.DeleteReplicationTask"] }
def X-Amz-Target-completer-19 [] { ["AmazonDMSv20160101.DeleteReplicationTaskAssessmentRun"] }
def X-Amz-Target-completer-20 [] { ["AmazonDMSv20160101.DescribeAccountAttributes"] }
def X-Amz-Target-completer-21 [] { ["AmazonDMSv20160101.DescribeApplicableIndividualAssessments"] }
def X-Amz-Target-completer-22 [] { ["AmazonDMSv20160101.DescribeCertificates"] }
def X-Amz-Target-completer-23 [] { ["AmazonDMSv20160101.DescribeConnections"] }
def X-Amz-Target-completer-24 [] { ["AmazonDMSv20160101.DescribeEndpointSettings"] }
def X-Amz-Target-completer-25 [] { ["AmazonDMSv20160101.DescribeEndpointTypes"] }
def X-Amz-Target-completer-26 [] { ["AmazonDMSv20160101.DescribeEndpoints"] }
def X-Amz-Target-completer-27 [] { ["AmazonDMSv20160101.DescribeEventCategories"] }
def X-Amz-Target-completer-28 [] { ["AmazonDMSv20160101.DescribeEventSubscriptions"] }
def X-Amz-Target-completer-29 [] { ["AmazonDMSv20160101.DescribeEvents"] }
def X-Amz-Target-completer-30 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorCollectors"] }
def X-Amz-Target-completer-31 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorDatabases"] }
def X-Amz-Target-completer-32 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorLsaAnalysis"] }
def X-Amz-Target-completer-33 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorSchemaObjectSummary"] }
def X-Amz-Target-completer-34 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorSchemas"] }
def X-Amz-Target-completer-35 [] { ["AmazonDMSv20160101.DescribeOrderableReplicationInstances"] }
def X-Amz-Target-completer-36 [] { ["AmazonDMSv20160101.DescribePendingMaintenanceActions"] }
def X-Amz-Target-completer-37 [] { ["AmazonDMSv20160101.DescribeRecommendationLimitations"] }
def X-Amz-Target-completer-38 [] { ["AmazonDMSv20160101.DescribeRecommendations"] }
def X-Amz-Target-completer-39 [] { ["AmazonDMSv20160101.DescribeRefreshSchemasStatus"] }
def X-Amz-Target-completer-40 [] { ["AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs"] }
def X-Amz-Target-completer-41 [] { ["AmazonDMSv20160101.DescribeReplicationInstances"] }
def X-Amz-Target-completer-42 [] { ["AmazonDMSv20160101.DescribeReplicationSubnetGroups"] }
def X-Amz-Target-completer-43 [] { ["AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults"] }
def X-Amz-Target-completer-44 [] { ["AmazonDMSv20160101.DescribeReplicationTaskAssessmentRuns"] }
def X-Amz-Target-completer-45 [] { ["AmazonDMSv20160101.DescribeReplicationTaskIndividualAssessments"] }
def X-Amz-Target-completer-46 [] { ["AmazonDMSv20160101.DescribeReplicationTasks"] }
def X-Amz-Target-completer-47 [] { ["AmazonDMSv20160101.DescribeSchemas"] }
def X-Amz-Target-completer-48 [] { ["AmazonDMSv20160101.DescribeTableStatistics"] }
def X-Amz-Target-completer-49 [] { ["AmazonDMSv20160101.ImportCertificate"] }
def X-Amz-Target-completer-50 [] { ["AmazonDMSv20160101.ListTagsForResource"] }
def X-Amz-Target-completer-51 [] { ["AmazonDMSv20160101.ModifyEndpoint"] }
def X-Amz-Target-completer-52 [] { ["AmazonDMSv20160101.ModifyEventSubscription"] }
def X-Amz-Target-completer-53 [] { ["AmazonDMSv20160101.ModifyReplicationInstance"] }
def X-Amz-Target-completer-54 [] { ["AmazonDMSv20160101.ModifyReplicationSubnetGroup"] }
def X-Amz-Target-completer-55 [] { ["AmazonDMSv20160101.ModifyReplicationTask"] }
def X-Amz-Target-completer-56 [] { ["AmazonDMSv20160101.MoveReplicationTask"] }
def X-Amz-Target-completer-57 [] { ["AmazonDMSv20160101.RebootReplicationInstance"] }
def X-Amz-Target-completer-58 [] { ["AmazonDMSv20160101.RefreshSchemas"] }
def X-Amz-Target-completer-59 [] { ["AmazonDMSv20160101.ReloadTables"] }
def X-Amz-Target-completer-60 [] { ["AmazonDMSv20160101.RemoveTagsFromResource"] }
def X-Amz-Target-completer-61 [] { ["AmazonDMSv20160101.RunFleetAdvisorLsaAnalysis"] }
def X-Amz-Target-completer-62 [] { ["AmazonDMSv20160101.StartRecommendations"] }
def X-Amz-Target-completer-63 [] { ["AmazonDMSv20160101.StartReplicationTask"] }
def X-Amz-Target-completer-64 [] { ["AmazonDMSv20160101.StartReplicationTaskAssessment"] }
def X-Amz-Target-completer-65 [] { ["AmazonDMSv20160101.StartReplicationTaskAssessmentRun"] }
def X-Amz-Target-completer-66 [] { ["AmazonDMSv20160101.StopReplicationTask"] }
def X-Amz-Target-completer-67 [] { ["AmazonDMSv20160101.TestConnection"] }
def X-Amz-Target-completer-68 [] { ["AmazonDMSv20160101.UpdateSubscriptionsToEventBridge"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-amazon-dm-sv20160101-add-tags-to-resource AddTagsToResource" } } | get name | first)
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

# Adds metadata tags to an DMS resource, including replication instance, endpoint, subnet group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS. For more information, see <a href="https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html"> <code>Tag</code> </a> data type description.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.AddTagsToResource
# operationId: AddTagsToResource
export def "x-amz-target-amazon-dm-sv20160101-add-tags-to-resource AddTagsToResource" [
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
  ResourceArn: any
  Tags: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.AddTagsToResource")
  let body = {ResourceArn: $ResourceArn, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Applies a pending maintenance action to a resource (for example, to a replication instance).
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ApplyPendingMaintenanceAction
# operationId: ApplyPendingMaintenanceAction
export def "x-amz-target-amazon-dm-sv20160101-apply-pending-maintenance-action ApplyPendingMaintenanceAction" [
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
  ReplicationInstanceArn: any
  ApplyAction: any
  OptInType: any
]: any -> record<ResourcePendingMaintenanceActions: record<ResourceIdentifier: record, PendingMaintenanceActionDetails: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ApplyPendingMaintenanceAction")
  let body = {ReplicationInstanceArn: $ReplicationInstanceArn, ApplyAction: $ApplyAction, OptInType: $OptInType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Starts the analysis of up to 20 source databases to recommend target engines for each source database. This is a batch version of <a href="https://docs.aws.amazon.com/dms/latest/APIReference/API_StartRecommendations.html">StartRecommendations</a>.</p> <p>The result of analysis of each source database is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.BatchStartRecommendations
# operationId: BatchStartRecommendations
export def "x-amz-target-amazon-dm-sv20160101-batch-start-recommendations BatchStartRecommendations" [
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
  --Data: any
]: any -> record<ErrorEntries: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.BatchStartRecommendations")
  let body = {Data: $Data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Cancels a single premigration assessment run.</p> <p>This operation prevents any individual assessments from running if they haven't started running. It also attempts to cancel any individual assessments that are currently running.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CancelReplicationTaskAssessmentRun
# operationId: CancelReplicationTaskAssessmentRun
export def "x-amz-target-amazon-dm-sv20160101-cancel-replication-task-assessment-run CancelReplicationTaskAssessmentRun" [
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
  ReplicationTaskAssessmentRunArn: any
]: any -> record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: record, ReplicationTaskArn: record, Status: record, ReplicationTaskAssessmentRunCreationDate: record, AssessmentProgress: record<IndividualAssessmentCount: record, IndividualAssessmentCompletedCount: record>, LastFailureMessage: record, ServiceAccessRoleArn: record, ResultLocationBucket: record, ResultLocationFolder: record, ResultEncryptionMode: record, ResultKmsKeyArn: record, AssessmentRunName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CancelReplicationTaskAssessmentRun")
  let body = {ReplicationTaskAssessmentRunArn: $ReplicationTaskAssessmentRunArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an endpoint using the provided settings.</p> <note> <p>For a MySQL source or target endpoint, don't explicitly specify the database using the <code>DatabaseName</code> request parameter on the <code>CreateEndpoint</code> API call. Specifying <code>DatabaseName</code> when you create a MySQL endpoint replicates all the task tables to this single database. For MySQL endpoints, you specify the database only when you specify the schema in the table-mapping rules of the DMS task.</p> </note>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateEndpoint
# operationId: CreateEndpoint
# --RedshiftSettings shape: {AcceptAnyDate?: any, AfterConnectScript?: any, BucketFolder?: any, BucketName?: any, CaseSensitiveNames?: any, CompUpdate?: any, ConnectionTimeout?: any, DatabaseName?: any, DateFormat?: any, EmptyAsNull?: any, EncryptionMode?: any, ExplicitIds?: any, FileTransferUploadStreams?: any, LoadTimeout?: any, MaxFileSize?: any, Password?: any, Port?: any, RemoveQuotes?: any, ReplaceInvalidChars?: any, ReplaceChars?: any, ServerName?: any, ServiceAccessRoleArn?: any, ServerSideEncryptionKmsKeyId?: any, TimeFormat?: any, TrimBlanks?: any, TruncateColumns?: any, Username?: any, WriteBufferSize?: any, SecretsManagerAccessRoleArn?: any, SecretsManagerSecretId?: any, MapBooleanAsBoolean?: any}
# --DocDbSettings shape: {Username?: any, Password?: any, ServerName?: any, Port?: any, DatabaseName?: any, NestingLevel?: any, ExtractDocId?: any, DocsToInvestigate?: any, KmsKeyId?: any, SecretsManagerAccessRoleArn?: any, SecretsManagerSecretId?: any}
export def "x-amz-target-amazon-dm-sv20160101-create-endpoint CreateEndpoint" [
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
  EndpointIdentifier: any
  EndpointType: any
  EngineName: any
  --Username: any
  --Password: any
  --ServerName: any
  --Port: any
  --DatabaseName: any
  --ExtraConnectionAttributes: any
  --KmsKeyId: any
  --Tags: any
  --CertificateArn: any
  --SslMode: any
  --ServiceAccessRoleArn: any
  --ExternalTableDefinition: any
  --DynamoDbSettings: any
  --S3Settings: any
  --DmsTransferSettings: any
  --MongoDbSettings: any
  --KinesisSettings: any
  --KafkaSettings: any
  --ElasticsearchSettings: any
  --NeptuneSettings: any
  --RedshiftSettings: record # Provides information that defines an Amazon Redshift endpoint. — shape: {AcceptAnyDate?: any, AfterConnectScript?: any, BucketFolder?: any, BucketName?: any, CaseSensitiveNames?: any, CompUpdate?: any, ConnectionTimeout?: any, DatabaseName?: any, DateFormat?: any, EmptyAsNull?: any, EncryptionMode?: any, ExplicitIds?: any, FileTransferUploadStreams?: any, LoadTimeout?: any, MaxFileSize?: any, Password?: any, Port?: any, RemoveQuotes?: any, ReplaceInvalidChars?: any, ReplaceChars?: any, ServerName?: any, ServiceAccessRoleArn?: any, ServerSideEncryptionKmsKeyId?: any, TimeFormat?: any, TrimBlanks?: any, TruncateColumns?: any, Username?: any, WriteBufferSize?: any, SecretsManagerAccessRoleArn?: any, SecretsManagerSecretId?: any, MapBooleanAsBoolean?: any}
  --PostgreSQLSettings: any
  --MySQLSettings: any
  --OracleSettings: any
  --SybaseSettings: any
  --MicrosoftSQLServerSettings: any
  --IBMDb2Settings: any
  --ResourceIdentifier: any
  --DocDbSettings: record # Provides information that defines a DocumentDB endpoint. — shape: {Username?: any, Password?: any, ServerName?: any, Port?: any, DatabaseName?: any, NestingLevel?: any, ExtractDocId?: any, DocsToInvestigate?: any, KmsKeyId?: any, SecretsManagerAccessRoleArn?: any, SecretsManagerSecretId?: any}
  --RedisSettings: any
  --GcpMySQLSettings: any
]: any -> record<Endpoint: record<EndpointIdentifier: record, EndpointType: record, EngineName: record, EngineDisplayName: record, Username: record, ServerName: record, Port: record, DatabaseName: record, ExtraConnectionAttributes: record, Status: record, KmsKeyId: record, EndpointArn: record, CertificateArn: record, SslMode: record, ServiceAccessRoleArn: record, ExternalTableDefinition: record, ExternalId: record, DynamoDbSettings: record<ServiceAccessRoleArn: record>, S3Settings: record<ServiceAccessRoleArn: record, ExternalTableDefinition: record, CsvRowDelimiter: record, CsvDelimiter: record, BucketFolder: record, BucketName: record, CompressionType: record, EncryptionMode: record, ServerSideEncryptionKmsKeyId: record, DataFormat: record, EncodingType: record, DictPageSizeLimit: record, RowGroupLength: record, DataPageSize: record, ParquetVersion: record, EnableStatistics: record, IncludeOpForFullLoad: record, CdcInsertsOnly: record, TimestampColumnName: record, ParquetTimestampInMillisecond: record, CdcInsertsAndUpdates: record, DatePartitionEnabled: record, DatePartitionSequence: record, DatePartitionDelimiter: record, UseCsvNoSupValue: record, CsvNoSupValue: record, PreserveTransactions: record, CdcPath: record, UseTaskStartTimeForFullLoadTimestamp: record, CannedAclForObjects: record, AddColumnName: record, CdcMaxBatchInterval: record, CdcMinFileSize: record, CsvNullValue: record, IgnoreHeaderRows: record, MaxFileSize: record, Rfc4180: record, DatePartitionTimezone: record, AddTrailingPaddingCharacter: record, ExpectedBucketOwner: record, GlueCatalogGeneration: record>, DmsTransferSettings: record<ServiceAccessRoleArn: record, BucketName: record>, MongoDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, AuthType: record, AuthMechanism: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, AuthSource: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, KinesisSettings: record<StreamArn: record, MessageFormat: record, ServiceAccessRoleArn: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, IncludeNullAndEmpty: record, NoHexPrefix: record>, KafkaSettings: record<Broker: record, Topic: record, MessageFormat: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, MessageMaxBytes: record, IncludeNullAndEmpty: record, SecurityProtocol: record, SslClientCertificateArn: record, SslClientKeyArn: record, SslClientKeyPassword: record, SslCaCertificateArn: record, SaslUsername: record, SaslPassword: record, NoHexPrefix: record, SaslMechanism: record>, ElasticsearchSettings: record<ServiceAccessRoleArn: record, EndpointUri: record, FullLoadErrorPercentage: record, ErrorRetryDuration: record, UseNewMappingType: record>, NeptuneSettings: record<ServiceAccessRoleArn: record, S3BucketName: record, S3BucketFolder: record, ErrorRetryDuration: record, MaxFileSize: record, MaxRetryCount: record, IamAuthEnabled: record>, RedshiftSettings: record<AcceptAnyDate: record, AfterConnectScript: record, BucketFolder: record, BucketName: record, CaseSensitiveNames: record, CompUpdate: record, ConnectionTimeout: record, DatabaseName: record, DateFormat: record, EmptyAsNull: record, EncryptionMode: record, ExplicitIds: record, FileTransferUploadStreams: record, LoadTimeout: record, MaxFileSize: record, Password: record, Port: record, RemoveQuotes: record, ReplaceInvalidChars: record, ReplaceChars: record, ServerName: record, ServiceAccessRoleArn: record, ServerSideEncryptionKmsKeyId: record, TimeFormat: record, TrimBlanks: record, TruncateColumns: record, Username: record, WriteBufferSize: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, MapBooleanAsBoolean: record>, PostgreSQLSettings: record<AfterConnectScript: record, CaptureDdls: record, MaxFileSize: record, DatabaseName: record, DdlArtifactsSchema: record, ExecuteTimeout: record, FailTasksOnLobTruncation: record, HeartbeatEnable: record, HeartbeatSchema: record, HeartbeatFrequency: record, Password: record, Port: record, ServerName: record, Username: record, SlotName: record, PluginName: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, MapBooleanAsBoolean: record>, MySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, OracleSettings: record<AddSupplementalLogging: record, ArchivedLogDestId: record, AdditionalArchivedLogDestId: record, ExtraArchivedLogDestIds: record, AllowSelectNestedTables: record, ParallelAsmReadThreads: record, ReadAheadBlocks: record, AccessAlternateDirectly: record, UseAlternateFolderForOnline: record, OraclePathPrefix: record, UsePathPrefix: record, ReplacePathPrefix: record, EnableHomogenousTablespace: record, DirectPathNoLog: record, ArchivedLogsOnly: record, AsmPassword: record, AsmServer: record, AsmUser: record, CharLengthSemantics: record, DatabaseName: record, DirectPathParallelLoad: record, FailTasksOnLobTruncation: record, NumberDatatypeScale: record, Password: record, Port: record, ReadTableSpaceName: record, RetryInterval: record, SecurityDbEncryption: record, SecurityDbEncryptionName: record, ServerName: record, SpatialDataOptionToGeoJsonFunctionName: record, StandbyDelayTime: record, Username: record, UseBFile: record, UseDirectPathFullLoad: record, UseLogminerReader: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, SecretsManagerOracleAsmAccessRoleArn: record, SecretsManagerOracleAsmSecretId: record, TrimSpaceInChar: record, ConvertTimestampWithZoneToUTC: record>, SybaseSettings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, MicrosoftSQLServerSettings: record<Port: record, BcpPacketSize: record, DatabaseName: record, ControlTablesFileGroup: record, Password: record, QuerySingleAlwaysOnNode: record, ReadBackupOnly: record, SafeguardPolicy: record, ServerName: record, Username: record, UseBcpFullLoad: record, UseThirdPartyBackupDevice: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, TlogAccessMode: record, ForceLobLookup: record>, IBMDb2Settings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, SetDataCaptureChanges: record, CurrentLsn: record, MaxKBytesPerRead: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, DocDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, RedisSettings: record<ServerName: record, Port: record, SslSecurityProtocol: record, AuthType: record, AuthUserName: record, AuthPassword: record, SslCaCertificateArn: record>, GcpMySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateEndpoint")
  let body = {EndpointIdentifier: $EndpointIdentifier, EndpointType: $EndpointType, EngineName: $EngineName, Username: $Username, Password: $Password, ServerName: $ServerName, Port: $Port, DatabaseName: $DatabaseName, ExtraConnectionAttributes: $ExtraConnectionAttributes, KmsKeyId: $KmsKeyId, Tags: $Tags, CertificateArn: $CertificateArn, SslMode: $SslMode, ServiceAccessRoleArn: $ServiceAccessRoleArn, ExternalTableDefinition: $ExternalTableDefinition, DynamoDbSettings: $DynamoDbSettings, S3Settings: $S3Settings, DmsTransferSettings: $DmsTransferSettings, MongoDbSettings: $MongoDbSettings, KinesisSettings: $KinesisSettings, KafkaSettings: $KafkaSettings, ElasticsearchSettings: $ElasticsearchSettings, NeptuneSettings: $NeptuneSettings, RedshiftSettings: $RedshiftSettings, PostgreSQLSettings: $PostgreSQLSettings, MySQLSettings: $MySQLSettings, OracleSettings: $OracleSettings, SybaseSettings: $SybaseSettings, MicrosoftSQLServerSettings: $MicrosoftSQLServerSettings, IBMDb2Settings: $IBMDb2Settings, ResourceIdentifier: $ResourceIdentifier, DocDbSettings: $DocDbSettings, RedisSettings: $RedisSettings, GcpMySQLSettings: $GcpMySQLSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p> Creates an DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all DMS sources belonging to your customer account.</p> <p>For more information about DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>Database Migration Service User Guide.</i> </p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateEventSubscription
# operationId: CreateEventSubscription
export def "x-amz-target-amazon-dm-sv20160101-create-event-subscription CreateEventSubscription" [
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
  SubscriptionName: any
  SnsTopicArn: any
  --SourceType: any
  --EventCategories: any
  --SourceIds: any
  --Enabled: any
  --Tags: any
]: any -> record<EventSubscription: record<CustomerAwsId: record, CustSubscriptionId: record, SnsTopicArn: record, Status: record, SubscriptionCreationTime: record, SourceType: record, SourceIdsList: record, EventCategoriesList: record, Enabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateEventSubscription")
  let body = {SubscriptionName: $SubscriptionName, SnsTopicArn: $SnsTopicArn, SourceType: $SourceType, EventCategories: $EventCategories, SourceIds: $SourceIds, Enabled: $Enabled, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a Fleet Advisor collector using the specified parameters.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateFleetAdvisorCollector
# operationId: CreateFleetAdvisorCollector
export def "x-amz-target-amazon-dm-sv20160101-create-fleet-advisor-collector CreateFleetAdvisorCollector" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-6
  CollectorName: any
  --Description: any
  ServiceAccessRoleArn: any
  S3BucketName: any
]: any -> record<CollectorReferencedId: record, CollectorName: record, Description: record, ServiceAccessRoleArn: record, S3BucketName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateFleetAdvisorCollector")
  let body = {CollectorName: $CollectorName, Description: $Description, ServiceAccessRoleArn: $ServiceAccessRoleArn, S3BucketName: $S3BucketName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates the replication instance using the specified parameters.</p> <p>DMS requires that your account have certain roles with appropriate permissions before you can create a replication instance. For information on the required roles, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.APIRole">Creating the IAM Roles to Use With the CLI and DMS API</a>. For information on the required permissions, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.IAMPermissions">IAM Permissions Needed to Use DMS</a>.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateReplicationInstance
# operationId: CreateReplicationInstance
export def "x-amz-target-amazon-dm-sv20160101-create-replication-instance CreateReplicationInstance" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-7
  ReplicationInstanceIdentifier: any
  --AllocatedStorage: any
  ReplicationInstanceClass: any
  --VpcSecurityGroupIds: any
  --AvailabilityZone: any
  --ReplicationSubnetGroupIdentifier: any
  --PreferredMaintenanceWindow: any
  --MultiAZ: any
  --EngineVersion: any
  --AutoMinorVersionUpgrade: any
  --Tags: any
  --KmsKeyId: any
  --PubliclyAccessible: any
  --DnsNameServers: any
  --ResourceIdentifier: any
  --NetworkType: any
]: any -> record<ReplicationInstance: record<ReplicationInstanceIdentifier: record, ReplicationInstanceClass: record, ReplicationInstanceStatus: record, AllocatedStorage: record, InstanceCreateTime: record, VpcSecurityGroups: record, AvailabilityZone: record, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>, PreferredMaintenanceWindow: record, PendingModifiedValues: record<ReplicationInstanceClass: record, AllocatedStorage: record, MultiAZ: record, EngineVersion: record, NetworkType: record>, MultiAZ: record, EngineVersion: record, AutoMinorVersionUpgrade: record, KmsKeyId: record, ReplicationInstanceArn: record, ReplicationInstancePublicIpAddress: record, ReplicationInstancePrivateIpAddress: record, ReplicationInstancePublicIpAddresses: record, ReplicationInstancePrivateIpAddresses: record, ReplicationInstanceIpv6Addresses: record, PubliclyAccessible: record, SecondaryAvailabilityZone: record, FreeUntil: record, DnsNameServers: record, NetworkType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationInstance")
  let body = {ReplicationInstanceIdentifier: $ReplicationInstanceIdentifier, AllocatedStorage: $AllocatedStorage, ReplicationInstanceClass: $ReplicationInstanceClass, VpcSecurityGroupIds: $VpcSecurityGroupIds, AvailabilityZone: $AvailabilityZone, ReplicationSubnetGroupIdentifier: $ReplicationSubnetGroupIdentifier, PreferredMaintenanceWindow: $PreferredMaintenanceWindow, MultiAZ: $MultiAZ, EngineVersion: $EngineVersion, AutoMinorVersionUpgrade: $AutoMinorVersionUpgrade, Tags: $Tags, KmsKeyId: $KmsKeyId, PubliclyAccessible: $PubliclyAccessible, DnsNameServers: $DnsNameServers, ResourceIdentifier: $ResourceIdentifier, NetworkType: $NetworkType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a replication subnet group given a list of the subnet IDs in a VPC.</p> <p>The VPC needs to have at least one subnet in at least two availability zones in the Amazon Web Services Region, otherwise the service will throw a <code>ReplicationSubnetGroupDoesNotCoverEnoughAZs</code> exception.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateReplicationSubnetGroup
# operationId: CreateReplicationSubnetGroup
export def "x-amz-target-amazon-dm-sv20160101-create-replication-subnet-group CreateReplicationSubnetGroup" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-8
  ReplicationSubnetGroupIdentifier: any
  ReplicationSubnetGroupDescription: any
  SubnetIds: any
  --Tags: any
]: any -> record<ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationSubnetGroup")
  let body = {ReplicationSubnetGroupIdentifier: $ReplicationSubnetGroupIdentifier, ReplicationSubnetGroupDescription: $ReplicationSubnetGroupDescription, SubnetIds: $SubnetIds, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a replication task using the specified parameters.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.CreateReplicationTask
# operationId: CreateReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-create-replication-task CreateReplicationTask" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-9
  ReplicationTaskIdentifier: any
  SourceEndpointArn: any
  TargetEndpointArn: any
  ReplicationInstanceArn: any
  MigrationType: any
  TableMappings: any
  --ReplicationTaskSettings: any
  --CdcStartTime: any
  --CdcStartPosition: any
  --CdcStopPosition: any
  --Tags: any
  --TaskData: any
  --ResourceIdentifier: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationTask")
  let body = {ReplicationTaskIdentifier: $ReplicationTaskIdentifier, SourceEndpointArn: $SourceEndpointArn, TargetEndpointArn: $TargetEndpointArn, ReplicationInstanceArn: $ReplicationInstanceArn, MigrationType: $MigrationType, TableMappings: $TableMappings, ReplicationTaskSettings: $ReplicationTaskSettings, CdcStartTime: $CdcStartTime, CdcStartPosition: $CdcStartPosition, CdcStopPosition: $CdcStopPosition, Tags: $Tags, TaskData: $TaskData, ResourceIdentifier: $ResourceIdentifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the specified certificate. 
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteCertificate
# operationId: DeleteCertificate
export def "x-amz-target-amazon-dm-sv20160101-delete-certificate DeleteCertificate" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-10
  CertificateArn: any
]: any -> record<Certificate: record<CertificateIdentifier: record, CertificateCreationDate: record, CertificatePem: record, CertificateWallet: record, CertificateArn: record, CertificateOwner: record, ValidFromDate: record, ValidToDate: record, SigningAlgorithm: record, KeyLength: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteCertificate")
  let body = {CertificateArn: $CertificateArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the connection between a replication instance and an endpoint.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteConnection
# operationId: DeleteConnection
export def "x-amz-target-amazon-dm-sv20160101-delete-connection DeleteConnection" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-11
  EndpointArn: any
  ReplicationInstanceArn: any
]: any -> record<Connection: record<ReplicationInstanceArn: record, EndpointArn: record, Status: record, LastFailureMessage: record, EndpointIdentifier: record, ReplicationInstanceIdentifier: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteConnection")
  let body = {EndpointArn: $EndpointArn, ReplicationInstanceArn: $ReplicationInstanceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteEndpoint
# operationId: DeleteEndpoint
export def "x-amz-target-amazon-dm-sv20160101-delete-endpoint DeleteEndpoint" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-12
  EndpointArn: any
]: any -> record<Endpoint: record<EndpointIdentifier: record, EndpointType: record, EngineName: record, EngineDisplayName: record, Username: record, ServerName: record, Port: record, DatabaseName: record, ExtraConnectionAttributes: record, Status: record, KmsKeyId: record, EndpointArn: record, CertificateArn: record, SslMode: record, ServiceAccessRoleArn: record, ExternalTableDefinition: record, ExternalId: record, DynamoDbSettings: record<ServiceAccessRoleArn: record>, S3Settings: record<ServiceAccessRoleArn: record, ExternalTableDefinition: record, CsvRowDelimiter: record, CsvDelimiter: record, BucketFolder: record, BucketName: record, CompressionType: record, EncryptionMode: record, ServerSideEncryptionKmsKeyId: record, DataFormat: record, EncodingType: record, DictPageSizeLimit: record, RowGroupLength: record, DataPageSize: record, ParquetVersion: record, EnableStatistics: record, IncludeOpForFullLoad: record, CdcInsertsOnly: record, TimestampColumnName: record, ParquetTimestampInMillisecond: record, CdcInsertsAndUpdates: record, DatePartitionEnabled: record, DatePartitionSequence: record, DatePartitionDelimiter: record, UseCsvNoSupValue: record, CsvNoSupValue: record, PreserveTransactions: record, CdcPath: record, UseTaskStartTimeForFullLoadTimestamp: record, CannedAclForObjects: record, AddColumnName: record, CdcMaxBatchInterval: record, CdcMinFileSize: record, CsvNullValue: record, IgnoreHeaderRows: record, MaxFileSize: record, Rfc4180: record, DatePartitionTimezone: record, AddTrailingPaddingCharacter: record, ExpectedBucketOwner: record, GlueCatalogGeneration: record>, DmsTransferSettings: record<ServiceAccessRoleArn: record, BucketName: record>, MongoDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, AuthType: record, AuthMechanism: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, AuthSource: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, KinesisSettings: record<StreamArn: record, MessageFormat: record, ServiceAccessRoleArn: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, IncludeNullAndEmpty: record, NoHexPrefix: record>, KafkaSettings: record<Broker: record, Topic: record, MessageFormat: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, MessageMaxBytes: record, IncludeNullAndEmpty: record, SecurityProtocol: record, SslClientCertificateArn: record, SslClientKeyArn: record, SslClientKeyPassword: record, SslCaCertificateArn: record, SaslUsername: record, SaslPassword: record, NoHexPrefix: record, SaslMechanism: record>, ElasticsearchSettings: record<ServiceAccessRoleArn: record, EndpointUri: record, FullLoadErrorPercentage: record, ErrorRetryDuration: record, UseNewMappingType: record>, NeptuneSettings: record<ServiceAccessRoleArn: record, S3BucketName: record, S3BucketFolder: record, ErrorRetryDuration: record, MaxFileSize: record, MaxRetryCount: record, IamAuthEnabled: record>, RedshiftSettings: record<AcceptAnyDate: record, AfterConnectScript: record, BucketFolder: record, BucketName: record, CaseSensitiveNames: record, CompUpdate: record, ConnectionTimeout: record, DatabaseName: record, DateFormat: record, EmptyAsNull: record, EncryptionMode: record, ExplicitIds: record, FileTransferUploadStreams: record, LoadTimeout: record, MaxFileSize: record, Password: record, Port: record, RemoveQuotes: record, ReplaceInvalidChars: record, ReplaceChars: record, ServerName: record, ServiceAccessRoleArn: record, ServerSideEncryptionKmsKeyId: record, TimeFormat: record, TrimBlanks: record, TruncateColumns: record, Username: record, WriteBufferSize: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, MapBooleanAsBoolean: record>, PostgreSQLSettings: record<AfterConnectScript: record, CaptureDdls: record, MaxFileSize: record, DatabaseName: record, DdlArtifactsSchema: record, ExecuteTimeout: record, FailTasksOnLobTruncation: record, HeartbeatEnable: record, HeartbeatSchema: record, HeartbeatFrequency: record, Password: record, Port: record, ServerName: record, Username: record, SlotName: record, PluginName: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, MapBooleanAsBoolean: record>, MySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, OracleSettings: record<AddSupplementalLogging: record, ArchivedLogDestId: record, AdditionalArchivedLogDestId: record, ExtraArchivedLogDestIds: record, AllowSelectNestedTables: record, ParallelAsmReadThreads: record, ReadAheadBlocks: record, AccessAlternateDirectly: record, UseAlternateFolderForOnline: record, OraclePathPrefix: record, UsePathPrefix: record, ReplacePathPrefix: record, EnableHomogenousTablespace: record, DirectPathNoLog: record, ArchivedLogsOnly: record, AsmPassword: record, AsmServer: record, AsmUser: record, CharLengthSemantics: record, DatabaseName: record, DirectPathParallelLoad: record, FailTasksOnLobTruncation: record, NumberDatatypeScale: record, Password: record, Port: record, ReadTableSpaceName: record, RetryInterval: record, SecurityDbEncryption: record, SecurityDbEncryptionName: record, ServerName: record, SpatialDataOptionToGeoJsonFunctionName: record, StandbyDelayTime: record, Username: record, UseBFile: record, UseDirectPathFullLoad: record, UseLogminerReader: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, SecretsManagerOracleAsmAccessRoleArn: record, SecretsManagerOracleAsmSecretId: record, TrimSpaceInChar: record, ConvertTimestampWithZoneToUTC: record>, SybaseSettings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, MicrosoftSQLServerSettings: record<Port: record, BcpPacketSize: record, DatabaseName: record, ControlTablesFileGroup: record, Password: record, QuerySingleAlwaysOnNode: record, ReadBackupOnly: record, SafeguardPolicy: record, ServerName: record, Username: record, UseBcpFullLoad: record, UseThirdPartyBackupDevice: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, TlogAccessMode: record, ForceLobLookup: record>, IBMDb2Settings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, SetDataCaptureChanges: record, CurrentLsn: record, MaxKBytesPerRead: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, DocDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, RedisSettings: record<ServerName: record, Port: record, SslSecurityProtocol: record, AuthType: record, AuthUserName: record, AuthPassword: record, SslCaCertificateArn: record>, GcpMySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteEndpoint")
  let body = {EndpointArn: $EndpointArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Deletes an DMS event subscription. 
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteEventSubscription
# operationId: DeleteEventSubscription
export def "x-amz-target-amazon-dm-sv20160101-delete-event-subscription DeleteEventSubscription" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-13
  SubscriptionName: any
]: any -> record<EventSubscription: record<CustomerAwsId: record, CustSubscriptionId: record, SnsTopicArn: record, Status: record, SubscriptionCreationTime: record, SourceType: record, SourceIdsList: record, EventCategoriesList: record, Enabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteEventSubscription")
  let body = {SubscriptionName: $SubscriptionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the specified Fleet Advisor collector.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteFleetAdvisorCollector
# operationId: DeleteFleetAdvisorCollector
export def "x-amz-target-amazon-dm-sv20160101-delete-fleet-advisor-collector DeleteFleetAdvisorCollector" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-14
  CollectorReferencedId: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteFleetAdvisorCollector")
  let body = {CollectorReferencedId: $CollectorReferencedId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the specified Fleet Advisor collector databases.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteFleetAdvisorDatabases
# operationId: DeleteFleetAdvisorDatabases
export def "x-amz-target-amazon-dm-sv20160101-delete-fleet-advisor-databases DeleteFleetAdvisorDatabases" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-15
  DatabaseIds: any
]: any -> record<DatabaseIds: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteFleetAdvisorDatabases")
  let body = {DatabaseIds: $DatabaseIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationInstance
# operationId: DeleteReplicationInstance
export def "x-amz-target-amazon-dm-sv20160101-delete-replication-instance DeleteReplicationInstance" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-16
  ReplicationInstanceArn: any
]: any -> record<ReplicationInstance: record<ReplicationInstanceIdentifier: record, ReplicationInstanceClass: record, ReplicationInstanceStatus: record, AllocatedStorage: record, InstanceCreateTime: record, VpcSecurityGroups: record, AvailabilityZone: record, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>, PreferredMaintenanceWindow: record, PendingModifiedValues: record<ReplicationInstanceClass: record, AllocatedStorage: record, MultiAZ: record, EngineVersion: record, NetworkType: record>, MultiAZ: record, EngineVersion: record, AutoMinorVersionUpgrade: record, KmsKeyId: record, ReplicationInstanceArn: record, ReplicationInstancePublicIpAddress: record, ReplicationInstancePrivateIpAddress: record, ReplicationInstancePublicIpAddresses: record, ReplicationInstancePrivateIpAddresses: record, ReplicationInstanceIpv6Addresses: record, PubliclyAccessible: record, SecondaryAvailabilityZone: record, FreeUntil: record, DnsNameServers: record, NetworkType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationInstance")
  let body = {ReplicationInstanceArn: $ReplicationInstanceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a subnet group.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationSubnetGroup
# operationId: DeleteReplicationSubnetGroup
export def "x-amz-target-amazon-dm-sv20160101-delete-replication-subnet-group DeleteReplicationSubnetGroup" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-17
  ReplicationSubnetGroupIdentifier: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationSubnetGroup")
  let body = {ReplicationSubnetGroupIdentifier: $ReplicationSubnetGroupIdentifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the specified replication task.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTask
# operationId: DeleteReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-delete-replication-task DeleteReplicationTask" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-18
  ReplicationTaskArn: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTask")
  let body = {ReplicationTaskArn: $ReplicationTaskArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes the record of a single premigration assessment run.</p> <p>This operation removes all metadata that DMS maintains about this assessment run. However, the operation leaves untouched all information about this assessment run that is stored in your Amazon S3 bucket.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTaskAssessmentRun
# operationId: DeleteReplicationTaskAssessmentRun
export def "x-amz-target-amazon-dm-sv20160101-delete-replication-task-assessment-run DeleteReplicationTaskAssessmentRun" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-19
  ReplicationTaskAssessmentRunArn: any
]: any -> record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: record, ReplicationTaskArn: record, Status: record, ReplicationTaskAssessmentRunCreationDate: record, AssessmentProgress: record<IndividualAssessmentCount: record, IndividualAssessmentCompletedCount: record>, LastFailureMessage: record, ServiceAccessRoleArn: record, ResultLocationBucket: record, ResultLocationFolder: record, ResultEncryptionMode: record, ResultKmsKeyArn: record, AssessmentRunName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTaskAssessmentRun")
  let body = {ReplicationTaskAssessmentRunArn: $ReplicationTaskAssessmentRunArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Lists all of the DMS attributes for a customer account. These attributes include DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeAccountAttributes
# operationId: DescribeAccountAttributes
export def "x-amz-target-amazon-dm-sv20160101-describe-account-attributes DescribeAccountAttributes" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-20
  --body: record
]: any -> record<AccountQuotas: record, UniqueAccountIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeAccountAttributes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Provides a list of individual assessments that you can specify for a new premigration assessment run, given one or more parameters.</p> <p>If you specify an existing migration task, this operation provides the default individual assessments you can specify for that task. Otherwise, the specified parameters model elements of a possible migration task on which to base a premigration assessment run.</p> <p>To use these migration task modeling parameters, you must specify an existing replication instance, a source database engine, a target database engine, and a migration type. This combination of parameters potentially limits the default individual assessments available for an assessment run created for a corresponding migration task.</p> <p>If you specify no parameters, this operation provides a list of all possible individual assessments that you can specify for an assessment run. If you specify any one of the task modeling parameters, you must specify all of them or the operation cannot provide a list of individual assessments. The only parameter that you can specify alone is for an existing migration task. The specified task definition then determines the default list of individual assessments that you can specify in an assessment run for the task.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeApplicableIndividualAssessments
# operationId: DescribeApplicableIndividualAssessments
export def "x-amz-target-amazon-dm-sv20160101-describe-applicable-individual-assessments DescribeApplicableIndividualAssessments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-21
  --ReplicationTaskArn: any
  --ReplicationInstanceArn: any
  --SourceEngineName: any
  --TargetEngineName: any
  --MigrationType: any
  --MaxRecords: any
  --Marker: any
]: any -> record<IndividualAssessmentNames: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeApplicableIndividualAssessments" $qp)
  let body = {ReplicationTaskArn: $ReplicationTaskArn, ReplicationInstanceArn: $ReplicationInstanceArn, SourceEngineName: $SourceEngineName, TargetEngineName: $TargetEngineName, MigrationType: $MigrationType, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provides a description of the certificate.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeCertificates
# operationId: DescribeCertificates
export def "x-amz-target-amazon-dm-sv20160101-describe-certificates DescribeCertificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-22
  --Filters: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, Certificates: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeCertificates" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeConnections
# operationId: DescribeConnections
export def "x-amz-target-amazon-dm-sv20160101-describe-connections DescribeConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-23
  --Filters: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, Connections: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeConnections" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the possible endpoint settings available when you create an endpoint for a specific database engine.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointSettings
# operationId: DescribeEndpointSettings
export def "x-amz-target-amazon-dm-sv20160101-describe-endpoint-settings DescribeEndpointSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-24
  EngineName: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, EndpointSettings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointSettings" $qp)
  let body = {EngineName: $EngineName, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the type of endpoints available.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointTypes
# operationId: DescribeEndpointTypes
export def "x-amz-target-amazon-dm-sv20160101-describe-endpoint-types DescribeEndpointTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-25
  --Filters: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, SupportedEndpointTypes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointTypes" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the endpoints for your account in the current region.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEndpoints
# operationId: DescribeEndpoints
export def "x-amz-target-amazon-dm-sv20160101-describe-endpoints DescribeEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-26
  --Filters: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, Endpoints: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpoints" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>Database Migration Service User Guide.</i> 
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEventCategories
# operationId: DescribeEventCategories
export def "x-amz-target-amazon-dm-sv20160101-describe-event-categories DescribeEventCategories" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-27
  --SourceType: any
  --Filters: any
]: any -> record<EventCategoryGroupList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventCategories")
  let body = {SourceType: $SourceType, Filters: $Filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEventSubscriptions
# operationId: DescribeEventSubscriptions
export def "x-amz-target-amazon-dm-sv20160101-describe-event-subscriptions DescribeEventSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-28
  --SubscriptionName: any
  --Filters: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, EventSubscriptionsList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventSubscriptions" $qp)
  let body = {SubscriptionName: $SubscriptionName, Filters: $Filters, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>Database Migration Service User Guide.</i> 
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeEvents
# operationId: DescribeEvents
export def "x-amz-target-amazon-dm-sv20160101-describe-events DescribeEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-29
  --SourceIdentifier: any
  --SourceType: any
  --StartTime: any
  --EndTime: any
  --Duration: any
  --EventCategories: any
  --Filters: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, Events: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeEvents" $qp)
  let body = {SourceIdentifier: $SourceIdentifier, SourceType: $SourceType, StartTime: $StartTime, EndTime: $EndTime, Duration: $Duration, EventCategories: $EventCategories, Filters: $Filters, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of the Fleet Advisor collectors in your account.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorCollectors
# operationId: DescribeFleetAdvisorCollectors
export def "x-amz-target-amazon-dm-sv20160101-describe-fleet-advisor-collectors DescribeFleetAdvisorCollectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-30
  --Filters: any
  --MaxRecords: any
  --NextToken: any
]: any -> record<Collectors: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorCollectors" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of Fleet Advisor databases in your account.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorDatabases
# operationId: DescribeFleetAdvisorDatabases
export def "x-amz-target-amazon-dm-sv20160101-describe-fleet-advisor-databases DescribeFleetAdvisorDatabases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-31
  --Filters: any
  --MaxRecords: any
  --NextToken: any
]: any -> record<Databases: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorDatabases" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provides descriptions of large-scale assessment (LSA) analyses produced by your Fleet Advisor collectors. 
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorLsaAnalysis
# operationId: DescribeFleetAdvisorLsaAnalysis
export def "x-amz-target-amazon-dm-sv20160101-describe-fleet-advisor-lsa-analysis DescribeFleetAdvisorLsaAnalysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-32
  --MaxRecords: any
  --NextToken: any
]: any -> record<Analysis: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorLsaAnalysis" $qp)
  let body = {MaxRecords: $MaxRecords, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provides descriptions of the schemas discovered by your Fleet Advisor collectors.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorSchemaObjectSummary
# operationId: DescribeFleetAdvisorSchemaObjectSummary
export def "x-amz-target-amazon-dm-sv20160101-describe-fleet-advisor-schema-object-summary DescribeFleetAdvisorSchemaObjectSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-33
  --Filters: any
  --MaxRecords: any
  --NextToken: any
]: any -> record<FleetAdvisorSchemaObjects: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorSchemaObjectSummary" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of schemas detected by Fleet Advisor Collectors in your account.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorSchemas
# operationId: DescribeFleetAdvisorSchemas
export def "x-amz-target-amazon-dm-sv20160101-describe-fleet-advisor-schemas DescribeFleetAdvisorSchemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-34
  --Filters: any
  --MaxRecords: any
  --NextToken: any
]: any -> record<FleetAdvisorSchemas: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeFleetAdvisorSchemas" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the replication instance types that can be created in the specified region.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeOrderableReplicationInstances
# operationId: DescribeOrderableReplicationInstances
export def "x-amz-target-amazon-dm-sv20160101-describe-orderable-replication-instances DescribeOrderableReplicationInstances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-35
  --MaxRecords: any
  --Marker: any
]: any -> record<OrderableReplicationInstances: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeOrderableReplicationInstances" $qp)
  let body = {MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# For internal use only
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribePendingMaintenanceActions
# operationId: DescribePendingMaintenanceActions
export def "x-amz-target-amazon-dm-sv20160101-describe-pending-maintenance-actions DescribePendingMaintenanceActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-36
  --ReplicationInstanceArn: any
  --Filters: any
  --Marker: any
  --MaxRecords: any
]: any -> record<PendingMaintenanceActions: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribePendingMaintenanceActions" $qp)
  let body = {ReplicationInstanceArn: $ReplicationInstanceArn, Filters: $Filters, Marker: $Marker, MaxRecords: $MaxRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a paginated list of limitations for recommendations of target Amazon Web Services engines.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeRecommendationLimitations
# operationId: DescribeRecommendationLimitations
export def "x-amz-target-amazon-dm-sv20160101-describe-recommendation-limitations DescribeRecommendationLimitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-37
  --Filters: any
  --MaxRecords: any
  --NextToken: any
]: any -> record<NextToken: record, Limitations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeRecommendationLimitations" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a paginated list of target engine recommendations for your source databases.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeRecommendations
# operationId: DescribeRecommendations
export def "x-amz-target-amazon-dm-sv20160101-describe-recommendations DescribeRecommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-38
  --Filters: any
  --MaxRecords: any
  --NextToken: any
]: any -> record<NextToken: record, Recommendations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeRecommendations" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the status of the RefreshSchemas operation.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeRefreshSchemasStatus
# operationId: DescribeRefreshSchemasStatus
export def "x-amz-target-amazon-dm-sv20160101-describe-refresh-schemas-status DescribeRefreshSchemasStatus" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-39
  EndpointArn: any
]: any -> record<RefreshSchemasStatus: record<EndpointArn: record, ReplicationInstanceArn: record, Status: record, LastRefreshDate: record, LastFailureMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeRefreshSchemasStatus")
  let body = {EndpointArn: $EndpointArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the task logs for the specified task.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs
# operationId: DescribeReplicationInstanceTaskLogs
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-instance-task-logs DescribeReplicationInstanceTaskLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-40
  ReplicationInstanceArn: any
  --MaxRecords: any
  --Marker: any
]: any -> record<ReplicationInstanceArn: record, ReplicationInstanceTaskLogs: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs" $qp)
  let body = {ReplicationInstanceArn: $ReplicationInstanceArn, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about replication instances for your account in the current region.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstances
# operationId: DescribeReplicationInstances
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-instances DescribeReplicationInstances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-41
  --Filters: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, ReplicationInstances: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstances" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the replication subnet groups.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationSubnetGroups
# operationId: DescribeReplicationSubnetGroups
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-subnet-groups DescribeReplicationSubnetGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-42
  --Filters: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, ReplicationSubnetGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationSubnetGroups" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns the task assessment results from the Amazon S3 bucket that DMS creates in your Amazon Web Services account. This action always returns the latest results.</p> <p>For more information about DMS task assessments, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.AssessmentReport.html">Creating a task assessment report</a> in the <i>Database Migration Service User Guide</i>.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults
# operationId: DescribeReplicationTaskAssessmentResults
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-task-assessment-results DescribeReplicationTaskAssessmentResults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-43
  --ReplicationTaskArn: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, BucketName: record, ReplicationTaskAssessmentResults: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults" $qp)
  let body = {ReplicationTaskArn: $ReplicationTaskArn, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns a paginated list of premigration assessment runs based on filter settings.</p> <p>These filter settings can specify a combination of premigration assessment runs, migration tasks, replication instances, and assessment run status values.</p> <note> <p>This operation doesn't return information about individual assessments. For this information, see the <code>DescribeReplicationTaskIndividualAssessments</code> operation. </p> </note>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentRuns
# operationId: DescribeReplicationTaskAssessmentRuns
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-task-assessment-runs DescribeReplicationTaskAssessmentRuns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-44
  --Filters: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, ReplicationTaskAssessmentRuns: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentRuns" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns a paginated list of individual assessments based on filter settings.</p> <p>These filter settings can specify a combination of premigration assessment runs, migration tasks, and assessment status values.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskIndividualAssessments
# operationId: DescribeReplicationTaskIndividualAssessments
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-task-individual-assessments DescribeReplicationTaskIndividualAssessments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-45
  --Filters: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, ReplicationTaskIndividualAssessments: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskIndividualAssessments" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about replication tasks for your account in the current region.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTasks
# operationId: DescribeReplicationTasks
export def "x-amz-target-amazon-dm-sv20160101-describe-replication-tasks DescribeReplicationTasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-46
  --Filters: any
  --MaxRecords: any
  --Marker: any
  --WithoutSettings: any
]: any -> record<Marker: record, ReplicationTasks: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTasks" $qp)
  let body = {Filters: $Filters, MaxRecords: $MaxRecords, Marker: $Marker, WithoutSettings: $WithoutSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns information about the schema for the specified endpoint.</p> <p/>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeSchemas
# operationId: DescribeSchemas
export def "x-amz-target-amazon-dm-sv20160101-describe-schemas DescribeSchemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-47
  EndpointArn: any
  --MaxRecords: any
  --Marker: any
]: any -> record<Marker: record, Schemas: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeSchemas" $qp)
  let body = {EndpointArn: $EndpointArn, MaxRecords: $MaxRecords, Marker: $Marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.DescribeTableStatistics
# operationId: DescribeTableStatistics
export def "x-amz-target-amazon-dm-sv20160101-describe-table-statistics DescribeTableStatistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxRecords: string # Pagination limit
  --Marker: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-48
  ReplicationTaskArn: any
  --MaxRecords: any
  --Marker: any
  --Filters: any
]: any -> record<ReplicationTaskArn: record, TableStatistics: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxRecords" $MaxRecords "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.DescribeTableStatistics" $qp)
  let body = {ReplicationTaskArn: $ReplicationTaskArn, MaxRecords: $MaxRecords, Marker: $Marker, Filters: $Filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Uploads the specified certificate.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ImportCertificate
# operationId: ImportCertificate
export def "x-amz-target-amazon-dm-sv20160101-import-certificate ImportCertificate" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-49
  CertificateIdentifier: any
  --CertificatePem: any
  --CertificateWallet: any
  --Tags: any
]: any -> record<Certificate: record<CertificateIdentifier: record, CertificateCreationDate: record, CertificatePem: record, CertificateWallet: record, CertificateArn: record, CertificateOwner: record, ValidFromDate: record, ValidToDate: record, SigningAlgorithm: record, KeyLength: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ImportCertificate")
  let body = {CertificateIdentifier: $CertificateIdentifier, CertificatePem: $CertificatePem, CertificateWallet: $CertificateWallet, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all metadata tags attached to an DMS resource, including replication instance, endpoint, subnet group, and migration task. For more information, see <a href="https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html"> <code>Tag</code> </a> data type description.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ListTagsForResource
# operationId: ListTagsForResource
export def "x-amz-target-amazon-dm-sv20160101-list-tags-for-resource ListTagsForResource" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-50
  --ResourceArn: any
  --ResourceArnList: any
]: any -> record<TagList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ListTagsForResource")
  let body = {ResourceArn: $ResourceArn, ResourceArnList: $ResourceArnList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Modifies the specified endpoint.</p> <note> <p>For a MySQL source or target endpoint, don't explicitly specify the database using the <code>DatabaseName</code> request parameter on the <code>ModifyEndpoint</code> API call. Specifying <code>DatabaseName</code> when you modify a MySQL endpoint replicates all the task tables to this single database. For MySQL endpoints, you specify the database only when you specify the schema in the table-mapping rules of the DMS task.</p> </note>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ModifyEndpoint
# operationId: ModifyEndpoint
# --RedshiftSettings shape: {AcceptAnyDate?: any, AfterConnectScript?: any, BucketFolder?: any, BucketName?: any, CaseSensitiveNames?: any, CompUpdate?: any, ConnectionTimeout?: any, DatabaseName?: any, DateFormat?: any, EmptyAsNull?: any, EncryptionMode?: any, ExplicitIds?: any, FileTransferUploadStreams?: any, LoadTimeout?: any, MaxFileSize?: any, Password?: any, Port?: any, RemoveQuotes?: any, ReplaceInvalidChars?: any, ReplaceChars?: any, ServerName?: any, ServiceAccessRoleArn?: any, ServerSideEncryptionKmsKeyId?: any, TimeFormat?: any, TrimBlanks?: any, TruncateColumns?: any, Username?: any, WriteBufferSize?: any, SecretsManagerAccessRoleArn?: any, SecretsManagerSecretId?: any, MapBooleanAsBoolean?: any}
export def "x-amz-target-amazon-dm-sv20160101-modify-endpoint ModifyEndpoint" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-51
  EndpointArn: any
  --EndpointIdentifier: any
  --EndpointType: any
  --EngineName: any
  --Username: any
  --Password: any
  --ServerName: any
  --Port: any
  --DatabaseName: any
  --ExtraConnectionAttributes: any
  --CertificateArn: any
  --SslMode: any
  --ServiceAccessRoleArn: any
  --ExternalTableDefinition: any
  --DynamoDbSettings: any
  --S3Settings: any
  --DmsTransferSettings: any
  --MongoDbSettings: any
  --KinesisSettings: any
  --KafkaSettings: any
  --ElasticsearchSettings: any
  --NeptuneSettings: any
  --RedshiftSettings: record # Provides information that defines an Amazon Redshift endpoint. — shape: {AcceptAnyDate?: any, AfterConnectScript?: any, BucketFolder?: any, BucketName?: any, CaseSensitiveNames?: any, CompUpdate?: any, ConnectionTimeout?: any, DatabaseName?: any, DateFormat?: any, EmptyAsNull?: any, EncryptionMode?: any, ExplicitIds?: any, FileTransferUploadStreams?: any, LoadTimeout?: any, MaxFileSize?: any, Password?: any, Port?: any, RemoveQuotes?: any, ReplaceInvalidChars?: any, ReplaceChars?: any, ServerName?: any, ServiceAccessRoleArn?: any, ServerSideEncryptionKmsKeyId?: any, TimeFormat?: any, TrimBlanks?: any, TruncateColumns?: any, Username?: any, WriteBufferSize?: any, SecretsManagerAccessRoleArn?: any, SecretsManagerSecretId?: any, MapBooleanAsBoolean?: any}
  --PostgreSQLSettings: any
  --MySQLSettings: any
  --OracleSettings: any
  --SybaseSettings: any
  --MicrosoftSQLServerSettings: any
  --IBMDb2Settings: any
  --DocDbSettings: any
  --RedisSettings: any
  --ExactSettings: any
  --GcpMySQLSettings: any
]: any -> record<Endpoint: record<EndpointIdentifier: record, EndpointType: record, EngineName: record, EngineDisplayName: record, Username: record, ServerName: record, Port: record, DatabaseName: record, ExtraConnectionAttributes: record, Status: record, KmsKeyId: record, EndpointArn: record, CertificateArn: record, SslMode: record, ServiceAccessRoleArn: record, ExternalTableDefinition: record, ExternalId: record, DynamoDbSettings: record<ServiceAccessRoleArn: record>, S3Settings: record<ServiceAccessRoleArn: record, ExternalTableDefinition: record, CsvRowDelimiter: record, CsvDelimiter: record, BucketFolder: record, BucketName: record, CompressionType: record, EncryptionMode: record, ServerSideEncryptionKmsKeyId: record, DataFormat: record, EncodingType: record, DictPageSizeLimit: record, RowGroupLength: record, DataPageSize: record, ParquetVersion: record, EnableStatistics: record, IncludeOpForFullLoad: record, CdcInsertsOnly: record, TimestampColumnName: record, ParquetTimestampInMillisecond: record, CdcInsertsAndUpdates: record, DatePartitionEnabled: record, DatePartitionSequence: record, DatePartitionDelimiter: record, UseCsvNoSupValue: record, CsvNoSupValue: record, PreserveTransactions: record, CdcPath: record, UseTaskStartTimeForFullLoadTimestamp: record, CannedAclForObjects: record, AddColumnName: record, CdcMaxBatchInterval: record, CdcMinFileSize: record, CsvNullValue: record, IgnoreHeaderRows: record, MaxFileSize: record, Rfc4180: record, DatePartitionTimezone: record, AddTrailingPaddingCharacter: record, ExpectedBucketOwner: record, GlueCatalogGeneration: record>, DmsTransferSettings: record<ServiceAccessRoleArn: record, BucketName: record>, MongoDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, AuthType: record, AuthMechanism: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, AuthSource: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, KinesisSettings: record<StreamArn: record, MessageFormat: record, ServiceAccessRoleArn: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, IncludeNullAndEmpty: record, NoHexPrefix: record>, KafkaSettings: record<Broker: record, Topic: record, MessageFormat: record, IncludeTransactionDetails: record, IncludePartitionValue: record, PartitionIncludeSchemaTable: record, IncludeTableAlterOperations: record, IncludeControlDetails: record, MessageMaxBytes: record, IncludeNullAndEmpty: record, SecurityProtocol: record, SslClientCertificateArn: record, SslClientKeyArn: record, SslClientKeyPassword: record, SslCaCertificateArn: record, SaslUsername: record, SaslPassword: record, NoHexPrefix: record, SaslMechanism: record>, ElasticsearchSettings: record<ServiceAccessRoleArn: record, EndpointUri: record, FullLoadErrorPercentage: record, ErrorRetryDuration: record, UseNewMappingType: record>, NeptuneSettings: record<ServiceAccessRoleArn: record, S3BucketName: record, S3BucketFolder: record, ErrorRetryDuration: record, MaxFileSize: record, MaxRetryCount: record, IamAuthEnabled: record>, RedshiftSettings: record<AcceptAnyDate: record, AfterConnectScript: record, BucketFolder: record, BucketName: record, CaseSensitiveNames: record, CompUpdate: record, ConnectionTimeout: record, DatabaseName: record, DateFormat: record, EmptyAsNull: record, EncryptionMode: record, ExplicitIds: record, FileTransferUploadStreams: record, LoadTimeout: record, MaxFileSize: record, Password: record, Port: record, RemoveQuotes: record, ReplaceInvalidChars: record, ReplaceChars: record, ServerName: record, ServiceAccessRoleArn: record, ServerSideEncryptionKmsKeyId: record, TimeFormat: record, TrimBlanks: record, TruncateColumns: record, Username: record, WriteBufferSize: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, MapBooleanAsBoolean: record>, PostgreSQLSettings: record<AfterConnectScript: record, CaptureDdls: record, MaxFileSize: record, DatabaseName: record, DdlArtifactsSchema: record, ExecuteTimeout: record, FailTasksOnLobTruncation: record, HeartbeatEnable: record, HeartbeatSchema: record, HeartbeatFrequency: record, Password: record, Port: record, ServerName: record, Username: record, SlotName: record, PluginName: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, MapBooleanAsBoolean: record>, MySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, OracleSettings: record<AddSupplementalLogging: record, ArchivedLogDestId: record, AdditionalArchivedLogDestId: record, ExtraArchivedLogDestIds: record, AllowSelectNestedTables: record, ParallelAsmReadThreads: record, ReadAheadBlocks: record, AccessAlternateDirectly: record, UseAlternateFolderForOnline: record, OraclePathPrefix: record, UsePathPrefix: record, ReplacePathPrefix: record, EnableHomogenousTablespace: record, DirectPathNoLog: record, ArchivedLogsOnly: record, AsmPassword: record, AsmServer: record, AsmUser: record, CharLengthSemantics: record, DatabaseName: record, DirectPathParallelLoad: record, FailTasksOnLobTruncation: record, NumberDatatypeScale: record, Password: record, Port: record, ReadTableSpaceName: record, RetryInterval: record, SecurityDbEncryption: record, SecurityDbEncryptionName: record, ServerName: record, SpatialDataOptionToGeoJsonFunctionName: record, StandbyDelayTime: record, Username: record, UseBFile: record, UseDirectPathFullLoad: record, UseLogminerReader: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, SecretsManagerOracleAsmAccessRoleArn: record, SecretsManagerOracleAsmSecretId: record, TrimSpaceInChar: record, ConvertTimestampWithZoneToUTC: record>, SybaseSettings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, MicrosoftSQLServerSettings: record<Port: record, BcpPacketSize: record, DatabaseName: record, ControlTablesFileGroup: record, Password: record, QuerySingleAlwaysOnNode: record, ReadBackupOnly: record, SafeguardPolicy: record, ServerName: record, Username: record, UseBcpFullLoad: record, UseThirdPartyBackupDevice: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record, TrimSpaceInChar: record, TlogAccessMode: record, ForceLobLookup: record>, IBMDb2Settings: record<DatabaseName: record, Password: record, Port: record, ServerName: record, SetDataCaptureChanges: record, CurrentLsn: record, MaxKBytesPerRead: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, DocDbSettings: record<Username: record, Password: record, ServerName: record, Port: record, DatabaseName: record, NestingLevel: record, ExtractDocId: record, DocsToInvestigate: record, KmsKeyId: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>, RedisSettings: record<ServerName: record, Port: record, SslSecurityProtocol: record, AuthType: record, AuthUserName: record, AuthPassword: record, SslCaCertificateArn: record>, GcpMySQLSettings: record<AfterConnectScript: record, CleanSourceMetadataOnMismatch: record, DatabaseName: record, EventsPollInterval: record, TargetDbType: record, MaxFileSize: record, ParallelLoadThreads: record, Password: record, Port: record, ServerName: record, ServerTimezone: record, Username: record, SecretsManagerAccessRoleArn: record, SecretsManagerSecretId: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ModifyEndpoint")
  let body = {EndpointArn: $EndpointArn, EndpointIdentifier: $EndpointIdentifier, EndpointType: $EndpointType, EngineName: $EngineName, Username: $Username, Password: $Password, ServerName: $ServerName, Port: $Port, DatabaseName: $DatabaseName, ExtraConnectionAttributes: $ExtraConnectionAttributes, CertificateArn: $CertificateArn, SslMode: $SslMode, ServiceAccessRoleArn: $ServiceAccessRoleArn, ExternalTableDefinition: $ExternalTableDefinition, DynamoDbSettings: $DynamoDbSettings, S3Settings: $S3Settings, DmsTransferSettings: $DmsTransferSettings, MongoDbSettings: $MongoDbSettings, KinesisSettings: $KinesisSettings, KafkaSettings: $KafkaSettings, ElasticsearchSettings: $ElasticsearchSettings, NeptuneSettings: $NeptuneSettings, RedshiftSettings: $RedshiftSettings, PostgreSQLSettings: $PostgreSQLSettings, MySQLSettings: $MySQLSettings, OracleSettings: $OracleSettings, SybaseSettings: $SybaseSettings, MicrosoftSQLServerSettings: $MicrosoftSQLServerSettings, IBMDb2Settings: $IBMDb2Settings, DocDbSettings: $DocDbSettings, RedisSettings: $RedisSettings, ExactSettings: $ExactSettings, GcpMySQLSettings: $GcpMySQLSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Modifies an existing DMS event notification subscription. 
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ModifyEventSubscription
# operationId: ModifyEventSubscription
export def "x-amz-target-amazon-dm-sv20160101-modify-event-subscription ModifyEventSubscription" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-52
  SubscriptionName: any
  --SnsTopicArn: any
  --SourceType: any
  --EventCategories: any
  --Enabled: any
]: any -> record<EventSubscription: record<CustomerAwsId: record, CustSubscriptionId: record, SnsTopicArn: record, Status: record, SubscriptionCreationTime: record, SourceType: record, SourceIdsList: record, EventCategoriesList: record, Enabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ModifyEventSubscription")
  let body = {SubscriptionName: $SubscriptionName, SnsTopicArn: $SnsTopicArn, SourceType: $SourceType, EventCategories: $EventCategories, Enabled: $Enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationInstance
# operationId: ModifyReplicationInstance
export def "x-amz-target-amazon-dm-sv20160101-modify-replication-instance ModifyReplicationInstance" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-53
  ReplicationInstanceArn: any
  --AllocatedStorage: any
  --ApplyImmediately: any
  --ReplicationInstanceClass: any
  --VpcSecurityGroupIds: any
  --PreferredMaintenanceWindow: any
  --MultiAZ: any
  --EngineVersion: any
  --AllowMajorVersionUpgrade: any
  --AutoMinorVersionUpgrade: any
  --ReplicationInstanceIdentifier: any
  --NetworkType: any
]: any -> record<ReplicationInstance: record<ReplicationInstanceIdentifier: record, ReplicationInstanceClass: record, ReplicationInstanceStatus: record, AllocatedStorage: record, InstanceCreateTime: record, VpcSecurityGroups: record, AvailabilityZone: record, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>, PreferredMaintenanceWindow: record, PendingModifiedValues: record<ReplicationInstanceClass: record, AllocatedStorage: record, MultiAZ: record, EngineVersion: record, NetworkType: record>, MultiAZ: record, EngineVersion: record, AutoMinorVersionUpgrade: record, KmsKeyId: record, ReplicationInstanceArn: record, ReplicationInstancePublicIpAddress: record, ReplicationInstancePrivateIpAddress: record, ReplicationInstancePublicIpAddresses: record, ReplicationInstancePrivateIpAddresses: record, ReplicationInstanceIpv6Addresses: record, PubliclyAccessible: record, SecondaryAvailabilityZone: record, FreeUntil: record, DnsNameServers: record, NetworkType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationInstance")
  let body = {ReplicationInstanceArn: $ReplicationInstanceArn, AllocatedStorage: $AllocatedStorage, ApplyImmediately: $ApplyImmediately, ReplicationInstanceClass: $ReplicationInstanceClass, VpcSecurityGroupIds: $VpcSecurityGroupIds, PreferredMaintenanceWindow: $PreferredMaintenanceWindow, MultiAZ: $MultiAZ, EngineVersion: $EngineVersion, AllowMajorVersionUpgrade: $AllowMajorVersionUpgrade, AutoMinorVersionUpgrade: $AutoMinorVersionUpgrade, ReplicationInstanceIdentifier: $ReplicationInstanceIdentifier, NetworkType: $NetworkType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Modifies the settings for the specified replication subnet group.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationSubnetGroup
# operationId: ModifyReplicationSubnetGroup
export def "x-amz-target-amazon-dm-sv20160101-modify-replication-subnet-group ModifyReplicationSubnetGroup" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-54
  ReplicationSubnetGroupIdentifier: any
  --ReplicationSubnetGroupDescription: any
  SubnetIds: any
]: any -> record<ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationSubnetGroup")
  let body = {ReplicationSubnetGroupIdentifier: $ReplicationSubnetGroupIdentifier, ReplicationSubnetGroupDescription: $ReplicationSubnetGroupDescription, SubnetIds: $SubnetIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>Database Migration Service User Guide</i>.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationTask
# operationId: ModifyReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-modify-replication-task ModifyReplicationTask" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-55
  ReplicationTaskArn: any
  --ReplicationTaskIdentifier: any
  --MigrationType: any
  --TableMappings: any
  --ReplicationTaskSettings: any
  --CdcStartTime: any
  --CdcStartPosition: any
  --CdcStopPosition: any
  --TaskData: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationTask")
  let body = {ReplicationTaskArn: $ReplicationTaskArn, ReplicationTaskIdentifier: $ReplicationTaskIdentifier, MigrationType: $MigrationType, TableMappings: $TableMappings, ReplicationTaskSettings: $ReplicationTaskSettings, CdcStartTime: $CdcStartTime, CdcStartPosition: $CdcStartPosition, CdcStopPosition: $CdcStopPosition, TaskData: $TaskData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Moves a replication task from its current replication instance to a different target replication instance using the specified parameters. The target replication instance must be created with the same or later DMS version as the current replication instance.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.MoveReplicationTask
# operationId: MoveReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-move-replication-task MoveReplicationTask" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-56
  ReplicationTaskArn: any
  TargetReplicationInstanceArn: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.MoveReplicationTask")
  let body = {ReplicationTaskArn: $ReplicationTaskArn, TargetReplicationInstanceArn: $TargetReplicationInstanceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.RebootReplicationInstance
# operationId: RebootReplicationInstance
export def "x-amz-target-amazon-dm-sv20160101-reboot-replication-instance RebootReplicationInstance" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-57
  ReplicationInstanceArn: any
  --ForceFailover: any
  --ForcePlannedFailover: any
]: any -> record<ReplicationInstance: record<ReplicationInstanceIdentifier: record, ReplicationInstanceClass: record, ReplicationInstanceStatus: record, AllocatedStorage: record, InstanceCreateTime: record, VpcSecurityGroups: record, AvailabilityZone: record, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: record, ReplicationSubnetGroupDescription: record, VpcId: record, SubnetGroupStatus: record, Subnets: record, SupportedNetworkTypes: record>, PreferredMaintenanceWindow: record, PendingModifiedValues: record<ReplicationInstanceClass: record, AllocatedStorage: record, MultiAZ: record, EngineVersion: record, NetworkType: record>, MultiAZ: record, EngineVersion: record, AutoMinorVersionUpgrade: record, KmsKeyId: record, ReplicationInstanceArn: record, ReplicationInstancePublicIpAddress: record, ReplicationInstancePrivateIpAddress: record, ReplicationInstancePublicIpAddresses: record, ReplicationInstancePrivateIpAddresses: record, ReplicationInstanceIpv6Addresses: record, PubliclyAccessible: record, SecondaryAvailabilityZone: record, FreeUntil: record, DnsNameServers: record, NetworkType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.RebootReplicationInstance")
  let body = {ReplicationInstanceArn: $ReplicationInstanceArn, ForceFailover: $ForceFailover, ForcePlannedFailover: $ForcePlannedFailover} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.RefreshSchemas
# operationId: RefreshSchemas
export def "x-amz-target-amazon-dm-sv20160101-refresh-schemas RefreshSchemas" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-58
  EndpointArn: any
  ReplicationInstanceArn: any
]: any -> record<RefreshSchemasStatus: record<EndpointArn: record, ReplicationInstanceArn: record, Status: record, LastRefreshDate: record, LastFailureMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.RefreshSchemas")
  let body = {EndpointArn: $EndpointArn, ReplicationInstanceArn: $ReplicationInstanceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Reloads the target database table with the source data. </p> <p>You can only use this operation with a task in the <code>RUNNING</code> state, otherwise the service will throw an <code>InvalidResourceStateFault</code> exception.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.ReloadTables
# operationId: ReloadTables
export def "x-amz-target-amazon-dm-sv20160101-reload-tables ReloadTables" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-59
  ReplicationTaskArn: any
  TablesToReload: any
  --ReloadOption: any
]: any -> record<ReplicationTaskArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.ReloadTables")
  let body = {ReplicationTaskArn: $ReplicationTaskArn, TablesToReload: $TablesToReload, ReloadOption: $ReloadOption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes metadata tags from an DMS resource, including replication instance, endpoint, subnet group, and migration task. For more information, see <a href="https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html"> <code>Tag</code> </a> data type description.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.RemoveTagsFromResource
# operationId: RemoveTagsFromResource
export def "x-amz-target-amazon-dm-sv20160101-remove-tags-from-resource RemoveTagsFromResource" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-60
  ResourceArn: any
  TagKeys: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.RemoveTagsFromResource")
  let body = {ResourceArn: $ResourceArn, TagKeys: $TagKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Runs large-scale assessment (LSA) analysis on every Fleet Advisor collector in your account.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.RunFleetAdvisorLsaAnalysis
# operationId: RunFleetAdvisorLsaAnalysis
export def "x-amz-target-amazon-dm-sv20160101-run-fleet-advisor-lsa-analysis RunFleetAdvisorLsaAnalysis" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-61
]: nothing -> record<LsaAnalysisId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.RunFleetAdvisorLsaAnalysis")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Starts the analysis of your source database to provide recommendations of target engines.</p> <p>You can create recommendations for multiple source databases using <a href="https://docs.aws.amazon.com/dms/latest/APIReference/API_BatchStartRecommendations.html">BatchStartRecommendations</a>.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.StartRecommendations
# operationId: StartRecommendations
export def "x-amz-target-amazon-dm-sv20160101-start-recommendations StartRecommendations" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-62
  DatabaseId: any
  Settings: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.StartRecommendations")
  let body = {DatabaseId: $DatabaseId, Settings: $Settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Starts the replication task.</p> <p>For more information about DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>Database Migration Service User Guide.</i> </p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.StartReplicationTask
# operationId: StartReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-start-replication-task StartReplicationTask" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-63
  ReplicationTaskArn: any
  StartReplicationTaskType: any
  --CdcStartTime: any
  --CdcStartPosition: any
  --CdcStopPosition: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTask")
  let body = {ReplicationTaskArn: $ReplicationTaskArn, StartReplicationTaskType: $StartReplicationTaskType, CdcStartTime: $CdcStartTime, CdcStartPosition: $CdcStartPosition, CdcStopPosition: $CdcStopPosition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p> Starts the replication task assessment for unsupported data types in the source database. </p> <p>You can only use this operation for a task if the following conditions are true:</p> <ul> <li> <p>The task must be in the <code>stopped</code> state.</p> </li> <li> <p>The task must have successful connections to the source and target.</p> </li> </ul> <p>If either of these conditions are not met, an <code>InvalidResourceStateFault</code> error will result. </p> <p>For information about DMS task assessments, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.AssessmentReport.html">Creating a task assessment report</a> in the <i>Database Migration Service User Guide</i>.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessment
# operationId: StartReplicationTaskAssessment
export def "x-amz-target-amazon-dm-sv20160101-start-replication-task-assessment StartReplicationTaskAssessment" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-64
  ReplicationTaskArn: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessment")
  let body = {ReplicationTaskArn: $ReplicationTaskArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Starts a new premigration assessment run for one or more individual assessments of a migration task.</p> <p>The assessments that you can specify depend on the source and target database engine and the migration type defined for the given task. To run this operation, your migration task must already be created. After you run this operation, you can review the status of each individual assessment. You can also run the migration task manually after the assessment run and its individual assessments complete.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessmentRun
# operationId: StartReplicationTaskAssessmentRun
export def "x-amz-target-amazon-dm-sv20160101-start-replication-task-assessment-run StartReplicationTaskAssessmentRun" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-65
  ReplicationTaskArn: any
  ServiceAccessRoleArn: any
  ResultLocationBucket: any
  --ResultLocationFolder: any
  --ResultEncryptionMode: any
  --ResultKmsKeyArn: any
  AssessmentRunName: any
  --IncludeOnly: any
  --Exclude: any
]: any -> record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: record, ReplicationTaskArn: record, Status: record, ReplicationTaskAssessmentRunCreationDate: record, AssessmentProgress: record<IndividualAssessmentCount: record, IndividualAssessmentCompletedCount: record>, LastFailureMessage: record, ServiceAccessRoleArn: record, ResultLocationBucket: record, ResultLocationFolder: record, ResultEncryptionMode: record, ResultKmsKeyArn: record, AssessmentRunName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessmentRun")
  let body = {ReplicationTaskArn: $ReplicationTaskArn, ServiceAccessRoleArn: $ServiceAccessRoleArn, ResultLocationBucket: $ResultLocationBucket, ResultLocationFolder: $ResultLocationFolder, ResultEncryptionMode: $ResultEncryptionMode, ResultKmsKeyArn: $ResultKmsKeyArn, AssessmentRunName: $AssessmentRunName, IncludeOnly: $IncludeOnly, Exclude: $Exclude} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stops the replication task.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.StopReplicationTask
# operationId: StopReplicationTask
export def "x-amz-target-amazon-dm-sv20160101-stop-replication-task StopReplicationTask" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-66
  ReplicationTaskArn: any
]: any -> record<ReplicationTask: record<ReplicationTaskIdentifier: record, SourceEndpointArn: record, TargetEndpointArn: record, ReplicationInstanceArn: record, MigrationType: record, TableMappings: record, ReplicationTaskSettings: record, Status: record, LastFailureMessage: record, StopReason: record, ReplicationTaskCreationDate: record, ReplicationTaskStartDate: record, CdcStartPosition: record, CdcStopPosition: record, RecoveryCheckpoint: record, ReplicationTaskArn: record, ReplicationTaskStats: record<FullLoadProgressPercent: record, ElapsedTimeMillis: record, TablesLoaded: record, TablesLoading: record, TablesQueued: record, TablesErrored: record, FreshStartDate: record, StartDate: record, StopDate: record, FullLoadStartDate: record, FullLoadFinishDate: record>, TaskData: record, TargetReplicationInstanceArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.StopReplicationTask")
  let body = {ReplicationTaskArn: $ReplicationTaskArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Tests the connection between the replication instance and the endpoint.
#
# POST /#X-Amz-Target=AmazonDMSv20160101.TestConnection
# operationId: TestConnection
export def "x-amz-target-amazon-dm-sv20160101-test-connection TestConnection" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-67
  ReplicationInstanceArn: any
  EndpointArn: any
]: any -> record<Connection: record<ReplicationInstanceArn: record, EndpointArn: record, Status: record, LastFailureMessage: record, EndpointIdentifier: record, ReplicationInstanceIdentifier: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.TestConnection")
  let body = {ReplicationInstanceArn: $ReplicationInstanceArn, EndpointArn: $EndpointArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Migrates 10 active and enabled Amazon SNS subscriptions at a time and converts them to corresponding Amazon EventBridge rules. By default, this operation migrates subscriptions only when all your replication instance versions are 3.4.6 or higher. If any replication instances are from versions earlier than 3.4.6, the operation raises an error and tells you to upgrade these instances to version 3.4.6 or higher. To enable migration regardless of version, set the <code>Force</code> option to true. However, if you don't upgrade instances earlier than version 3.4.6, some types of events might not be available when you use Amazon EventBridge.</p> <p>To call this operation, make sure that you have certain permissions added to your user account. For more information, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html#CHAP_Events-migrate-to-eventbridge">Migrating event subscriptions to Amazon EventBridge</a> in the <i>Amazon Web Services Database Migration Service User Guide</i>.</p>
#
# POST /#X-Amz-Target=AmazonDMSv20160101.UpdateSubscriptionsToEventBridge
# operationId: UpdateSubscriptionsToEventBridge
export def "x-amz-target-amazon-dm-sv20160101-update-subscriptions-to-event-bridge UpdateSubscriptionsToEventBridge" [
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
  --X-Amz-Target: string@X-Amz-Target-completer-68
  --ForceMove: any
]: any -> record<Result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AmazonDMSv20160101.UpdateSubscriptionsToEventBridge")
  let body = {ForceMove: $ForceMove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
