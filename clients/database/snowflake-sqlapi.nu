# Auto-generated client for Snowflake SQL API v2.0.0
# Source: https://raw.githubusercontent.com/snowflakedb/snowflake-rest-api-specs/main/specifications/sqlapi.yaml
# Auth: --token flag or $env.SNOWFLAKE_SQL_API_TOKEN

const BASE_URL = "https://org-account.snowflakecomputing.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SNOWFLAKE_SQL_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://org-account.snowflakecomputing.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "statements SubmitStatement" } } | get name | first)
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

# Submits a SQL statement for execution.
#
# POST /api/v2/statements
# operationId: SubmitStatement
# --parameters shape: {timezone?: string, query_tag?: string, binary_output_format?: string, date_output_format?: string, time_output_format?: string, timestamp_output_format?: string, timestamp_ltz_output_format?: string, timestamp_ntz_output_format?: string, timestamp_tz_output_format?: string, multi_statement_count?: int}
export def "statements SubmitStatement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requestId: string # Unique ID of the API request. This ensures that the execution is idempotent. If not specified, a new UUID is generated and assigned. (format: uuid)
  --async: oneof<nothing, bool> # Set to true to execute the statement asynchronously and return the statement handle. If the parameter is not specified or is set to false, a statement is executed and the first result is returned if the execution is completed in 45 seconds. If the statement execution takes longer to complete, the statement handle is returned. (e.g. true)
  --nullable: oneof<nothing, bool> # Set to true to execute the statement to generate the result set including null. If the parameter is set to false, the result set value null will be replaced with a string 'null'. (e.g. true)
  --Accept: string # The response payload format. The schema should be specified in resultSetMetaData in the request payload. (e.g. application/json)
  --User-Agent: string # Set this to the name and version of your application (e.g. “applicationName/applicationVersion”). You must use a value that complies with RFC 7231. (e.g. myApplication/1.0)
  --X-Snowflake-Authorization-Token-Type: string # Specify the authorization token type for the Authorization header. KEYPAIR_JWT is for Keypair JWT or OAUTH for oAuth token. If not specified, OAUTH is assumed. (e.g. KEYPAIR_JWT)
  --statement: string # SQL statement or batch of SQL statements to execute. You can specify query, DML and DDL statements. The following statements are not supported: PUT, GET, USE, ALTER SESSION, BEGIN, COMMIT, ROLLBACK, statements that set session variables, and statements that create temporary tables and stages.
  --timeout: int # Timeout in seconds for statement execution. If the execution of a statement takes longer than the specified timeout, the execution is automatically canceled. To set the timeout to the maximum value (604800 seconds), set timeout to 0. (format: int64, e.g. 10)
  --database: string # Database in which the statement should be executed. The value in this field is case-sensitive. (e.g. TESTDB)
  --schema: string # Schema in which the statement should be executed. The value in this field is case-sensitive. (e.g. TESTSCHEMA)
  --warehouse: string # Warehouse to use when executing the statement. The value in this field is case-sensitive. (e.g. TESTWH)
  --role: string # Role to use when executing the statement. The value in this field is case-sensitive. (e.g. TESTROLE)
  --bindings: record # Values of bind variables in the SQL statement. When executing the statement, Snowflake replaces placeholders ('?' and ':name') in the statement with these specified values. (e.g. {1: {type: FIXED, value: 123}, 2: {type: TEXT, value: teststring}})
  --parameters: record # Session parameters that should be set before executing the statement. — shape: {timezone?: string, query_tag?: string, binary_output_format?: string, date_output_format?: string, time_output_format?: string, timestamp_output_format?: string, timestamp_ltz_output_format?: string, timestamp_ntz_output_format?: string, timestamp_tz_output_format?: string, multi_statement_count?: int}
]: any -> record<code: string, sqlState: string, message: string, statementHandle: string, createdOn: int, statementStatusUrl: string, resultSetMetaData: record<format: string, numRows: int, rowType: list<record>, partitionInfo: list<record>, nullable: bool, parameters: record<binary_output_format: string, date_output_format: string, time_output_format: string, timestamp_output_format: string, timestamp_ltz_output_format: string, timestamp_ntz_output_format: string, timestamp_tz_output_format: string, multi_statement_count: int>>, data: list<list<string>>, stats: record<numRowsInserted: int, numRowsUpdated: int, numRowsDeleted: int, numDuplicateRowsUpdated: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requestId" $requestId "scalar") (serialize-qp "async" $async "scalar") (serialize-qp "nullable" $nullable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/statements" $qp)
  let body = {statement: $statement, timeout: $timeout, database: $database, schema: $schema, warehouse: $warehouse, role: $role, bindings: $bindings, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "User-Agent": $User_Agent, "X-Snowflake-Authorization-Token-Type": $X_Snowflake_Authorization_Token_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Checks the status of the execution of a statement
#
# GET /api/v2/statements/{statementHandle}
# operationId: GetStatementStatus
export def "statements GetStatementStatus" [
  statementHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requestId: string # Unique ID of the API request. This ensures that the execution is idempotent. If not specified, a new UUID is generated and assigned. (format: uuid)
  --partition: int # Number of the partition of results to return. The number can range from 0 to the total number of partitions minus 1. (format: int64, e.g. 2)
  --Accept: string # The response payload format. The schema should be specified in resultSetMetaData in the request payload. (e.g. application/json)
  --User-Agent: string # Set this to the name and version of your application (e.g. “applicationName/applicationVersion”). You must use a value that complies with RFC 7231. (e.g. myApplication/1.0)
  --X-Snowflake-Authorization-Token-Type: string # Specify the authorization token type for the Authorization header. KEYPAIR_JWT is for Keypair JWT or OAUTH for oAuth token. If not specified, OAUTH is assumed. (e.g. KEYPAIR_JWT)
]: nothing -> record<code: string, sqlState: string, message: string, statementHandle: string, createdOn: int, statementStatusUrl: string, resultSetMetaData: record<format: string, numRows: int, rowType: list<record>, partitionInfo: list<record>, nullable: bool, parameters: record<binary_output_format: string, date_output_format: string, time_output_format: string, timestamp_output_format: string, timestamp_ltz_output_format: string, timestamp_ntz_output_format: string, timestamp_tz_output_format: string, multi_statement_count: int>>, data: list<list<string>>, stats: record<numRowsInserted: int, numRowsUpdated: int, numRowsDeleted: int, numDuplicateRowsUpdated: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requestId" $requestId "scalar") (serialize-qp "partition" $partition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/statements/($statementHandle)" $qp)
  let extra_headers = {"Accept": $Accept, "User-Agent": $User_Agent, "X-Snowflake-Authorization-Token-Type": $X_Snowflake_Authorization_Token_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancels the execution of a statement.
#
# POST /api/v2/statements/{statementHandle}/cancel
# operationId: CancelStatement
export def "statements-cancel CancelStatement" [
  statementHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requestId: string # Unique ID of the API request. This ensures that the execution is idempotent. If not specified, a new UUID is generated and assigned. (format: uuid)
  --Accept: string # The response payload format. The schema should be specified in resultSetMetaData in the request payload. (e.g. application/json)
  --User-Agent: string # Set this to the name and version of your application (e.g. “applicationName/applicationVersion”). You must use a value that complies with RFC 7231. (e.g. myApplication/1.0)
  --X-Snowflake-Authorization-Token-Type: string # Specify the authorization token type for the Authorization header. KEYPAIR_JWT is for Keypair JWT or OAUTH for oAuth token. If not specified, OAUTH is assumed. (e.g. KEYPAIR_JWT)
]: nothing -> record<code: string, sqlState: string, message: string, statementHandle: string, statementStatusUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requestId" $requestId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/statements/($statementHandle)/cancel" $qp)
  let extra_headers = {"Accept": $Accept, "User-Agent": $User_Agent, "X-Snowflake-Authorization-Token-Type": $X_Snowflake_Authorization_Token_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
