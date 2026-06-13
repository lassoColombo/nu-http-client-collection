# Auto-generated client for Amazon QuickSight v2018-04-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/quicksight/2018-04-01/openapi.json
# Auth: --token flag or $env.AMAZON_QUICKSIGHT_TOKEN

const BASE_URL = "http://quicksight.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_QUICKSIGHT_TOKEN | default "" }
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

def base-url-completer [] { ["http://quicksight.us-east-1.amazonaws.com" "http://quicksight.us-east-2.amazonaws.com" "http://quicksight.us-west-1.amazonaws.com" "http://quicksight.us-west-2.amazonaws.com" "http://quicksight.us-gov-west-1.amazonaws.com" "http://quicksight.us-gov-east-1.amazonaws.com" "http://quicksight.ca-central-1.amazonaws.com" "http://quicksight.eu-north-1.amazonaws.com" "http://quicksight.eu-west-1.amazonaws.com" "http://quicksight.eu-west-2.amazonaws.com" "http://quicksight.eu-west-3.amazonaws.com" "http://quicksight.eu-central-1.amazonaws.com" "http://quicksight.eu-south-1.amazonaws.com" "http://quicksight.af-south-1.amazonaws.com" "http://quicksight.ap-northeast-1.amazonaws.com" "http://quicksight.ap-northeast-2.amazonaws.com" "http://quicksight.ap-northeast-3.amazonaws.com" "http://quicksight.ap-southeast-1.amazonaws.com" "http://quicksight.ap-southeast-2.amazonaws.com" "http://quicksight.ap-east-1.amazonaws.com" "http://quicksight.ap-south-1.amazonaws.com" "http://quicksight.sa-east-1.amazonaws.com" "http://quicksight.me-south-1.amazonaws.com" "https://quicksight.us-east-1.amazonaws.com" "https://quicksight.us-east-2.amazonaws.com" "https://quicksight.us-west-1.amazonaws.com" "https://quicksight.us-west-2.amazonaws.com" "https://quicksight.us-gov-west-1.amazonaws.com" "https://quicksight.us-gov-east-1.amazonaws.com" "https://quicksight.ca-central-1.amazonaws.com" "https://quicksight.eu-north-1.amazonaws.com" "https://quicksight.eu-west-1.amazonaws.com" "https://quicksight.eu-west-2.amazonaws.com" "https://quicksight.eu-west-3.amazonaws.com" "https://quicksight.eu-central-1.amazonaws.com" "https://quicksight.eu-south-1.amazonaws.com" "https://quicksight.af-south-1.amazonaws.com" "https://quicksight.ap-northeast-1.amazonaws.com" "https://quicksight.ap-northeast-2.amazonaws.com" "https://quicksight.ap-northeast-3.amazonaws.com" "https://quicksight.ap-southeast-1.amazonaws.com" "https://quicksight.ap-southeast-2.amazonaws.com" "https://quicksight.ap-east-1.amazonaws.com" "https://quicksight.ap-south-1.amazonaws.com" "https://quicksight.sa-east-1.amazonaws.com" "https://quicksight.me-south-1.amazonaws.com" "http://quicksight.cn-north-1.amazonaws.com.cn" "http://quicksight.cn-northwest-1.amazonaws.com.cn" "https://quicksight.cn-north-1.amazonaws.com.cn" "https://quicksight.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def IngestionType-completer [] { ["FULL_REFRESH" "INCREMENTAL_REFRESH"] }
def Edition-completer [] { ["ENTERPRISE" "ENTERPRISE_AND_Q" "STANDARD"] }
def AuthenticationMethod-completer [] { ["ACTIVE_DIRECTORY" "IAM_AND_QUICKSIGHT" "IAM_ONLY"] }
def ImportMode-completer [] { ["DIRECT_QUERY" "SPICE"] }
def Type-completer [] { ["ADOBE_ANALYTICS" "AMAZON_ELASTICSEARCH" "AMAZON_OPENSEARCH" "ATHENA" "AURORA" "AURORA_POSTGRESQL" "AWS_IOT_ANALYTICS" "DATABRICKS" "EXASOL" "GITHUB" "JIRA" "MARIADB" "MYSQL" "ORACLE" "POSTGRESQL" "PRESTO" "REDSHIFT" "S3" "SALESFORCE" "SERVICENOW" "SNOWFLAKE" "SPARK" "SQLSERVER" "TERADATA" "TIMESTREAM" "TWITTER"] }
def FolderType-completer [] { ["SHARED"] }
def AssignmentStatus-completer [] { ["DISABLED" "DRAFT" "ENABLED"] }
def IdentityStore-completer [] { ["QUICKSIGHT"] }
def Role-completer [] { ["ADMIN" "AUTHOR" "READER" "RESTRICTED_AUTHOR" "RESTRICTED_READER"] }
def creds-type-completer [] { ["ANONYMOUS" "IAM" "QUICKSIGHT"] }
def type-completer [] { ["ALL" "CUSTOM" "QUICKSIGHT"] }
def IdentityType-completer [] { ["IAM" "QUICKSIGHT"] }
def UserRole-completer [] { ["ADMIN" "AUTHOR" "READER" "RESTRICTED_AUTHOR" "RESTRICTED_READER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-data-sets-ingestions CancelIngestion" } } | get name | first)
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

# Cancels an ongoing ingestion of data into SPICE.
#
# DELETE /accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}
# operationId: CancelIngestion
export def "accounts-data-sets-ingestions CancelIngestion" [
  AwsAccountId: string
  DataSetId: string
  IngestionId: string
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
]: nothing -> record<Arn: record, IngestionId: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/ingestions/($IngestionId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Creates and starts a new SPICE ingestion for a dataset. You can manually refresh datasets in an Enterprise edition account 32 times in a 24-hour period. You can manually refresh datasets in a Standard edition account 8 times in a 24-hour period. Each 24-hour period is measured starting 24 hours before the current date and time.</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="http://aws.amazon.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the Amazon Web Services Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
#
# PUT /accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}
# operationId: CreateIngestion
export def "accounts-data-sets-ingestions CreateIngestion" [
  DataSetId: string
  IngestionId: string
  AwsAccountId: string
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
  --IngestionType: string@IngestionType-completer # This defines the type of ingestion user wants to trigger. This is part of create ingestion request.
]: any -> record<Arn: record, IngestionId: record, IngestionStatus: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/ingestions/($IngestionId)")
  let body = {IngestionType: $IngestionType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes a SPICE ingestion.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}
# operationId: DescribeIngestion
export def "accounts-data-sets-ingestions DescribeIngestion" [
  AwsAccountId: string
  DataSetId: string
  IngestionId: string
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
]: nothing -> record<Ingestion: record<Arn: record, IngestionId: record, IngestionStatus: record, ErrorInfo: record<Type: record, Message: record>, RowInfo: record<RowsIngested: record, RowsDropped: record, TotalRowsInDataset: record>, QueueInfo: record<WaitingOnIngestion: record, QueuedIngestion: record>, CreatedTime: record, IngestionTimeInSeconds: record, IngestionSizeInBytes: record, RequestSource: record, RequestType: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/ingestions/($IngestionId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Creates Amazon QuickSight customizations for the current Amazon Web Services Region. Currently, you can add a custom default theme by using the <code>CreateAccountCustomization</code> or <code>UpdateAccountCustomization</code> API operation. To further customize Amazon QuickSight by removing Amazon QuickSight sample assets and videos for all new users, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/customizing-quicksight.html">Customizing Amazon QuickSight</a> in the <i>Amazon QuickSight User Guide.</i> </p> <p>You can create customizations for your Amazon Web Services account or, if you specify a namespace, for a QuickSight namespace instead. Customizations that apply to a namespace always override customizations that apply to an Amazon Web Services account. To find out which customizations apply, use the <code>DescribeAccountCustomization</code> API operation.</p> <p>Before you use the <code>CreateAccountCustomization</code> API operation to add a theme as the namespace default, make sure that you first share the theme with the namespace. If you don't share it with the namespace, the theme isn't visible to your users even if you make it the default theme. To check if the theme is shared, view the current permissions by using the <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeThemePermissions.html">DescribeThemePermissions</a> </code> API operation. To share the theme, grant permissions by using the <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateThemePermissions.html">UpdateThemePermissions</a> </code> API operation. </p>
#
# POST /accounts/{AwsAccountId}/customizations
# operationId: CreateAccountCustomization
# --AccountCustomization shape: {DefaultTheme?: any, DefaultEmailCustomizationTemplate?: any}
# --Tags item shape: {Key: any, Value: any}
export def "accounts-customizations CreateAccountCustomization" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The Amazon QuickSight namespace that you want to add customizations to.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  AccountCustomization: record # The Amazon QuickSight customizations associated with your Amazon Web Services account or a QuickSight namespace in a specific Amazon Web Services Region. — shape: {DefaultTheme?: any, DefaultEmailCustomizationTemplate?: any}
  --Tags: list # A list of the tags that you want to attach to this resource. — item shape: {Key: any, Value: any}
]: any -> record<Arn: record, AwsAccountId: record, Namespace: record, AccountCustomization: record<DefaultTheme: record, DefaultEmailCustomizationTemplate: record>, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/customizations" $qp)
  let body = {AccountCustomization: $AccountCustomization, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes all Amazon QuickSight customizations in this Amazon Web Services Region for the specified Amazon Web Services account and Amazon QuickSight namespace.
#
# DELETE /accounts/{AwsAccountId}/customizations
# operationId: DeleteAccountCustomization
export def "accounts-customizations DeleteAccountCustomization" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The Amazon QuickSight namespace that you're deleting the customizations from.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/customizations" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Describes the customizations associated with the provided Amazon Web Services account and Amazon Amazon QuickSight namespace in an Amazon Web Services Region. The Amazon QuickSight console evaluates which customizations to apply by running this API operation with the <code>Resolved</code> flag included. </p> <p>To determine what customizations display when you run this command, it can help to visualize the relationship of the entities involved. </p> <ul> <li> <p> <code>Amazon Web Services account</code> - The Amazon Web Services account exists at the top of the hierarchy. It has the potential to use all of the Amazon Web Services Regions and Amazon Web Services Services. When you subscribe to Amazon QuickSight, you choose one Amazon Web Services Region to use as your home Region. That's where your free SPICE capacity is located. You can use Amazon QuickSight in any supported Amazon Web Services Region. </p> </li> <li> <p> <code>Amazon Web Services Region</code> - In each Amazon Web Services Region where you sign in to Amazon QuickSight at least once, Amazon QuickSight acts as a separate instance of the same service. If you have a user directory, it resides in us-east-1, which is the US East (N. Virginia). Generally speaking, these users have access to Amazon QuickSight in any Amazon Web Services Region, unless they are constrained to a namespace. </p> <p>To run the command in a different Amazon Web Services Region, you change your Region settings. If you're using the CLI, you can use one of the following options:</p> <ul> <li> <p>Use <a href="https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-options.html">command line options</a>. </p> </li> <li> <p>Use <a href="https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html">named profiles</a>. </p> </li> <li> <p>Run <code>aws configure</code> to change your default Amazon Web Services Region. Use Enter to key the same settings for your keys. For more information, see <a href="https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html">Configuring the CLI</a>.</p> </li> </ul> </li> <li> <p> <code>Namespace</code> - A QuickSight namespace is a partition that contains users and assets (data sources, datasets, dashboards, and so on). To access assets that are in a specific namespace, users and groups must also be part of the same namespace. People who share a namespace are completely isolated from users and assets in other namespaces, even if they are in the same Amazon Web Services account and Amazon Web Services Region.</p> </li> <li> <p> <code>Applied customizations</code> - Within an Amazon Web Services Region, a set of Amazon QuickSight customizations can apply to an Amazon Web Services account or to a namespace. Settings that you apply to a namespace override settings that you apply to an Amazon Web Services account. All settings are isolated to a single Amazon Web Services Region. To apply them in other Amazon Web Services Regions, run the <code>CreateAccountCustomization</code> command in each Amazon Web Services Region where you want to apply the same customizations. </p> </li> </ul>
#
# GET /accounts/{AwsAccountId}/customizations
# operationId: DescribeAccountCustomization
export def "accounts-customizations DescribeAccountCustomization" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The Amazon QuickSight namespace that you want to describe Amazon QuickSight customizations for.
  --resolved: oneof<nothing, bool> # The <code>Resolved</code> flag works with the other parameters to determine which view of Amazon QuickSight customizations is returned. You can add this flag to your command to use the same view that Amazon QuickSight uses to identify which customizations to apply to the console. Omit this flag, or set it to <code>no-resolved</code>, to reveal customizations that are configured at different levels. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, AwsAccountId: record, Namespace: record, AccountCustomization: record<DefaultTheme: record, DefaultEmailCustomizationTemplate: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "resolved" $resolved "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/customizations" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Updates Amazon QuickSight customizations for the current Amazon Web Services Region. Currently, the only customization that you can use is a theme.</p> <p>You can use customizations for your Amazon Web Services account or, if you specify a namespace, for a Amazon QuickSight namespace instead. Customizations that apply to a namespace override customizations that apply to an Amazon Web Services account. To find out which customizations apply, use the <code>DescribeAccountCustomization</code> API operation. </p>
#
# PUT /accounts/{AwsAccountId}/customizations
# operationId: UpdateAccountCustomization
# --AccountCustomization shape: {DefaultTheme?: any, DefaultEmailCustomizationTemplate?: any}
export def "accounts-customizations UpdateAccountCustomization" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The namespace that you want to update Amazon QuickSight customizations for.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  AccountCustomization: record # The Amazon QuickSight customizations associated with your Amazon Web Services account or a QuickSight namespace in a specific Amazon Web Services Region. — shape: {DefaultTheme?: any, DefaultEmailCustomizationTemplate?: any}
]: any -> record<Arn: record, AwsAccountId: record, Namespace: record, AccountCustomization: record<DefaultTheme: record, DefaultEmailCustomizationTemplate: record>, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/customizations" $qp)
  let body = {AccountCustomization: $AccountCustomization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an Amazon QuickSight account, or subscribes to Amazon QuickSight Q.</p> <p>The Amazon Web Services Region for the account is derived from what is configured in the CLI or SDK. This operation isn't supported in the US East (Ohio) Region, South America (Sao Paulo) Region, or Asia Pacific (Singapore) Region. </p> <p>Before you use this operation, make sure that you can connect to an existing Amazon Web Services account. If you don't have an Amazon Web Services account, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/setting-up-aws-sign-up.html">Sign up for Amazon Web Services</a> in the <i>Amazon QuickSight User Guide</i>. The person who signs up for Amazon QuickSight needs to have the correct Identity and Access Management (IAM) permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/iam-policy-examples.html">IAM Policy Examples for Amazon QuickSight</a> in the <i>Amazon QuickSight User Guide</i>.</p> <p>If your IAM policy includes both the <code>Subscribe</code> and <code>CreateAccountSubscription</code> actions, make sure that both actions are set to <code>Allow</code>. If either action is set to <code>Deny</code>, the <code>Deny</code> action prevails and your API call fails.</p> <p>You can't pass an existing IAM role to access other Amazon Web Services services using this API operation. To pass your existing IAM role to Amazon QuickSight, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/security_iam_service-with-iam.html#security-create-iam-role">Passing IAM roles to Amazon QuickSight</a> in the <i>Amazon QuickSight User Guide</i>.</p> <p>You can't set default resource access on the new account from the Amazon QuickSight API. Instead, add default resource access from the Amazon QuickSight console. For more information about setting default resource access to Amazon Web Services services, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/scoping-policies-defaults.html">Setting default resource access to Amazon Web Services services</a> in the <i>Amazon QuickSight User Guide</i>.</p>
#
# POST /account/{AwsAccountId}
# operationId: CreateAccountSubscription
export def "account CreateAccountSubscription" [
  AwsAccountId: string
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
  Edition: string@Edition-completer # <p>The edition of Amazon QuickSight that you want your account to have. Currently, you can choose from <code>ENTERPRISE</code> or <code>ENTERPRISE_AND_Q</code>.</p> <p>If you choose <code>ENTERPRISE_AND_Q</code>, the following parameters are required:</p> <ul> <li> <p> <code>FirstName</code> </p> </li> <li> <p> <code>LastName</code> </p> </li> <li> <p> <code>EmailAddress</code> </p> </li> <li> <p> <code>ContactNumber</code> </p> </li> </ul>
  AuthenticationMethod: string@AuthenticationMethod-completer # <p>The method that you want to use to authenticate your Amazon QuickSight account. Currently, the valid values for this parameter are <code>IAM_AND_QUICKSIGHT</code>, <code>IAM_ONLY</code>, and <code>ACTIVE_DIRECTORY</code>.</p> <p>If you choose <code>ACTIVE_DIRECTORY</code>, provide an <code>ActiveDirectoryName</code> and an <code>AdminGroup</code> associated with your Active Directory.</p>
  AccountName: string # The name of your Amazon QuickSight account. This name is unique over all of Amazon Web Services, and it appears only when users sign in. You can't change <code>AccountName</code> value after the Amazon QuickSight account is created.
  NotificationEmail: string # The email address that you want Amazon QuickSight to send notifications to regarding your Amazon QuickSight account or Amazon QuickSight subscription.
  --ActiveDirectoryName: string # The name of your Active Directory. This field is required if <code>ACTIVE_DIRECTORY</code> is the selected authentication method of the new Amazon QuickSight account.
  --Realm: string # The realm of the Active Directory that is associated with your Amazon QuickSight account. This field is required if <code>ACTIVE_DIRECTORY</code> is the selected authentication method of the new Amazon QuickSight account.
  --DirectoryId: string # The ID of the Active Directory that is associated with your Amazon QuickSight account.
  --AdminGroup: list # The admin group associated with your Active Directory. This field is required if <code>ACTIVE_DIRECTORY</code> is the selected authentication method of the new Amazon QuickSight account. For more information about using Active Directory in Amazon QuickSight, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/aws-directory-service.html">Using Active Directory with Amazon QuickSight Enterprise Edition</a> in the Amazon QuickSight User Guide.
  --AuthorGroup: list # The author group associated with your Active Directory. For more information about using Active Directory in Amazon QuickSight, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/aws-directory-service.html">Using Active Directory with Amazon QuickSight Enterprise Edition</a> in the Amazon QuickSight User Guide.
  --ReaderGroup: list # The reader group associated with your Active Direcrtory. For more information about using Active Directory in Amazon QuickSight, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/aws-directory-service.html">Using Active Directory with Amazon QuickSight Enterprise Edition</a> in the <i>Amazon QuickSight User Guide</i>.
  --FirstName: string # The first name of the author of the Amazon QuickSight account to use for future communications. This field is required if <code>ENTERPPRISE_AND_Q</code> is the selected edition of the new Amazon QuickSight account.
  --LastName: string # The last name of the author of the Amazon QuickSight account to use for future communications. This field is required if <code>ENTERPPRISE_AND_Q</code> is the selected edition of the new Amazon QuickSight account.
  --EmailAddress: string # The email address of the author of the Amazon QuickSight account to use for future communications. This field is required if <code>ENTERPPRISE_AND_Q</code> is the selected edition of the new Amazon QuickSight account.
  --ContactNumber: string # A 10-digit phone number for the author of the Amazon QuickSight account to use for future communications. This field is required if <code>ENTERPPRISE_AND_Q</code> is the selected edition of the new Amazon QuickSight account.
]: any -> record<SignupResponse: record<IAMUser: record, userLoginName: record, accountName: record, directoryType: record>, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($AwsAccountId)")
  let body = {Edition: $Edition, AuthenticationMethod: $AuthenticationMethod, AccountName: $AccountName, NotificationEmail: $NotificationEmail, ActiveDirectoryName: $ActiveDirectoryName, Realm: $Realm, DirectoryId: $DirectoryId, AdminGroup: $AdminGroup, AuthorGroup: $AuthorGroup, ReaderGroup: $ReaderGroup, FirstName: $FirstName, LastName: $LastName, EmailAddress: $EmailAddress, ContactNumber: $ContactNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use the <code>DeleteAccountSubscription</code> operation to delete an Amazon QuickSight account. This operation will result in an error message if you have configured your account termination protection settings to <code>True</code>. To change this setting and delete your account, call the <code>UpdateAccountSettings</code> API and set the value of the <code>TerminationProtectionEnabled</code> parameter to <code>False</code>, then make another call to the <code>DeleteAccountSubscription</code> API.
#
# DELETE /account/{AwsAccountId}
# operationId: DeleteAccountSubscription
export def "account DeleteAccountSubscription" [
  AwsAccountId: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($AwsAccountId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use the DescribeAccountSubscription operation to receive a description of an Amazon QuickSight account's subscription. A successful API call returns an <code>AccountInfo</code> object that includes an account's name, subscription status, authentication type, edition, and notification email address.
#
# GET /account/{AwsAccountId}
# operationId: DescribeAccountSubscription
export def "account DescribeAccountSubscription" [
  AwsAccountId: string
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
]: nothing -> record<AccountInfo: record<AccountName: record, Edition: record, NotificationEmail: record, AuthenticationType: record, AccountSubscriptionStatus: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/($AwsAccountId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an analysis in Amazon QuickSight. Analyses can be created either from a template or from an <code>AnalysisDefinition</code>.
#
# POST /accounts/{AwsAccountId}/analyses/{AnalysisId}
# operationId: CreateAnalysis
# --Parameters shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
# --Permissions item shape: {Principal: any, Actions: any}
# --SourceEntity shape: {SourceTemplate?: any}
# --Tags item shape: {Key: any, Value: any}
# --Definition shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-analyses CreateAnalysis" [
  AwsAccountId: string
  AnalysisId: string
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
  Name: string # A descriptive name for the analysis that you're creating. This name displays for the analysis in the Amazon QuickSight console. 
  --Parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
  --Permissions: list # <p>A structure that describes the principals and the resource-level permissions on an analysis. You can use the <code>Permissions</code> structure to grant permissions by providing a list of Identity and Access Management (IAM) action information for each principal listed by Amazon Resource Name (ARN). </p> <p>To specify no permissions, omit <code>Permissions</code>.</p> — item shape: {Principal: any, Actions: any}
  --SourceEntity: record # The source entity of an analysis. — shape: {SourceTemplate?: any}
  --ThemeArn: string # The ARN for the theme to apply to the analysis that you're creating. To see the theme in the Amazon QuickSight console, make sure that you have access to it.
  --Tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the analysis. — item shape: {Key: any, Value: any}
  --Definition: record # The definition of an analysis. — shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<Arn: record, AnalysisId: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/analyses/($AnalysisId)")
  let body = {Name: $Name, Parameters: $Parameters, Permissions: $Permissions, SourceEntity: $SourceEntity, ThemeArn: $ThemeArn, Tags: $Tags, Definition: $Definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes an analysis from Amazon QuickSight. You can optionally include a recovery window during which you can restore the analysis. If you don't specify a recovery window value, the operation defaults to 30 days. Amazon QuickSight attaches a <code>DeletionTime</code> stamp to the response that specifies the end of the recovery window. At the end of the recovery window, Amazon QuickSight deletes the analysis permanently.</p> <p>At any time before recovery window ends, you can use the <code>RestoreAnalysis</code> API operation to remove the <code>DeletionTime</code> stamp and cancel the deletion of the analysis. The analysis remains visible in the API until it's deleted, so you can describe it but you can't make a template from it.</p> <p>An analysis that's scheduled for deletion isn't accessible in the Amazon QuickSight console. To access it in the console, restore it. Deleting an analysis doesn't delete the dashboards that you publish from it.</p>
#
# DELETE /accounts/{AwsAccountId}/analyses/{AnalysisId}
# operationId: DeleteAnalysis
export def "accounts-analyses DeleteAnalysis" [
  AwsAccountId: string
  AnalysisId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recovery-window-in-days: int # A value that specifies the number of days that Amazon QuickSight waits before it deletes the analysis. You can't use this parameter with the <code>ForceDeleteWithoutRecovery</code> option in the same API call. The default value is 30.
  --force-delete-without-recovery: oneof<nothing, bool> # This option defaults to the value <code>NoForceDeleteWithoutRecovery</code>. To immediately delete the analysis, add the <code>ForceDeleteWithoutRecovery</code> option. You can't restore an analysis after it's deleted. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Status: record, Arn: record, AnalysisId: record, DeletionTime: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recovery-window-in-days" $recovery_window_in_days "scalar") (serialize-qp "force-delete-without-recovery" $force_delete_without_recovery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/analyses/($AnalysisId)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides a summary of the metadata for an analysis.
#
# GET /accounts/{AwsAccountId}/analyses/{AnalysisId}
# operationId: DescribeAnalysis
export def "accounts-analyses DescribeAnalysis" [
  AwsAccountId: string
  AnalysisId: string
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
]: nothing -> record<Analysis: record<AnalysisId: record, Arn: record, Name: record, Status: record, Errors: record, DataSetArns: record, ThemeArn: record, CreatedTime: record, LastUpdatedTime: record, Sheets: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/analyses/($AnalysisId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an analysis in Amazon QuickSight
#
# PUT /accounts/{AwsAccountId}/analyses/{AnalysisId}
# operationId: UpdateAnalysis
# --Parameters shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
# --SourceEntity shape: {SourceTemplate?: any}
# --Definition shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-analyses UpdateAnalysis" [
  AwsAccountId: string
  AnalysisId: string
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
  Name: string # A descriptive name for the analysis that you're updating. This name displays for the analysis in the Amazon QuickSight console.
  --Parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
  --SourceEntity: record # The source entity of an analysis. — shape: {SourceTemplate?: any}
  --ThemeArn: string # The Amazon Resource Name (ARN) for the theme to apply to the analysis that you're creating. To see the theme in the Amazon QuickSight console, make sure that you have access to it.
  --Definition: record # The definition of an analysis. — shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<Arn: record, AnalysisId: record, UpdateStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/analyses/($AnalysisId)")
  let body = {Name: $Name, Parameters: $Parameters, SourceEntity: $SourceEntity, ThemeArn: $ThemeArn, Definition: $Definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a dashboard from either a template or directly with a <code>DashboardDefinition</code>. To first create a template, see the <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_CreateTemplate.html">CreateTemplate</a> </code> API operation.</p> <p>A dashboard is an entity in Amazon QuickSight that identifies Amazon QuickSight reports, created from analyses. You can share Amazon QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. If you have the correct permissions, you can create a dashboard from a template that exists in a different Amazon Web Services account.</p>
#
# POST /accounts/{AwsAccountId}/dashboards/{DashboardId}
# operationId: CreateDashboard
# --Parameters shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
# --Permissions item shape: {Principal: any, Actions: any}
# --SourceEntity shape: {SourceTemplate?: any}
# --Tags item shape: {Key: any, Value: any}
# --DashboardPublishOptions shape: {AdHocFilteringOption?: any, ExportToCSVOption?: any, SheetControlsOption?: any, VisualPublishOptions?: any, SheetLayoutElementMaximizationOption?: any, VisualMenuOption?: any, VisualAxisSortOption?: any, ExportWithHiddenFieldsOption?: any, DataPointDrillUpDownOption?: any, DataPointMenuLabelOption?: any, DataPointTooltipOption?: any}
# --Definition shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-dashboards CreateDashboard" [
  AwsAccountId: string
  DashboardId: string
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
  Name: string # The display name of the dashboard.
  --Parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
  --Permissions: list # <p>A structure that contains the permissions of the dashboard. You can use this structure for granting permissions by providing a list of IAM action information for each principal ARN. </p> <p>To specify no permissions, omit the permissions list.</p> — item shape: {Principal: any, Actions: any}
  --SourceEntity: record # Dashboard source entity. — shape: {SourceTemplate?: any}
  --Tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the dashboard. — item shape: {Key: any, Value: any}
  --VersionDescription: string # A description for the first version of the dashboard being created.
  --DashboardPublishOptions: record # Dashboard publish options. — shape: {AdHocFilteringOption?: any, ExportToCSVOption?: any, SheetControlsOption?: any, VisualPublishOptions?: any, SheetLayoutElementMaximizationOption?: any, VisualMenuOption?: any, VisualAxisSortOption?: any, ExportWithHiddenFieldsOption?: any, DataPointDrillUpDownOption?: any, DataPointMenuLabelOption?: any, DataPointTooltipOption?: any}
  --ThemeArn: string # The Amazon Resource Name (ARN) of the theme that is being used for this dashboard. If you add a value for this field, it overrides the value that is used in the source entity. The theme ARN must exist in the same Amazon Web Services account where you create the dashboard.
  --Definition: record # The contents of a dashboard. — shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<Arn: record, VersionArn: record, DashboardId: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/dashboards/($DashboardId)")
  let body = {Name: $Name, Parameters: $Parameters, Permissions: $Permissions, SourceEntity: $SourceEntity, Tags: $Tags, VersionDescription: $VersionDescription, DashboardPublishOptions: $DashboardPublishOptions, ThemeArn: $ThemeArn, Definition: $Definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a dashboard.
#
# DELETE /accounts/{AwsAccountId}/dashboards/{DashboardId}
# operationId: DeleteDashboard
export def "accounts-dashboards DeleteDashboard" [
  AwsAccountId: string
  DashboardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Status: record, Arn: record, DashboardId: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/dashboards/($DashboardId)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides a summary for a dashboard.
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}
# operationId: DescribeDashboard
export def "accounts-dashboards DescribeDashboard" [
  AwsAccountId: string
  DashboardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described. 
  --alias-name: string # The alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Dashboard: record<DashboardId: record, Arn: record, Name: record, Version: record<CreatedTime: record, Errors: record, VersionNumber: record, Status: record, Arn: record, SourceEntityArn: record, DataSetArns: record, Description: record, ThemeArn: record, Sheets: record>, CreatedTime: record, LastPublishedTime: record, LastUpdatedTime: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar") (serialize-qp "alias-name" $alias_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/dashboards/($DashboardId)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Updates a dashboard in an Amazon Web Services account.</p> <note> <p>Updating a Dashboard creates a new dashboard version but does not immediately publish the new version. You can update the published version of a dashboard by using the <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateDashboardPublishedVersion.html">UpdateDashboardPublishedVersion</a> </code> API operation.</p> </note>
#
# PUT /accounts/{AwsAccountId}/dashboards/{DashboardId}
# operationId: UpdateDashboard
# --SourceEntity shape: {SourceTemplate?: any}
# --Parameters shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
# --DashboardPublishOptions shape: {AdHocFilteringOption?: any, ExportToCSVOption?: any, SheetControlsOption?: any, VisualPublishOptions?: any, SheetLayoutElementMaximizationOption?: any, VisualMenuOption?: any, VisualAxisSortOption?: any, ExportWithHiddenFieldsOption?: any, DataPointDrillUpDownOption?: any, DataPointMenuLabelOption?: any, DataPointTooltipOption?: any}
# --Definition shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-dashboards UpdateDashboard" [
  AwsAccountId: string
  DashboardId: string
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
  Name: string # The display name of the dashboard.
  --SourceEntity: record # Dashboard source entity. — shape: {SourceTemplate?: any}
  --Parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
  --VersionDescription: string # A description for the first version of the dashboard being created.
  --DashboardPublishOptions: record # Dashboard publish options. — shape: {AdHocFilteringOption?: any, ExportToCSVOption?: any, SheetControlsOption?: any, VisualPublishOptions?: any, SheetLayoutElementMaximizationOption?: any, VisualMenuOption?: any, VisualAxisSortOption?: any, ExportWithHiddenFieldsOption?: any, DataPointDrillUpDownOption?: any, DataPointMenuLabelOption?: any, DataPointTooltipOption?: any}
  --ThemeArn: string # The Amazon Resource Name (ARN) of the theme that is being used for this dashboard. If you add a value for this field, it overrides the value that was originally associated with the entity. The theme ARN must exist in the same Amazon Web Services account where you create the dashboard.
  --Definition: record # The contents of a dashboard. — shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<Arn: record, VersionArn: record, DashboardId: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/dashboards/($DashboardId)")
  let body = {Name: $Name, SourceEntity: $SourceEntity, Parameters: $Parameters, VersionDescription: $VersionDescription, DashboardPublishOptions: $DashboardPublishOptions, ThemeArn: $ThemeArn, Definition: $Definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a dataset. This operation doesn't support datasets that include uploaded files as a source.
#
# POST /accounts/{AwsAccountId}/data-sets
# operationId: CreateDataSet
# --ColumnGroups item shape: {GeoSpatialColumnGroup?: any}
# --Permissions item shape: {Principal: any, Actions: any}
# --RowLevelPermissionDataSet shape: {Namespace?: any, Arn?: any, PermissionPolicy?: any, FormatVersion?: any, Status?: any}
# --RowLevelPermissionTagConfiguration shape: {Status?: any, TagRules?: any, TagRuleConfigurations?: any}
# --ColumnLevelPermissionRules item shape: {Principals?: any, ColumnNames?: any}
# --Tags item shape: {Key: any, Value: any}
# --DataSetUsageConfiguration shape: {DisableUseAsDirectQuerySource?: any, DisableUseAsImportedSource?: any}
export def "accounts-data-sets CreateDataSet" [
  AwsAccountId: string
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
  DataSetId: string # An ID for the dataset that you want to create. This ID is unique per Amazon Web Services Region for each Amazon Web Services account.
  Name: string # The display name for the dataset.
  PhysicalTableMap: record # Declares the physical tables that are available in the underlying data sources.
  --LogicalTableMap: record # Configures the combination and transformation of the data from the physical tables.
  ImportMode: string@ImportMode-completer # Indicates whether you want to import the data into SPICE.
  --ColumnGroups: list # Groupings of columns that work together in certain Amazon QuickSight features. Currently, only geospatial hierarchy is supported. — item shape: {GeoSpatialColumnGroup?: any}
  --FieldFolders: record # The folder that contains fields and nested subfolders for your dataset.
  --Permissions: list # A list of resource permissions on the dataset. — item shape: {Principal: any, Actions: any}
  --RowLevelPermissionDataSet: record # <p>Information about a dataset that contains permissions for row-level security (RLS). The permissions dataset maps fields to users or groups. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/restrict-access-to-a-data-set-using-row-level-security.html">Using Row-Level Security (RLS) to Restrict Access to a Dataset</a> in the <i>Amazon QuickSight User Guide</i>.</p> <p>The option to deny permissions by setting <code>PermissionPolicy</code> to <code>DENY_ACCESS</code> is not supported for new RLS datasets.</p> — shape: {Namespace?: any, Arn?: any, PermissionPolicy?: any, FormatVersion?: any, Status?: any}
  --RowLevelPermissionTagConfiguration: record # The configuration of tags on a dataset to set row-level security.  — shape: {Status?: any, TagRules?: any, TagRuleConfigurations?: any}
  --ColumnLevelPermissionRules: list # A set of one or more definitions of a <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_ColumnLevelPermissionRule.html">ColumnLevelPermissionRule</a> </code>. — item shape: {Principals?: any, ColumnNames?: any}
  --Tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the dataset. — item shape: {Key: any, Value: any}
  --DataSetUsageConfiguration: record # The usage configuration to apply to child datasets that reference this dataset as a source. — shape: {DisableUseAsDirectQuerySource?: any, DisableUseAsImportedSource?: any}
]: any -> record<Arn: record, DataSetId: record, IngestionArn: record, IngestionId: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets")
  let body = {DataSetId: $DataSetId, Name: $Name, PhysicalTableMap: $PhysicalTableMap, LogicalTableMap: $LogicalTableMap, ImportMode: $ImportMode, ColumnGroups: $ColumnGroups, FieldFolders: $FieldFolders, Permissions: $Permissions, RowLevelPermissionDataSet: $RowLevelPermissionDataSet, RowLevelPermissionTagConfiguration: $RowLevelPermissionTagConfiguration, ColumnLevelPermissionRules: $ColumnLevelPermissionRules, Tags: $Tags, DataSetUsageConfiguration: $DataSetUsageConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Lists all of the datasets belonging to the current Amazon Web Services account in an Amazon Web Services Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
#
# GET /accounts/{AwsAccountId}/data-sets
# operationId: ListDataSets
export def "accounts-data-sets ListDataSets" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DataSetSummaries: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a data source.
#
# POST /accounts/{AwsAccountId}/data-sources
# operationId: CreateDataSource
# --DataSourceParameters shape: {AmazonElasticsearchParameters?: any, AthenaParameters?: any, AuroraParameters?: any, AuroraPostgreSqlParameters?: any, AwsIotAnalyticsParameters?: any, JiraParameters?: any, MariaDbParameters?: any, MySqlParameters?: any, OracleParameters?: any, PostgreSqlParameters?: any, PrestoParameters?: any, RdsParameters?: any, RedshiftParameters?: any, S3Parameters?: any, ServiceNowParameters?: any, SnowflakeParameters?: any, SparkParameters?: any, SqlServerParameters?: any, TeradataParameters?: any, TwitterParameters?: any, AmazonOpenSearchParameters?: any, ExasolParameters?: any, DatabricksParameters?: any}
# --Credentials shape: {CredentialPair?: any, CopySourceArn?: any, SecretArn?: any}
# --Permissions item shape: {Principal: any, Actions: any}
# --VpcConnectionProperties shape: {VpcConnectionArn?: any}
# --SslProperties shape: {DisableSsl?: any}
# --Tags item shape: {Key: any, Value: any}
export def "accounts-data-sources CreateDataSource" [
  AwsAccountId: string
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
  DataSourceId: string # An ID for the data source. This ID is unique per Amazon Web Services Region for each Amazon Web Services account. 
  Name: string # A display name for the data source.
  Type: string@Type-completer # <p>The type of the data source. To return a list of all data sources, use <code>ListDataSources</code>.</p> <p>Use <code>AMAZON_ELASTICSEARCH</code> for Amazon OpenSearch Service.</p>
  --DataSourceParameters: record # The parameters that Amazon QuickSight uses to connect to your underlying data source. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {AmazonElasticsearchParameters?: any, AthenaParameters?: any, AuroraParameters?: any, AuroraPostgreSqlParameters?: any, AwsIotAnalyticsParameters?: any, JiraParameters?: any, MariaDbParameters?: any, MySqlParameters?: any, OracleParameters?: any, PostgreSqlParameters?: any, PrestoParameters?: any, RdsParameters?: any, RedshiftParameters?: any, S3Parameters?: any, ServiceNowParameters?: any, SnowflakeParameters?: any, SparkParameters?: any, SqlServerParameters?: any, TeradataParameters?: any, TwitterParameters?: any, AmazonOpenSearchParameters?: any, ExasolParameters?: any, DatabricksParameters?: any}
  --Credentials: record # Data source credentials. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {CredentialPair?: any, CopySourceArn?: any, SecretArn?: any}
  --Permissions: list # A list of resource permissions on the data source. — item shape: {Principal: any, Actions: any}
  --VpcConnectionProperties: record # VPC connection properties. — shape: {VpcConnectionArn?: any}
  --SslProperties: record # Secure Socket Layer (SSL) properties that apply when Amazon QuickSight connects to your underlying data source. — shape: {DisableSsl?: any}
  --Tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the data source. — item shape: {Key: any, Value: any}
]: any -> record<Arn: record, DataSourceId: record, CreationStatus: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sources")
  let body = {DataSourceId: $DataSourceId, Name: $Name, Type: $Type, DataSourceParameters: $DataSourceParameters, Credentials: $Credentials, Permissions: $Permissions, VpcConnectionProperties: $VpcConnectionProperties, SslProperties: $SslProperties, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists data sources in current Amazon Web Services Region that belong to this Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/data-sources
# operationId: ListDataSources
export def "accounts-data-sources ListDataSources" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DataSources: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sources" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an empty shared folder.
#
# POST /accounts/{AwsAccountId}/folders/{FolderId}
# operationId: CreateFolder
# --Permissions item shape: {Principal: any, Actions: any}
# --Tags item shape: {Key: any, Value: any}
export def "accounts-folders CreateFolder" [
  AwsAccountId: string
  FolderId: string
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
  --Name: string # The name of the folder.
  --FolderType: string@FolderType-completer # The type of folder. By default, <code>folderType</code> is <code>SHARED</code>.
  --ParentFolderArn: string # <p>The Amazon Resource Name (ARN) for the parent folder.</p> <p> <code>ParentFolderArn</code> can be null. An empty <code>parentFolderArn</code> creates a root-level folder.</p>
  --Permissions: list # <p>A structure that describes the principals and the resource-level permissions of a folder.</p> <p>To specify no permissions, omit <code>Permissions</code>.</p> — item shape: {Principal: any, Actions: any}
  --Tags: list # Tags for the folder. — item shape: {Key: any, Value: any}
]: any -> record<Status: record, Arn: record, FolderId: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/folders/($FolderId)")
  let body = {Name: $Name, FolderType: $FolderType, ParentFolderArn: $ParentFolderArn, Permissions: $Permissions, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an empty folder.
#
# DELETE /accounts/{AwsAccountId}/folders/{FolderId}
# operationId: DeleteFolder
export def "accounts-folders DeleteFolder" [
  AwsAccountId: string
  FolderId: string
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
]: nothing -> record<Status: record, Arn: record, FolderId: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/folders/($FolderId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes a folder.
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}
# operationId: DescribeFolder
export def "accounts-folders DescribeFolder" [
  AwsAccountId: string
  FolderId: string
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
]: nothing -> record<Status: record, Folder: record<FolderId: record, Arn: record, Name: record, FolderType: record, FolderPath: record, CreatedTime: record, LastUpdatedTime: record>, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/folders/($FolderId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the name of a folder.
#
# PUT /accounts/{AwsAccountId}/folders/{FolderId}
# operationId: UpdateFolder
export def "accounts-folders UpdateFolder" [
  AwsAccountId: string
  FolderId: string
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
  Name: string # The name of the folder.
]: any -> record<Status: record, Arn: record, FolderId: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/folders/($FolderId)")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds an asset, such as a dashboard, analysis, or dataset into a folder.
#
# PUT /accounts/{AwsAccountId}/folders/{FolderId}/members/{MemberType}/{MemberId}
# operationId: CreateFolderMembership
export def "accounts-folders-members CreateFolderMembership" [
  AwsAccountId: string
  FolderId: string
  MemberId: string
  MemberType: string
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
]: nothing -> record<Status: record, FolderMember: record<MemberId: record, MemberType: record>, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/folders/($FolderId)/members/($MemberType)/($MemberId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes an asset, such as a dashboard, analysis, or dataset, from a folder.
#
# DELETE /accounts/{AwsAccountId}/folders/{FolderId}/members/{MemberType}/{MemberId}
# operationId: DeleteFolderMembership
export def "accounts-folders-members DeleteFolderMembership" [
  AwsAccountId: string
  FolderId: string
  MemberId: string
  MemberType: string
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
]: nothing -> record<Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/folders/($FolderId)/members/($MemberType)/($MemberId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Use the <code>CreateGroup</code> operation to create a group in Amazon QuickSight. You can create up to 10,000 groups in a namespace. If you want to create more than 10,000 groups in a namespace, contact AWS Support.</p> <p>The permissions resource is <code>arn:aws:quicksight:&lt;your-region&gt;:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/groups
# operationId: CreateGroup
export def "accounts-namespaces-groups CreateGroup" [
  AwsAccountId: string
  Namespace: string
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
  GroupName: string # A name for the group that you want to create.
  --Description: string # A description for the group that you want to create.
]: any -> record<Group: record<Arn: record, GroupName: record, Description: record, PrincipalId: record>, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/groups")
  let body = {GroupName: $GroupName, Description: $Description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all user groups in Amazon QuickSight. 
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups
# operationId: ListGroups
export def "accounts-namespaces-groups ListGroups" [
  AwsAccountId: string
  Namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<GroupList: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/groups" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds an Amazon QuickSight user to an Amazon QuickSight group. 
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}
# operationId: CreateGroupMembership
export def "accounts-namespaces-groups-members CreateGroupMembership" [
  MemberName: string
  GroupName: string
  AwsAccountId: string
  Namespace: string
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
]: nothing -> record<GroupMember: record<Arn: record, MemberName: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/groups/($GroupName)/members/($MemberName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a user from a group so that the user is no longer a member of the group.
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}
# operationId: DeleteGroupMembership
export def "accounts-namespaces-groups-members DeleteGroupMembership" [
  MemberName: string
  GroupName: string
  AwsAccountId: string
  Namespace: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/groups/($GroupName)/members/($MemberName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use the <code>DescribeGroupMembership</code> operation to determine if a user is a member of the specified group. If the user exists and is a member of the specified group, an associated <code>GroupMember</code> object is returned.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}
# operationId: DescribeGroupMembership
export def "accounts-namespaces-groups-members DescribeGroupMembership" [
  MemberName: string
  GroupName: string
  AwsAccountId: string
  Namespace: string
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
]: nothing -> record<GroupMember: record<Arn: record, MemberName: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/groups/($GroupName)/members/($MemberName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy assignment is attached to the specified groups or users of Amazon QuickSight. Assignment names are unique per Amazon Web Services account. To avoid overwriting rules in other namespaces, use assignment names that are unique.
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/
# operationId: CreateIAMPolicyAssignment
export def "accounts-namespaces-iam-policy-assignments CreateIAMPolicyAssignment" [
  AwsAccountId: string
  Namespace: string
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
  AssignmentName: string # The name of the assignment, also called a rule. It must be unique within an Amazon Web Services account.
  AssignmentStatus: string@AssignmentStatus-completer # <p>The status of the assignment. Possible values are as follows:</p> <ul> <li> <p> <code>ENABLED</code> - Anything specified in this assignment is used when creating the data source.</p> </li> <li> <p> <code>DISABLED</code> - This assignment isn't used when creating the data source.</p> </li> <li> <p> <code>DRAFT</code> - This assignment is an unfinished draft and isn't used when creating the data source.</p> </li> </ul>
  --PolicyArn: string # The ARN for the IAM policy to apply to the Amazon QuickSight users and groups specified in this assignment.
  --Identities: record # The Amazon QuickSight users, groups, or both that you want to assign the policy to.
]: any -> record<AssignmentName: record, AssignmentId: record, AssignmentStatus: record, PolicyArn: record, Identities: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/iam-policy-assignments/")
  let body = {AssignmentName: $AssignmentName, AssignmentStatus: $AssignmentStatus, PolicyArn: $PolicyArn, Identities: $Identities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>(Enterprise edition only) Creates a new namespace for you to use with Amazon QuickSight.</p> <p>A namespace allows you to isolate the Amazon QuickSight users and groups that are registered for that namespace. Users that access the namespace can share assets only with other users or groups in the same namespace. They can't see users and groups in other namespaces. You can create a namespace after your Amazon Web Services account is subscribed to Amazon QuickSight. The namespace must be unique within the Amazon Web Services account. By default, there is a limit of 100 namespaces per Amazon Web Services account. To increase your limit, create a ticket with Amazon Web Services Support. </p>
#
# POST /accounts/{AwsAccountId}
# operationId: CreateNamespace
# --Tags item shape: {Key: any, Value: any}
export def "accounts CreateNamespace" [
  AwsAccountId: string
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
  Namespace: string # The name that you want to use to describe the new namespace.
  IdentityStore: string@IdentityStore-completer # Specifies the type of your user identity directory. Currently, this supports users with an identity type of <code>QUICKSIGHT</code>.
  --Tags: list # The tags that you want to associate with the namespace that you're creating. — item shape: {Key: any, Value: any}
]: any -> record<Arn: record, Name: record, CapacityRegion: record, CreationStatus: record, IdentityStore: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)")
  let body = {Namespace: $Namespace, IdentityStore: $IdentityStore, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a refresh schedule for a dataset. You can create up to 5 different schedules for a single dataset.
#
# POST /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules
# operationId: CreateRefreshSchedule
# --Schedule shape: {ScheduleId?: any, ScheduleFrequency?: any, StartAfterDateTime?: any, RefreshType?: any, Arn?: any}
export def "accounts-data-sets-refresh-schedules CreateRefreshSchedule" [
  DataSetId: string
  AwsAccountId: string
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
  Schedule: record # The refresh schedule of a dataset. — shape: {ScheduleId?: any, ScheduleFrequency?: any, StartAfterDateTime?: any, RefreshType?: any, Arn?: any}
]: any -> record<Status: record, RequestId: record, ScheduleId: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/refresh-schedules")
  let body = {Schedule: $Schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the refresh schedules of a dataset. Each dataset can have up to 5 schedules. 
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules
# operationId: ListRefreshSchedules
export def "accounts-data-sets-refresh-schedules ListRefreshSchedules" [
  AwsAccountId: string
  DataSetId: string
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
]: nothing -> record<RefreshSchedules: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/refresh-schedules")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a refresh schedule for a dataset.
#
# PUT /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules
# operationId: UpdateRefreshSchedule
# --Schedule shape: {ScheduleId?: any, ScheduleFrequency?: any, StartAfterDateTime?: any, RefreshType?: any, Arn?: any}
export def "accounts-data-sets-refresh-schedules UpdateRefreshSchedule" [
  DataSetId: string
  AwsAccountId: string
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
  Schedule: record # The refresh schedule of a dataset. — shape: {ScheduleId?: any, ScheduleFrequency?: any, StartAfterDateTime?: any, RefreshType?: any, Arn?: any}
]: any -> record<Status: record, RequestId: record, ScheduleId: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/refresh-schedules")
  let body = {Schedule: $Schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a template either from a <code>TemplateDefinition</code> or from an existing Amazon QuickSight analysis or template. You can use the resulting template to create additional dashboards, templates, or analyses.</p> <p>A <i>template</i> is an entity in Amazon QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
#
# POST /accounts/{AwsAccountId}/templates/{TemplateId}
# operationId: CreateTemplate
# --Permissions item shape: {Principal: any, Actions: any}
# --SourceEntity shape: {SourceAnalysis?: any, SourceTemplate?: any}
# --Tags item shape: {Key: any, Value: any}
# --Definition shape: {DataSetConfigurations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-templates CreateTemplate" [
  AwsAccountId: string
  TemplateId: string
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
  --Name: string # A display name for the template.
  --Permissions: list # A list of resource permissions to be set on the template.  — item shape: {Principal: any, Actions: any}
  --SourceEntity: record # The source entity of the template. — shape: {SourceAnalysis?: any, SourceTemplate?: any}
  --Tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the resource. — item shape: {Key: any, Value: any}
  --VersionDescription: string # A description of the current template version being created. This API operation creates the first version of the template. Every time <code>UpdateTemplate</code> is called, a new version is created. Each version of the template maintains a description of the version in the <code>VersionDescription</code> field.
  --Definition: record # The detailed definition of a template. — shape: {DataSetConfigurations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<Arn: record, VersionArn: record, TemplateId: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)")
  let body = {Name: $Name, Permissions: $Permissions, SourceEntity: $SourceEntity, Tags: $Tags, VersionDescription: $VersionDescription, Definition: $Definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a template.
#
# DELETE /accounts/{AwsAccountId}/templates/{TemplateId}
# operationId: DeleteTemplate
export def "accounts-templates DeleteTemplate" [
  AwsAccountId: string
  TemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<RequestId: record, Arn: record, TemplateId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes a template's metadata.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}
# operationId: DescribeTemplate
export def "accounts-templates DescribeTemplate" [
  AwsAccountId: string
  TemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # (Optional) The number for the version to describe. If a <code>VersionNumber</code> parameter value isn't provided, the latest version of the template is described.
  --alias-name: string # The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Template: record<Arn: record, Name: record, Version: record<CreatedTime: record, Errors: record, VersionNumber: record, Status: record, DataSetConfigurations: record, Description: record, SourceEntityArn: record, ThemeArn: record, Sheets: record>, TemplateId: record, LastUpdatedTime: record, CreatedTime: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar") (serialize-qp "alias-name" $alias_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a template from an existing Amazon QuickSight analysis or another template.
#
# PUT /accounts/{AwsAccountId}/templates/{TemplateId}
# operationId: UpdateTemplate
# --SourceEntity shape: {SourceAnalysis?: any, SourceTemplate?: any}
# --Definition shape: {DataSetConfigurations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-templates UpdateTemplate" [
  AwsAccountId: string
  TemplateId: string
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
  --SourceEntity: record # The source entity of the template. — shape: {SourceAnalysis?: any, SourceTemplate?: any}
  --VersionDescription: string # A description of the current template version that is being updated. Every time you call <code>UpdateTemplate</code>, you create a new version of the template. Each version of the template maintains a description of the version in the <code>VersionDescription</code> field.
  --Name: string # The name for the template.
  --Definition: record # The detailed definition of a template. — shape: {DataSetConfigurations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<TemplateId: record, Arn: record, VersionArn: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)")
  let body = {SourceEntity: $SourceEntity, VersionDescription: $VersionDescription, Name: $Name, Definition: $Definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a template alias for a template.
#
# POST /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# operationId: CreateTemplateAlias
export def "accounts-templates-aliases CreateTemplateAlias" [
  AwsAccountId: string
  TemplateId: string
  AliasName: string
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
  TemplateVersionNumber: int # The version number of the template.
]: any -> record<TemplateAlias: record<AliasName: record, Arn: record, TemplateVersionNumber: record>, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)/aliases/($AliasName)")
  let body = {TemplateVersionNumber: $TemplateVersionNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
#
# DELETE /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# operationId: DeleteTemplateAlias
export def "accounts-templates-aliases DeleteTemplateAlias" [
  AwsAccountId: string
  TemplateId: string
  AliasName: string
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
]: nothing -> record<Status: record, TemplateId: record, AliasName: record, Arn: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)/aliases/($AliasName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes the template alias for a template.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# operationId: DescribeTemplateAlias
export def "accounts-templates-aliases DescribeTemplateAlias" [
  AwsAccountId: string
  TemplateId: string
  AliasName: string
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
]: nothing -> record<TemplateAlias: record<AliasName: record, Arn: record, TemplateVersionNumber: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)/aliases/($AliasName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the template alias of a template.
#
# PUT /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# operationId: UpdateTemplateAlias
export def "accounts-templates-aliases UpdateTemplateAlias" [
  AwsAccountId: string
  TemplateId: string
  AliasName: string
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
  TemplateVersionNumber: int # The version number of the template.
]: any -> record<TemplateAlias: record<AliasName: record, Arn: record, TemplateVersionNumber: record>, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)/aliases/($AliasName)")
  let body = {TemplateVersionNumber: $TemplateVersionNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a theme.</p> <p>A <i>theme</i> is set of configuration options for color and layout. Themes apply to analyses and dashboards. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/themes-in-quicksight.html">Using Themes in Amazon QuickSight</a> in the <i>Amazon QuickSight User Guide</i>.</p>
#
# POST /accounts/{AwsAccountId}/themes/{ThemeId}
# operationId: CreateTheme
# --Configuration shape: {DataColorPalette?: any, UIColorPalette?: any, Sheet?: any, Typography?: record}
# --Permissions item shape: {Principal: any, Actions: any}
# --Tags item shape: {Key: any, Value: any}
export def "accounts-themes CreateTheme" [
  AwsAccountId: string
  ThemeId: string
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
  Name: string # A display name for the theme.
  BaseThemeId: string # The ID of the theme that a custom theme will inherit from. All themes inherit from one of the starting themes defined by Amazon QuickSight. For a list of the starting themes, use <code>ListThemes</code> or choose <b>Themes</b> from within an analysis. 
  --VersionDescription: string # A description of the first version of the theme that you're creating. Every time <code>UpdateTheme</code> is called, a new version is created. Each version of the theme has a description of the version in the <code>VersionDescription</code> field.
  Configuration: record # The theme configuration. This configuration contains all of the display properties for a theme. — shape: {DataColorPalette?: any, UIColorPalette?: any, Sheet?: any, Typography?: record}
  --Permissions: list # A valid grouping of resource permissions to apply to the new theme.  — item shape: {Principal: any, Actions: any}
  --Tags: list # A map of the key-value pairs for the resource tag or tags that you want to add to the resource. — item shape: {Key: any, Value: any}
]: any -> record<Arn: record, VersionArn: record, ThemeId: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)")
  let body = {Name: $Name, BaseThemeId: $BaseThemeId, VersionDescription: $VersionDescription, Configuration: $Configuration, Permissions: $Permissions, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a theme.
#
# DELETE /accounts/{AwsAccountId}/themes/{ThemeId}
# operationId: DeleteTheme
export def "accounts-themes DeleteTheme" [
  AwsAccountId: string
  ThemeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # <p>The version of the theme that you want to delete. </p> <p> <b>Note:</b> If you don't provide a version number, you're using this call to <code>DeleteTheme</code> to delete all versions of the theme.</p>
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Arn: record, RequestId: record, Status: record, ThemeId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}
# operationId: DescribeTheme
export def "accounts-themes DescribeTheme" [
  AwsAccountId: string
  ThemeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number for the version to describe. If a <code>VersionNumber</code> parameter value isn't provided, the latest version of the theme is described.
  --alias-name: string # The alias of the theme that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the theme by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to themes.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Theme: record<Arn: record, Name: record, ThemeId: record, Version: record<VersionNumber: record, Arn: record, Description: record, BaseThemeId: record, CreatedTime: record, Configuration: record, Errors: record, Status: record>, CreatedTime: record, LastUpdatedTime: record, Type: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar") (serialize-qp "alias-name" $alias_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a theme.
#
# PUT /accounts/{AwsAccountId}/themes/{ThemeId}
# operationId: UpdateTheme
# --Configuration shape: {DataColorPalette?: any, UIColorPalette?: any, Sheet?: any, Typography?: record}
export def "accounts-themes UpdateTheme" [
  AwsAccountId: string
  ThemeId: string
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
  --Name: string # The name for the theme.
  BaseThemeId: string # The theme ID, defined by Amazon QuickSight, that a custom theme inherits from. All themes initially inherit from a default Amazon QuickSight theme.
  --VersionDescription: string # A description of the theme version that you're updating Every time that you call <code>UpdateTheme</code>, you create a new version of the theme. Each version of the theme maintains a description of the version in <code>VersionDescription</code>.
  --Configuration: record # The theme configuration. This configuration contains all of the display properties for a theme. — shape: {DataColorPalette?: any, UIColorPalette?: any, Sheet?: any, Typography?: record}
]: any -> record<ThemeId: record, Arn: record, VersionArn: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)")
  let body = {Name: $Name, BaseThemeId: $BaseThemeId, VersionDescription: $VersionDescription, Configuration: $Configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a theme alias for a theme.
#
# POST /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# operationId: CreateThemeAlias
export def "accounts-themes-aliases CreateThemeAlias" [
  AwsAccountId: string
  ThemeId: string
  AliasName: string
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
  ThemeVersionNumber: int # The version number of the theme.
]: any -> record<ThemeAlias: record<Arn: record, AliasName: record, ThemeVersionNumber: record>, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)/aliases/($AliasName)")
  let body = {ThemeVersionNumber: $ThemeVersionNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the version of the theme that the specified theme alias points to. If you provide a specific alias, you delete the version of the theme that the alias points to.
#
# DELETE /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# operationId: DeleteThemeAlias
export def "accounts-themes-aliases DeleteThemeAlias" [
  AwsAccountId: string
  ThemeId: string
  AliasName: string
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
]: nothing -> record<AliasName: record, Arn: record, RequestId: record, Status: record, ThemeId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)/aliases/($AliasName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes the alias for a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# operationId: DescribeThemeAlias
export def "accounts-themes-aliases DescribeThemeAlias" [
  AwsAccountId: string
  ThemeId: string
  AliasName: string
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
]: nothing -> record<ThemeAlias: record<Arn: record, AliasName: record, ThemeVersionNumber: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)/aliases/($AliasName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an alias of a theme.
#
# PUT /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# operationId: UpdateThemeAlias
export def "accounts-themes-aliases UpdateThemeAlias" [
  AwsAccountId: string
  ThemeId: string
  AliasName: string
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
  ThemeVersionNumber: int # The version number of the theme that the alias should reference.
]: any -> record<ThemeAlias: record<Arn: record, AliasName: record, ThemeVersionNumber: record>, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)/aliases/($AliasName)")
  let body = {ThemeVersionNumber: $ThemeVersionNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a dataset.
#
# DELETE /accounts/{AwsAccountId}/data-sets/{DataSetId}
# operationId: DeleteDataSet
export def "accounts-data-sets DeleteDataSet" [
  AwsAccountId: string
  DataSetId: string
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
]: nothing -> record<Arn: record, DataSetId: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes a dataset. This operation doesn't support datasets that include uploaded files as a source.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}
# operationId: DescribeDataSet
export def "accounts-data-sets DescribeDataSet" [
  AwsAccountId: string
  DataSetId: string
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
]: nothing -> record<DataSet: record<Arn: record, DataSetId: record, Name: record, CreatedTime: record, LastUpdatedTime: record, PhysicalTableMap: record, LogicalTableMap: record, OutputColumns: record, ImportMode: record, ConsumedSpiceCapacityInBytes: record, ColumnGroups: record, FieldFolders: record, RowLevelPermissionDataSet: record<Namespace: record, Arn: record, PermissionPolicy: record, FormatVersion: record, Status: record>, RowLevelPermissionTagConfiguration: record<Status: record, TagRules: record, TagRuleConfigurations: record>, ColumnLevelPermissionRules: record, DataSetUsageConfiguration: record<DisableUseAsDirectQuerySource: record, DisableUseAsImportedSource: record>>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a dataset. This operation doesn't support datasets that include uploaded files as a source. Partial updates are not supported by this operation.
#
# PUT /accounts/{AwsAccountId}/data-sets/{DataSetId}
# operationId: UpdateDataSet
# --ColumnGroups item shape: {GeoSpatialColumnGroup?: any}
# --RowLevelPermissionDataSet shape: {Namespace?: any, Arn?: any, PermissionPolicy?: any, FormatVersion?: any, Status?: any}
# --RowLevelPermissionTagConfiguration shape: {Status?: any, TagRules?: any, TagRuleConfigurations?: any}
# --ColumnLevelPermissionRules item shape: {Principals?: any, ColumnNames?: any}
# --DataSetUsageConfiguration shape: {DisableUseAsDirectQuerySource?: any, DisableUseAsImportedSource?: any}
export def "accounts-data-sets UpdateDataSet" [
  AwsAccountId: string
  DataSetId: string
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
  Name: string # The display name for the dataset.
  PhysicalTableMap: record # Declares the physical tables that are available in the underlying data sources.
  --LogicalTableMap: record # Configures the combination and transformation of the data from the physical tables.
  ImportMode: string@ImportMode-completer # Indicates whether you want to import the data into SPICE.
  --ColumnGroups: list # Groupings of columns that work together in certain Amazon QuickSight features. Currently, only geospatial hierarchy is supported. — item shape: {GeoSpatialColumnGroup?: any}
  --FieldFolders: record # The folder that contains fields and nested subfolders for your dataset.
  --RowLevelPermissionDataSet: record # <p>Information about a dataset that contains permissions for row-level security (RLS). The permissions dataset maps fields to users or groups. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/restrict-access-to-a-data-set-using-row-level-security.html">Using Row-Level Security (RLS) to Restrict Access to a Dataset</a> in the <i>Amazon QuickSight User Guide</i>.</p> <p>The option to deny permissions by setting <code>PermissionPolicy</code> to <code>DENY_ACCESS</code> is not supported for new RLS datasets.</p> — shape: {Namespace?: any, Arn?: any, PermissionPolicy?: any, FormatVersion?: any, Status?: any}
  --RowLevelPermissionTagConfiguration: record # The configuration of tags on a dataset to set row-level security.  — shape: {Status?: any, TagRules?: any, TagRuleConfigurations?: any}
  --ColumnLevelPermissionRules: list # A set of one or more definitions of a <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_ColumnLevelPermissionRule.html">ColumnLevelPermissionRule</a> </code>. — item shape: {Principals?: any, ColumnNames?: any}
  --DataSetUsageConfiguration: record # The usage configuration to apply to child datasets that reference this dataset as a source. — shape: {DisableUseAsDirectQuerySource?: any, DisableUseAsImportedSource?: any}
]: any -> record<Arn: record, DataSetId: record, IngestionArn: record, IngestionId: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)")
  let body = {Name: $Name, PhysicalTableMap: $PhysicalTableMap, LogicalTableMap: $LogicalTableMap, ImportMode: $ImportMode, ColumnGroups: $ColumnGroups, FieldFolders: $FieldFolders, RowLevelPermissionDataSet: $RowLevelPermissionDataSet, RowLevelPermissionTagConfiguration: $RowLevelPermissionTagConfiguration, ColumnLevelPermissionRules: $ColumnLevelPermissionRules, DataSetUsageConfiguration: $DataSetUsageConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the dataset refresh properties of the dataset.
#
# DELETE /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties
# operationId: DeleteDataSetRefreshProperties
export def "accounts-data-sets-refresh-properties DeleteDataSetRefreshProperties" [
  AwsAccountId: string
  DataSetId: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/refresh-properties")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes the refresh properties of a dataset.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties
# operationId: DescribeDataSetRefreshProperties
export def "accounts-data-sets-refresh-properties DescribeDataSetRefreshProperties" [
  AwsAccountId: string
  DataSetId: string
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
]: nothing -> record<RequestId: record, Status: record, DataSetRefreshProperties: record<RefreshConfiguration: record<IncrementalRefresh: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/refresh-properties")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates the dataset refresh properties for the dataset.
#
# PUT /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties
# operationId: PutDataSetRefreshProperties
# --DataSetRefreshProperties shape: {RefreshConfiguration?: any}
export def "accounts-data-sets-refresh-properties PutDataSetRefreshProperties" [
  AwsAccountId: string
  DataSetId: string
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
  DataSetRefreshProperties: record # The refresh properties of a dataset. — shape: {RefreshConfiguration?: any}
]: any -> record<RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/refresh-properties")
  let body = {DataSetRefreshProperties: $DataSetRefreshProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the data source permanently. This operation breaks all the datasets that reference the deleted data source.
#
# DELETE /accounts/{AwsAccountId}/data-sources/{DataSourceId}
# operationId: DeleteDataSource
export def "accounts-data-sources DeleteDataSource" [
  AwsAccountId: string
  DataSourceId: string
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
]: nothing -> record<Arn: record, DataSourceId: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sources/($DataSourceId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes a data source.
#
# GET /accounts/{AwsAccountId}/data-sources/{DataSourceId}
# operationId: DescribeDataSource
export def "accounts-data-sources DescribeDataSource" [
  AwsAccountId: string
  DataSourceId: string
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
]: nothing -> record<DataSource: record<Arn: record, DataSourceId: record, Name: record, Type: record, Status: record, CreatedTime: record, LastUpdatedTime: record, DataSourceParameters: record<AmazonElasticsearchParameters: record, AthenaParameters: record, AuroraParameters: record, AuroraPostgreSqlParameters: record, AwsIotAnalyticsParameters: record, JiraParameters: record, MariaDbParameters: record, MySqlParameters: record, OracleParameters: record, PostgreSqlParameters: record, PrestoParameters: record, RdsParameters: record, RedshiftParameters: record, S3Parameters: record, ServiceNowParameters: record, SnowflakeParameters: record, SparkParameters: record, SqlServerParameters: record, TeradataParameters: record, TwitterParameters: record, AmazonOpenSearchParameters: record, ExasolParameters: record, DatabricksParameters: record>, AlternateDataSourceParameters: record, VpcConnectionProperties: record<VpcConnectionArn: record>, SslProperties: record<DisableSsl: record>, ErrorInfo: record<Type: record, Message: record>, SecretArn: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sources/($DataSourceId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a data source.
#
# PUT /accounts/{AwsAccountId}/data-sources/{DataSourceId}
# operationId: UpdateDataSource
# --DataSourceParameters shape: {AmazonElasticsearchParameters?: any, AthenaParameters?: any, AuroraParameters?: any, AuroraPostgreSqlParameters?: any, AwsIotAnalyticsParameters?: any, JiraParameters?: any, MariaDbParameters?: any, MySqlParameters?: any, OracleParameters?: any, PostgreSqlParameters?: any, PrestoParameters?: any, RdsParameters?: any, RedshiftParameters?: any, S3Parameters?: any, ServiceNowParameters?: any, SnowflakeParameters?: any, SparkParameters?: any, SqlServerParameters?: any, TeradataParameters?: any, TwitterParameters?: any, AmazonOpenSearchParameters?: any, ExasolParameters?: any, DatabricksParameters?: any}
# --Credentials shape: {CredentialPair?: any, CopySourceArn?: any, SecretArn?: any}
# --VpcConnectionProperties shape: {VpcConnectionArn?: any}
# --SslProperties shape: {DisableSsl?: any}
export def "accounts-data-sources UpdateDataSource" [
  AwsAccountId: string
  DataSourceId: string
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
  Name: string # A display name for the data source.
  --DataSourceParameters: record # The parameters that Amazon QuickSight uses to connect to your underlying data source. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {AmazonElasticsearchParameters?: any, AthenaParameters?: any, AuroraParameters?: any, AuroraPostgreSqlParameters?: any, AwsIotAnalyticsParameters?: any, JiraParameters?: any, MariaDbParameters?: any, MySqlParameters?: any, OracleParameters?: any, PostgreSqlParameters?: any, PrestoParameters?: any, RdsParameters?: any, RedshiftParameters?: any, S3Parameters?: any, ServiceNowParameters?: any, SnowflakeParameters?: any, SparkParameters?: any, SqlServerParameters?: any, TeradataParameters?: any, TwitterParameters?: any, AmazonOpenSearchParameters?: any, ExasolParameters?: any, DatabricksParameters?: any}
  --Credentials: record # Data source credentials. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {CredentialPair?: any, CopySourceArn?: any, SecretArn?: any}
  --VpcConnectionProperties: record # VPC connection properties. — shape: {VpcConnectionArn?: any}
  --SslProperties: record # Secure Socket Layer (SSL) properties that apply when Amazon QuickSight connects to your underlying data source. — shape: {DisableSsl?: any}
]: any -> record<Arn: record, DataSourceId: record, UpdateStatus: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sources/($DataSourceId)")
  let body = {Name: $Name, DataSourceParameters: $DataSourceParameters, Credentials: $Credentials, VpcConnectionProperties: $VpcConnectionProperties, SslProperties: $SslProperties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a user group from Amazon QuickSight. 
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}
# operationId: DeleteGroup
export def "accounts-namespaces-groups DeleteGroup" [
  GroupName: string
  AwsAccountId: string
  Namespace: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/groups/($GroupName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}
# operationId: DescribeGroup
export def "accounts-namespaces-groups DescribeGroup" [
  GroupName: string
  AwsAccountId: string
  Namespace: string
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
]: nothing -> record<Group: record<Arn: record, GroupName: record, Description: record, PrincipalId: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/groups/($GroupName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Changes a group description. 
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}
# operationId: UpdateGroup
export def "accounts-namespaces-groups UpdateGroup" [
  GroupName: string
  AwsAccountId: string
  Namespace: string
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
  --Description: string # The description for the group that you want to update.
]: any -> record<Group: record<Arn: record, GroupName: record, Description: record, PrincipalId: record>, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/groups/($GroupName)")
  let body = {Description: $Description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an existing IAM policy assignment.
#
# DELETE /accounts/{AwsAccountId}/namespace/{Namespace}/iam-policy-assignments/{AssignmentName}
# operationId: DeleteIAMPolicyAssignment
export def "accounts-namespace-iam-policy-assignments DeleteIAMPolicyAssignment" [
  AwsAccountId: string
  AssignmentName: string
  Namespace: string
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
]: nothing -> record<AssignmentName: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespace/($Namespace)/iam-policy-assignments/($AssignmentName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a namespace and the users and groups that are associated with the namespace. This is an asynchronous process. Assets including dashboards, analyses, datasets and data sources are not deleted. To delete these assets, you use the API operations for the relevant asset. 
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}
# operationId: DeleteNamespace
export def "accounts-namespaces DeleteNamespace" [
  AwsAccountId: string
  Namespace: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes the current namespace.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}
# operationId: DescribeNamespace
export def "accounts-namespaces DescribeNamespace" [
  AwsAccountId: string
  Namespace: string
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
]: nothing -> record<Namespace: record<Name: record, Arn: record, CapacityRegion: record, CreationStatus: record, IdentityStore: record, NamespaceError: record<Type: record, Message: record>>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a refresh schedule from a dataset.
#
# DELETE /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules/{ScheduleId}
# operationId: DeleteRefreshSchedule
export def "accounts-data-sets-refresh-schedules DeleteRefreshSchedule" [
  DataSetId: string
  AwsAccountId: string
  ScheduleId: string
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
]: nothing -> record<Status: record, RequestId: record, ScheduleId: record, Arn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/refresh-schedules/($ScheduleId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides a summary of a refresh schedule.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules/{ScheduleId}
# operationId: DescribeRefreshSchedule
export def "accounts-data-sets-refresh-schedules DescribeRefreshSchedule" [
  AwsAccountId: string
  DataSetId: string
  ScheduleId: string
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
]: nothing -> record<RefreshSchedule: record<ScheduleId: record, ScheduleFrequency: record<Interval: record, RefreshOnDay: record, Timezone: record, TimeOfTheDay: record>, StartAfterDateTime: record, RefreshType: record, Arn: record>, Status: record, RequestId: record, Arn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/refresh-schedules/($ScheduleId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the Amazon QuickSight user that is associated with the identity of the IAM user or role that's making the call. The IAM user isn't deleted as a result of this call. 
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}
# operationId: DeleteUser
export def "accounts-namespaces-users DeleteUser" [
  UserName: string
  AwsAccountId: string
  Namespace: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/users/($UserName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a user, given the user name. 
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}
# operationId: DescribeUser
export def "accounts-namespaces-users DescribeUser" [
  UserName: string
  AwsAccountId: string
  Namespace: string
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
]: nothing -> record<User: record<Arn: record, UserName: record, Email: record, Role: record, IdentityType: record, Active: record, PrincipalId: record, CustomPermissionsName: record, ExternalLoginFederationProviderType: record, ExternalLoginFederationProviderUrl: record, ExternalLoginId: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/users/($UserName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an Amazon QuickSight user.
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}
# operationId: UpdateUser
export def "accounts-namespaces-users UpdateUser" [
  UserName: string
  AwsAccountId: string
  Namespace: string
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
  Email: string # The email address of the user that you want to update.
  Role: string@Role-completer # <p>The Amazon QuickSight role of the user. The role can be one of the following default security cohorts:</p> <ul> <li> <p> <code>READER</code>: A user who has read-only access to dashboards.</p> </li> <li> <p> <code>AUTHOR</code>: A user who can create data sources, datasets, analyses, and dashboards.</p> </li> <li> <p> <code>ADMIN</code>: A user who is an author, who can also manage Amazon QuickSight settings.</p> </li> </ul> <p>The name of the Amazon QuickSight role is invisible to the user except for the console screens dealing with permissions.</p>
  --CustomPermissionsName: string # <p>(Enterprise edition only) The name of the custom permissions profile that you want to assign to this user. Customized permissions allows you to control a user's access by restricting access the following operations:</p> <ul> <li> <p>Create and update data sources</p> </li> <li> <p>Create and update datasets</p> </li> <li> <p>Create and update email reports</p> </li> <li> <p>Subscribe to email reports</p> </li> </ul> <p>A set of custom permissions includes any combination of these restrictions. Currently, you need to create the profile names for custom permission sets by using the Amazon QuickSight console. Then, you use the <code>RegisterUser</code> API operation to assign the named set of permissions to a Amazon QuickSight user. </p> <p>Amazon QuickSight custom permissions are applied through IAM policies. Therefore, they override the permissions typically granted by assigning Amazon QuickSight users to one of the default security cohorts in Amazon QuickSight (admin, author, reader).</p> <p>This feature is available only to Amazon QuickSight Enterprise edition subscriptions.</p>
  --UnapplyCustomPermissions: oneof<nothing, bool> # A flag that you use to indicate that you want to remove all custom permissions from this user. Using this parameter resets the user to the state it was in before a custom permissions profile was applied. This parameter defaults to NULL and it doesn't accept any other value.
  --ExternalLoginFederationProviderType: string # <p>The type of supported external login provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. The type of supported external login provider can be one of the following.</p> <ul> <li> <p> <code>COGNITO</code>: Amazon Cognito. The provider URL is cognito-identity.amazonaws.com. When choosing the <code>COGNITO</code> provider type, don’t use the "CustomFederationProviderUrl" parameter which is only needed when the external provider is custom.</p> </li> <li> <p> <code>CUSTOM_OIDC</code>: Custom OpenID Connect (OIDC) provider. When choosing <code>CUSTOM_OIDC</code> type, use the <code>CustomFederationProviderUrl</code> parameter to provide the custom OIDC provider URL.</p> </li> <li> <p> <code>NONE</code>: This clears all the previously saved external login information for a user. Use the <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeUser.html">DescribeUser</a> </code> API operation to check the external login information.</p> </li> </ul>
  --CustomFederationProviderUrl: string # The URL of the custom OpenID Connect (OIDC) provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. This parameter should only be used when <code>ExternalLoginFederationProviderType</code> parameter is set to <code>CUSTOM_OIDC</code>.
  --ExternalLoginId: string # The identity ID for a user in the external login provider.
]: any -> record<User: record<Arn: record, UserName: record, Email: record, Role: record, IdentityType: record, Active: record, PrincipalId: record, CustomPermissionsName: record, ExternalLoginFederationProviderType: record, ExternalLoginFederationProviderUrl: record, ExternalLoginId: record>, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/users/($UserName)")
  let body = {Email: $Email, Role: $Role, CustomPermissionsName: $CustomPermissionsName, UnapplyCustomPermissions: $UnapplyCustomPermissions, ExternalLoginFederationProviderType: $ExternalLoginFederationProviderType, CustomFederationProviderUrl: $CustomFederationProviderUrl, ExternalLoginId: $ExternalLoginId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a user identified by its principal ID. 
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}
# operationId: DeleteUserByPrincipalId
export def "accounts-namespaces-user-principals DeleteUserByPrincipalId" [
  PrincipalId: string
  AwsAccountId: string
  Namespace: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/user-principals/($PrincipalId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes the settings that were used when your Amazon QuickSight subscription was first created in this Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/settings
# operationId: DescribeAccountSettings
export def "accounts-settings DescribeAccountSettings" [
  AwsAccountId: string
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
]: nothing -> record<AccountSettings: record<AccountName: record, Edition: record, DefaultNamespace: record, NotificationEmail: record, PublicSharingEnabled: record, TerminationProtectionEnabled: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/settings")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Amazon QuickSight settings in your Amazon Web Services account.
#
# PUT /accounts/{AwsAccountId}/settings
# operationId: UpdateAccountSettings
export def "accounts-settings UpdateAccountSettings" [
  AwsAccountId: string
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
  DefaultNamespace: string # The default namespace for this Amazon Web Services account. Currently, the default is <code>default</code>. IAM users that register for the first time with Amazon QuickSight provide an email address that becomes associated with the default namespace. 
  --NotificationEmail: string # The email address that you want Amazon QuickSight to send notifications to regarding your Amazon Web Services account or Amazon QuickSight subscription.
  --TerminationProtectionEnabled: oneof<nothing, bool> # A boolean value that determines whether or not an Amazon QuickSight account can be deleted. A <code>True</code> value doesn't allow the account to be deleted and results in an error message if a user tries to make a <code>DeleteAccountSubscription</code> request. A <code>False</code> value will allow the account to be deleted.
]: any -> record<RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/settings")
  let body = {DefaultNamespace: $DefaultNamespace, NotificationEmail: $NotificationEmail, TerminationProtectionEnabled: $TerminationProtectionEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Provides a detailed description of the definition of an analysis.</p> <note> <p>If you do not need to know details about the content of an Analysis, for instance if you are trying to check the status of a recently created or updated Analysis, use the <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeAnalysis.html"> <code>DescribeAnalysis</code> </a> instead. </p> </note>
#
# GET /accounts/{AwsAccountId}/analyses/{AnalysisId}/definition
# operationId: DescribeAnalysisDefinition
export def "accounts-analyses-definition DescribeAnalysisDefinition" [
  AwsAccountId: string
  AnalysisId: string
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
]: nothing -> record<AnalysisId: record, Name: record, Errors: record, ResourceStatus: record, ThemeArn: record, Definition: record<DataSetIdentifierDeclarations: record, Sheets: record, CalculatedFields: record, ParameterDeclarations: record, FilterGroups: record, ColumnConfigurations: record, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/analyses/($AnalysisId)/definition")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides the read and write permissions for an analysis.
#
# GET /accounts/{AwsAccountId}/analyses/{AnalysisId}/permissions
# operationId: DescribeAnalysisPermissions
export def "accounts-analyses-permissions DescribeAnalysisPermissions" [
  AwsAccountId: string
  AnalysisId: string
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
]: nothing -> record<AnalysisId: record, AnalysisArn: record, Permissions: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/analyses/($AnalysisId)/permissions")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the read and write permissions for an analysis.
#
# PUT /accounts/{AwsAccountId}/analyses/{AnalysisId}/permissions
# operationId: UpdateAnalysisPermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-analyses-permissions UpdateAnalysisPermissions" [
  AwsAccountId: string
  AnalysisId: string
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
  --GrantPermissions: list # A structure that describes the permissions to add and the principal to add them to. — item shape: {Principal: any, Actions: any}
  --RevokePermissions: list # A structure that describes the permissions to remove and the principal to remove them from. — item shape: {Principal: any, Actions: any}
]: any -> record<AnalysisArn: record, AnalysisId: record, Permissions: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/analyses/($AnalysisId)/permissions")
  let body = {GrantPermissions: $GrantPermissions, RevokePermissions: $RevokePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Provides a detailed description of the definition of a dashboard.</p> <note> <p>If you do not need to know details about the content of a dashboard, for instance if you are trying to check the status of a recently created or updated dashboard, use the <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeDashboard.html"> <code>DescribeDashboard</code> </a> instead. </p> </note>
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/definition
# operationId: DescribeDashboardDefinition
export def "accounts-dashboards-definition DescribeDashboardDefinition" [
  AwsAccountId: string
  DashboardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described. 
  --alias-name: string # The alias name.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DashboardId: record, Errors: record, Name: record, ResourceStatus: record, ThemeArn: record, Definition: record<DataSetIdentifierDeclarations: record, Sheets: record, CalculatedFields: record, ParameterDeclarations: record, FilterGroups: record, ColumnConfigurations: record, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: record, RequestId: record, DashboardPublishOptions: record<AdHocFilteringOption: record<AvailabilityStatus: record>, ExportToCSVOption: record<AvailabilityStatus: record>, SheetControlsOption: record<VisibilityState: record>, VisualPublishOptions: record<ExportHiddenFieldsOption: record>, SheetLayoutElementMaximizationOption: record<AvailabilityStatus: record>, VisualMenuOption: record<AvailabilityStatus: record>, VisualAxisSortOption: record<AvailabilityStatus: record>, ExportWithHiddenFieldsOption: record<AvailabilityStatus: record>, DataPointDrillUpDownOption: record<AvailabilityStatus: record>, DataPointMenuLabelOption: record<AvailabilityStatus: record>, DataPointTooltipOption: record<AvailabilityStatus: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar") (serialize-qp "alias-name" $alias_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/dashboards/($DashboardId)/definition" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes read and write permissions for a dashboard.
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions
# operationId: DescribeDashboardPermissions
export def "accounts-dashboards-permissions DescribeDashboardPermissions" [
  AwsAccountId: string
  DashboardId: string
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
]: nothing -> record<DashboardId: record, DashboardArn: record, Permissions: record, Status: record, RequestId: record, LinkSharingConfiguration: record<Permissions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/dashboards/($DashboardId)/permissions")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates read and write permissions on a dashboard.
#
# PUT /accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions
# operationId: UpdateDashboardPermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
# --GrantLinkPermissions item shape: {Principal: any, Actions: any}
# --RevokeLinkPermissions item shape: {Principal: any, Actions: any}
export def "accounts-dashboards-permissions UpdateDashboardPermissions" [
  AwsAccountId: string
  DashboardId: string
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
  --GrantPermissions: list # The permissions that you want to grant on this resource. — item shape: {Principal: any, Actions: any}
  --RevokePermissions: list # The permissions that you want to revoke from this resource. — item shape: {Principal: any, Actions: any}
  --GrantLinkPermissions: list # Grants link permissions to all users in a defined namespace. — item shape: {Principal: any, Actions: any}
  --RevokeLinkPermissions: list # Revokes link permissions from all users in a defined namespace. — item shape: {Principal: any, Actions: any}
]: any -> record<DashboardArn: record, DashboardId: record, Permissions: record, RequestId: record, Status: record, LinkSharingConfiguration: record<Permissions: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/dashboards/($DashboardId)/permissions")
  let body = {GrantPermissions: $GrantPermissions, RevokePermissions: $RevokePermissions, GrantLinkPermissions: $GrantLinkPermissions, RevokeLinkPermissions: $RevokeLinkPermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions
# operationId: DescribeDataSetPermissions
export def "accounts-data-sets-permissions DescribeDataSetPermissions" [
  AwsAccountId: string
  DataSetId: string
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
]: nothing -> record<DataSetArn: record, DataSetId: record, Permissions: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/permissions")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
#
# POST /accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions
# operationId: UpdateDataSetPermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-data-sets-permissions UpdateDataSetPermissions" [
  AwsAccountId: string
  DataSetId: string
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
  --GrantPermissions: list # The resource permissions that you want to grant to the dataset. — item shape: {Principal: any, Actions: any}
  --RevokePermissions: list # The resource permissions that you want to revoke from the dataset. — item shape: {Principal: any, Actions: any}
]: any -> record<DataSetArn: record, DataSetId: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/permissions")
  let body = {GrantPermissions: $GrantPermissions, RevokePermissions: $RevokePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the resource permissions for a data source.
#
# GET /accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions
# operationId: DescribeDataSourcePermissions
export def "accounts-data-sources-permissions DescribeDataSourcePermissions" [
  AwsAccountId: string
  DataSourceId: string
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
]: nothing -> record<DataSourceArn: record, DataSourceId: record, Permissions: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sources/($DataSourceId)/permissions")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the permissions to a data source.
#
# POST /accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions
# operationId: UpdateDataSourcePermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-data-sources-permissions UpdateDataSourcePermissions" [
  AwsAccountId: string
  DataSourceId: string
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
  --GrantPermissions: list # A list of resource permissions that you want to grant on the data source. — item shape: {Principal: any, Actions: any}
  --RevokePermissions: list # A list of resource permissions that you want to revoke on the data source. — item shape: {Principal: any, Actions: any}
]: any -> record<DataSourceArn: record, DataSourceId: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sources/($DataSourceId)/permissions")
  let body = {GrantPermissions: $GrantPermissions, RevokePermissions: $RevokePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes permissions for a folder.
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}/permissions
# operationId: DescribeFolderPermissions
export def "accounts-folders-permissions DescribeFolderPermissions" [
  AwsAccountId: string
  FolderId: string
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
]: nothing -> record<Status: record, FolderId: record, Arn: record, Permissions: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/folders/($FolderId)/permissions")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates permissions of a folder.
#
# PUT /accounts/{AwsAccountId}/folders/{FolderId}/permissions
# operationId: UpdateFolderPermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-folders-permissions UpdateFolderPermissions" [
  AwsAccountId: string
  FolderId: string
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
  --GrantPermissions: list # The permissions that you want to grant on a resource. — item shape: {Principal: any, Actions: any}
  --RevokePermissions: list # The permissions that you want to revoke from a resource. — item shape: {Principal: any, Actions: any}
]: any -> record<Status: record, Arn: record, FolderId: record, Permissions: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/folders/($FolderId)/permissions")
  let body = {GrantPermissions: $GrantPermissions, RevokePermissions: $RevokePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the folder resolved permissions. Permissions consists of both folder direct permissions and the inherited permissions from the ancestor folders.
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}/resolved-permissions
# operationId: DescribeFolderResolvedPermissions
export def "accounts-folders-resolved-permissions DescribeFolderResolvedPermissions" [
  AwsAccountId: string
  FolderId: string
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
]: nothing -> record<Status: record, FolderId: record, Arn: record, Permissions: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/folders/($FolderId)/resolved-permissions")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes an existing IAM policy assignment, as specified by the assignment name.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}
# operationId: DescribeIAMPolicyAssignment
export def "accounts-namespaces-iam-policy-assignments DescribeIAMPolicyAssignment" [
  AwsAccountId: string
  AssignmentName: string
  Namespace: string
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
]: nothing -> record<IAMPolicyAssignment: record<AwsAccountId: record, AssignmentId: record, AssignmentName: record, PolicyArn: record, Identities: record, AssignmentStatus: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/iam-policy-assignments/($AssignmentName)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request. This overwrites all of the users included in <code>Identities</code>. 
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}
# operationId: UpdateIAMPolicyAssignment
export def "accounts-namespaces-iam-policy-assignments UpdateIAMPolicyAssignment" [
  AwsAccountId: string
  AssignmentName: string
  Namespace: string
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
  --AssignmentStatus: string@AssignmentStatus-completer # <p>The status of the assignment. Possible values are as follows:</p> <ul> <li> <p> <code>ENABLED</code> - Anything specified in this assignment is used when creating the data source.</p> </li> <li> <p> <code>DISABLED</code> - This assignment isn't used when creating the data source.</p> </li> <li> <p> <code>DRAFT</code> - This assignment is an unfinished draft and isn't used when creating the data source.</p> </li> </ul>
  --PolicyArn: string # The ARN for the IAM policy to apply to the Amazon QuickSight users and groups specified in this assignment.
  --Identities: record # The Amazon QuickSight users, groups, or both that you want to assign the policy to.
]: any -> record<AssignmentName: record, AssignmentId: record, PolicyArn: record, Identities: record, AssignmentStatus: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/iam-policy-assignments/($AssignmentName)")
  let body = {AssignmentStatus: $AssignmentStatus, PolicyArn: $PolicyArn, Identities: $Identities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provides a summary and status of IP rules.
#
# GET /accounts/{AwsAccountId}/ip-restriction
# operationId: DescribeIpRestriction
export def "accounts-ip-restriction DescribeIpRestriction" [
  AwsAccountId: string
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
]: nothing -> record<AwsAccountId: record, IpRestrictionRuleMap: record, Enabled: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/ip-restriction")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the content and status of IP rules. To use this operation, you need to provide the entire map of rules. You can use the <code>DescribeIpRestriction</code> operation to get the current rule map.
#
# POST /accounts/{AwsAccountId}/ip-restriction
# operationId: UpdateIpRestriction
export def "accounts-ip-restriction UpdateIpRestriction" [
  AwsAccountId: string
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
  --IpRestrictionRuleMap: record # A map that describes the updated IP rules with CIDR ranges and descriptions.
  --Enabled: oneof<nothing, bool> # A value that specifies whether IP rules are turned on.
]: any -> record<AwsAccountId: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/ip-restriction")
  let body = {IpRestrictionRuleMap: $IpRestrictionRuleMap, Enabled: $Enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Provides a detailed description of the definition of a template.</p> <note> <p>If you do not need to know details about the content of a template, for instance if you are trying to check the status of a recently created or updated template, use the <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeTemplate.html"> <code>DescribeTemplate</code> </a> instead. </p> </note>
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/definition
# operationId: DescribeTemplateDefinition
export def "accounts-templates-definition DescribeTemplateDefinition" [
  AwsAccountId: string
  TemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number of the template.
  --alias-name: string # The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Name: record, TemplateId: record, Errors: record, ResourceStatus: record, ThemeArn: record, Definition: record<DataSetConfigurations: record, Sheets: record, CalculatedFields: record, ParameterDeclarations: record, FilterGroups: record, ColumnConfigurations: record, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar") (serialize-qp "alias-name" $alias_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)/definition" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes read and write permissions on a template.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/permissions
# operationId: DescribeTemplatePermissions
export def "accounts-templates-permissions DescribeTemplatePermissions" [
  AwsAccountId: string
  TemplateId: string
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
]: nothing -> record<TemplateId: record, TemplateArn: record, Permissions: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)/permissions")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the resource permissions for a template.
#
# PUT /accounts/{AwsAccountId}/templates/{TemplateId}/permissions
# operationId: UpdateTemplatePermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-templates-permissions UpdateTemplatePermissions" [
  AwsAccountId: string
  TemplateId: string
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
  --GrantPermissions: list # A list of resource permissions to be granted on the template.  — item shape: {Principal: any, Actions: any}
  --RevokePermissions: list # A list of resource permissions to be revoked from the template.  — item shape: {Principal: any, Actions: any}
]: any -> record<TemplateId: record, TemplateArn: record, Permissions: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)/permissions")
  let body = {GrantPermissions: $GrantPermissions, RevokePermissions: $RevokePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the read and write permissions for a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/permissions
# operationId: DescribeThemePermissions
export def "accounts-themes-permissions DescribeThemePermissions" [
  AwsAccountId: string
  ThemeId: string
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
]: nothing -> record<ThemeId: record, ThemeArn: record, Permissions: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)/permissions")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Updates the resource permissions for a theme. Permissions apply to the action to grant or revoke permissions on, for example <code>"quicksight:DescribeTheme"</code>.</p> <p>Theme permissions apply in groupings. Valid groupings include the following for the three levels of permissions, which are user, owner, or no permissions: </p> <ul> <li> <p>User</p> <ul> <li> <p> <code>"quicksight:DescribeTheme"</code> </p> </li> <li> <p> <code>"quicksight:DescribeThemeAlias"</code> </p> </li> <li> <p> <code>"quicksight:ListThemeAliases"</code> </p> </li> <li> <p> <code>"quicksight:ListThemeVersions"</code> </p> </li> </ul> </li> <li> <p>Owner</p> <ul> <li> <p> <code>"quicksight:DescribeTheme"</code> </p> </li> <li> <p> <code>"quicksight:DescribeThemeAlias"</code> </p> </li> <li> <p> <code>"quicksight:ListThemeAliases"</code> </p> </li> <li> <p> <code>"quicksight:ListThemeVersions"</code> </p> </li> <li> <p> <code>"quicksight:DeleteTheme"</code> </p> </li> <li> <p> <code>"quicksight:UpdateTheme"</code> </p> </li> <li> <p> <code>"quicksight:CreateThemeAlias"</code> </p> </li> <li> <p> <code>"quicksight:DeleteThemeAlias"</code> </p> </li> <li> <p> <code>"quicksight:UpdateThemeAlias"</code> </p> </li> <li> <p> <code>"quicksight:UpdateThemePermissions"</code> </p> </li> <li> <p> <code>"quicksight:DescribeThemePermissions"</code> </p> </li> </ul> </li> <li> <p>To specify no permissions, omit the permissions list.</p> </li> </ul>
#
# PUT /accounts/{AwsAccountId}/themes/{ThemeId}/permissions
# operationId: UpdateThemePermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-themes-permissions UpdateThemePermissions" [
  AwsAccountId: string
  ThemeId: string
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
  --GrantPermissions: list # A list of resource permissions to be granted for the theme. — item shape: {Principal: any, Actions: any}
  --RevokePermissions: list # A list of resource permissions to be revoked from the theme. — item shape: {Principal: any, Actions: any}
]: any -> record<ThemeId: record, ThemeArn: record, Permissions: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)/permissions")
  let body = {GrantPermissions: $GrantPermissions, RevokePermissions: $RevokePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Generates an embed URL that you can use to embed an Amazon QuickSight dashboard or visual in your website, without having to register any reader users. Before you use this action, make sure that you have configured the dashboards and permissions.</p> <p>The following rules apply to the generated URL:</p> <ul> <li> <p>It contains a temporary bearer token. It is valid for 5 minutes after it is generated. Once redeemed within this period, it cannot be re-used again.</p> </li> <li> <p>The URL validity period should not be confused with the actual session lifetime that can be customized using the <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_GenerateEmbedUrlForAnonymousUser.html#QS-GenerateEmbedUrlForAnonymousUser-request-SessionLifetimeInMinutes">SessionLifetimeInMinutes</a> </code> parameter. The resulting user session is valid for 15 minutes (minimum) to 10 hours (maximum). The default session duration is 10 hours.</p> </li> <li> <p>You are charged only when the URL is used or there is interaction with Amazon QuickSight.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics.html">Embedded Analytics</a> in the <i>Amazon QuickSight User Guide</i>.</p> <p>For more information about the high-level steps for embedding and for an interactive demo of the ways you can customize embedding, visit the <a href="https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-portal.html">Amazon QuickSight Developer Portal</a>.</p>
#
# POST /accounts/{AwsAccountId}/embed-url/anonymous-user
# operationId: GenerateEmbedUrlForAnonymousUser
# --SessionTags item shape: {Key: any, Value: any}
# --ExperienceConfiguration shape: {Dashboard?: any, DashboardVisual?: any, QSearchBar?: any}
export def "accounts-embed-url-anonymous-user GenerateEmbedUrlForAnonymousUser" [
  AwsAccountId: string
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
  --SessionLifetimeInMinutes: int # How many minutes the session is valid. The session lifetime must be in [15-600] minutes range.
  Namespace: string # The Amazon QuickSight namespace that the anonymous user virtually belongs to. If you are not using an Amazon QuickSight custom namespace, set this to <code>default</code>.
  --SessionTags: list # <p>The session tags used for row-level security. Before you use this parameter, make sure that you have configured the relevant datasets using the <code>DataSet$RowLevelPermissionTagConfiguration</code> parameter so that session tags can be used to provide row-level security.</p> <p>These are not the tags used for the Amazon Web Services resource tagging feature. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-rls-tags.html">Using Row-Level Security (RLS) with Tags</a>in the <i>Amazon QuickSight User Guide</i>.</p> — item shape: {Key: any, Value: any}
  AuthorizedResourceArns: list # The Amazon Resource Names (ARNs) for the Amazon QuickSight resources that the user is authorized to access during the lifetime of the session. If you choose <code>Dashboard</code> embedding experience, pass the list of dashboard ARNs in the account that you want the user to be able to view. Currently, you can pass up to 25 dashboard ARNs in each API call.
  ExperienceConfiguration: record # The type of experience you want to embed. For anonymous users, you can embed Amazon QuickSight dashboards. — shape: {Dashboard?: any, DashboardVisual?: any, QSearchBar?: any}
  --AllowedDomains: list # <p>The domains that you want to add to the allow list for access to the generated URL that is then embedded. This optional parameter overrides the static domains that are configured in the Manage QuickSight menu in the Amazon QuickSight console. Instead, it allows only the domains that you include in this parameter. You can list up to three domains or subdomains in each API call.</p> <p>To include all subdomains under a specific domain to the allow list, use <code>*</code>. For example, <code>https://*.sapp.amazon.com</code> includes all subdomains under <code>https://sapp.amazon.com</code>.</p>
]: any -> record<EmbedUrl: record, Status: record, RequestId: record, AnonymousUserArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/embed-url/anonymous-user")
  let body = {SessionLifetimeInMinutes: $SessionLifetimeInMinutes, Namespace: $Namespace, SessionTags: $SessionTags, AuthorizedResourceArns: $AuthorizedResourceArns, ExperienceConfiguration: $ExperienceConfiguration, AllowedDomains: $AllowedDomains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Generates an embed URL that you can use to embed an Amazon QuickSight experience in your website. This action can be used for any type of user registered in an Amazon QuickSight account. Before you use this action, make sure that you have configured the relevant Amazon QuickSight resource and permissions.</p> <p>The following rules apply to the generated URL:</p> <ul> <li> <p>It contains a temporary bearer token. It is valid for 5 minutes after it is generated. Once redeemed within this period, it cannot be re-used again.</p> </li> <li> <p>The URL validity period should not be confused with the actual session lifetime that can be customized using the <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_GenerateEmbedUrlForRegisteredUser.html#QS-GenerateEmbedUrlForRegisteredUser-request-SessionLifetimeInMinutes">SessionLifetimeInMinutes</a> </code> parameter.</p> <p>The resulting user session is valid for 15 minutes (minimum) to 10 hours (maximum). The default session duration is 10 hours.</p> </li> <li> <p>You are charged only when the URL is used or there is interaction with Amazon QuickSight.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics.html">Embedded Analytics</a> in the <i>Amazon QuickSight User Guide</i>.</p> <p>For more information about the high-level steps for embedding and for an interactive demo of the ways you can customize embedding, visit the <a href="https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-portal.html">Amazon QuickSight Developer Portal</a>.</p>
#
# POST /accounts/{AwsAccountId}/embed-url/registered-user
# operationId: GenerateEmbedUrlForRegisteredUser
# --ExperienceConfiguration shape: {Dashboard?: any, QuickSightConsole?: any, QSearchBar?: any, DashboardVisual?: any}
export def "accounts-embed-url-registered-user GenerateEmbedUrlForRegisteredUser" [
  AwsAccountId: string
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
  --SessionLifetimeInMinutes: int # How many minutes the session is valid. The session lifetime must be in [15-600] minutes range.
  UserArn: string # The Amazon Resource Name for the registered user.
  ExperienceConfiguration: record # <p>The type of experience you want to embed. For registered users, you can embed Amazon QuickSight dashboards or the Amazon QuickSight console.</p> <note> <p>Exactly one of the experience configurations is required. You can choose <code>Dashboard</code> or <code>QuickSightConsole</code>. You cannot choose more than one experience configuration.</p> </note> — shape: {Dashboard?: any, QuickSightConsole?: any, QSearchBar?: any, DashboardVisual?: any}
  --AllowedDomains: list # <p>The domains that you want to add to the allow list for access to the generated URL that is then embedded. This optional parameter overrides the static domains that are configured in the Manage QuickSight menu in the Amazon QuickSight console. Instead, it allows only the domains that you include in this parameter. You can list up to three domains or subdomains in each API call.</p> <p>To include all subdomains under a specific domain to the allow list, use <code>*</code>. For example, <code>https://*.sapp.amazon.com</code> includes all subdomains under <code>https://sapp.amazon.com</code>.</p>
]: any -> record<EmbedUrl: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/embed-url/registered-user")
  let body = {SessionLifetimeInMinutes: $SessionLifetimeInMinutes, UserArn: $UserArn, ExperienceConfiguration: $ExperienceConfiguration, AllowedDomains: $AllowedDomains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Generates a temporary session URL and authorization code(bearer token) that you can use to embed an Amazon QuickSight read-only dashboard in your website or application. Before you use this command, make sure that you have configured the dashboards and permissions. </p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user's browser. The following rules apply to the generated URL:</p> <ul> <li> <p>They must be used together.</p> </li> <li> <p>They can be used one time only.</p> </li> <li> <p>They are valid for 5 minutes after you run this command.</p> </li> <li> <p>You are charged only when the URL is used or there is interaction with Amazon QuickSight.</p> </li> <li> <p>The resulting user session is valid for 15 minutes (default) up to 10 hours (maximum). You can use the optional <code>SessionLifetimeInMinutes</code> parameter to customize session duration.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics-deprecated.html">Embedding Analytics Using GetDashboardEmbedUrl</a> in the <i>Amazon QuickSight User Guide</i>.</p> <p>For more information about the high-level steps for embedding and for an interactive demo of the ways you can customize embedding, visit the <a href="https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-portal.html">Amazon QuickSight Developer Portal</a>.</p>
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url#creds-type
# operationId: GetDashboardEmbedUrl
export def "accounts-dashboards-embed-urlcreds-type GetDashboardEmbedUrl" [
  AwsAccountId: string
  DashboardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --creds-type: string@creds-type-completer # The authentication method that the user uses to sign in.
  --session-lifetime: int # How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  --undo-redo-disabled: oneof<nothing, bool> # Remove the undo/redo button on the embedded dashboard. The default is FALSE, which enables the undo/redo button.
  --reset-disabled: oneof<nothing, bool> # Remove the reset button on the embedded dashboard. The default is FALSE, which enables the reset button.
  --state-persistence-enabled: oneof<nothing, bool> # Adds persistence of state for the user session in an embedded dashboard. Persistence applies to the sheet and the parameter settings. These are control settings that the dashboard subscriber (Amazon QuickSight reader) chooses while viewing the dashboard. If this is set to <code>TRUE</code>, the settings are the same when the subscriber reopens the same dashboard URL. The state is stored in Amazon QuickSight, not in a browser cookie. If this is set to FALSE, the state of the user session is not persisted. The default is <code>FALSE</code>.
  --user-arn: string # <p>The Amazon QuickSight user's Amazon Resource Name (ARN), for use with <code>QUICKSIGHT</code> identity type. You can use this for any Amazon QuickSight users in your account (readers, authors, or admins) authenticated as one of the following:</p> <ul> <li> <p>Active Directory (AD) users or group members</p> </li> <li> <p>Invited nonfederated users</p> </li> <li> <p>IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation.</p> </li> </ul> <p>Omit this parameter for users in the third group – IAM users and IAM role-based sessions.</p>
  --namespace: string # The Amazon QuickSight namespace that contains the dashboard IDs in this request. If you're not using a custom namespace, set <code>Namespace = default</code>.
  --additional-dashboard-ids: list # A list of one or more dashboard IDs that you want anonymous users to have tempporary access to. Currently, the <code>IdentityType</code> parameter must be set to <code>ANONYMOUS</code> because other identity types authenticate as Amazon QuickSight or IAM users. For example, if you set "<code>--dashboard-id dash_id1 --dashboard-id dash_id2 dash_id3 identity-type ANONYMOUS</code>", the session can access all three dashboards.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<EmbedUrl: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creds-type" $creds_type "scalar") (serialize-qp "session-lifetime" $session_lifetime "scalar") (serialize-qp "undo-redo-disabled" $undo_redo_disabled "scalar") (serialize-qp "reset-disabled" $reset_disabled "scalar") (serialize-qp "state-persistence-enabled" $state_persistence_enabled "scalar") (serialize-qp "user-arn" $user_arn "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "additional-dashboard-ids" $additional_dashboard_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/dashboards/($DashboardId)/embed-url#creds-type" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Generates a session URL and authorization code that you can use to embed the Amazon Amazon QuickSight console in your web server code. Use <code>GetSessionEmbedUrl</code> where you want to provide an authoring portal that allows users to create data sources, datasets, analyses, and dashboards. The users who access an embedded Amazon QuickSight console need belong to the author or admin security cohort. If you want to restrict permissions to some of these features, add a custom permissions profile to the user with the <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateUser.html">UpdateUser</a> </code> API operation. Use <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_RegisterUser.html">RegisterUser</a> </code> API operation to add a new user with a custom permission profile attached. For more information, see the following sections in the <i>Amazon QuickSight User Guide</i>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics.html">Embedding Analytics</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/quicksight/latest/user/customizing-permissions-to-the-quicksight-console.html">Customizing Access to the Amazon QuickSight Console</a> </p> </li> </ul>
#
# GET /accounts/{AwsAccountId}/session-embed-url
# operationId: GetSessionEmbedUrl
export def "accounts-session-embed-url GetSessionEmbedUrl" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entry-point: string # <p>The URL you use to access the embedded session. The entry point URL is constrained to the following paths:</p> <ul> <li> <p> <code>/start</code> </p> </li> <li> <p> <code>/start/analyses</code> </p> </li> <li> <p> <code>/start/dashboards</code> </p> </li> <li> <p> <code>/start/favorites</code> </p> </li> <li> <p> <code>/dashboards/<i>DashboardId</i> </code> - where <code>DashboardId</code> is the actual ID key from the Amazon QuickSight console URL of the dashboard</p> </li> <li> <p> <code>/analyses/<i>AnalysisId</i> </code> - where <code>AnalysisId</code> is the actual ID key from the Amazon QuickSight console URL of the analysis</p> </li> </ul>
  --session-lifetime: int # How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  --user-arn: string # <p>The Amazon QuickSight user's Amazon Resource Name (ARN), for use with <code>QUICKSIGHT</code> identity type. You can use this for any type of Amazon QuickSight users in your account (readers, authors, or admins). They need to be authenticated as one of the following:</p> <ol> <li> <p>Active Directory (AD) users or group members</p> </li> <li> <p>Invited nonfederated users</p> </li> <li> <p>IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation</p> </li> </ol> <p>Omit this parameter for users in the third group, IAM users and IAM role-based sessions.</p>
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<EmbedUrl: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entry-point" $entry_point "scalar") (serialize-qp "session-lifetime" $session_lifetime "scalar") (serialize-qp "user-arn" $user_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/session-embed-url" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists Amazon QuickSight analyses that exist in the specified Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/analyses
# operationId: ListAnalyses
export def "accounts-analyses ListAnalyses" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<AnalysisSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/analyses" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the versions of the dashboards in the Amazon QuickSight subscription.
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/versions
# operationId: ListDashboardVersions
export def "accounts-dashboards-versions ListDashboardVersions" [
  AwsAccountId: string
  DashboardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DashboardVersionSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/dashboards/($DashboardId)/versions" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists dashboards in an Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/dashboards
# operationId: ListDashboards
export def "accounts-dashboards ListDashboards" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<DashboardSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/dashboards" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all assets (<code>DASHBOARD</code>, <code>ANALYSIS</code>, and <code>DATASET</code>) in a folder. 
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}/members
# operationId: ListFolderMembers
export def "accounts-folders-members ListFolderMembers" [
  AwsAccountId: string
  FolderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Status: record, FolderMemberList: record, NextToken: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/folders/($FolderId)/members" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all folders in an account.
#
# GET /accounts/{AwsAccountId}/folders
# operationId: ListFolders
export def "accounts-folders ListFolders" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Status: record, FolderSummaryList: record, NextToken: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/folders" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists member users in a group.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members
# operationId: ListGroupMemberships
export def "accounts-namespaces-groups-members ListGroupMemberships" [
  GroupName: string
  AwsAccountId: string
  Namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<GroupMemberList: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/groups/($GroupName)/members" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists IAM policy assignments in the current Amazon QuickSight account.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments
# operationId: ListIAMPolicyAssignments
export def "accounts-namespaces-iam-policy-assignments ListIAMPolicyAssignments" [
  AwsAccountId: string
  Namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --AssignmentStatus: string@AssignmentStatus-completer # The status of the assignments.
]: any -> record<IAMPolicyAssignments: record, NextToken: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/iam-policy-assignments" $qp)
  let body = {AssignmentStatus: $AssignmentStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/iam-policy-assignments
# operationId: ListIAMPolicyAssignmentsForUser
export def "accounts-namespaces-users-iam-policy-assignments ListIAMPolicyAssignmentsForUser" [
  AwsAccountId: string
  UserName: string
  Namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ActiveAssignments: record, RequestId: record, NextToken: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/users/($UserName)/iam-policy-assignments" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the history of SPICE ingestions for a dataset.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions
# operationId: ListIngestions
export def "accounts-data-sets-ingestions ListIngestions" [
  DataSetId: string
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Ingestions: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/data-sets/($DataSetId)/ingestions" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the namespaces for the specified Amazon Web Services account. This operation doesn't list deleted namespaces.
#
# GET /accounts/{AwsAccountId}/namespaces
# operationId: ListNamespaces
export def "accounts-namespaces ListNamespaces" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A unique pagination token that can be used in a subsequent request. You will receive a pagination token in the response body of a previous <code>ListNameSpaces</code> API call if there is more data that can be returned. To receive the data, make another <code>ListNamespaces</code> API call with the returned token to retrieve the next page of data. Each token is valid for 24 hours. If you try to make a <code>ListNamespaces</code> API call with an expired token, you will receive a <code>HTTP 400 InvalidNextTokenException</code> error.
  --max-results: int # The maximum number of results to return.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<Namespaces: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the tags assigned to a resource.
#
# GET /resources/{ResourceArn}/tags
# operationId: ListTagsForResource
export def "resources-tags ListTagsForResource" [
  ResourceArn: string
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
]: nothing -> record<Tags: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/resources/($ResourceArn)/tags")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Assigns one or more tags (key-value pairs) to the specified Amazon QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. Amazon QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for Amazon QuickSight works in a similar way to tagging for other Amazon Web Services services, except for the following:</p> <ul> <li> <p>You can't use tags to track costs for Amazon QuickSight. This isn't possible because you can't tag the resources that Amazon QuickSight costs are based on, for example Amazon QuickSight storage capacity (SPICE), number of users, type of users, and usage metrics.</p> </li> <li> <p>Amazon QuickSight doesn't currently support the tag editor for Resource Groups.</p> </li> </ul>
#
# POST /resources/{ResourceArn}/tags
# operationId: TagResource
# --Tags item shape: {Key: any, Value: any}
export def "resources-tags TagResource" [
  ResourceArn: string
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
  Tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the resource. — item shape: {Key: any, Value: any}
]: any -> record<RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/resources/($ResourceArn)/tags")
  let body = {Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all the aliases of a template.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/aliases
# operationId: ListTemplateAliases
export def "accounts-templates-aliases ListTemplateAliases" [
  AwsAccountId: string
  TemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-result: int # The maximum number of results to be returned per request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<TemplateAliasList: record, Status: record, RequestId: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-result" $max_result "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)/aliases" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the versions of the templates in the current Amazon QuickSight account.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/versions
# operationId: ListTemplateVersions
export def "accounts-templates-versions ListTemplateVersions" [
  AwsAccountId: string
  TemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<TemplateVersionSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates/($TemplateId)/versions" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the templates in the current Amazon QuickSight account.
#
# GET /accounts/{AwsAccountId}/templates
# operationId: ListTemplates
export def "accounts-templates ListTemplates" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-result: int # The maximum number of results to be returned per request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<TemplateSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-result" $max_result "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/templates" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the aliases of a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/aliases
# operationId: ListThemeAliases
export def "accounts-themes-aliases ListThemeAliases" [
  AwsAccountId: string
  ThemeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-result: int # The maximum number of results to be returned per request.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ThemeAliasList: record, Status: record, RequestId: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-result" $max_result "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)/aliases" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the versions of the themes in the current Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/versions
# operationId: ListThemeVersions
export def "accounts-themes-versions ListThemeVersions" [
  AwsAccountId: string
  ThemeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ThemeVersionSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes/($ThemeId)/versions" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the themes in the current Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/themes
# operationId: ListThemes
export def "accounts-themes ListThemes" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --type: string@type-completer # <p>The type of themes that you want to list. Valid options include the following:</p> <ul> <li> <p> <code>ALL (default)</code>- Display all existing themes.</p> </li> <li> <p> <code>CUSTOM</code> - Display only the themes created by people using Amazon QuickSight.</p> </li> <li> <p> <code>QUICKSIGHT</code> - Display only the starting themes defined by Amazon QuickSight.</p> </li> </ul>
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<ThemeSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/themes" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups
# operationId: ListUserGroups
export def "accounts-namespaces-users-groups ListUserGroups" [
  UserName: string
  AwsAccountId: string
  Namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<GroupList: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/users/($UserName)/groups" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of all of the Amazon QuickSight users belonging to this account. 
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users
# operationId: ListUsers
export def "accounts-namespaces-users ListUsers" [
  AwsAccountId: string
  Namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<UserList: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/users" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an Amazon QuickSight user whose identity is associated with the Identity and Access Management (IAM) identity or role specified in the request. When you register a new user from the Amazon QuickSight API, Amazon QuickSight generates a registration URL. The user accesses this registration URL to create their account. Amazon QuickSight doesn't send a registration email to users who are registered from the Amazon QuickSight API. If you want new users to receive a registration email, then add those users in the Amazon QuickSight console. For more information on registering a new user in the Amazon QuickSight console, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/managing-users.html#inviting-users"> Inviting users to access Amazon QuickSight</a>.
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/users
# operationId: RegisterUser
export def "accounts-namespaces-users RegisterUser" [
  AwsAccountId: string
  Namespace: string
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
  IdentityType: string@IdentityType-completer # <p>Amazon QuickSight supports several ways of managing the identity of users. This parameter accepts two values:</p> <ul> <li> <p> <code>IAM</code>: A user whose identity maps to an existing IAM user or role. </p> </li> <li> <p> <code>QUICKSIGHT</code>: A user whose identity is owned and managed internally by Amazon QuickSight. </p> </li> </ul>
  Email: string # The email address of the user that you want to register.
  UserRole: string@UserRole-completer # <p>The Amazon QuickSight role for the user. The user role can be one of the following:</p> <ul> <li> <p> <code>READER</code>: A user who has read-only access to dashboards.</p> </li> <li> <p> <code>AUTHOR</code>: A user who can create data sources, datasets, analyses, and dashboards.</p> </li> <li> <p> <code>ADMIN</code>: A user who is an author, who can also manage Amazon QuickSight settings.</p> </li> <li> <p> <code>RESTRICTED_READER</code>: This role isn't currently available for use.</p> </li> <li> <p> <code>RESTRICTED_AUTHOR</code>: This role isn't currently available for use.</p> </li> </ul>
  --IamArn: string # The ARN of the IAM user or role that you are registering with Amazon QuickSight. 
  --SessionName: string # You need to use this parameter only when you register one or more users using an assumed IAM role. You don't need to provide the session name for other scenarios, for example when you are registering an IAM user or an Amazon QuickSight user. You can register multiple users using the same IAM role if each user has a different session name. For more information on assuming IAM roles, see <a href="https://docs.aws.amazon.com/cli/latest/reference/sts/assume-role.html"> <code>assume-role</code> </a> in the <i>CLI Reference.</i> 
  --UserName: string # The Amazon QuickSight user name that you want to create for the user you are registering.
  --CustomPermissionsName: string # <p>(Enterprise edition only) The name of the custom permissions profile that you want to assign to this user. Customized permissions allows you to control a user's access by restricting access the following operations:</p> <ul> <li> <p>Create and update data sources</p> </li> <li> <p>Create and update datasets</p> </li> <li> <p>Create and update email reports</p> </li> <li> <p>Subscribe to email reports</p> </li> </ul> <p>To add custom permissions to an existing user, use <code> <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateUser.html">UpdateUser</a> </code> instead.</p> <p>A set of custom permissions includes any combination of these restrictions. Currently, you need to create the profile names for custom permission sets by using the Amazon QuickSight console. Then, you use the <code>RegisterUser</code> API operation to assign the named set of permissions to a Amazon QuickSight user. </p> <p>Amazon QuickSight custom permissions are applied through IAM policies. Therefore, they override the permissions typically granted by assigning Amazon QuickSight users to one of the default security cohorts in Amazon QuickSight (admin, author, reader).</p> <p>This feature is available only to Amazon QuickSight Enterprise edition subscriptions.</p>
  --ExternalLoginFederationProviderType: string # <p>The type of supported external login provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. The type of supported external login provider can be one of the following.</p> <ul> <li> <p> <code>COGNITO</code>: Amazon Cognito. The provider URL is cognito-identity.amazonaws.com. When choosing the <code>COGNITO</code> provider type, don’t use the "CustomFederationProviderUrl" parameter which is only needed when the external provider is custom.</p> </li> <li> <p> <code>CUSTOM_OIDC</code>: Custom OpenID Connect (OIDC) provider. When choosing <code>CUSTOM_OIDC</code> type, use the <code>CustomFederationProviderUrl</code> parameter to provide the custom OIDC provider URL.</p> </li> </ul>
  --CustomFederationProviderUrl: string # The URL of the custom OpenID Connect (OIDC) provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. This parameter should only be used when <code>ExternalLoginFederationProviderType</code> parameter is set to <code>CUSTOM_OIDC</code>.
  --ExternalLoginId: string # The identity ID for a user in the external login provider.
]: any -> record<User: record<Arn: record, UserName: record, Email: record, Role: record, IdentityType: record, Active: record, PrincipalId: record, CustomPermissionsName: record, ExternalLoginFederationProviderType: record, ExternalLoginFederationProviderUrl: record, ExternalLoginId: record>, UserInvitationUrl: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/users")
  let body = {IdentityType: $IdentityType, Email: $Email, UserRole: $UserRole, IamArn: $IamArn, SessionName: $SessionName, UserName: $UserName, CustomPermissionsName: $CustomPermissionsName, ExternalLoginFederationProviderType: $ExternalLoginFederationProviderType, CustomFederationProviderUrl: $CustomFederationProviderUrl, ExternalLoginId: $ExternalLoginId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restores an analysis.
#
# POST /accounts/{AwsAccountId}/restore/analyses/{AnalysisId}
# operationId: RestoreAnalysis
export def "accounts-restore-analyses RestoreAnalysis" [
  AwsAccountId: string
  AnalysisId: string
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
]: nothing -> record<Status: record, Arn: record, AnalysisId: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/restore/analyses/($AnalysisId)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Searches for analyses that belong to the user specified in the filter.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
#
# POST /accounts/{AwsAccountId}/search/analyses
# operationId: SearchAnalyses
# --Filters item shape: {Operator?: any, Name?: any, Value?: any}
export def "accounts-search-analyses SearchAnalyses" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Filters: list # The structure for the search filters that you want to apply to your search.  — item shape: {Operator?: any, Name?: any, Value?: any}
  --NextToken: string # A pagination token that can be used in a subsequent request.
  --MaxResults: int # The maximum number of results to return.
]: any -> record<AnalysisSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/search/analyses" $qp)
  let body = {Filters: $Filters, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Searches for dashboards that belong to a user. </p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
#
# POST /accounts/{AwsAccountId}/search/dashboards
# operationId: SearchDashboards
# --Filters item shape: {Operator: any, Name?: any, Value?: any}
export def "accounts-search-dashboards SearchDashboards" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Filters: list # The filters to apply to the search. Currently, you can search only by user name, for example, <code>"Filters": [ { "Name": "QUICKSIGHT_USER", "Operator": "StringEquals", "Value": "arn:aws:quicksight:us-east-1:1:user/default/UserName1" } ]</code>  — item shape: {Operator: any, Name?: any, Value?: any}
  --NextToken: string # The token for the next set of results, or null if there are no more results.
  --MaxResults: int # The maximum number of results to be returned per request.
]: any -> record<DashboardSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/search/dashboards" $qp)
  let body = {Filters: $Filters, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use the <code>SearchDataSets</code> operation to search for datasets that belong to an account.
#
# POST /accounts/{AwsAccountId}/search/data-sets
# operationId: SearchDataSets
# --Filters item shape: {Operator: any, Name: any, Value: any}
export def "accounts-search-data-sets SearchDataSets" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Filters: list # The filters to apply to the search. — item shape: {Operator: any, Name: any, Value: any}
  --NextToken: string # A pagination token that can be used in a subsequent request.
  --MaxResults: int # The maximum number of results to be returned per request.
]: any -> record<DataSetSummaries: record, NextToken: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/search/data-sets" $qp)
  let body = {Filters: $Filters, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use the <code>SearchDataSources</code> operation to search for data sources that belong to an account.
#
# POST /accounts/{AwsAccountId}/search/data-sources
# operationId: SearchDataSources
# --Filters item shape: {Operator: any, Name: any, Value: any}
export def "accounts-search-data-sources SearchDataSources" [
  AwsAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Filters: list # The filters to apply to the search. — item shape: {Operator: any, Name: any, Value: any}
  --NextToken: string # A pagination token that can be used in a subsequent request.
  --MaxResults: int # The maximum number of results to be returned per request.
]: any -> record<DataSourceSummaries: record, NextToken: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/search/data-sources" $qp)
  let body = {Filters: $Filters, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Searches the subfolders in a folder.
#
# POST /accounts/{AwsAccountId}/search/folders
# operationId: SearchFolders
# --Filters item shape: {Operator?: any, Name?: any, Value?: any}
export def "accounts-search-folders SearchFolders" [
  AwsAccountId: string
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
  Filters: list # The filters to apply to the search. Currently, you can search only by the parent folder ARN. For example, <code>"Filters": [ { "Name": "PARENT_FOLDER_ARN", "Operator": "StringEquals", "Value": "arn:aws:quicksight:us-east-1:1:folder/folderId" } ]</code>. — item shape: {Operator?: any, Name?: any, Value?: any}
  --NextToken: string # The token for the next set of results, or null if there are no more results.
  --MaxResults: int # The maximum number of results to be returned per request.
]: any -> record<Status: record, FolderSummaryList: record, NextToken: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/search/folders")
  let body = {Filters: $Filters, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use the <code>SearchGroups</code> operation to search groups in a specified Amazon QuickSight namespace using the supplied filters.
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/groups-search
# operationId: SearchGroups
# --Filters item shape: {Operator: any, Name: any, Value: any}
export def "accounts-namespaces-groups-search SearchGroups" [
  AwsAccountId: string
  Namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Filters: list # The structure for the search filters that you want to apply to your search. — item shape: {Operator: any, Name: any, Value: any}
]: any -> record<GroupList: record, NextToken: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/namespaces/($Namespace)/groups-search" $qp)
  let body = {Filters: $Filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a tag or tags from a resource.
#
# DELETE /resources/{ResourceArn}/tags#keys
# operationId: UntagResource
export def "resources-tagskeys UntagResource" [
  ResourceArn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keys: list # The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keys" $keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/resources/($ResourceArn)/tags#keys" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the published version of a dashboard.
#
# PUT /accounts/{AwsAccountId}/dashboards/{DashboardId}/versions/{VersionNumber}
# operationId: UpdateDashboardPublishedVersion
export def "accounts-dashboards-versions UpdateDashboardPublishedVersion" [
  AwsAccountId: string
  DashboardId: string
  VersionNumber: int
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
]: nothing -> record<DashboardId: record, DashboardArn: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/dashboards/($DashboardId)/versions/($VersionNumber)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Use the <code>UpdatePublicSharingSettings</code> operation to turn on or turn off the public sharing settings of an Amazon QuickSight dashboard.</p> <p>To use this operation, turn on session capacity pricing for your Amazon QuickSight account.</p> <p>Before you can turn on public sharing on your account, make sure to give public sharing permissions to an administrative user in the Identity and Access Management (IAM) console. For more information on using IAM with Amazon QuickSight, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/security_iam_service-with-iam.html">Using Amazon QuickSight with IAM</a> in the <i>Amazon QuickSight User Guide</i>.</p>
#
# PUT /accounts/{AwsAccountId}/public-sharing-settings
# operationId: UpdatePublicSharingSettings
export def "accounts-public-sharing-settings UpdatePublicSharingSettings" [
  AwsAccountId: string
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
  --PublicSharingEnabled: oneof<nothing, bool> # A Boolean value that indicates whether public sharing is turned on for an Amazon QuickSight account.
]: any -> record<RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($AwsAccountId)/public-sharing-settings")
  let body = {PublicSharingEnabled: $PublicSharingEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
