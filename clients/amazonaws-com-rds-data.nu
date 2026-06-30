# Auto-generated client for AWS RDS DataService v2018-08-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/rds-data/2018-08-01/openapi.json
# Auth: --token flag or $env.AWS_RDS_DATASERVICE_TOKEN

const BASE_URL = "http://rds-data.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_RDS_DATASERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["http://rds-data.us-east-1.amazonaws.com" "http://rds-data.us-east-2.amazonaws.com" "http://rds-data.us-west-1.amazonaws.com" "http://rds-data.us-west-2.amazonaws.com" "http://rds-data.us-gov-west-1.amazonaws.com" "http://rds-data.us-gov-east-1.amazonaws.com" "http://rds-data.ca-central-1.amazonaws.com" "http://rds-data.eu-north-1.amazonaws.com" "http://rds-data.eu-west-1.amazonaws.com" "http://rds-data.eu-west-2.amazonaws.com" "http://rds-data.eu-west-3.amazonaws.com" "http://rds-data.eu-central-1.amazonaws.com" "http://rds-data.eu-south-1.amazonaws.com" "http://rds-data.af-south-1.amazonaws.com" "http://rds-data.ap-northeast-1.amazonaws.com" "http://rds-data.ap-northeast-2.amazonaws.com" "http://rds-data.ap-northeast-3.amazonaws.com" "http://rds-data.ap-southeast-1.amazonaws.com" "http://rds-data.ap-southeast-2.amazonaws.com" "http://rds-data.ap-east-1.amazonaws.com" "http://rds-data.ap-south-1.amazonaws.com" "http://rds-data.sa-east-1.amazonaws.com" "http://rds-data.me-south-1.amazonaws.com" "https://rds-data.us-east-1.amazonaws.com" "https://rds-data.us-east-2.amazonaws.com" "https://rds-data.us-west-1.amazonaws.com" "https://rds-data.us-west-2.amazonaws.com" "https://rds-data.us-gov-west-1.amazonaws.com" "https://rds-data.us-gov-east-1.amazonaws.com" "https://rds-data.ca-central-1.amazonaws.com" "https://rds-data.eu-north-1.amazonaws.com" "https://rds-data.eu-west-1.amazonaws.com" "https://rds-data.eu-west-2.amazonaws.com" "https://rds-data.eu-west-3.amazonaws.com" "https://rds-data.eu-central-1.amazonaws.com" "https://rds-data.eu-south-1.amazonaws.com" "https://rds-data.af-south-1.amazonaws.com" "https://rds-data.ap-northeast-1.amazonaws.com" "https://rds-data.ap-northeast-2.amazonaws.com" "https://rds-data.ap-northeast-3.amazonaws.com" "https://rds-data.ap-southeast-1.amazonaws.com" "https://rds-data.ap-southeast-2.amazonaws.com" "https://rds-data.ap-east-1.amazonaws.com" "https://rds-data.ap-south-1.amazonaws.com" "https://rds-data.sa-east-1.amazonaws.com" "https://rds-data.me-south-1.amazonaws.com" "http://rds-data.cn-north-1.amazonaws.com.cn" "http://rds-data.cn-northwest-1.amazonaws.com.cn" "https://rds-data.cn-north-1.amazonaws.com.cn" "https://rds-data.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def format-records-as-completer [] { ["JSON" "NONE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "batch-execute create-statement" } } | get name | first)
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

# Runs a batch SQL statement over an array of data. You can run bulk update and insert operations for multiple records using a DML statement with different parameter sets. Bulk operations can provide a significant performance improvement over individual insert and update operations. If a call isn't part of a transaction because it doesn't include the transactionID parameter, changes that result from the call are committed automatically. There isn't a fixed upper limit on the number of parameter sets. However, the maximum size of the HTTP request submitted through the Data API is 4 MiB. If the request exceeds this limit, the Data API returns an error and doesn't process the request. This 4-MiB limit includes the size of the HTTP headers and the JSON notation in the request. Thus, the number of parameter sets that you can include depends on a combination of factors, such as the size of the SQL statement and the size of each parameter set. The response size limit is 1 MiB. If the call returns more than 1 MiB of response data, the call is terminated.
#
# POST /BatchExecute
# operationId: BatchExecuteStatement
export def "batch-execute create-statement" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the Aurora Serverless DB cluster.
  secret_arn: string # The ARN of the secret that enables access to the DB cluster. Enter the database user name and password for the credentials in the secret. For information about creating the secret, see Create a database secret (https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_database_secret.html).
  sql: string # The SQL statement to run. Don't include a semicolon (;) at the end of the SQL statement.
  --database: string # The name of the database.
  --schema: string # The name of the database schema. Currently, the schema parameter isn't supported.
  --parameter-sets: list # The parameter set for the batch operation. The SQL statement is executed as many times as the number of parameter sets provided. To execute a SQL statement with no parameters, use one of the following options: Specify one or more empty parameter sets. Use the ExecuteStatement operation instead of the BatchExecuteStatement operation. Array parameters are not supported.
  --transaction-id: string # The identifier of a transaction that was started by using the BeginTransaction operation. Specify the transaction ID of the transaction that you want to include the SQL statement in. If the SQL statement is not part of a transaction, don't set this parameter.
]: any -> record<updateResults: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/BatchExecute" $auth.query)
  let req_body = {"resourceArn": $resource_arn, "secretArn": $secret_arn, "sql": $sql, "database": $database, "schema": $schema, "parameterSets": $parameter_sets, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Starts a SQL transaction. A transaction can run for a maximum of 24 hours. A transaction is terminated and rolled back automatically after 24 hours. A transaction times out if no calls use its transaction ID in three minutes. If a transaction times out before it's committed, it's rolled back automatically. DDL statements inside a transaction cause an implicit commit. We recommend that you run each DDL statement in a separate ExecuteStatement call with continueAfterTimeout enabled.
#
# POST /BeginTransaction
# operationId: BeginTransaction
export def "begin-transaction create" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the Aurora Serverless DB cluster.
  secret_arn: string # The name or ARN of the secret that enables access to the DB cluster.
  --database: string # The name of the database.
  --schema: string # The name of the database schema.
]: any -> record<transactionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/BeginTransaction" $auth.query)
  let req_body = {"resourceArn": $resource_arn, "secretArn": $secret_arn, "database": $database, "schema": $schema} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Ends a SQL transaction started with the BeginTransaction operation and commits the changes.
#
# POST /CommitTransaction
# operationId: CommitTransaction
export def "commit-transaction commit" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the Aurora Serverless DB cluster.
  secret_arn: string # The name or ARN of the secret that enables access to the DB cluster.
  transaction_id: string # The identifier of the transaction to end and commit.
]: any -> record<transactionStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/CommitTransaction" $auth.query)
  let req_body = {"resourceArn": $resource_arn, "secretArn": $secret_arn, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Runs one or more SQL statements. This operation is deprecated. Use the BatchExecuteStatement or ExecuteStatement operation.
#
# POST /ExecuteSql
# DEPRECATED
# operationId: ExecuteSql
@deprecated
export def "execute-sql create" [
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
  db_cluster_or_instance_arn: string # The ARN of the Aurora Serverless DB cluster.
  aws_secret_store_arn: string # The Amazon Resource Name (ARN) of the secret that enables access to the DB cluster. Enter the database user name and password for the credentials in the secret. For information about creating the secret, see Create a database secret (https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_database_secret.html).
  sql_statements: string # One or more SQL statements to run on the DB cluster. You can separate SQL statements from each other with a semicolon (;). Any valid SQL statement is permitted, including data definition, data manipulation, and commit statements.
  --database: string # The name of the database.
  --schema: string # The name of the database schema.
]: any -> record<sqlStatementResults: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ExecuteSql" $auth.query)
  let req_body = {"dbClusterOrInstanceArn": $db_cluster_or_instance_arn, "awsSecretStoreArn": $aws_secret_store_arn, "sqlStatements": $sql_statements, "database": $database, "schema": $schema} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Runs a SQL statement against a database. If a call isn't part of a transaction because it doesn't include the transactionID parameter, changes that result from the call are committed automatically. If the binary response data from the database is more than 1 MB, the call is terminated.
#
# POST /Execute
# operationId: ExecuteStatement
# --parameters item shape: {name?: any, value?: any, typeHint?: any}
# --resultSetOptions shape: {decimalReturnType?: any, longReturnType?: any}
export def "execute create-statement" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the Aurora Serverless DB cluster.
  secret_arn: string # The ARN of the secret that enables access to the DB cluster. Enter the database user name and password for the credentials in the secret. For information about creating the secret, see Create a database secret (https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_database_secret.html).
  sql: string # The SQL statement to run.
  --database: string # The name of the database.
  --schema: string # The name of the database schema. Currently, the schema parameter isn't supported.
  --parameters: list # The parameters for the SQL statement. Array parameters are not supported. — item shape: {name?: any, value?: any, typeHint?: any}
  --transaction-id: string # The identifier of a transaction that was started by using the BeginTransaction operation. Specify the transaction ID of the transaction that you want to include the SQL statement in. If the SQL statement is not part of a transaction, don't set this parameter.
  --include-result-metadata: oneof<nothing, bool> # A value that indicates whether to include metadata in the results.
  --continue-after-timeout: oneof<nothing, bool> # A value that indicates whether to continue running the statement after the call times out. By default, the statement stops running when the call times out. For DDL statements, we recommend continuing to run the statement after the call times out. When a DDL statement terminates before it is finished running, it can result in errors and possibly corrupted data structures.
  --result-set-options: record # Options that control how the result set is returned. — shape: {decimalReturnType?: any, longReturnType?: any}
  --format-records-as: string@format-records-as-completer # A value that indicates whether to format the result set as a single JSON string. This parameter only applies to SELECT statements and is ignored for other types of statements. Allowed values are NONE and JSON. The default value is NONE. The result is returned in the formattedRecords field. For usage information about the JSON format for result sets, see Using the Data API (https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/data-api.html) in the Amazon Aurora User Guide.
]: any -> record<records: record, columnMetadata: record, numberOfRecordsUpdated: record, generatedFields: record, formattedRecords: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Execute" $auth.query)
  let req_body = {"resourceArn": $resource_arn, "secretArn": $secret_arn, "sql": $sql, "database": $database, "schema": $schema, "parameters": $parameters, "transactionId": $transaction_id, "includeResultMetadata": $include_result_metadata, "continueAfterTimeout": $continue_after_timeout, "resultSetOptions": $result_set_options, "formatRecordsAs": $format_records_as} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# Performs a rollback of a transaction. Rolling back a transaction cancels its changes.
#
# POST /RollbackTransaction
# operationId: RollbackTransaction
export def "rollback-transaction create" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the Aurora Serverless DB cluster.
  secret_arn: string # The name or ARN of the secret that enables access to the DB cluster.
  transaction_id: string # The identifier of the transaction to roll back.
]: any -> record<transactionStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/RollbackTransaction" $auth.query)
  let req_body = {"resourceArn": $resource_arn, "secretArn": $secret_arn, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
