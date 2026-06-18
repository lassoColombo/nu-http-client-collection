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

def base-url-completer [] { ["http://quicksight.us-east-1.amazonaws.com" "http://quicksight.us-east-2.amazonaws.com" "http://quicksight.us-west-1.amazonaws.com" "http://quicksight.us-west-2.amazonaws.com" "http://quicksight.us-gov-west-1.amazonaws.com" "http://quicksight.us-gov-east-1.amazonaws.com" "http://quicksight.ca-central-1.amazonaws.com" "http://quicksight.eu-north-1.amazonaws.com" "http://quicksight.eu-west-1.amazonaws.com" "http://quicksight.eu-west-2.amazonaws.com" "http://quicksight.eu-west-3.amazonaws.com" "http://quicksight.eu-central-1.amazonaws.com" "http://quicksight.eu-south-1.amazonaws.com" "http://quicksight.af-south-1.amazonaws.com" "http://quicksight.ap-northeast-1.amazonaws.com" "http://quicksight.ap-northeast-2.amazonaws.com" "http://quicksight.ap-northeast-3.amazonaws.com" "http://quicksight.ap-southeast-1.amazonaws.com" "http://quicksight.ap-southeast-2.amazonaws.com" "http://quicksight.ap-east-1.amazonaws.com" "http://quicksight.ap-south-1.amazonaws.com" "http://quicksight.sa-east-1.amazonaws.com" "http://quicksight.me-south-1.amazonaws.com" "https://quicksight.us-east-1.amazonaws.com" "https://quicksight.us-east-2.amazonaws.com" "https://quicksight.us-west-1.amazonaws.com" "https://quicksight.us-west-2.amazonaws.com" "https://quicksight.us-gov-west-1.amazonaws.com" "https://quicksight.us-gov-east-1.amazonaws.com" "https://quicksight.ca-central-1.amazonaws.com" "https://quicksight.eu-north-1.amazonaws.com" "https://quicksight.eu-west-1.amazonaws.com" "https://quicksight.eu-west-2.amazonaws.com" "https://quicksight.eu-west-3.amazonaws.com" "https://quicksight.eu-central-1.amazonaws.com" "https://quicksight.eu-south-1.amazonaws.com" "https://quicksight.af-south-1.amazonaws.com" "https://quicksight.ap-northeast-1.amazonaws.com" "https://quicksight.ap-northeast-2.amazonaws.com" "https://quicksight.ap-northeast-3.amazonaws.com" "https://quicksight.ap-southeast-1.amazonaws.com" "https://quicksight.ap-southeast-2.amazonaws.com" "https://quicksight.ap-east-1.amazonaws.com" "https://quicksight.ap-south-1.amazonaws.com" "https://quicksight.sa-east-1.amazonaws.com" "https://quicksight.me-south-1.amazonaws.com" "http://quicksight.cn-north-1.amazonaws.com.cn" "http://quicksight.cn-northwest-1.amazonaws.com.cn" "https://quicksight.cn-north-1.amazonaws.com.cn" "https://quicksight.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def ingestion-type-completer [] { ["FULL_REFRESH" "INCREMENTAL_REFRESH"] }
def edition-completer [] { ["ENTERPRISE" "ENTERPRISE_AND_Q" "STANDARD"] }
def authentication-method-completer [] { ["ACTIVE_DIRECTORY" "IAM_AND_QUICKSIGHT" "IAM_ONLY"] }
def import-mode-completer [] { ["DIRECT_QUERY" "SPICE"] }
def type-completer [] { ["ADOBE_ANALYTICS" "AMAZON_ELASTICSEARCH" "AMAZON_OPENSEARCH" "ATHENA" "AURORA" "AURORA_POSTGRESQL" "AWS_IOT_ANALYTICS" "DATABRICKS" "EXASOL" "GITHUB" "JIRA" "MARIADB" "MYSQL" "ORACLE" "POSTGRESQL" "PRESTO" "REDSHIFT" "S3" "SALESFORCE" "SERVICENOW" "SNOWFLAKE" "SPARK" "SQLSERVER" "TERADATA" "TIMESTREAM" "TWITTER"] }
def folder-type-completer [] { ["SHARED"] }
def assignment-status-completer [] { ["DISABLED" "DRAFT" "ENABLED"] }
def identity-store-completer [] { ["QUICKSIGHT"] }
def role-completer [] { ["ADMIN" "AUTHOR" "READER" "RESTRICTED_AUTHOR" "RESTRICTED_READER"] }
def creds-type-completer [] { ["ANONYMOUS" "IAM" "QUICKSIGHT"] }
def type-completer-1 [] { ["ALL" "CUSTOM" "QUICKSIGHT"] }
def identity-type-completer [] { ["IAM" "QUICKSIGHT"] }
def user-role-completer [] { ["ADMIN" "AUTHOR" "READER" "RESTRICTED_AUTHOR" "RESTRICTED_READER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-data-sets-ingestions cancel" } } | get name | first)
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
export def "accounts-data-sets-ingestions cancel" [
  aws_account_id: string
  data_set_id: string
  ingestion_id: string
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
]: nothing -> record<Arn: record, IngestionId: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id), ingestion_id: (encode-path-segment $ingestion_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/ingestions/{ingestion_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates and starts a new SPICE ingestion for a dataset. You can manually refresh datasets in an Enterprise edition account 32 times in a 24-hour period. You can manually refresh datasets in a Standard edition account 8 times in a 24-hour period. Each 24-hour period is measured starting 24 hours before the current date and time. Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see How do I create an IAM policy to control access to Amazon EC2 resources using tags? (http://aws.amazon.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/) in the Amazon Web Services Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.
#
# PUT /accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}
# operationId: CreateIngestion
export def "accounts-data-sets-ingestions create" [
  aws_account_id: string
  data_set_id: string
  ingestion_id: string
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
  --ingestion-type: string@ingestion-type-completer # This defines the type of ingestion user wants to trigger. This is part of create ingestion request.
]: any -> record<Arn: record, IngestionId: record, IngestionStatus: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id), ingestion_id: (encode-path-segment $ingestion_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/ingestions/{ingestion_id}"))
  let req_body = {"IngestionType": $ingestion_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes a SPICE ingestion.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}
# operationId: DescribeIngestion
export def "accounts-data-sets-ingestions get" [
  aws_account_id: string
  data_set_id: string
  ingestion_id: string
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
]: nothing -> record<Ingestion: record<Arn: record, IngestionId: record, IngestionStatus: record, ErrorInfo: record<Type: record, Message: record>, RowInfo: record<RowsIngested: record, RowsDropped: record, TotalRowsInDataset: record>, QueueInfo: record<WaitingOnIngestion: record, QueuedIngestion: record>, CreatedTime: record, IngestionTimeInSeconds: record, IngestionSizeInBytes: record, RequestSource: record, RequestType: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id), ingestion_id: (encode-path-segment $ingestion_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/ingestions/{ingestion_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates Amazon QuickSight customizations for the current Amazon Web Services Region. Currently, you can add a custom default theme by using the CreateAccountCustomization or UpdateAccountCustomization API operation. To further customize Amazon QuickSight by removing Amazon QuickSight sample assets and videos for all new users, see Customizing Amazon QuickSight (https://docs.aws.amazon.com/quicksight/latest/user/customizing-quicksight.html) in the Amazon QuickSight User Guide. You can create customizations for your Amazon Web Services account or, if you specify a namespace, for a QuickSight namespace instead. Customizations that apply to a namespace always override customizations that apply to an Amazon Web Services account. To find out which customizations apply, use the DescribeAccountCustomization API operation. Before you use the CreateAccountCustomization API operation to add a theme as the namespace default, make sure that you first share the theme with the namespace. If you don't share it with the namespace, the theme isn't visible to your users even if you make it the default theme. To check if the theme is shared, view the current permissions by using the DescribeThemePermissions (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeThemePermissions.html) API operation. To share the theme, grant permissions by using the UpdateThemePermissions (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateThemePermissions.html) API operation.
#
# POST /accounts/{AwsAccountId}/customizations
# operationId: CreateAccountCustomization
# --AccountCustomization shape: {DefaultTheme?: any, DefaultEmailCustomizationTemplate?: any}
# --Tags item shape: {Key: any, Value: any}
export def "accounts-customizations create" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The Amazon QuickSight namespace that you want to add customizations to.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  account_customization: record # The Amazon QuickSight customizations associated with your Amazon Web Services account or a QuickSight namespace in a specific Amazon Web Services Region. — shape: {DefaultTheme?: any, DefaultEmailCustomizationTemplate?: any}
  --tags: list # A list of the tags that you want to attach to this resource. — item shape: {Key: any, Value: any}
]: any -> record<Arn: record, AwsAccountId: record, Namespace: record, AccountCustomization: record<DefaultTheme: record, DefaultEmailCustomizationTemplate: record>, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/customizations") $qp)
  let req_body = {"AccountCustomization": $account_customization, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes all Amazon QuickSight customizations in this Amazon Web Services Region for the specified Amazon Web Services account and Amazon QuickSight namespace.
#
# DELETE /accounts/{AwsAccountId}/customizations
# operationId: DeleteAccountCustomization
export def "accounts-customizations delete" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The Amazon QuickSight namespace that you're deleting the customizations from.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/customizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes the customizations associated with the provided Amazon Web Services account and Amazon Amazon QuickSight namespace in an Amazon Web Services Region. The Amazon QuickSight console evaluates which customizations to apply by running this API operation with the Resolved flag included. To determine what customizations display when you run this command, it can help to visualize the relationship of the entities involved. Amazon Web Services account - The Amazon Web Services account exists at the top of the hierarchy. It has the potential to use all of the Amazon Web Services Regions and Amazon Web Services Services. When you subscribe to Amazon QuickSight, you choose one Amazon Web Services Region to use as your home Region. That's where your free SPICE capacity is located. You can use Amazon QuickSight in any supported Amazon Web Services Region. Amazon Web Services Region - In each Amazon Web Services Region where you sign in to Amazon QuickSight at least once, Amazon QuickSight acts as a separate instance of the same service. If you have a user directory, it resides in us-east-1, which is the US East (N. Virginia). Generally speaking, these users have access to Amazon QuickSight in any Amazon Web Services Region, unless they are constrained to a namespace. To run the command in a different Amazon Web Services Region, you change your Region settings. If you're using the CLI, you can use one of the following options: Use command line options (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-options.html). Use named profiles (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html). Run aws configure to change your default Amazon Web Services Region. Use Enter to key the same settings for your keys. For more information, see Configuring the CLI (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html). Namespace - A QuickSight namespace is a partition that contains users and assets (data sources, datasets, dashboards, and so on). To access assets that are in a specific namespace, users and groups must also be part of the same namespace. People who share a namespace are completely isolated from users and assets in other namespaces, even if they are in the same Amazon Web Services account and Amazon Web Services Region. Applied customizations - Within an Amazon Web Services Region, a set of Amazon QuickSight customizations can apply to an Amazon Web Services account or to a namespace. Settings that you apply to a namespace override settings that you apply to an Amazon Web Services account. All settings are isolated to a single Amazon Web Services Region. To apply them in other Amazon Web Services Regions, run the CreateAccountCustomization command in each Amazon Web Services Region where you want to apply the same customizations.
#
# GET /accounts/{AwsAccountId}/customizations
# operationId: DescribeAccountCustomization
export def "accounts-customizations get" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The Amazon QuickSight namespace that you want to describe Amazon QuickSight customizations for.
  --resolved: oneof<nothing, bool> # The Resolved flag works with the other parameters to determine which view of Amazon QuickSight customizations is returned. You can add this flag to your command to use the same view that Amazon QuickSight uses to identify which customizations to apply to the console. Omit this flag, or set it to no-resolved, to reveal customizations that are configured at different levels.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Arn: record, AwsAccountId: record, Namespace: record, AccountCustomization: record<DefaultTheme: record, DefaultEmailCustomizationTemplate: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "resolved" $resolved "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/customizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates Amazon QuickSight customizations for the current Amazon Web Services Region. Currently, the only customization that you can use is a theme. You can use customizations for your Amazon Web Services account or, if you specify a namespace, for a Amazon QuickSight namespace instead. Customizations that apply to a namespace override customizations that apply to an Amazon Web Services account. To find out which customizations apply, use the DescribeAccountCustomization API operation.
#
# PUT /accounts/{AwsAccountId}/customizations
# operationId: UpdateAccountCustomization
# --AccountCustomization shape: {DefaultTheme?: any, DefaultEmailCustomizationTemplate?: any}
export def "accounts-customizations update" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The namespace that you want to update Amazon QuickSight customizations for.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  account_customization: record # The Amazon QuickSight customizations associated with your Amazon Web Services account or a QuickSight namespace in a specific Amazon Web Services Region. — shape: {DefaultTheme?: any, DefaultEmailCustomizationTemplate?: any}
]: any -> record<Arn: record, AwsAccountId: record, Namespace: record, AccountCustomization: record<DefaultTheme: record, DefaultEmailCustomizationTemplate: record>, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/customizations") $qp)
  let req_body = {"AccountCustomization": $account_customization} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates an Amazon QuickSight account, or subscribes to Amazon QuickSight Q. The Amazon Web Services Region for the account is derived from what is configured in the CLI or SDK. This operation isn't supported in the US East (Ohio) Region, South America (Sao Paulo) Region, or Asia Pacific (Singapore) Region. Before you use this operation, make sure that you can connect to an existing Amazon Web Services account. If you don't have an Amazon Web Services account, see Sign up for Amazon Web Services (https://docs.aws.amazon.com/quicksight/latest/user/setting-up-aws-sign-up.html) in the Amazon QuickSight User Guide. The person who signs up for Amazon QuickSight needs to have the correct Identity and Access Management (IAM) permissions. For more information, see IAM Policy Examples for Amazon QuickSight (https://docs.aws.amazon.com/quicksight/latest/user/iam-policy-examples.html) in the Amazon QuickSight User Guide. If your IAM policy includes both the Subscribe and CreateAccountSubscription actions, make sure that both actions are set to Allow. If either action is set to Deny, the Deny action prevails and your API call fails. You can't pass an existing IAM role to access other Amazon Web Services services using this API operation. To pass your existing IAM role to Amazon QuickSight, see Passing IAM roles to Amazon QuickSight (https://docs.aws.amazon.com/quicksight/latest/user/security_iam_service-with-iam.html#security-create-iam-role) in the Amazon QuickSight User Guide. You can't set default resource access on the new account from the Amazon QuickSight API. Instead, add default resource access from the Amazon QuickSight console. For more information about setting default resource access to Amazon Web Services services, see Setting default resource access to Amazon Web Services services (https://docs.aws.amazon.com/quicksight/latest/user/scoping-policies-defaults.html) in the Amazon QuickSight User Guide.
#
# POST /account/{AwsAccountId}
# operationId: CreateAccountSubscription
export def "account create-subscription" [
  aws_account_id: string
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
  edition: string@edition-completer # The edition of Amazon QuickSight that you want your account to have. Currently, you can choose from ENTERPRISE or ENTERPRISE_AND_Q. If you choose ENTERPRISE_AND_Q, the following parameters are required: FirstName LastName EmailAddress ContactNumber
  authentication_method: string@authentication-method-completer # The method that you want to use to authenticate your Amazon QuickSight account. Currently, the valid values for this parameter are IAM_AND_QUICKSIGHT, IAM_ONLY, and ACTIVE_DIRECTORY. If you choose ACTIVE_DIRECTORY, provide an ActiveDirectoryName and an AdminGroup associated with your Active Directory.
  account_name: string # The name of your Amazon QuickSight account. This name is unique over all of Amazon Web Services, and it appears only when users sign in. You can't change AccountName value after the Amazon QuickSight account is created.
  notification_email: string # The email address that you want Amazon QuickSight to send notifications to regarding your Amazon QuickSight account or Amazon QuickSight subscription.
  --active-directory-name: string # The name of your Active Directory. This field is required if ACTIVE_DIRECTORY is the selected authentication method of the new Amazon QuickSight account.
  --realm: string # The realm of the Active Directory that is associated with your Amazon QuickSight account. This field is required if ACTIVE_DIRECTORY is the selected authentication method of the new Amazon QuickSight account.
  --directory-id: string # The ID of the Active Directory that is associated with your Amazon QuickSight account.
  --admin-group: list<string> # The admin group associated with your Active Directory. This field is required if ACTIVE_DIRECTORY is the selected authentication method of the new Amazon QuickSight account. For more information about using Active Directory in Amazon QuickSight, see Using Active Directory with Amazon QuickSight Enterprise Edition (https://docs.aws.amazon.com/quicksight/latest/user/aws-directory-service.html) in the Amazon QuickSight User Guide.
  --author-group: list<string> # The author group associated with your Active Directory. For more information about using Active Directory in Amazon QuickSight, see Using Active Directory with Amazon QuickSight Enterprise Edition (https://docs.aws.amazon.com/quicksight/latest/user/aws-directory-service.html) in the Amazon QuickSight User Guide.
  --reader-group: list<string> # The reader group associated with your Active Direcrtory. For more information about using Active Directory in Amazon QuickSight, see Using Active Directory with Amazon QuickSight Enterprise Edition (https://docs.aws.amazon.com/quicksight/latest/user/aws-directory-service.html) in the Amazon QuickSight User Guide.
  --first-name: string # The first name of the author of the Amazon QuickSight account to use for future communications. This field is required if ENTERPPRISE_AND_Q is the selected edition of the new Amazon QuickSight account.
  --last-name: string # The last name of the author of the Amazon QuickSight account to use for future communications. This field is required if ENTERPPRISE_AND_Q is the selected edition of the new Amazon QuickSight account.
  --email-address: string # The email address of the author of the Amazon QuickSight account to use for future communications. This field is required if ENTERPPRISE_AND_Q is the selected edition of the new Amazon QuickSight account.
  --contact-number: string # A 10-digit phone number for the author of the Amazon QuickSight account to use for future communications. This field is required if ENTERPPRISE_AND_Q is the selected edition of the new Amazon QuickSight account.
]: any -> record<SignupResponse: record<IAMUser: record, userLoginName: record, accountName: record, directoryType: record>, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/account/{aws_account_id}"))
  let req_body = {"Edition": $edition, "AuthenticationMethod": $authentication_method, "AccountName": $account_name, "NotificationEmail": $notification_email, "ActiveDirectoryName": $active_directory_name, "Realm": $realm, "DirectoryId": $directory_id, "AdminGroup": $admin_group, "AuthorGroup": $author_group, "ReaderGroup": $reader_group, "FirstName": $first_name, "LastName": $last_name, "EmailAddress": $email_address, "ContactNumber": $contact_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Use the DeleteAccountSubscription operation to delete an Amazon QuickSight account. This operation will result in an error message if you have configured your account termination protection settings to True. To change this setting and delete your account, call the UpdateAccountSettings API and set the value of the TerminationProtectionEnabled parameter to False, then make another call to the DeleteAccountSubscription API.
#
# DELETE /account/{AwsAccountId}
# operationId: DeleteAccountSubscription
export def "account delete-subscription" [
  aws_account_id: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/account/{aws_account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Use the DescribeAccountSubscription operation to receive a description of an Amazon QuickSight account's subscription. A successful API call returns an AccountInfo object that includes an account's name, subscription status, authentication type, edition, and notification email address.
#
# GET /account/{AwsAccountId}
# operationId: DescribeAccountSubscription
export def "account get-subscription" [
  aws_account_id: string
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
]: nothing -> record<AccountInfo: record<AccountName: record, Edition: record, NotificationEmail: record, AuthenticationType: record, AccountSubscriptionStatus: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/account/{aws_account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates an analysis in Amazon QuickSight. Analyses can be created either from a template or from an AnalysisDefinition.
#
# POST /accounts/{AwsAccountId}/analyses/{AnalysisId}
# operationId: CreateAnalysis
# --Parameters shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
# --Permissions item shape: {Principal: any, Actions: any}
# --SourceEntity shape: {SourceTemplate?: any}
# --Tags item shape: {Key: any, Value: any}
# --Definition shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-analyses create-analysis" [
  aws_account_id: string
  analysis_id: string
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
  name: string # A descriptive name for the analysis that you're creating. This name displays for the analysis in the Amazon QuickSight console.
  --parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
  --permissions: list # A structure that describes the principals and the resource-level permissions on an analysis. You can use the Permissions structure to grant permissions by providing a list of Identity and Access Management (IAM) action information for each principal listed by Amazon Resource Name (ARN). To specify no permissions, omit Permissions. — item shape: {Principal: any, Actions: any}
  --source-entity: record # The source entity of an analysis. — shape: {SourceTemplate?: any}
  --theme-arn: string # The ARN for the theme to apply to the analysis that you're creating. To see the theme in the Amazon QuickSight console, make sure that you have access to it.
  --tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the analysis. — item shape: {Key: any, Value: any}
  --definition: record # The definition of an analysis. — shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<Arn: record, AnalysisId: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), analysis_id: (encode-path-segment $analysis_id)} | format pattern "/accounts/{aws_account_id}/analyses/{analysis_id}"))
  let req_body = {"Name": $name, "Parameters": $parameters, "Permissions": $permissions, "SourceEntity": $source_entity, "ThemeArn": $theme_arn, "Tags": $tags, "Definition": $definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes an analysis from Amazon QuickSight. You can optionally include a recovery window during which you can restore the analysis. If you don't specify a recovery window value, the operation defaults to 30 days. Amazon QuickSight attaches a DeletionTime stamp to the response that specifies the end of the recovery window. At the end of the recovery window, Amazon QuickSight deletes the analysis permanently. At any time before recovery window ends, you can use the RestoreAnalysis API operation to remove the DeletionTime stamp and cancel the deletion of the analysis. The analysis remains visible in the API until it's deleted, so you can describe it but you can't make a template from it. An analysis that's scheduled for deletion isn't accessible in the Amazon QuickSight console. To access it in the console, restore it. Deleting an analysis doesn't delete the dashboards that you publish from it.
#
# DELETE /accounts/{AwsAccountId}/analyses/{AnalysisId}
# operationId: DeleteAnalysis
export def "accounts-analyses delete-analysis" [
  aws_account_id: string
  analysis_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recovery-window-in-days: int # A value that specifies the number of days that Amazon QuickSight waits before it deletes the analysis. You can't use this parameter with the ForceDeleteWithoutRecovery option in the same API call. The default value is 30.
  --force-delete-without-recovery: oneof<nothing, bool> # This option defaults to the value NoForceDeleteWithoutRecovery. To immediately delete the analysis, add the ForceDeleteWithoutRecovery option. You can't restore an analysis after it's deleted.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Status: record, Arn: record, AnalysisId: record, DeletionTime: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recovery-window-in-days" $recovery_window_in_days "scalar") (serialize-qp "force-delete-without-recovery" $force_delete_without_recovery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), analysis_id: (encode-path-segment $analysis_id)} | format pattern "/accounts/{aws_account_id}/analyses/{analysis_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Provides a summary of the metadata for an analysis.
#
# GET /accounts/{AwsAccountId}/analyses/{AnalysisId}
# operationId: DescribeAnalysis
export def "accounts-analyses get-analysis" [
  aws_account_id: string
  analysis_id: string
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
]: nothing -> record<Analysis: record<AnalysisId: record, Arn: record, Name: record, Status: record, Errors: record, DataSetArns: record, ThemeArn: record, CreatedTime: record, LastUpdatedTime: record, Sheets: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), analysis_id: (encode-path-segment $analysis_id)} | format pattern "/accounts/{aws_account_id}/analyses/{analysis_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an analysis in Amazon QuickSight
#
# PUT /accounts/{AwsAccountId}/analyses/{AnalysisId}
# operationId: UpdateAnalysis
# --Parameters shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
# --SourceEntity shape: {SourceTemplate?: any}
# --Definition shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-analyses update-analysis" [
  aws_account_id: string
  analysis_id: string
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
  name: string # A descriptive name for the analysis that you're updating. This name displays for the analysis in the Amazon QuickSight console.
  --parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
  --source-entity: record # The source entity of an analysis. — shape: {SourceTemplate?: any}
  --theme-arn: string # The Amazon Resource Name (ARN) for the theme to apply to the analysis that you're creating. To see the theme in the Amazon QuickSight console, make sure that you have access to it.
  --definition: record # The definition of an analysis. — shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<Arn: record, AnalysisId: record, UpdateStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), analysis_id: (encode-path-segment $analysis_id)} | format pattern "/accounts/{aws_account_id}/analyses/{analysis_id}"))
  let req_body = {"Name": $name, "Parameters": $parameters, "SourceEntity": $source_entity, "ThemeArn": $theme_arn, "Definition": $definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a dashboard from either a template or directly with a DashboardDefinition. To first create a template, see the CreateTemplate (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_CreateTemplate.html) API operation. A dashboard is an entity in Amazon QuickSight that identifies Amazon QuickSight reports, created from analyses. You can share Amazon QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. If you have the correct permissions, you can create a dashboard from a template that exists in a different Amazon Web Services account.
#
# POST /accounts/{AwsAccountId}/dashboards/{DashboardId}
# operationId: CreateDashboard
# --Parameters shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
# --Permissions item shape: {Principal: any, Actions: any}
# --SourceEntity shape: {SourceTemplate?: any}
# --Tags item shape: {Key: any, Value: any}
# --DashboardPublishOptions shape: {AdHocFilteringOption?: any, ExportToCSVOption?: any, SheetControlsOption?: any, VisualPublishOptions?: any, SheetLayoutElementMaximizationOption?: any, VisualMenuOption?: any, VisualAxisSortOption?: any, ExportWithHiddenFieldsOption?: any, DataPointDrillUpDownOption?: any, DataPointMenuLabelOption?: any, DataPointTooltipOption?: any}
# --Definition shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-dashboards create" [
  aws_account_id: string
  dashboard_id: string
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
  name: string # The display name of the dashboard.
  --parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
  --permissions: list # A structure that contains the permissions of the dashboard. You can use this structure for granting permissions by providing a list of IAM action information for each principal ARN. To specify no permissions, omit the permissions list. — item shape: {Principal: any, Actions: any}
  --source-entity: record # Dashboard source entity. — shape: {SourceTemplate?: any}
  --tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the dashboard. — item shape: {Key: any, Value: any}
  --version-description: string # A description for the first version of the dashboard being created.
  --dashboard-publish-options: record # Dashboard publish options. — shape: {AdHocFilteringOption?: any, ExportToCSVOption?: any, SheetControlsOption?: any, VisualPublishOptions?: any, SheetLayoutElementMaximizationOption?: any, VisualMenuOption?: any, VisualAxisSortOption?: any, ExportWithHiddenFieldsOption?: any, DataPointDrillUpDownOption?: any, DataPointMenuLabelOption?: any, DataPointTooltipOption?: any}
  --theme-arn: string # The Amazon Resource Name (ARN) of the theme that is being used for this dashboard. If you add a value for this field, it overrides the value that is used in the source entity. The theme ARN must exist in the same Amazon Web Services account where you create the dashboard.
  --definition: record # The contents of a dashboard. — shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<Arn: record, VersionArn: record, DashboardId: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/accounts/{aws_account_id}/dashboards/{dashboard_id}"))
  let req_body = {"Name": $name, "Parameters": $parameters, "Permissions": $permissions, "SourceEntity": $source_entity, "Tags": $tags, "VersionDescription": $version_description, "DashboardPublishOptions": $dashboard_publish_options, "ThemeArn": $theme_arn, "Definition": $definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a dashboard.
#
# DELETE /accounts/{AwsAccountId}/dashboards/{DashboardId}
# operationId: DeleteDashboard
export def "accounts-dashboards delete" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Status: record, Arn: record, DashboardId: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/accounts/{aws_account_id}/dashboards/{dashboard_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Provides a summary for a dashboard.
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}
# operationId: DescribeDashboard
export def "accounts-dashboards get" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described.
  --alias-name: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Dashboard: record<DashboardId: record, Arn: record, Name: record, Version: record<CreatedTime: record, Errors: record, VersionNumber: record, Status: record, Arn: record, SourceEntityArn: record, DataSetArns: record, Description: record, ThemeArn: record, Sheets: record>, CreatedTime: record, LastPublishedTime: record, LastUpdatedTime: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar") (serialize-qp "alias-name" $alias_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/accounts/{aws_account_id}/dashboards/{dashboard_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a dashboard in an Amazon Web Services account. Updating a Dashboard creates a new dashboard version but does not immediately publish the new version. You can update the published version of a dashboard by using the UpdateDashboardPublishedVersion (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateDashboardPublishedVersion.html) API operation.
#
# PUT /accounts/{AwsAccountId}/dashboards/{DashboardId}
# operationId: UpdateDashboard
# --SourceEntity shape: {SourceTemplate?: any}
# --Parameters shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
# --DashboardPublishOptions shape: {AdHocFilteringOption?: any, ExportToCSVOption?: any, SheetControlsOption?: any, VisualPublishOptions?: any, SheetLayoutElementMaximizationOption?: any, VisualMenuOption?: any, VisualAxisSortOption?: any, ExportWithHiddenFieldsOption?: any, DataPointDrillUpDownOption?: any, DataPointMenuLabelOption?: any, DataPointTooltipOption?: any}
# --Definition shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-dashboards update" [
  aws_account_id: string
  dashboard_id: string
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
  name: string # The display name of the dashboard.
  --source-entity: record # Dashboard source entity. — shape: {SourceTemplate?: any}
  --parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: any, IntegerParameters?: any, DecimalParameters?: any, DateTimeParameters?: any}
  --version-description: string # A description for the first version of the dashboard being created.
  --dashboard-publish-options: record # Dashboard publish options. — shape: {AdHocFilteringOption?: any, ExportToCSVOption?: any, SheetControlsOption?: any, VisualPublishOptions?: any, SheetLayoutElementMaximizationOption?: any, VisualMenuOption?: any, VisualAxisSortOption?: any, ExportWithHiddenFieldsOption?: any, DataPointDrillUpDownOption?: any, DataPointMenuLabelOption?: any, DataPointTooltipOption?: any}
  --theme-arn: string # The Amazon Resource Name (ARN) of the theme that is being used for this dashboard. If you add a value for this field, it overrides the value that was originally associated with the entity. The theme ARN must exist in the same Amazon Web Services account where you create the dashboard.
  --definition: record # The contents of a dashboard. — shape: {DataSetIdentifierDeclarations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<Arn: record, VersionArn: record, DashboardId: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/accounts/{aws_account_id}/dashboards/{dashboard_id}"))
  let req_body = {"Name": $name, "SourceEntity": $source_entity, "Parameters": $parameters, "VersionDescription": $version_description, "DashboardPublishOptions": $dashboard_publish_options, "ThemeArn": $theme_arn, "Definition": $definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
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
export def "accounts-data-sets create" [
  aws_account_id: string
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
  data_set_id: string # An ID for the dataset that you want to create. This ID is unique per Amazon Web Services Region for each Amazon Web Services account.
  name: string # The display name for the dataset.
  physical_table_map: record # Declares the physical tables that are available in the underlying data sources.
  --logical-table-map: record # Configures the combination and transformation of the data from the physical tables.
  import_mode: string@import-mode-completer # Indicates whether you want to import the data into SPICE.
  --column-groups: list # Groupings of columns that work together in certain Amazon QuickSight features. Currently, only geospatial hierarchy is supported. — item shape: {GeoSpatialColumnGroup?: any}
  --field-folders: record # The folder that contains fields and nested subfolders for your dataset.
  --permissions: list # A list of resource permissions on the dataset. — item shape: {Principal: any, Actions: any}
  --row-level-permission-data-set: record # Information about a dataset that contains permissions for row-level security (RLS). The permissions dataset maps fields to users or groups. For more information, see Using Row-Level Security (RLS) to Restrict Access to a Dataset (https://docs.aws.amazon.com/quicksight/latest/user/restrict-access-to-a-data-set-using-row-level-security.html) in the Amazon QuickSight User Guide. The option to deny permissions by setting PermissionPolicy to DENY_ACCESS is not supported for new RLS datasets. — shape: {Namespace?: any, Arn?: any, PermissionPolicy?: any, FormatVersion?: any, Status?: any}
  --row-level-permission-tag-configuration: record # The configuration of tags on a dataset to set row-level security. — shape: {Status?: any, TagRules?: any, TagRuleConfigurations?: any}
  --column-level-permission-rules: list # A set of one or more definitions of a ColumnLevelPermissionRule (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_ColumnLevelPermissionRule.html) . — item shape: {Principals?: any, ColumnNames?: any}
  --tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the dataset. — item shape: {Key: any, Value: any}
  --data-set-usage-configuration: record # The usage configuration to apply to child datasets that reference this dataset as a source. — shape: {DisableUseAsDirectQuerySource?: any, DisableUseAsImportedSource?: any}
]: any -> record<Arn: record, DataSetId: record, IngestionArn: record, IngestionId: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/data-sets"))
  let req_body = {"DataSetId": $data_set_id, "Name": $name, "PhysicalTableMap": $physical_table_map, "LogicalTableMap": $logical_table_map, "ImportMode": $import_mode, "ColumnGroups": $column_groups, "FieldFolders": $field_folders, "Permissions": $permissions, "RowLevelPermissionDataSet": $row_level_permission_data_set, "RowLevelPermissionTagConfiguration": $row_level_permission_tag_configuration, "ColumnLevelPermissionRules": $column_level_permission_rules, "Tags": $tags, "DataSetUsageConfiguration": $data_set_usage_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all of the datasets belonging to the current Amazon Web Services account in an Amazon Web Services Region. The permissions resource is arn:aws:quicksight:region:aws-account-id:dataset/*.
#
# GET /accounts/{AwsAccountId}/data-sets
# operationId: ListDataSets
export def "accounts-data-sets list" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DataSetSummaries: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/data-sets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a data source.
#
# POST /accounts/{AwsAccountId}/data-sources
# operationId: CreateDataSource
# --DataSourceParameters shape: {AmazonElasticsearchParameters?: any, AthenaParameters?: any, AuroraParameters?: any, AuroraPostgreSqlParameters?: any, AwsIotAnalyticsParameters?: any, JiraParameters?: any, MariaDbParameters?: any, MySqlParameters?: any, OracleParameters?: any, PostgreSqlParameters?: any, PrestoParameters?: any, RdsParameters?: any, RedshiftParameters?: any, S3Parameters?: any, ServiceNowParameters?: any, SnowflakeParameters?: any, SparkParameters?: any, SqlServerParameters?: any, TeradataParameters?: any, ... (4 more fields)}
# --Credentials shape: {CredentialPair?: any, CopySourceArn?: any, SecretArn?: any}
# --Permissions item shape: {Principal: any, Actions: any}
# --VpcConnectionProperties shape: {VpcConnectionArn?: any}
# --SslProperties shape: {DisableSsl?: any}
# --Tags item shape: {Key: any, Value: any}
export def "accounts-data-sources create" [
  aws_account_id: string
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
  data_source_id: string # An ID for the data source. This ID is unique per Amazon Web Services Region for each Amazon Web Services account.
  name: string # A display name for the data source.
  type: string@type-completer # The type of the data source. To return a list of all data sources, use ListDataSources. Use AMAZON_ELASTICSEARCH for Amazon OpenSearch Service.
  --data-source-parameters: record # The parameters that Amazon QuickSight uses to connect to your underlying data source. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {AmazonElasticsearchParameters?: any, AthenaParameters?: any, AuroraParameters?: any, AuroraPostgreSqlParameters?: any, AwsIotAnalyticsParameters?: any, JiraParameters?: any, MariaDbParameters?: any, MySqlParameters?: any, OracleParameters?: any, PostgreSqlParameters?: any, PrestoParameters?: any, RdsParameters?: any, RedshiftParameters?: any, S3Parameters?: any, ServiceNowParameters?: any, SnowflakeParameters?: any, SparkParameters?: any, SqlServerParameters?: any, TeradataParameters?: any, ... (4 more fields)}
  --credentials: record # Data source credentials. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {CredentialPair?: any, CopySourceArn?: any, SecretArn?: any}
  --permissions: list # A list of resource permissions on the data source. — item shape: {Principal: any, Actions: any}
  --vpc-connection-properties: record # VPC connection properties. — shape: {VpcConnectionArn?: any}
  --ssl-properties: record # Secure Socket Layer (SSL) properties that apply when Amazon QuickSight connects to your underlying data source. — shape: {DisableSsl?: any}
  --tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the data source. — item shape: {Key: any, Value: any}
]: any -> record<Arn: record, DataSourceId: record, CreationStatus: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/data-sources"))
  let req_body = {"DataSourceId": $data_source_id, "Name": $name, "Type": $type, "DataSourceParameters": $data_source_parameters, "Credentials": $credentials, "Permissions": $permissions, "VpcConnectionProperties": $vpc_connection_properties, "SslProperties": $ssl_properties, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists data sources in current Amazon Web Services Region that belong to this Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/data-sources
# operationId: ListDataSources
export def "accounts-data-sources list" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DataSources: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/data-sources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates an empty shared folder.
#
# POST /accounts/{AwsAccountId}/folders/{FolderId}
# operationId: CreateFolder
# --Permissions item shape: {Principal: any, Actions: any}
# --Tags item shape: {Key: any, Value: any}
export def "accounts-folders create" [
  aws_account_id: string
  folder_id: string
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
  --name: string # The name of the folder.
  --folder-type: string@folder-type-completer # The type of folder. By default, folderType is SHARED.
  --parent-folder-arn: string # The Amazon Resource Name (ARN) for the parent folder. ParentFolderArn can be null. An empty parentFolderArn creates a root-level folder.
  --permissions: list # A structure that describes the principals and the resource-level permissions of a folder. To specify no permissions, omit Permissions. — item shape: {Principal: any, Actions: any}
  --tags: list # Tags for the folder. — item shape: {Key: any, Value: any}
]: any -> record<Status: record, Arn: record, FolderId: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/accounts/{aws_account_id}/folders/{folder_id}"))
  let req_body = {"Name": $name, "FolderType": $folder_type, "ParentFolderArn": $parent_folder_arn, "Permissions": $permissions, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes an empty folder.
#
# DELETE /accounts/{AwsAccountId}/folders/{FolderId}
# operationId: DeleteFolder
export def "accounts-folders delete" [
  aws_account_id: string
  folder_id: string
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
]: nothing -> record<Status: record, Arn: record, FolderId: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/accounts/{aws_account_id}/folders/{folder_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes a folder.
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}
# operationId: DescribeFolder
export def "accounts-folders get" [
  aws_account_id: string
  folder_id: string
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
]: nothing -> record<Status: record, Folder: record<FolderId: record, Arn: record, Name: record, FolderType: record, FolderPath: record, CreatedTime: record, LastUpdatedTime: record>, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/accounts/{aws_account_id}/folders/{folder_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the name of a folder.
#
# PUT /accounts/{AwsAccountId}/folders/{FolderId}
# operationId: UpdateFolder
export def "accounts-folders update" [
  aws_account_id: string
  folder_id: string
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
  name: string # The name of the folder.
]: any -> record<Status: record, Arn: record, FolderId: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/accounts/{aws_account_id}/folders/{folder_id}"))
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Adds an asset, such as a dashboard, analysis, or dataset into a folder.
#
# PUT /accounts/{AwsAccountId}/folders/{FolderId}/members/{MemberType}/{MemberId}
# operationId: CreateFolderMembership
export def "accounts-folders-members create-membership" [
  aws_account_id: string
  folder_id: string
  member_type: string
  member_id: string
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
]: nothing -> record<Status: record, FolderMember: record<MemberId: record, MemberType: record>, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), folder_id: (encode-path-segment $folder_id), member_type: (encode-path-segment $member_type), member_id: (encode-path-segment $member_id)} | format pattern "/accounts/{aws_account_id}/folders/{folder_id}/members/{member_type}/{member_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Removes an asset, such as a dashboard, analysis, or dataset, from a folder.
#
# DELETE /accounts/{AwsAccountId}/folders/{FolderId}/members/{MemberType}/{MemberId}
# operationId: DeleteFolderMembership
export def "accounts-folders-members delete-membership" [
  aws_account_id: string
  folder_id: string
  member_type: string
  member_id: string
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
]: nothing -> record<Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), folder_id: (encode-path-segment $folder_id), member_type: (encode-path-segment $member_type), member_id: (encode-path-segment $member_id)} | format pattern "/accounts/{aws_account_id}/folders/{folder_id}/members/{member_type}/{member_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Use the CreateGroup operation to create a group in Amazon QuickSight. You can create up to 10,000 groups in a namespace. If you want to create more than 10,000 groups in a namespace, contact AWS Support. The permissions resource is arn:aws:quicksight:<your-region>:<relevant-aws-account-id>:group/default/<group-name> . The response is a group object.
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/groups
# operationId: CreateGroup
export def "accounts-namespaces-groups create" [
  aws_account_id: string
  namespace: string
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
  group_name: string # A name for the group that you want to create.
  --description: string # A description for the group that you want to create.
]: any -> record<Group: record<Arn: record, GroupName: record, Description: record, PrincipalId: record>, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/groups"))
  let req_body = {"GroupName": $group_name, "Description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all user groups in Amazon QuickSight.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups
# operationId: ListGroups
export def "accounts-namespaces-groups list" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<GroupList: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Adds an Amazon QuickSight user to an Amazon QuickSight group.
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}
# operationId: CreateGroupMembership
export def "accounts-namespaces-groups-members create-membership" [
  aws_account_id: string
  namespace: string
  group_name: string
  member_name: string
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
]: nothing -> record<GroupMember: record<Arn: record, MemberName: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), group_name: (encode-path-segment $group_name), member_name: (encode-path-segment $member_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/groups/{group_name}/members/{member_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Removes a user from a group so that the user is no longer a member of the group.
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}
# operationId: DeleteGroupMembership
export def "accounts-namespaces-groups-members delete-membership" [
  aws_account_id: string
  namespace: string
  group_name: string
  member_name: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), group_name: (encode-path-segment $group_name), member_name: (encode-path-segment $member_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/groups/{group_name}/members/{member_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Use the DescribeGroupMembership operation to determine if a user is a member of the specified group. If the user exists and is a member of the specified group, an associated GroupMember object is returned.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}
# operationId: DescribeGroupMembership
export def "accounts-namespaces-groups-members get-membership" [
  aws_account_id: string
  namespace: string
  group_name: string
  member_name: string
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
]: nothing -> record<GroupMember: record<Arn: record, MemberName: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), group_name: (encode-path-segment $group_name), member_name: (encode-path-segment $member_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/groups/{group_name}/members/{member_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy assignment is attached to the specified groups or users of Amazon QuickSight. Assignment names are unique per Amazon Web Services account. To avoid overwriting rules in other namespaces, use assignment names that are unique.
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/
# operationId: CreateIAMPolicyAssignment
export def "accounts-namespaces-iam-policy-assignments create" [
  aws_account_id: string
  namespace: string
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
  assignment_name: string # The name of the assignment, also called a rule. It must be unique within an Amazon Web Services account.
  assignment_status: string@assignment-status-completer # The status of the assignment. Possible values are as follows: ENABLED - Anything specified in this assignment is used when creating the data source. DISABLED - This assignment isn't used when creating the data source. DRAFT - This assignment is an unfinished draft and isn't used when creating the data source.
  --policy-arn: string # The ARN for the IAM policy to apply to the Amazon QuickSight users and groups specified in this assignment.
  --identities: record # The Amazon QuickSight users, groups, or both that you want to assign the policy to.
]: any -> record<AssignmentName: record, AssignmentId: record, AssignmentStatus: record, PolicyArn: record, Identities: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/iam-policy-assignments/"))
  let req_body = {"AssignmentName": $assignment_name, "AssignmentStatus": $assignment_status, "PolicyArn": $policy_arn, "Identities": $identities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# (Enterprise edition only) Creates a new namespace for you to use with Amazon QuickSight. A namespace allows you to isolate the Amazon QuickSight users and groups that are registered for that namespace. Users that access the namespace can share assets only with other users or groups in the same namespace. They can't see users and groups in other namespaces. You can create a namespace after your Amazon Web Services account is subscribed to Amazon QuickSight. The namespace must be unique within the Amazon Web Services account. By default, there is a limit of 100 namespaces per Amazon Web Services account. To increase your limit, create a ticket with Amazon Web Services Support.
#
# POST /accounts/{AwsAccountId}
# operationId: CreateNamespace
# --Tags item shape: {Key: any, Value: any}
export def "accounts create-namespace" [
  aws_account_id: string
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
  namespace: string # The name that you want to use to describe the new namespace.
  identity_store: string@identity-store-completer # Specifies the type of your user identity directory. Currently, this supports users with an identity type of QUICKSIGHT.
  --tags: list # The tags that you want to associate with the namespace that you're creating. — item shape: {Key: any, Value: any}
]: any -> record<Arn: record, Name: record, CapacityRegion: record, CreationStatus: record, IdentityStore: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}"))
  let req_body = {"Namespace": $namespace, "IdentityStore": $identity_store, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a refresh schedule for a dataset. You can create up to 5 different schedules for a single dataset.
#
# POST /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules
# operationId: CreateRefreshSchedule
# --Schedule shape: {ScheduleId?: any, ScheduleFrequency?: any, StartAfterDateTime?: any, RefreshType?: any, Arn?: any}
export def "accounts-data-sets-refresh-schedules create" [
  aws_account_id: string
  data_set_id: string
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
  schedule: record # The refresh schedule of a dataset. — shape: {ScheduleId?: any, ScheduleFrequency?: any, StartAfterDateTime?: any, RefreshType?: any, Arn?: any}
]: any -> record<Status: record, RequestId: record, ScheduleId: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/refresh-schedules"))
  let req_body = {"Schedule": $schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the refresh schedules of a dataset. Each dataset can have up to 5 schedules.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules
# operationId: ListRefreshSchedules
export def "accounts-data-sets-refresh-schedules list" [
  aws_account_id: string
  data_set_id: string
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
]: nothing -> record<RefreshSchedules: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/refresh-schedules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a refresh schedule for a dataset.
#
# PUT /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules
# operationId: UpdateRefreshSchedule
# --Schedule shape: {ScheduleId?: any, ScheduleFrequency?: any, StartAfterDateTime?: any, RefreshType?: any, Arn?: any}
export def "accounts-data-sets-refresh-schedules update" [
  aws_account_id: string
  data_set_id: string
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
  schedule: record # The refresh schedule of a dataset. — shape: {ScheduleId?: any, ScheduleFrequency?: any, StartAfterDateTime?: any, RefreshType?: any, Arn?: any}
]: any -> record<Status: record, RequestId: record, ScheduleId: record, Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/refresh-schedules"))
  let req_body = {"Schedule": $schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a template either from a TemplateDefinition or from an existing Amazon QuickSight analysis or template. You can use the resulting template to create additional dashboards, templates, or analyses. A template is an entity in Amazon QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.
#
# POST /accounts/{AwsAccountId}/templates/{TemplateId}
# operationId: CreateTemplate
# --Permissions item shape: {Principal: any, Actions: any}
# --SourceEntity shape: {SourceAnalysis?: any, SourceTemplate?: any}
# --Tags item shape: {Key: any, Value: any}
# --Definition shape: {DataSetConfigurations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-templates create" [
  aws_account_id: string
  template_id: string
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
  --name: string # A display name for the template.
  --permissions: list # A list of resource permissions to be set on the template. — item shape: {Principal: any, Actions: any}
  --source-entity: record # The source entity of the template. — shape: {SourceAnalysis?: any, SourceTemplate?: any}
  --tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the resource. — item shape: {Key: any, Value: any}
  --version-description: string # A description of the current template version being created. This API operation creates the first version of the template. Every time UpdateTemplate is called, a new version is created. Each version of the template maintains a description of the version in the VersionDescription field.
  --definition: record # The detailed definition of a template. — shape: {DataSetConfigurations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<Arn: record, VersionArn: record, TemplateId: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}"))
  let req_body = {"Name": $name, "Permissions": $permissions, "SourceEntity": $source_entity, "Tags": $tags, "VersionDescription": $version_description, "Definition": $definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a template.
#
# DELETE /accounts/{AwsAccountId}/templates/{TemplateId}
# operationId: DeleteTemplate
export def "accounts-templates delete" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # Specifies the version of the template that you want to delete. If you don't provide a version number, DeleteTemplate deletes all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<RequestId: record, Arn: record, TemplateId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes a template's metadata.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}
# operationId: DescribeTemplate
export def "accounts-templates get" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # (Optional) The number for the version to describe. If a VersionNumber parameter value isn't provided, the latest version of the template is described.
  --alias-name: string # The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword $LATEST in the AliasName parameter. The keyword $PUBLISHED doesn't apply to templates.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Template: record<Arn: record, Name: record, Version: record<CreatedTime: record, Errors: record, VersionNumber: record, Status: record, DataSetConfigurations: record, Description: record, SourceEntityArn: record, ThemeArn: record, Sheets: record>, TemplateId: record, LastUpdatedTime: record, CreatedTime: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar") (serialize-qp "alias-name" $alias_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a template from an existing Amazon QuickSight analysis or another template.
#
# PUT /accounts/{AwsAccountId}/templates/{TemplateId}
# operationId: UpdateTemplate
# --SourceEntity shape: {SourceAnalysis?: any, SourceTemplate?: any}
# --Definition shape: {DataSetConfigurations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
export def "accounts-templates update" [
  aws_account_id: string
  template_id: string
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
  --source-entity: record # The source entity of the template. — shape: {SourceAnalysis?: any, SourceTemplate?: any}
  --version-description: string # A description of the current template version that is being updated. Every time you call UpdateTemplate, you create a new version of the template. Each version of the template maintains a description of the version in the VersionDescription field.
  --name: string # The name for the template.
  --definition: record # The detailed definition of a template. — shape: {DataSetConfigurations?: any, Sheets?: any, CalculatedFields?: any, ParameterDeclarations?: any, FilterGroups?: any, ColumnConfigurations?: any, AnalysisDefaults?: record}
]: any -> record<TemplateId: record, Arn: record, VersionArn: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}"))
  let req_body = {"SourceEntity": $source_entity, "VersionDescription": $version_description, "Name": $name, "Definition": $definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a template alias for a template.
#
# POST /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# operationId: CreateTemplateAlias
export def "accounts-templates-aliases create-alias" [
  aws_account_id: string
  template_id: string
  alias_name: string
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
  template_version_number: int # The version number of the template.
]: any -> record<TemplateAlias: record<AliasName: record, Arn: record, TemplateVersionNumber: record>, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id), alias_name: (encode-path-segment $alias_name)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}/aliases/{alias_name}"))
  let req_body = {"TemplateVersionNumber": $template_version_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
#
# DELETE /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# operationId: DeleteTemplateAlias
export def "accounts-templates-aliases delete-alias" [
  aws_account_id: string
  template_id: string
  alias_name: string
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
]: nothing -> record<Status: record, TemplateId: record, AliasName: record, Arn: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id), alias_name: (encode-path-segment $alias_name)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}/aliases/{alias_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes the template alias for a template.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# operationId: DescribeTemplateAlias
export def "accounts-templates-aliases get-alias" [
  aws_account_id: string
  template_id: string
  alias_name: string
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
]: nothing -> record<TemplateAlias: record<AliasName: record, Arn: record, TemplateVersionNumber: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id), alias_name: (encode-path-segment $alias_name)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}/aliases/{alias_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the template alias of a template.
#
# PUT /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# operationId: UpdateTemplateAlias
export def "accounts-templates-aliases update-alias" [
  aws_account_id: string
  template_id: string
  alias_name: string
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
  template_version_number: int # The version number of the template.
]: any -> record<TemplateAlias: record<AliasName: record, Arn: record, TemplateVersionNumber: record>, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id), alias_name: (encode-path-segment $alias_name)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}/aliases/{alias_name}"))
  let req_body = {"TemplateVersionNumber": $template_version_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a theme. A theme is set of configuration options for color and layout. Themes apply to analyses and dashboards. For more information, see Using Themes in Amazon QuickSight (https://docs.aws.amazon.com/quicksight/latest/user/themes-in-quicksight.html) in the Amazon QuickSight User Guide.
#
# POST /accounts/{AwsAccountId}/themes/{ThemeId}
# operationId: CreateTheme
# --Configuration shape: {DataColorPalette?: any, UIColorPalette?: any, Sheet?: any, Typography?: record}
# --Permissions item shape: {Principal: any, Actions: any}
# --Tags item shape: {Key: any, Value: any}
export def "accounts-themes create" [
  aws_account_id: string
  theme_id: string
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
  name: string # A display name for the theme.
  base_theme_id: string # The ID of the theme that a custom theme will inherit from. All themes inherit from one of the starting themes defined by Amazon QuickSight. For a list of the starting themes, use ListThemes or choose Themes from within an analysis.
  --version-description: string # A description of the first version of the theme that you're creating. Every time UpdateTheme is called, a new version is created. Each version of the theme has a description of the version in the VersionDescription field.
  configuration: record # The theme configuration. This configuration contains all of the display properties for a theme. — shape: {DataColorPalette?: any, UIColorPalette?: any, Sheet?: any, Typography?: record}
  --permissions: list # A valid grouping of resource permissions to apply to the new theme. — item shape: {Principal: any, Actions: any}
  --tags: list # A map of the key-value pairs for the resource tag or tags that you want to add to the resource. — item shape: {Key: any, Value: any}
]: any -> record<Arn: record, VersionArn: record, ThemeId: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}"))
  let req_body = {"Name": $name, "BaseThemeId": $base_theme_id, "VersionDescription": $version_description, "Configuration": $configuration, "Permissions": $permissions, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a theme.
#
# DELETE /accounts/{AwsAccountId}/themes/{ThemeId}
# operationId: DeleteTheme
export def "accounts-themes delete" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version of the theme that you want to delete. Note: If you don't provide a version number, you're using this call to DeleteTheme to delete all versions of the theme.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Arn: record, RequestId: record, Status: record, ThemeId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}
# operationId: DescribeTheme
export def "accounts-themes get" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number for the version to describe. If a VersionNumber parameter value isn't provided, the latest version of the theme is described.
  --alias-name: string # The alias of the theme that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the theme by providing the keyword $LATEST in the AliasName parameter. The keyword $PUBLISHED doesn't apply to themes.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Theme: record<Arn: record, Name: record, ThemeId: record, Version: record<VersionNumber: record, Arn: record, Description: record, BaseThemeId: record, CreatedTime: record, Configuration: record, Errors: record, Status: record>, CreatedTime: record, LastUpdatedTime: record, Type: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar") (serialize-qp "alias-name" $alias_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a theme.
#
# PUT /accounts/{AwsAccountId}/themes/{ThemeId}
# operationId: UpdateTheme
# --Configuration shape: {DataColorPalette?: any, UIColorPalette?: any, Sheet?: any, Typography?: record}
export def "accounts-themes update" [
  aws_account_id: string
  theme_id: string
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
  --name: string # The name for the theme.
  base_theme_id: string # The theme ID, defined by Amazon QuickSight, that a custom theme inherits from. All themes initially inherit from a default Amazon QuickSight theme.
  --version-description: string # A description of the theme version that you're updating Every time that you call UpdateTheme, you create a new version of the theme. Each version of the theme maintains a description of the version in VersionDescription.
  --configuration: record # The theme configuration. This configuration contains all of the display properties for a theme. — shape: {DataColorPalette?: any, UIColorPalette?: any, Sheet?: any, Typography?: record}
]: any -> record<ThemeId: record, Arn: record, VersionArn: record, CreationStatus: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}"))
  let req_body = {"Name": $name, "BaseThemeId": $base_theme_id, "VersionDescription": $version_description, "Configuration": $configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a theme alias for a theme.
#
# POST /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# operationId: CreateThemeAlias
export def "accounts-themes-aliases create-alias" [
  aws_account_id: string
  theme_id: string
  alias_name: string
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
  theme_version_number: int # The version number of the theme.
]: any -> record<ThemeAlias: record<Arn: record, AliasName: record, ThemeVersionNumber: record>, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id), alias_name: (encode-path-segment $alias_name)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}/aliases/{alias_name}"))
  let req_body = {"ThemeVersionNumber": $theme_version_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the version of the theme that the specified theme alias points to. If you provide a specific alias, you delete the version of the theme that the alias points to.
#
# DELETE /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# operationId: DeleteThemeAlias
export def "accounts-themes-aliases delete-alias" [
  aws_account_id: string
  theme_id: string
  alias_name: string
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
]: nothing -> record<AliasName: record, Arn: record, RequestId: record, Status: record, ThemeId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id), alias_name: (encode-path-segment $alias_name)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}/aliases/{alias_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes the alias for a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# operationId: DescribeThemeAlias
export def "accounts-themes-aliases get-alias" [
  aws_account_id: string
  theme_id: string
  alias_name: string
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
]: nothing -> record<ThemeAlias: record<Arn: record, AliasName: record, ThemeVersionNumber: record>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id), alias_name: (encode-path-segment $alias_name)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}/aliases/{alias_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an alias of a theme.
#
# PUT /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# operationId: UpdateThemeAlias
export def "accounts-themes-aliases update-alias" [
  aws_account_id: string
  theme_id: string
  alias_name: string
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
  theme_version_number: int # The version number of the theme that the alias should reference.
]: any -> record<ThemeAlias: record<Arn: record, AliasName: record, ThemeVersionNumber: record>, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id), alias_name: (encode-path-segment $alias_name)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}/aliases/{alias_name}"))
  let req_body = {"ThemeVersionNumber": $theme_version_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a dataset.
#
# DELETE /accounts/{AwsAccountId}/data-sets/{DataSetId}
# operationId: DeleteDataSet
export def "accounts-data-sets delete" [
  aws_account_id: string
  data_set_id: string
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
]: nothing -> record<Arn: record, DataSetId: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes a dataset. This operation doesn't support datasets that include uploaded files as a source.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}
# operationId: DescribeDataSet
export def "accounts-data-sets get" [
  aws_account_id: string
  data_set_id: string
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
]: nothing -> record<DataSet: record<Arn: record, DataSetId: record, Name: record, CreatedTime: record, LastUpdatedTime: record, PhysicalTableMap: record, LogicalTableMap: record, OutputColumns: record, ImportMode: record, ConsumedSpiceCapacityInBytes: record, ColumnGroups: record, FieldFolders: record, RowLevelPermissionDataSet: record<Namespace: record, Arn: record, PermissionPolicy: record, FormatVersion: record, Status: record>, RowLevelPermissionTagConfiguration: record<Status: record, TagRules: record, TagRuleConfigurations: record>, ColumnLevelPermissionRules: record, DataSetUsageConfiguration: record<DisableUseAsDirectQuerySource: record, DisableUseAsImportedSource: record>>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
export def "accounts-data-sets update" [
  aws_account_id: string
  data_set_id: string
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
  name: string # The display name for the dataset.
  physical_table_map: record # Declares the physical tables that are available in the underlying data sources.
  --logical-table-map: record # Configures the combination and transformation of the data from the physical tables.
  import_mode: string@import-mode-completer # Indicates whether you want to import the data into SPICE.
  --column-groups: list # Groupings of columns that work together in certain Amazon QuickSight features. Currently, only geospatial hierarchy is supported. — item shape: {GeoSpatialColumnGroup?: any}
  --field-folders: record # The folder that contains fields and nested subfolders for your dataset.
  --row-level-permission-data-set: record # Information about a dataset that contains permissions for row-level security (RLS). The permissions dataset maps fields to users or groups. For more information, see Using Row-Level Security (RLS) to Restrict Access to a Dataset (https://docs.aws.amazon.com/quicksight/latest/user/restrict-access-to-a-data-set-using-row-level-security.html) in the Amazon QuickSight User Guide. The option to deny permissions by setting PermissionPolicy to DENY_ACCESS is not supported for new RLS datasets. — shape: {Namespace?: any, Arn?: any, PermissionPolicy?: any, FormatVersion?: any, Status?: any}
  --row-level-permission-tag-configuration: record # The configuration of tags on a dataset to set row-level security. — shape: {Status?: any, TagRules?: any, TagRuleConfigurations?: any}
  --column-level-permission-rules: list # A set of one or more definitions of a ColumnLevelPermissionRule (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_ColumnLevelPermissionRule.html) . — item shape: {Principals?: any, ColumnNames?: any}
  --data-set-usage-configuration: record # The usage configuration to apply to child datasets that reference this dataset as a source. — shape: {DisableUseAsDirectQuerySource?: any, DisableUseAsImportedSource?: any}
]: any -> record<Arn: record, DataSetId: record, IngestionArn: record, IngestionId: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}"))
  let req_body = {"Name": $name, "PhysicalTableMap": $physical_table_map, "LogicalTableMap": $logical_table_map, "ImportMode": $import_mode, "ColumnGroups": $column_groups, "FieldFolders": $field_folders, "RowLevelPermissionDataSet": $row_level_permission_data_set, "RowLevelPermissionTagConfiguration": $row_level_permission_tag_configuration, "ColumnLevelPermissionRules": $column_level_permission_rules, "DataSetUsageConfiguration": $data_set_usage_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the dataset refresh properties of the dataset.
#
# DELETE /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties
# operationId: DeleteDataSetRefreshProperties
export def "accounts-data-sets-refresh-properties delete" [
  aws_account_id: string
  data_set_id: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/refresh-properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes the refresh properties of a dataset.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties
# operationId: DescribeDataSetRefreshProperties
export def "accounts-data-sets-refresh-properties get" [
  aws_account_id: string
  data_set_id: string
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
]: nothing -> record<RequestId: record, Status: record, DataSetRefreshProperties: record<RefreshConfiguration: record<IncrementalRefresh: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/refresh-properties"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates or updates the dataset refresh properties for the dataset.
#
# PUT /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties
# operationId: PutDataSetRefreshProperties
# --DataSetRefreshProperties shape: {RefreshConfiguration?: any}
export def "accounts-data-sets-refresh-properties update" [
  aws_account_id: string
  data_set_id: string
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
  data_set_refresh_properties: record # The refresh properties of a dataset. — shape: {RefreshConfiguration?: any}
]: any -> record<RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/refresh-properties"))
  let req_body = {"DataSetRefreshProperties": $data_set_refresh_properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the data source permanently. This operation breaks all the datasets that reference the deleted data source.
#
# DELETE /accounts/{AwsAccountId}/data-sources/{DataSourceId}
# operationId: DeleteDataSource
export def "accounts-data-sources delete" [
  aws_account_id: string
  data_source_id: string
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
]: nothing -> record<Arn: record, DataSourceId: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_source_id: (encode-path-segment $data_source_id)} | format pattern "/accounts/{aws_account_id}/data-sources/{data_source_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes a data source.
#
# GET /accounts/{AwsAccountId}/data-sources/{DataSourceId}
# operationId: DescribeDataSource
export def "accounts-data-sources get" [
  aws_account_id: string
  data_source_id: string
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
]: nothing -> record<DataSource: record<Arn: record, DataSourceId: record, Name: record, Type: record, Status: record, CreatedTime: record, LastUpdatedTime: record, DataSourceParameters: record<AmazonElasticsearchParameters: record, AthenaParameters: record, AuroraParameters: record, AuroraPostgreSqlParameters: record, AwsIotAnalyticsParameters: record, JiraParameters: record, MariaDbParameters: record, MySqlParameters: record, OracleParameters: record, PostgreSqlParameters: record, PrestoParameters: record, RdsParameters: record, RedshiftParameters: record, S3Parameters: record, ServiceNowParameters: record, SnowflakeParameters: record, SparkParameters: record, SqlServerParameters: record, TeradataParameters: record, TwitterParameters: record, AmazonOpenSearchParameters: record, ExasolParameters: record, DatabricksParameters: record>, AlternateDataSourceParameters: record, VpcConnectionProperties: record<VpcConnectionArn: record>, SslProperties: record<DisableSsl: record>, ErrorInfo: record<Type: record, Message: record>, SecretArn: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_source_id: (encode-path-segment $data_source_id)} | format pattern "/accounts/{aws_account_id}/data-sources/{data_source_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a data source.
#
# PUT /accounts/{AwsAccountId}/data-sources/{DataSourceId}
# operationId: UpdateDataSource
# --DataSourceParameters shape: {AmazonElasticsearchParameters?: any, AthenaParameters?: any, AuroraParameters?: any, AuroraPostgreSqlParameters?: any, AwsIotAnalyticsParameters?: any, JiraParameters?: any, MariaDbParameters?: any, MySqlParameters?: any, OracleParameters?: any, PostgreSqlParameters?: any, PrestoParameters?: any, RdsParameters?: any, RedshiftParameters?: any, S3Parameters?: any, ServiceNowParameters?: any, SnowflakeParameters?: any, SparkParameters?: any, SqlServerParameters?: any, TeradataParameters?: any, ... (4 more fields)}
# --Credentials shape: {CredentialPair?: any, CopySourceArn?: any, SecretArn?: any}
# --VpcConnectionProperties shape: {VpcConnectionArn?: any}
# --SslProperties shape: {DisableSsl?: any}
export def "accounts-data-sources update" [
  aws_account_id: string
  data_source_id: string
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
  name: string # A display name for the data source.
  --data-source-parameters: record # The parameters that Amazon QuickSight uses to connect to your underlying data source. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {AmazonElasticsearchParameters?: any, AthenaParameters?: any, AuroraParameters?: any, AuroraPostgreSqlParameters?: any, AwsIotAnalyticsParameters?: any, JiraParameters?: any, MariaDbParameters?: any, MySqlParameters?: any, OracleParameters?: any, PostgreSqlParameters?: any, PrestoParameters?: any, RdsParameters?: any, RedshiftParameters?: any, S3Parameters?: any, ServiceNowParameters?: any, SnowflakeParameters?: any, SparkParameters?: any, SqlServerParameters?: any, TeradataParameters?: any, ... (4 more fields)}
  --credentials: record # Data source credentials. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {CredentialPair?: any, CopySourceArn?: any, SecretArn?: any}
  --vpc-connection-properties: record # VPC connection properties. — shape: {VpcConnectionArn?: any}
  --ssl-properties: record # Secure Socket Layer (SSL) properties that apply when Amazon QuickSight connects to your underlying data source. — shape: {DisableSsl?: any}
]: any -> record<Arn: record, DataSourceId: record, UpdateStatus: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_source_id: (encode-path-segment $data_source_id)} | format pattern "/accounts/{aws_account_id}/data-sources/{data_source_id}"))
  let req_body = {"Name": $name, "DataSourceParameters": $data_source_parameters, "Credentials": $credentials, "VpcConnectionProperties": $vpc_connection_properties, "SslProperties": $ssl_properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Removes a user group from Amazon QuickSight.
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}
# operationId: DeleteGroup
export def "accounts-namespaces-groups delete" [
  aws_account_id: string
  namespace: string
  group_name: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), group_name: (encode-path-segment $group_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/groups/{group_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN).
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}
# operationId: DescribeGroup
export def "accounts-namespaces-groups get" [
  aws_account_id: string
  namespace: string
  group_name: string
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
]: nothing -> record<Group: record<Arn: record, GroupName: record, Description: record, PrincipalId: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), group_name: (encode-path-segment $group_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/groups/{group_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Changes a group description.
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}
# operationId: UpdateGroup
export def "accounts-namespaces-groups update" [
  aws_account_id: string
  namespace: string
  group_name: string
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
  --description: string # The description for the group that you want to update.
]: any -> record<Group: record<Arn: record, GroupName: record, Description: record, PrincipalId: record>, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), group_name: (encode-path-segment $group_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/groups/{group_name}"))
  let req_body = {"Description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes an existing IAM policy assignment.
#
# DELETE /accounts/{AwsAccountId}/namespace/{Namespace}/iam-policy-assignments/{AssignmentName}
# operationId: DeleteIAMPolicyAssignment
export def "accounts-namespace-iam-policy-assignments delete" [
  aws_account_id: string
  namespace: string
  assignment_name: string
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
]: nothing -> record<AssignmentName: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), assignment_name: (encode-path-segment $assignment_name)} | format pattern "/accounts/{aws_account_id}/namespace/{namespace}/iam-policy-assignments/{assignment_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a namespace and the users and groups that are associated with the namespace. This is an asynchronous process. Assets including dashboards, analyses, datasets and data sources are not deleted. To delete these assets, you use the API operations for the relevant asset.
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}
# operationId: DeleteNamespace
export def "accounts-namespaces delete" [
  aws_account_id: string
  namespace: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes the current namespace.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}
# operationId: DescribeNamespace
export def "accounts-namespaces get" [
  aws_account_id: string
  namespace: string
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
]: nothing -> record<Namespace: record<Name: record, Arn: record, CapacityRegion: record, CreationStatus: record, IdentityStore: record, NamespaceError: record<Type: record, Message: record>>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a refresh schedule from a dataset.
#
# DELETE /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules/{ScheduleId}
# operationId: DeleteRefreshSchedule
export def "accounts-data-sets-refresh-schedules delete" [
  aws_account_id: string
  data_set_id: string
  schedule_id: string
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
]: nothing -> record<Status: record, RequestId: record, ScheduleId: record, Arn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id), schedule_id: (encode-path-segment $schedule_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/refresh-schedules/{schedule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Provides a summary of a refresh schedule.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules/{ScheduleId}
# operationId: DescribeRefreshSchedule
export def "accounts-data-sets-refresh-schedules get" [
  aws_account_id: string
  data_set_id: string
  schedule_id: string
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
]: nothing -> record<RefreshSchedule: record<ScheduleId: record, ScheduleFrequency: record<Interval: record, RefreshOnDay: record, Timezone: record, TimeOfTheDay: record>, StartAfterDateTime: record, RefreshType: record, Arn: record>, Status: record, RequestId: record, Arn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id), schedule_id: (encode-path-segment $schedule_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/refresh-schedules/{schedule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes the Amazon QuickSight user that is associated with the identity of the IAM user or role that's making the call. The IAM user isn't deleted as a result of this call.
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}
# operationId: DeleteUser
export def "accounts-namespaces-users delete" [
  aws_account_id: string
  namespace: string
  user_name: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), user_name: (encode-path-segment $user_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/users/{user_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns information about a user, given the user name.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}
# operationId: DescribeUser
export def "accounts-namespaces-users get" [
  aws_account_id: string
  namespace: string
  user_name: string
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
]: nothing -> record<User: record<Arn: record, UserName: record, Email: record, Role: record, IdentityType: record, Active: record, PrincipalId: record, CustomPermissionsName: record, ExternalLoginFederationProviderType: record, ExternalLoginFederationProviderUrl: record, ExternalLoginId: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), user_name: (encode-path-segment $user_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/users/{user_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an Amazon QuickSight user.
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}
# operationId: UpdateUser
export def "accounts-namespaces-users update" [
  aws_account_id: string
  namespace: string
  user_name: string
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
  email: string # The email address of the user that you want to update.
  role: string@role-completer # The Amazon QuickSight role of the user. The role can be one of the following default security cohorts: READER: A user who has read-only access to dashboards. AUTHOR: A user who can create data sources, datasets, analyses, and dashboards. ADMIN: A user who is an author, who can also manage Amazon QuickSight settings. The name of the Amazon QuickSight role is invisible to the user except for the console screens dealing with permissions.
  --custom-permissions-name: string # (Enterprise edition only) The name of the custom permissions profile that you want to assign to this user. Customized permissions allows you to control a user's access by restricting access the following operations: Create and update data sources Create and update datasets Create and update email reports Subscribe to email reports A set of custom permissions includes any combination of these restrictions. Currently, you need to create the profile names for custom permission sets by using the Amazon QuickSight console. Then, you use the RegisterUser API operation to assign the named set of permissions to a Amazon QuickSight user. Amazon QuickSight custom permissions are applied through IAM policies. Therefore, they override the permissions typically granted by assigning Amazon QuickSight users to one of the default security cohorts in Amazon QuickSight (admin, author, reader). This feature is available only to Amazon QuickSight Enterprise edition subscriptions.
  --unapply-custom-permissions: oneof<nothing, bool> # A flag that you use to indicate that you want to remove all custom permissions from this user. Using this parameter resets the user to the state it was in before a custom permissions profile was applied. This parameter defaults to NULL and it doesn't accept any other value.
  --external-login-federation-provider-type: string # The type of supported external login provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. The type of supported external login provider can be one of the following. COGNITO: Amazon Cognito. The provider URL is cognito-identity.amazonaws.com. When choosing the COGNITO provider type, don’t use the "CustomFederationProviderUrl" parameter which is only needed when the external provider is custom. CUSTOM_OIDC: Custom OpenID Connect (OIDC) provider. When choosing CUSTOM_OIDC type, use the CustomFederationProviderUrl parameter to provide the custom OIDC provider URL. NONE: This clears all the previously saved external login information for a user. Use the DescribeUser (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeUser.html) API operation to check the external login information.
  --custom-federation-provider-url: string # The URL of the custom OpenID Connect (OIDC) provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. This parameter should only be used when ExternalLoginFederationProviderType parameter is set to CUSTOM_OIDC.
  --external-login-id: string # The identity ID for a user in the external login provider.
]: any -> record<User: record<Arn: record, UserName: record, Email: record, Role: record, IdentityType: record, Active: record, PrincipalId: record, CustomPermissionsName: record, ExternalLoginFederationProviderType: record, ExternalLoginFederationProviderUrl: record, ExternalLoginId: record>, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), user_name: (encode-path-segment $user_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/users/{user_name}"))
  let req_body = {"Email": $email, "Role": $role, "CustomPermissionsName": $custom_permissions_name, "UnapplyCustomPermissions": $unapply_custom_permissions, "ExternalLoginFederationProviderType": $external_login_federation_provider_type, "CustomFederationProviderUrl": $custom_federation_provider_url, "ExternalLoginId": $external_login_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a user identified by its principal ID.
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}
# operationId: DeleteUserByPrincipalId
export def "accounts-namespaces-user-principals delete" [
  aws_account_id: string
  namespace: string
  principal_id: string
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
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), principal_id: (encode-path-segment $principal_id)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/user-principals/{principal_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes the settings that were used when your Amazon QuickSight subscription was first created in this Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/settings
# operationId: DescribeAccountSettings
export def "accounts-settings get" [
  aws_account_id: string
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
]: nothing -> record<AccountSettings: record<AccountName: record, Edition: record, DefaultNamespace: record, NotificationEmail: record, PublicSharingEnabled: record, TerminationProtectionEnabled: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the Amazon QuickSight settings in your Amazon Web Services account.
#
# PUT /accounts/{AwsAccountId}/settings
# operationId: UpdateAccountSettings
export def "accounts-settings update" [
  aws_account_id: string
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
  default_namespace: string # The default namespace for this Amazon Web Services account. Currently, the default is default. IAM users that register for the first time with Amazon QuickSight provide an email address that becomes associated with the default namespace.
  --notification-email: string # The email address that you want Amazon QuickSight to send notifications to regarding your Amazon Web Services account or Amazon QuickSight subscription.
  --termination-protection-enabled: oneof<nothing, bool> # A boolean value that determines whether or not an Amazon QuickSight account can be deleted. A True value doesn't allow the account to be deleted and results in an error message if a user tries to make a DeleteAccountSubscription request. A False value will allow the account to be deleted.
]: any -> record<RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/settings"))
  let req_body = {"DefaultNamespace": $default_namespace, "NotificationEmail": $notification_email, "TerminationProtectionEnabled": $termination_protection_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provides a detailed description of the definition of an analysis. If you do not need to know details about the content of an Analysis, for instance if you are trying to check the status of a recently created or updated Analysis, use the DescribeAnalysis (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeAnalysis.html) instead.
#
# GET /accounts/{AwsAccountId}/analyses/{AnalysisId}/definition
# operationId: DescribeAnalysisDefinition
export def "accounts-analyses-definition get-analysis" [
  aws_account_id: string
  analysis_id: string
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
]: nothing -> record<AnalysisId: record, Name: record, Errors: record, ResourceStatus: record, ThemeArn: record, Definition: record<DataSetIdentifierDeclarations: record, Sheets: record, CalculatedFields: record, ParameterDeclarations: record, FilterGroups: record, ColumnConfigurations: record, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), analysis_id: (encode-path-segment $analysis_id)} | format pattern "/accounts/{aws_account_id}/analyses/{analysis_id}/definition"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Provides the read and write permissions for an analysis.
#
# GET /accounts/{AwsAccountId}/analyses/{AnalysisId}/permissions
# operationId: DescribeAnalysisPermissions
export def "accounts-analyses-permissions get-analysis" [
  aws_account_id: string
  analysis_id: string
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
]: nothing -> record<AnalysisId: record, AnalysisArn: record, Permissions: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), analysis_id: (encode-path-segment $analysis_id)} | format pattern "/accounts/{aws_account_id}/analyses/{analysis_id}/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the read and write permissions for an analysis.
#
# PUT /accounts/{AwsAccountId}/analyses/{AnalysisId}/permissions
# operationId: UpdateAnalysisPermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-analyses-permissions update-analysis" [
  aws_account_id: string
  analysis_id: string
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
  --grant-permissions: list # A structure that describes the permissions to add and the principal to add them to. — item shape: {Principal: any, Actions: any}
  --revoke-permissions: list # A structure that describes the permissions to remove and the principal to remove them from. — item shape: {Principal: any, Actions: any}
]: any -> record<AnalysisArn: record, AnalysisId: record, Permissions: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), analysis_id: (encode-path-segment $analysis_id)} | format pattern "/accounts/{aws_account_id}/analyses/{analysis_id}/permissions"))
  let req_body = {"GrantPermissions": $grant_permissions, "RevokePermissions": $revoke_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provides a detailed description of the definition of a dashboard. If you do not need to know details about the content of a dashboard, for instance if you are trying to check the status of a recently created or updated dashboard, use the DescribeDashboard (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeDashboard.html) instead.
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/definition
# operationId: DescribeDashboardDefinition
export def "accounts-dashboards-definition get" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described.
  --alias-name: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DashboardId: record, Errors: record, Name: record, ResourceStatus: record, ThemeArn: record, Definition: record<DataSetIdentifierDeclarations: record, Sheets: record, CalculatedFields: record, ParameterDeclarations: record, FilterGroups: record, ColumnConfigurations: record, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: record, RequestId: record, DashboardPublishOptions: record<AdHocFilteringOption: record<AvailabilityStatus: record>, ExportToCSVOption: record<AvailabilityStatus: record>, SheetControlsOption: record<VisibilityState: record>, VisualPublishOptions: record<ExportHiddenFieldsOption: record>, SheetLayoutElementMaximizationOption: record<AvailabilityStatus: record>, VisualMenuOption: record<AvailabilityStatus: record>, VisualAxisSortOption: record<AvailabilityStatus: record>, ExportWithHiddenFieldsOption: record<AvailabilityStatus: record>, DataPointDrillUpDownOption: record<AvailabilityStatus: record>, DataPointMenuLabelOption: record<AvailabilityStatus: record>, DataPointTooltipOption: record<AvailabilityStatus: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar") (serialize-qp "alias-name" $alias_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/accounts/{aws_account_id}/dashboards/{dashboard_id}/definition") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes read and write permissions for a dashboard.
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions
# operationId: DescribeDashboardPermissions
export def "accounts-dashboards-permissions get" [
  aws_account_id: string
  dashboard_id: string
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
]: nothing -> record<DashboardId: record, DashboardArn: record, Permissions: record, Status: record, RequestId: record, LinkSharingConfiguration: record<Permissions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/accounts/{aws_account_id}/dashboards/{dashboard_id}/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates read and write permissions on a dashboard.
#
# PUT /accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions
# operationId: UpdateDashboardPermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
# --GrantLinkPermissions item shape: {Principal: any, Actions: any}
# --RevokeLinkPermissions item shape: {Principal: any, Actions: any}
export def "accounts-dashboards-permissions update" [
  aws_account_id: string
  dashboard_id: string
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
  --grant-permissions: list # The permissions that you want to grant on this resource. — item shape: {Principal: any, Actions: any}
  --revoke-permissions: list # The permissions that you want to revoke from this resource. — item shape: {Principal: any, Actions: any}
  --grant-link-permissions: list # Grants link permissions to all users in a defined namespace. — item shape: {Principal: any, Actions: any}
  --revoke-link-permissions: list # Revokes link permissions from all users in a defined namespace. — item shape: {Principal: any, Actions: any}
]: any -> record<DashboardArn: record, DashboardId: record, Permissions: record, RequestId: record, Status: record, LinkSharingConfiguration: record<Permissions: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/accounts/{aws_account_id}/dashboards/{dashboard_id}/permissions"))
  let req_body = {"GrantPermissions": $grant_permissions, "RevokePermissions": $revoke_permissions, "GrantLinkPermissions": $grant_link_permissions, "RevokeLinkPermissions": $revoke_link_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes the permissions on a dataset. The permissions resource is arn:aws:quicksight:region:aws-account-id:dataset/data-set-id.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions
# operationId: DescribeDataSetPermissions
export def "accounts-data-sets-permissions get" [
  aws_account_id: string
  data_set_id: string
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
]: nothing -> record<DataSetArn: record, DataSetId: record, Permissions: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the permissions on a dataset. The permissions resource is arn:aws:quicksight:region:aws-account-id:dataset/data-set-id.
#
# POST /accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions
# operationId: UpdateDataSetPermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-data-sets-permissions update" [
  aws_account_id: string
  data_set_id: string
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
  --grant-permissions: list # The resource permissions that you want to grant to the dataset. — item shape: {Principal: any, Actions: any}
  --revoke-permissions: list # The resource permissions that you want to revoke from the dataset. — item shape: {Principal: any, Actions: any}
]: any -> record<DataSetArn: record, DataSetId: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/permissions"))
  let req_body = {"GrantPermissions": $grant_permissions, "RevokePermissions": $revoke_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes the resource permissions for a data source.
#
# GET /accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions
# operationId: DescribeDataSourcePermissions
export def "accounts-data-sources-permissions get" [
  aws_account_id: string
  data_source_id: string
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
]: nothing -> record<DataSourceArn: record, DataSourceId: record, Permissions: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_source_id: (encode-path-segment $data_source_id)} | format pattern "/accounts/{aws_account_id}/data-sources/{data_source_id}/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the permissions to a data source.
#
# POST /accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions
# operationId: UpdateDataSourcePermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-data-sources-permissions update" [
  aws_account_id: string
  data_source_id: string
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
  --grant-permissions: list # A list of resource permissions that you want to grant on the data source. — item shape: {Principal: any, Actions: any}
  --revoke-permissions: list # A list of resource permissions that you want to revoke on the data source. — item shape: {Principal: any, Actions: any}
]: any -> record<DataSourceArn: record, DataSourceId: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_source_id: (encode-path-segment $data_source_id)} | format pattern "/accounts/{aws_account_id}/data-sources/{data_source_id}/permissions"))
  let req_body = {"GrantPermissions": $grant_permissions, "RevokePermissions": $revoke_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes permissions for a folder.
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}/permissions
# operationId: DescribeFolderPermissions
export def "accounts-folders-permissions get" [
  aws_account_id: string
  folder_id: string
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
]: nothing -> record<Status: record, FolderId: record, Arn: record, Permissions: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/accounts/{aws_account_id}/folders/{folder_id}/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates permissions of a folder.
#
# PUT /accounts/{AwsAccountId}/folders/{FolderId}/permissions
# operationId: UpdateFolderPermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-folders-permissions update" [
  aws_account_id: string
  folder_id: string
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
  --grant-permissions: list # The permissions that you want to grant on a resource. — item shape: {Principal: any, Actions: any}
  --revoke-permissions: list # The permissions that you want to revoke from a resource. — item shape: {Principal: any, Actions: any}
]: any -> record<Status: record, Arn: record, FolderId: record, Permissions: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/accounts/{aws_account_id}/folders/{folder_id}/permissions"))
  let req_body = {"GrantPermissions": $grant_permissions, "RevokePermissions": $revoke_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes the folder resolved permissions. Permissions consists of both folder direct permissions and the inherited permissions from the ancestor folders.
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}/resolved-permissions
# operationId: DescribeFolderResolvedPermissions
export def "accounts-folders-resolved-permissions get" [
  aws_account_id: string
  folder_id: string
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
]: nothing -> record<Status: record, FolderId: record, Arn: record, Permissions: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/accounts/{aws_account_id}/folders/{folder_id}/resolved-permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes an existing IAM policy assignment, as specified by the assignment name.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}
# operationId: DescribeIAMPolicyAssignment
export def "accounts-namespaces-iam-policy-assignments get" [
  aws_account_id: string
  namespace: string
  assignment_name: string
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
]: nothing -> record<IAMPolicyAssignment: record<AwsAccountId: record, AssignmentId: record, AssignmentName: record, PolicyArn: record, Identities: record, AssignmentStatus: record>, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), assignment_name: (encode-path-segment $assignment_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/iam-policy-assignments/{assignment_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request. This overwrites all of the users included in Identities.
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}
# operationId: UpdateIAMPolicyAssignment
export def "accounts-namespaces-iam-policy-assignments update" [
  aws_account_id: string
  namespace: string
  assignment_name: string
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
  --assignment-status: string@assignment-status-completer # The status of the assignment. Possible values are as follows: ENABLED - Anything specified in this assignment is used when creating the data source. DISABLED - This assignment isn't used when creating the data source. DRAFT - This assignment is an unfinished draft and isn't used when creating the data source.
  --policy-arn: string # The ARN for the IAM policy to apply to the Amazon QuickSight users and groups specified in this assignment.
  --identities: record # The Amazon QuickSight users, groups, or both that you want to assign the policy to.
]: any -> record<AssignmentName: record, AssignmentId: record, PolicyArn: record, Identities: record, AssignmentStatus: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), assignment_name: (encode-path-segment $assignment_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/iam-policy-assignments/{assignment_name}"))
  let req_body = {"AssignmentStatus": $assignment_status, "PolicyArn": $policy_arn, "Identities": $identities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provides a summary and status of IP rules.
#
# GET /accounts/{AwsAccountId}/ip-restriction
# operationId: DescribeIpRestriction
export def "accounts-ip-restriction get" [
  aws_account_id: string
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
]: nothing -> record<AwsAccountId: record, IpRestrictionRuleMap: record, Enabled: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/ip-restriction"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the content and status of IP rules. To use this operation, you need to provide the entire map of rules. You can use the DescribeIpRestriction operation to get the current rule map.
#
# POST /accounts/{AwsAccountId}/ip-restriction
# operationId: UpdateIpRestriction
export def "accounts-ip-restriction update" [
  aws_account_id: string
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
  --ip-restriction-rule-map: record # A map that describes the updated IP rules with CIDR ranges and descriptions.
  --enabled: oneof<nothing, bool> # A value that specifies whether IP rules are turned on.
]: any -> record<AwsAccountId: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/ip-restriction"))
  let req_body = {"IpRestrictionRuleMap": $ip_restriction_rule_map, "Enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provides a detailed description of the definition of a template. If you do not need to know details about the content of a template, for instance if you are trying to check the status of a recently created or updated template, use the DescribeTemplate (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeTemplate.html) instead.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/definition
# operationId: DescribeTemplateDefinition
export def "accounts-templates-definition get" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number of the template.
  --alias-name: string # The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword $LATEST in the AliasName parameter. The keyword $PUBLISHED doesn't apply to templates.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Name: record, TemplateId: record, Errors: record, ResourceStatus: record, ThemeArn: record, Definition: record<DataSetConfigurations: record, Sheets: record, CalculatedFields: record, ParameterDeclarations: record, FilterGroups: record, ColumnConfigurations: record, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version-number" $version_number "scalar") (serialize-qp "alias-name" $alias_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}/definition") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Describes read and write permissions on a template.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/permissions
# operationId: DescribeTemplatePermissions
export def "accounts-templates-permissions get" [
  aws_account_id: string
  template_id: string
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
]: nothing -> record<TemplateId: record, TemplateArn: record, Permissions: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the resource permissions for a template.
#
# PUT /accounts/{AwsAccountId}/templates/{TemplateId}/permissions
# operationId: UpdateTemplatePermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-templates-permissions update" [
  aws_account_id: string
  template_id: string
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
  --grant-permissions: list # A list of resource permissions to be granted on the template. — item shape: {Principal: any, Actions: any}
  --revoke-permissions: list # A list of resource permissions to be revoked from the template. — item shape: {Principal: any, Actions: any}
]: any -> record<TemplateId: record, TemplateArn: record, Permissions: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}/permissions"))
  let req_body = {"GrantPermissions": $grant_permissions, "RevokePermissions": $revoke_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes the read and write permissions for a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/permissions
# operationId: DescribeThemePermissions
export def "accounts-themes-permissions get" [
  aws_account_id: string
  theme_id: string
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
]: nothing -> record<ThemeId: record, ThemeArn: record, Permissions: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the resource permissions for a theme. Permissions apply to the action to grant or revoke permissions on, for example "quicksight:DescribeTheme". Theme permissions apply in groupings. Valid groupings include the following for the three levels of permissions, which are user, owner, or no permissions: User "quicksight:DescribeTheme" "quicksight:DescribeThemeAlias" "quicksight:ListThemeAliases" "quicksight:ListThemeVersions" Owner "quicksight:DescribeTheme" "quicksight:DescribeThemeAlias" "quicksight:ListThemeAliases" "quicksight:ListThemeVersions" "quicksight:DeleteTheme" "quicksight:UpdateTheme" "quicksight:CreateThemeAlias" "quicksight:DeleteThemeAlias" "quicksight:UpdateThemeAlias" "quicksight:UpdateThemePermissions" "quicksight:DescribeThemePermissions" To specify no permissions, omit the permissions list.
#
# PUT /accounts/{AwsAccountId}/themes/{ThemeId}/permissions
# operationId: UpdateThemePermissions
# --GrantPermissions item shape: {Principal: any, Actions: any}
# --RevokePermissions item shape: {Principal: any, Actions: any}
export def "accounts-themes-permissions update" [
  aws_account_id: string
  theme_id: string
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
  --grant-permissions: list # A list of resource permissions to be granted for the theme. — item shape: {Principal: any, Actions: any}
  --revoke-permissions: list # A list of resource permissions to be revoked from the theme. — item shape: {Principal: any, Actions: any}
]: any -> record<ThemeId: record, ThemeArn: record, Permissions: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}/permissions"))
  let req_body = {"GrantPermissions": $grant_permissions, "RevokePermissions": $revoke_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Generates an embed URL that you can use to embed an Amazon QuickSight dashboard or visual in your website, without having to register any reader users. Before you use this action, make sure that you have configured the dashboards and permissions. The following rules apply to the generated URL: It contains a temporary bearer token. It is valid for 5 minutes after it is generated. Once redeemed within this period, it cannot be re-used again. The URL validity period should not be confused with the actual session lifetime that can be customized using the SessionLifetimeInMinutes (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_GenerateEmbedUrlForAnonymousUser.html#QS-GenerateEmbedUrlForAnonymousUser-request-SessionLifetimeInMinutes) parameter. The resulting user session is valid for 15 minutes (minimum) to 10 hours (maximum). The default session duration is 10 hours. You are charged only when the URL is used or there is interaction with Amazon QuickSight. For more information, see Embedded Analytics (https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics.html) in the Amazon QuickSight User Guide. For more information about the high-level steps for embedding and for an interactive demo of the ways you can customize embedding, visit the Amazon QuickSight Developer Portal (https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-portal.html).
#
# POST /accounts/{AwsAccountId}/embed-url/anonymous-user
# operationId: GenerateEmbedUrlForAnonymousUser
# --SessionTags item shape: {Key: any, Value: any}
# --ExperienceConfiguration shape: {Dashboard?: any, DashboardVisual?: any, QSearchBar?: any}
export def "accounts-embed-url-anonymous-user generate" [
  aws_account_id: string
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
  --session-lifetime-in-minutes: int # How many minutes the session is valid. The session lifetime must be in [15-600] minutes range.
  namespace: string # The Amazon QuickSight namespace that the anonymous user virtually belongs to. If you are not using an Amazon QuickSight custom namespace, set this to default.
  --session-tags: list # The session tags used for row-level security. Before you use this parameter, make sure that you have configured the relevant datasets using the DataSet$RowLevelPermissionTagConfiguration parameter so that session tags can be used to provide row-level security. These are not the tags used for the Amazon Web Services resource tagging feature. For more information, see Using Row-Level Security (RLS) with Tags (https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-rls-tags.html)in the Amazon QuickSight User Guide. — item shape: {Key: any, Value: any}
  authorized_resource_arns: list<string> # The Amazon Resource Names (ARNs) for the Amazon QuickSight resources that the user is authorized to access during the lifetime of the session. If you choose Dashboard embedding experience, pass the list of dashboard ARNs in the account that you want the user to be able to view. Currently, you can pass up to 25 dashboard ARNs in each API call.
  experience_configuration: record # The type of experience you want to embed. For anonymous users, you can embed Amazon QuickSight dashboards. — shape: {Dashboard?: any, DashboardVisual?: any, QSearchBar?: any}
  --allowed-domains: list<string> # The domains that you want to add to the allow list for access to the generated URL that is then embedded. This optional parameter overrides the static domains that are configured in the Manage QuickSight menu in the Amazon QuickSight console. Instead, it allows only the domains that you include in this parameter. You can list up to three domains or subdomains in each API call. To include all subdomains under a specific domain to the allow list, use *. For example, https://*.sapp.amazon.com includes all subdomains under https://sapp.amazon.com.
]: any -> record<EmbedUrl: record, Status: record, RequestId: record, AnonymousUserArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/embed-url/anonymous-user"))
  let req_body = {"SessionLifetimeInMinutes": $session_lifetime_in_minutes, "Namespace": $namespace, "SessionTags": $session_tags, "AuthorizedResourceArns": $authorized_resource_arns, "ExperienceConfiguration": $experience_configuration, "AllowedDomains": $allowed_domains} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Generates an embed URL that you can use to embed an Amazon QuickSight experience in your website. This action can be used for any type of user registered in an Amazon QuickSight account. Before you use this action, make sure that you have configured the relevant Amazon QuickSight resource and permissions. The following rules apply to the generated URL: It contains a temporary bearer token. It is valid for 5 minutes after it is generated. Once redeemed within this period, it cannot be re-used again. The URL validity period should not be confused with the actual session lifetime that can be customized using the SessionLifetimeInMinutes (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_GenerateEmbedUrlForRegisteredUser.html#QS-GenerateEmbedUrlForRegisteredUser-request-SessionLifetimeInMinutes) parameter. The resulting user session is valid for 15 minutes (minimum) to 10 hours (maximum). The default session duration is 10 hours. You are charged only when the URL is used or there is interaction with Amazon QuickSight. For more information, see Embedded Analytics (https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics.html) in the Amazon QuickSight User Guide. For more information about the high-level steps for embedding and for an interactive demo of the ways you can customize embedding, visit the Amazon QuickSight Developer Portal (https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-portal.html).
#
# POST /accounts/{AwsAccountId}/embed-url/registered-user
# operationId: GenerateEmbedUrlForRegisteredUser
# --ExperienceConfiguration shape: {Dashboard?: any, QuickSightConsole?: any, QSearchBar?: any, DashboardVisual?: any}
export def "accounts-embed-url-registered-user generate" [
  aws_account_id: string
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
  --session-lifetime-in-minutes: int # How many minutes the session is valid. The session lifetime must be in [15-600] minutes range.
  user_arn: string # The Amazon Resource Name for the registered user.
  experience_configuration: record # The type of experience you want to embed. For registered users, you can embed Amazon QuickSight dashboards or the Amazon QuickSight console. Exactly one of the experience configurations is required. You can choose Dashboard or QuickSightConsole. You cannot choose more than one experience configuration. — shape: {Dashboard?: any, QuickSightConsole?: any, QSearchBar?: any, DashboardVisual?: any}
  --allowed-domains: list<string> # The domains that you want to add to the allow list for access to the generated URL that is then embedded. This optional parameter overrides the static domains that are configured in the Manage QuickSight menu in the Amazon QuickSight console. Instead, it allows only the domains that you include in this parameter. You can list up to three domains or subdomains in each API call. To include all subdomains under a specific domain to the allow list, use *. For example, https://*.sapp.amazon.com includes all subdomains under https://sapp.amazon.com.
]: any -> record<EmbedUrl: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/embed-url/registered-user"))
  let req_body = {"SessionLifetimeInMinutes": $session_lifetime_in_minutes, "UserArn": $user_arn, "ExperienceConfiguration": $experience_configuration, "AllowedDomains": $allowed_domains} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Generates a temporary session URL and authorization code(bearer token) that you can use to embed an Amazon QuickSight read-only dashboard in your website or application. Before you use this command, make sure that you have configured the dashboards and permissions. Currently, you can use GetDashboardEmbedURL only from the server, not from the user's browser. The following rules apply to the generated URL: They must be used together. They can be used one time only. They are valid for 5 minutes after you run this command. You are charged only when the URL is used or there is interaction with Amazon QuickSight. The resulting user session is valid for 15 minutes (default) up to 10 hours (maximum). You can use the optional SessionLifetimeInMinutes parameter to customize session duration. For more information, see Embedding Analytics Using GetDashboardEmbedUrl (https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics-deprecated.html) in the Amazon QuickSight User Guide. For more information about the high-level steps for embedding and for an interactive demo of the ways you can customize embedding, visit the Amazon QuickSight Developer Portal (https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-portal.html).
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url#creds-type
# operationId: GetDashboardEmbedUrl
export def "accounts-dashboards-embed-urlcreds-type get-url" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --creds-type: string@creds-type-completer # The authentication method that the user uses to sign in.
  --session-lifetime: int # How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  --undo-redo-disabled: oneof<nothing, bool> # Remove the undo/redo button on the embedded dashboard. The default is FALSE, which enables the undo/redo button.
  --reset-disabled: oneof<nothing, bool> # Remove the reset button on the embedded dashboard. The default is FALSE, which enables the reset button.
  --state-persistence-enabled: oneof<nothing, bool> # Adds persistence of state for the user session in an embedded dashboard. Persistence applies to the sheet and the parameter settings. These are control settings that the dashboard subscriber (Amazon QuickSight reader) chooses while viewing the dashboard. If this is set to TRUE, the settings are the same when the subscriber reopens the same dashboard URL. The state is stored in Amazon QuickSight, not in a browser cookie. If this is set to FALSE, the state of the user session is not persisted. The default is FALSE.
  --user-arn: string # The Amazon QuickSight user's Amazon Resource Name (ARN), for use with QUICKSIGHT identity type. You can use this for any Amazon QuickSight users in your account (readers, authors, or admins) authenticated as one of the following: Active Directory (AD) users or group members Invited nonfederated users IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation. Omit this parameter for users in the third group – IAM users and IAM role-based sessions.
  --namespace: string # The Amazon QuickSight namespace that contains the dashboard IDs in this request. If you're not using a custom namespace, set Namespace = default.
  --additional-dashboard-ids: list # A list of one or more dashboard IDs that you want anonymous users to have tempporary access to. Currently, the IdentityType parameter must be set to ANONYMOUS because other identity types authenticate as Amazon QuickSight or IAM users. For example, if you set "--dashboard-id dash_id1 --dashboard-id dash_id2 dash_id3 identity-type ANONYMOUS", the session can access all three dashboards.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<EmbedUrl: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creds-type" $creds_type "scalar") (serialize-qp "session-lifetime" $session_lifetime "scalar") (serialize-qp "undo-redo-disabled" $undo_redo_disabled "scalar") (serialize-qp "reset-disabled" $reset_disabled "scalar") (serialize-qp "state-persistence-enabled" $state_persistence_enabled "scalar") (serialize-qp "user-arn" $user_arn "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "additional-dashboard-ids" $additional_dashboard_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/accounts/{aws_account_id}/dashboards/{dashboard_id}/embed-url#creds-type") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Generates a session URL and authorization code that you can use to embed the Amazon Amazon QuickSight console in your web server code. Use GetSessionEmbedUrl where you want to provide an authoring portal that allows users to create data sources, datasets, analyses, and dashboards. The users who access an embedded Amazon QuickSight console need belong to the author or admin security cohort. If you want to restrict permissions to some of these features, add a custom permissions profile to the user with the UpdateUser (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateUser.html) API operation. Use RegisterUser (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_RegisterUser.html) API operation to add a new user with a custom permission profile attached. For more information, see the following sections in the Amazon QuickSight User Guide: Embedding Analytics (https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics.html) Customizing Access to the Amazon QuickSight Console (https://docs.aws.amazon.com/quicksight/latest/user/customizing-permissions-to-the-quicksight-console.html)
#
# GET /accounts/{AwsAccountId}/session-embed-url
# operationId: GetSessionEmbedUrl
export def "accounts-session-embed-url get" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entry-point: string # The URL you use to access the embedded session. The entry point URL is constrained to the following paths: /start /start/analyses /start/dashboards /start/favorites /dashboards/DashboardId - where DashboardId is the actual ID key from the Amazon QuickSight console URL of the dashboard /analyses/AnalysisId - where AnalysisId is the actual ID key from the Amazon QuickSight console URL of the analysis
  --session-lifetime: int # How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  --user-arn: string # The Amazon QuickSight user's Amazon Resource Name (ARN), for use with QUICKSIGHT identity type. You can use this for any type of Amazon QuickSight users in your account (readers, authors, or admins). They need to be authenticated as one of the following: Active Directory (AD) users or group members Invited nonfederated users IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation Omit this parameter for users in the third group, IAM users and IAM role-based sessions.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<EmbedUrl: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entry-point" $entry_point "scalar") (serialize-qp "session-lifetime" $session_lifetime "scalar") (serialize-qp "user-arn" $user_arn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/session-embed-url") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists Amazon QuickSight analyses that exist in the specified Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/analyses
# operationId: ListAnalyses
export def "accounts-analyses list" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<AnalysisSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/analyses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all the versions of the dashboards in the Amazon QuickSight subscription.
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/versions
# operationId: ListDashboardVersions
export def "accounts-dashboards-versions list" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DashboardVersionSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/accounts/{aws_account_id}/dashboards/{dashboard_id}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists dashboards in an Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/dashboards
# operationId: ListDashboards
export def "accounts-dashboards list" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<DashboardSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/dashboards") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List all assets (DASHBOARD, ANALYSIS, and DATASET) in a folder.
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}/members
# operationId: ListFolderMembers
export def "accounts-folders-members list" [
  aws_account_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Status: record, FolderMemberList: record, NextToken: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/accounts/{aws_account_id}/folders/{folder_id}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all folders in an account.
#
# GET /accounts/{AwsAccountId}/folders
# operationId: ListFolders
export def "accounts-folders list" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Status: record, FolderSummaryList: record, NextToken: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/folders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists member users in a group.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members
# operationId: ListGroupMemberships
export def "accounts-namespaces-groups-members list-memberships" [
  aws_account_id: string
  namespace: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<GroupMemberList: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), group_name: (encode-path-segment $group_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/groups/{group_name}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists IAM policy assignments in the current Amazon QuickSight account.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments
# operationId: ListIAMPolicyAssignments
export def "accounts-namespaces-iam-policy-assignments list" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --assignment-status: string@assignment-status-completer # The status of the assignments.
]: any -> record<IAMPolicyAssignments: record, NextToken: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/iam-policy-assignments") $qp)
  let req_body = {"AssignmentStatus": $assignment_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/iam-policy-assignments
# operationId: ListIAMPolicyAssignmentsForUser
export def "accounts-namespaces-users-iam-policy-assignments list" [
  aws_account_id: string
  namespace: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ActiveAssignments: record, RequestId: record, NextToken: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), user_name: (encode-path-segment $user_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/users/{user_name}/iam-policy-assignments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the history of SPICE ingestions for a dataset.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions
# operationId: ListIngestions
export def "accounts-data-sets-ingestions list" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Ingestions: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), data_set_id: (encode-path-segment $data_set_id)} | format pattern "/accounts/{aws_account_id}/data-sets/{data_set_id}/ingestions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the namespaces for the specified Amazon Web Services account. This operation doesn't list deleted namespaces.
#
# GET /accounts/{AwsAccountId}/namespaces
# operationId: ListNamespaces
export def "accounts-namespaces list" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A unique pagination token that can be used in a subsequent request. You will receive a pagination token in the response body of a previous ListNameSpaces API call if there is more data that can be returned. To receive the data, make another ListNamespaces API call with the returned token to retrieve the next page of data. Each token is valid for 24 hours. If you try to make a ListNamespaces API call with an expired token, you will receive a HTTP 400 InvalidNextTokenException error.
  --max-results: int # The maximum number of results to return.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Namespaces: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/namespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the tags assigned to a resource.
#
# GET /resources/{ResourceArn}/tags
# operationId: ListTagsForResource
export def "resources-tags list" [
  resource_arn: string
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
]: nothing -> record<Tags: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/resources/{resource_arn}/tags"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Assigns one or more tags (key-value pairs) to the specified Amazon QuickSight resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the TagResource operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag. You can associate as many as 50 tags with a resource. Amazon QuickSight supports tagging on data set, data source, dashboard, and template. Tagging for Amazon QuickSight works in a similar way to tagging for other Amazon Web Services services, except for the following: You can't use tags to track costs for Amazon QuickSight. This isn't possible because you can't tag the resources that Amazon QuickSight costs are based on, for example Amazon QuickSight storage capacity (SPICE), number of users, type of users, and usage metrics. Amazon QuickSight doesn't currently support the tag editor for Resource Groups.
#
# POST /resources/{ResourceArn}/tags
# operationId: TagResource
# --Tags item shape: {Key: any, Value: any}
export def "resources-tags tag" [
  resource_arn: string
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
  tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the resource. — item shape: {Key: any, Value: any}
]: any -> record<RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/resources/{resource_arn}/tags"))
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all the aliases of a template.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/aliases
# operationId: ListTemplateAliases
export def "accounts-templates-aliases list" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-result: int # The maximum number of results to be returned per request.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TemplateAliasList: record, Status: record, RequestId: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-result" $max_result "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}/aliases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all the versions of the templates in the current Amazon QuickSight account.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/versions
# operationId: ListTemplateVersions
export def "accounts-templates-versions list" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TemplateVersionSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), template_id: (encode-path-segment $template_id)} | format pattern "/accounts/{aws_account_id}/templates/{template_id}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all the templates in the current Amazon QuickSight account.
#
# GET /accounts/{AwsAccountId}/templates
# operationId: ListTemplates
export def "accounts-templates list" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-result: int # The maximum number of results to be returned per request.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<TemplateSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-result" $max_result "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/templates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all the aliases of a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/aliases
# operationId: ListThemeAliases
export def "accounts-themes-aliases list" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-result: int # The maximum number of results to be returned per request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ThemeAliasList: record, Status: record, RequestId: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-result" $max_result "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}/aliases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all the versions of the themes in the current Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/versions
# operationId: ListThemeVersions
export def "accounts-themes-versions list" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ThemeVersionSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), theme_id: (encode-path-segment $theme_id)} | format pattern "/accounts/{aws_account_id}/themes/{theme_id}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all the themes in the current Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/themes
# operationId: ListThemes
export def "accounts-themes list" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --type: string@type-completer-1 # The type of themes that you want to list. Valid options include the following: ALL (default)- Display all existing themes. CUSTOM - Display only the themes created by people using Amazon QuickSight. QUICKSIGHT - Display only the starting themes defined by Amazon QuickSight.
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ThemeSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/themes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups
# operationId: ListUserGroups
export def "accounts-namespaces-users-groups list" [
  aws_account_id: string
  namespace: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<GroupList: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace), user_name: (encode-path-segment $user_name)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/users/{user_name}/groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a list of all of the Amazon QuickSight users belonging to this account.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users
# operationId: ListUsers
export def "accounts-namespaces-users list" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<UserList: record, NextToken: record, RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates an Amazon QuickSight user whose identity is associated with the Identity and Access Management (IAM) identity or role specified in the request. When you register a new user from the Amazon QuickSight API, Amazon QuickSight generates a registration URL. The user accesses this registration URL to create their account. Amazon QuickSight doesn't send a registration email to users who are registered from the Amazon QuickSight API. If you want new users to receive a registration email, then add those users in the Amazon QuickSight console. For more information on registering a new user in the Amazon QuickSight console, see Inviting users to access Amazon QuickSight (https://docs.aws.amazon.com/quicksight/latest/user/managing-users.html#inviting-users).
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/users
# operationId: RegisterUser
export def "accounts-namespaces-users create" [
  aws_account_id: string
  namespace: string
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
  identity_type: string@identity-type-completer # Amazon QuickSight supports several ways of managing the identity of users. This parameter accepts two values: IAM: A user whose identity maps to an existing IAM user or role. QUICKSIGHT: A user whose identity is owned and managed internally by Amazon QuickSight.
  email: string # The email address of the user that you want to register.
  user_role: string@user-role-completer # The Amazon QuickSight role for the user. The user role can be one of the following: READER: A user who has read-only access to dashboards. AUTHOR: A user who can create data sources, datasets, analyses, and dashboards. ADMIN: A user who is an author, who can also manage Amazon QuickSight settings. RESTRICTED_READER: This role isn't currently available for use. RESTRICTED_AUTHOR: This role isn't currently available for use.
  --iam-arn: string # The ARN of the IAM user or role that you are registering with Amazon QuickSight.
  --session-name: string # You need to use this parameter only when you register one or more users using an assumed IAM role. You don't need to provide the session name for other scenarios, for example when you are registering an IAM user or an Amazon QuickSight user. You can register multiple users using the same IAM role if each user has a different session name. For more information on assuming IAM roles, see assume-role (https://docs.aws.amazon.com/cli/latest/reference/sts/assume-role.html) in the CLI Reference.
  --user-name: string # The Amazon QuickSight user name that you want to create for the user you are registering.
  --custom-permissions-name: string # (Enterprise edition only) The name of the custom permissions profile that you want to assign to this user. Customized permissions allows you to control a user's access by restricting access the following operations: Create and update data sources Create and update datasets Create and update email reports Subscribe to email reports To add custom permissions to an existing user, use UpdateUser (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateUser.html) instead. A set of custom permissions includes any combination of these restrictions. Currently, you need to create the profile names for custom permission sets by using the Amazon QuickSight console. Then, you use the RegisterUser API operation to assign the named set of permissions to a Amazon QuickSight user. Amazon QuickSight custom permissions are applied through IAM policies. Therefore, they override the permissions typically granted by assigning Amazon QuickSight users to one of the default security cohorts in Amazon QuickSight (admin, author, reader). This feature is available only to Amazon QuickSight Enterprise edition subscriptions.
  --external-login-federation-provider-type: string # The type of supported external login provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. The type of supported external login provider can be one of the following. COGNITO: Amazon Cognito. The provider URL is cognito-identity.amazonaws.com. When choosing the COGNITO provider type, don’t use the "CustomFederationProviderUrl" parameter which is only needed when the external provider is custom. CUSTOM_OIDC: Custom OpenID Connect (OIDC) provider. When choosing CUSTOM_OIDC type, use the CustomFederationProviderUrl parameter to provide the custom OIDC provider URL.
  --custom-federation-provider-url: string # The URL of the custom OpenID Connect (OIDC) provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. This parameter should only be used when ExternalLoginFederationProviderType parameter is set to CUSTOM_OIDC.
  --external-login-id: string # The identity ID for a user in the external login provider.
]: any -> record<User: record<Arn: record, UserName: record, Email: record, Role: record, IdentityType: record, Active: record, PrincipalId: record, CustomPermissionsName: record, ExternalLoginFederationProviderType: record, ExternalLoginFederationProviderUrl: record, ExternalLoginId: record>, UserInvitationUrl: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/users"))
  let req_body = {"IdentityType": $identity_type, "Email": $email, "UserRole": $user_role, "IamArn": $iam_arn, "SessionName": $session_name, "UserName": $user_name, "CustomPermissionsName": $custom_permissions_name, "ExternalLoginFederationProviderType": $external_login_federation_provider_type, "CustomFederationProviderUrl": $custom_federation_provider_url, "ExternalLoginId": $external_login_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Restores an analysis.
#
# POST /accounts/{AwsAccountId}/restore/analyses/{AnalysisId}
# operationId: RestoreAnalysis
export def "accounts-restore-analyses create-analysis" [
  aws_account_id: string
  analysis_id: string
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
]: nothing -> record<Status: record, Arn: record, AnalysisId: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), analysis_id: (encode-path-segment $analysis_id)} | format pattern "/accounts/{aws_account_id}/restore/analyses/{analysis_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Searches for analyses that belong to the user specified in the filter. This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.
#
# POST /accounts/{AwsAccountId}/search/analyses
# operationId: SearchAnalyses
# --Filters item shape: {Operator?: any, Name?: any, Value?: any}
export def "accounts-search-analyses list" [
  aws_account_id: string
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
  filters: list # The structure for the search filters that you want to apply to your search. — item shape: {Operator?: any, Name?: any, Value?: any}
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return.
]: any -> record<AnalysisSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/search/analyses") $qp)
  let req_body = {"Filters": $filters, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Searches for dashboards that belong to a user. This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.
#
# POST /accounts/{AwsAccountId}/search/dashboards
# operationId: SearchDashboards
# --Filters item shape: {Operator: any, Name?: any, Value?: any}
export def "accounts-search-dashboards list" [
  aws_account_id: string
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
  filters: list # The filters to apply to the search. Currently, you can search only by user name, for example, "Filters": [ { "Name": "QUICKSIGHT_USER", "Operator": "StringEquals", "Value": "arn:aws:quicksight:us-east-1:1:user/default/UserName1" } ] — item shape: {Operator: any, Name?: any, Value?: any}
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
]: any -> record<DashboardSummaryList: record, NextToken: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/search/dashboards") $qp)
  let req_body = {"Filters": $filters, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Use the SearchDataSets operation to search for datasets that belong to an account.
#
# POST /accounts/{AwsAccountId}/search/data-sets
# operationId: SearchDataSets
# --Filters item shape: {Operator: any, Name: any, Value: any}
export def "accounts-search-data-sets list" [
  aws_account_id: string
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
  filters: list # The filters to apply to the search. — item shape: {Operator: any, Name: any, Value: any}
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to be returned per request.
]: any -> record<DataSetSummaries: record, NextToken: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/search/data-sets") $qp)
  let req_body = {"Filters": $filters, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Use the SearchDataSources operation to search for data sources that belong to an account.
#
# POST /accounts/{AwsAccountId}/search/data-sources
# operationId: SearchDataSources
# --Filters item shape: {Operator: any, Name: any, Value: any}
export def "accounts-search-data-sources list" [
  aws_account_id: string
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
  filters: list # The filters to apply to the search. — item shape: {Operator: any, Name: any, Value: any}
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to be returned per request.
]: any -> record<DataSourceSummaries: record, NextToken: record, Status: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/search/data-sources") $qp)
  let req_body = {"Filters": $filters, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Searches the subfolders in a folder.
#
# POST /accounts/{AwsAccountId}/search/folders
# operationId: SearchFolders
# --Filters item shape: {Operator?: any, Name?: any, Value?: any}
export def "accounts-search-folders list" [
  aws_account_id: string
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
  filters: list # The filters to apply to the search. Currently, you can search only by the parent folder ARN. For example, "Filters": [ { "Name": "PARENT_FOLDER_ARN", "Operator": "StringEquals", "Value": "arn:aws:quicksight:us-east-1:1:folder/folderId" } ]. — item shape: {Operator?: any, Name?: any, Value?: any}
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
]: any -> record<Status: record, FolderSummaryList: record, NextToken: record, RequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/search/folders"))
  let req_body = {"Filters": $filters, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Use the SearchGroups operation to search groups in a specified Amazon QuickSight namespace using the supplied filters.
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/groups-search
# operationId: SearchGroups
# --Filters item shape: {Operator: any, Name: any, Value: any}
export def "accounts-namespaces-groups-search list" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  filters: list # The structure for the search filters that you want to apply to your search. — item shape: {Operator: any, Name: any, Value: any}
]: any -> record<GroupList: record, NextToken: record, RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), namespace: (encode-path-segment $namespace)} | format pattern "/accounts/{aws_account_id}/namespaces/{namespace}/groups-search") $qp)
  let req_body = {"Filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Removes a tag or tags from a resource.
#
# DELETE /resources/{ResourceArn}/tags#keys
# operationId: UntagResource
export def "resources-tagskeys untag" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keys: list # The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<RequestId: record, Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keys" $keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/resources/{resource_arn}/tags#keys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the published version of a dashboard.
#
# PUT /accounts/{AwsAccountId}/dashboards/{DashboardId}/versions/{VersionNumber}
# operationId: UpdateDashboardPublishedVersion
export def "accounts-dashboards-versions update-published" [
  aws_account_id: string
  dashboard_id: string
  version_number: int
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
]: nothing -> record<DashboardId: record, DashboardArn: record, Status: record, RequestId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id), dashboard_id: (encode-path-segment $dashboard_id), version_number: (encode-path-segment $version_number)} | format pattern "/accounts/{aws_account_id}/dashboards/{dashboard_id}/versions/{version_number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Use the UpdatePublicSharingSettings operation to turn on or turn off the public sharing settings of an Amazon QuickSight dashboard. To use this operation, turn on session capacity pricing for your Amazon QuickSight account. Before you can turn on public sharing on your account, make sure to give public sharing permissions to an administrative user in the Identity and Access Management (IAM) console. For more information on using IAM with Amazon QuickSight, see Using Amazon QuickSight with IAM (https://docs.aws.amazon.com/quicksight/latest/user/security_iam_service-with-iam.html) in the Amazon QuickSight User Guide.
#
# PUT /accounts/{AwsAccountId}/public-sharing-settings
# operationId: UpdatePublicSharingSettings
export def "accounts-public-sharing-settings update" [
  aws_account_id: string
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
  --public-sharing-enabled: oneof<nothing, bool> # A Boolean value that indicates whether public sharing is turned on for an Amazon QuickSight account.
]: any -> record<RequestId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({aws_account_id: (encode-path-segment $aws_account_id)} | format pattern "/accounts/{aws_account_id}/public-sharing-settings"))
  let req_body = {"PublicSharingEnabled": $public_sharing_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
