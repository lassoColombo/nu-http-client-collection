# Auto-generated client for Redshift Data API Service v2019-12-20
# Source: https://api.apis.guru/v2/specs/amazonaws.com/redshift-data/2019-12-20/openapi.json
# Auth: --token flag or $env.REDSHIFT_DATA_API_SERVICE_TOKEN

const BASE_URL = "http://redshift-data.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REDSHIFT_DATA_API_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://redshift-data.us-east-1.amazonaws.com" "http://redshift-data.us-east-2.amazonaws.com" "http://redshift-data.us-west-1.amazonaws.com" "http://redshift-data.us-west-2.amazonaws.com" "http://redshift-data.us-gov-west-1.amazonaws.com" "http://redshift-data.us-gov-east-1.amazonaws.com" "http://redshift-data.ca-central-1.amazonaws.com" "http://redshift-data.eu-north-1.amazonaws.com" "http://redshift-data.eu-west-1.amazonaws.com" "http://redshift-data.eu-west-2.amazonaws.com" "http://redshift-data.eu-west-3.amazonaws.com" "http://redshift-data.eu-central-1.amazonaws.com" "http://redshift-data.eu-south-1.amazonaws.com" "http://redshift-data.af-south-1.amazonaws.com" "http://redshift-data.ap-northeast-1.amazonaws.com" "http://redshift-data.ap-northeast-2.amazonaws.com" "http://redshift-data.ap-northeast-3.amazonaws.com" "http://redshift-data.ap-southeast-1.amazonaws.com" "http://redshift-data.ap-southeast-2.amazonaws.com" "http://redshift-data.ap-east-1.amazonaws.com" "http://redshift-data.ap-south-1.amazonaws.com" "http://redshift-data.sa-east-1.amazonaws.com" "http://redshift-data.me-south-1.amazonaws.com" "https://redshift-data.us-east-1.amazonaws.com" "https://redshift-data.us-east-2.amazonaws.com" "https://redshift-data.us-west-1.amazonaws.com" "https://redshift-data.us-west-2.amazonaws.com" "https://redshift-data.us-gov-west-1.amazonaws.com" "https://redshift-data.us-gov-east-1.amazonaws.com" "https://redshift-data.ca-central-1.amazonaws.com" "https://redshift-data.eu-north-1.amazonaws.com" "https://redshift-data.eu-west-1.amazonaws.com" "https://redshift-data.eu-west-2.amazonaws.com" "https://redshift-data.eu-west-3.amazonaws.com" "https://redshift-data.eu-central-1.amazonaws.com" "https://redshift-data.eu-south-1.amazonaws.com" "https://redshift-data.af-south-1.amazonaws.com" "https://redshift-data.ap-northeast-1.amazonaws.com" "https://redshift-data.ap-northeast-2.amazonaws.com" "https://redshift-data.ap-northeast-3.amazonaws.com" "https://redshift-data.ap-southeast-1.amazonaws.com" "https://redshift-data.ap-southeast-2.amazonaws.com" "https://redshift-data.ap-east-1.amazonaws.com" "https://redshift-data.ap-south-1.amazonaws.com" "https://redshift-data.sa-east-1.amazonaws.com" "https://redshift-data.me-south-1.amazonaws.com" "http://redshift-data.cn-north-1.amazonaws.com.cn" "http://redshift-data.cn-northwest-1.amazonaws.com.cn" "https://redshift-data.cn-north-1.amazonaws.com.cn" "https://redshift-data.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["RedshiftData.BatchExecuteStatement"] }
def x-amz-target-completer-1 [] { ["RedshiftData.CancelStatement"] }
def x-amz-target-completer-2 [] { ["RedshiftData.DescribeStatement"] }
def x-amz-target-completer-3 [] { ["RedshiftData.DescribeTable"] }
def x-amz-target-completer-4 [] { ["RedshiftData.ExecuteStatement"] }
def x-amz-target-completer-5 [] { ["RedshiftData.GetStatementResult"] }
def x-amz-target-completer-6 [] { ["RedshiftData.ListDatabases"] }
def x-amz-target-completer-7 [] { ["RedshiftData.ListSchemas"] }
def x-amz-target-completer-8 [] { ["RedshiftData.ListStatements"] }
def x-amz-target-completer-9 [] { ["RedshiftData.ListTables"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-redshift-data-batch-execute-statement create" } } | get name | first)
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

# Runs one or more SQL statements, which can be data manipulation language (DML) or data definition language (DDL). Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /#X-Amz-Target=RedshiftData.BatchExecuteStatement
# operationId: BatchExecuteStatement
export def "x-amz-target-redshift-data-batch-execute-statement create" [
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
  --client-token: any
  --cluster-identifier: any
  database: any
  --db-user: any
  --secret-arn: any
  sqls: any
  --statement-name: any
  --with-event: any
  --workgroup-name: any
]: any -> record<ClusterIdentifier: record, CreatedAt: record, Database: record, DbUser: record, Id: record, SecretArn: record, WorkgroupName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=RedshiftData.BatchExecuteStatement")
  let req_body = {"ClientToken": $client_token, "ClusterIdentifier": $cluster_identifier, "Database": $database, "DbUser": $db_user, "SecretArn": $secret_arn, "Sqls": $sqls, "StatementName": $statement_name, "WithEvent": $with_event, "WorkgroupName": $workgroup_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Cancels a running query. To be canceled, a query must be running. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /#X-Amz-Target=RedshiftData.CancelStatement
# operationId: CancelStatement
export def "x-amz-target-redshift-data-cancel-statement cancel" [
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
  id: any
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=RedshiftData.CancelStatement")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes the details about a specific instance when a query was run by the Amazon Redshift Data API. The information includes when the query started, when it finished, the query status, the number of rows returned, and the SQL statement. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /#X-Amz-Target=RedshiftData.DescribeStatement
# operationId: DescribeStatement
export def "x-amz-target-redshift-data-describe-statement get" [
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
  id: any
]: any -> record<ClusterIdentifier: record, CreatedAt: record, Database: record, DbUser: record, Duration: record, Error: record, HasResultSet: record, Id: record, QueryParameters: record, QueryString: record, RedshiftPid: record, RedshiftQueryId: record, ResultRows: record, ResultSize: record, SecretArn: record, Status: record, SubStatements: record, UpdatedAt: record, WorkgroupName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=RedshiftData.DescribeStatement")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes the detailed information about a table from metadata in the cluster. The information includes its columns. A token is returned to page through the column list. Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /#X-Amz-Target=RedshiftData.DescribeTable
# operationId: DescribeTable
export def "x-amz-target-redshift-data-describe-table get" [
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
  --x-amz-target: string@x-amz-target-completer-3
  --cluster-identifier: any
  --connected-database: any
  database: any
  --db-user: any
  --max-results: any
  --next-token: any
  --schema: any
  --secret-arn: any
  --table: any
  --workgroup-name: any
]: any -> record<ColumnList: record, NextToken: record, TableName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=RedshiftData.DescribeTable" $qp)
  let req_body = {"ClusterIdentifier": $cluster_identifier, "ConnectedDatabase": $connected_database, "Database": $database, "DbUser": $db_user, "MaxResults": $max_results, "NextToken": $next_token, "Schema": $schema, "SecretArn": $secret_arn, "Table": $table, "WorkgroupName": $workgroup_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Runs an SQL statement, which can be data manipulation language (DML) or data definition language (DDL). This statement must be a single SQL statement. Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /#X-Amz-Target=RedshiftData.ExecuteStatement
# operationId: ExecuteStatement
export def "x-amz-target-redshift-data-execute-statement create" [
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
  --client-token: any
  --cluster-identifier: any
  database: any
  --db-user: any
  --parameters: any
  --secret-arn: any
  sql: any
  --statement-name: any
  --with-event: any
  --workgroup-name: any
]: any -> record<ClusterIdentifier: record, CreatedAt: record, Database: record, DbUser: record, Id: record, SecretArn: record, WorkgroupName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=RedshiftData.ExecuteStatement")
  let req_body = {"ClientToken": $client_token, "ClusterIdentifier": $cluster_identifier, "Database": $database, "DbUser": $db_user, "Parameters": $parameters, "SecretArn": $secret_arn, "Sql": $sql, "StatementName": $statement_name, "WithEvent": $with_event, "WorkgroupName": $workgroup_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Fetches the temporarily cached result of an SQL statement. A token is returned to page through the statement results. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /#X-Amz-Target=RedshiftData.GetStatementResult
# operationId: GetStatementResult
export def "x-amz-target-redshift-data-get-statement-result get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5
  id: any
  --next-token: any
]: any -> record<ColumnMetadata: record, NextToken: record, Records: record, TotalNumRows: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=RedshiftData.GetStatementResult" $qp)
  let req_body = {"Id": $id, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List the databases in a cluster. A token is returned to page through the database list. Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /#X-Amz-Target=RedshiftData.ListDatabases
# operationId: ListDatabases
export def "x-amz-target-redshift-data-list-databases list" [
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
  --x-amz-target: string@x-amz-target-completer-6
  --cluster-identifier: any
  database: any
  --db-user: any
  --max-results: any
  --next-token: any
  --secret-arn: any
  --workgroup-name: any
]: any -> record<Databases: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=RedshiftData.ListDatabases" $qp)
  let req_body = {"ClusterIdentifier": $cluster_identifier, "Database": $database, "DbUser": $db_user, "MaxResults": $max_results, "NextToken": $next_token, "SecretArn": $secret_arn, "WorkgroupName": $workgroup_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the schemas in a database. A token is returned to page through the schema list. Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /#X-Amz-Target=RedshiftData.ListSchemas
# operationId: ListSchemas
export def "x-amz-target-redshift-data-list-schemas list" [
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
  --x-amz-target: string@x-amz-target-completer-7
  --cluster-identifier: any
  --connected-database: any
  database: any
  --db-user: any
  --max-results: any
  --next-token: any
  --schema-pattern: any
  --secret-arn: any
  --workgroup-name: any
]: any -> record<NextToken: record, Schemas: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=RedshiftData.ListSchemas" $qp)
  let req_body = {"ClusterIdentifier": $cluster_identifier, "ConnectedDatabase": $connected_database, "Database": $database, "DbUser": $db_user, "MaxResults": $max_results, "NextToken": $next_token, "SchemaPattern": $schema_pattern, "SecretArn": $secret_arn, "WorkgroupName": $workgroup_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List of SQL statements. By default, only finished statements are shown. A token is returned to page through the statement list. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /#X-Amz-Target=RedshiftData.ListStatements
# operationId: ListStatements
export def "x-amz-target-redshift-data-list-statements list" [
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
  --x-amz-target: string@x-amz-target-completer-8
  --max-results: any
  --next-token: any
  --role-level: any
  --statement-name: any
  --status: any
]: any -> record<NextToken: record, Statements: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=RedshiftData.ListStatements" $qp)
  let req_body = {"MaxResults": $max_results, "NextToken": $next_token, "RoleLevel": $role_level, "StatementName": $statement_name, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List the tables in a database. If neither SchemaPattern nor TablePattern are specified, then all tables in the database are returned. A token is returned to page through the table list. Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /#X-Amz-Target=RedshiftData.ListTables
# operationId: ListTables
export def "x-amz-target-redshift-data-list-tables list" [
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
  --x-amz-target: string@x-amz-target-completer-9
  --cluster-identifier: any
  --connected-database: any
  database: any
  --db-user: any
  --max-results: any
  --next-token: any
  --schema-pattern: any
  --secret-arn: any
  --table-pattern: any
  --workgroup-name: any
]: any -> record<NextToken: record, Tables: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=RedshiftData.ListTables" $qp)
  let req_body = {"ClusterIdentifier": $cluster_identifier, "ConnectedDatabase": $connected_database, "Database": $database, "DbUser": $db_user, "MaxResults": $max_results, "NextToken": $next_token, "SchemaPattern": $schema_pattern, "SecretArn": $secret_arn, "TablePattern": $table_pattern, "WorkgroupName": $workgroup_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
