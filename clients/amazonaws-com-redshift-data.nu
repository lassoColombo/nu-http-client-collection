# Auto-generated client for Redshift Data API Service v2019-12-20
# Source: https://api.apis.guru/v2/specs/amazonaws.com/redshift-data/2019-12-20/openapi.json
# Auth: --token flag or $env.REDSHIFT_DATA_API_SERVICE_TOKEN

const BASE_URL = "http://redshift-data.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o REDSHIFT_DATA_API_SERVICE_TOKEN | default "" }
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
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
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
def status-completer [] { ["ABORTED" "ALL" "FAILED" "FINISHED" "PICKED" "STARTED" "SUBMITTED"] }
def x-amz-target-completer-8 [] { ["RedshiftData.ListStatements"] }
def x-amz-target-completer-9 [] { ["RedshiftData.ListTables"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["batch-execute-statement" "cancel-statement" "describe-statement" "describe-table" "execute-statement" "get-statement-result" "list-databases" "list-schemas" "list-statements" "list-tables" "commands"] | sort) } | get name | first)
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

# Runs one or more SQL statements, which can be data manipulation language (DML) or data definition language (DDL). Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /
# operationId: BatchExecuteStatement
export def "batch-execute-statement" [
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
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --cluster-identifier: string # The cluster identifier. This parameter is required when connecting to a cluster and authenticating using either Secrets Manager or temporary credentials.
  database: string # The name of the database. This parameter is required when authenticating using either Secrets Manager or temporary credentials.
  --db-user: string # The database user name. This parameter is required when connecting to a cluster as a database user and authenticating using temporary credentials.
  --secret-arn: string # The name or ARN of the secret that enables access to the database. This parameter is required when authenticating using Secrets Manager.
  sqls: list<string> # One or more SQL statements to run. The SQL statements are run as a single transaction. They run serially in the order of the array. Subsequent SQL statements don't start until the previous statement in the array completes. If any SQL statement fails, then because they are run as one transaction, all work is rolled back.</p>
  --statement-name: string # The name of the SQL statements. You can name the SQL statements when you create them to identify the query.
  --with-event: oneof<nothing, bool> # A value that indicates whether to send an event to the Amazon EventBridge event bus after the SQL statements run.
  --workgroup-name: string # The serverless workgroup name or Amazon Resource Name (ARN). This parameter is required when connecting to a serverless workgroup and authenticating using either Secrets Manager or temporary credentials.
]: any -> oneof<record<ClusterIdentifier: string, CreatedAt: string, Database: string, DbUser: string, Id: string, SecretArn: string, WorkgroupName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "RedshiftData.BatchExecuteStatement")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientToken": $client_token, "ClusterIdentifier": $cluster_identifier, "Database": $database, "DbUser": $db_user, "SecretArn": $secret_arn, "Sqls": $sqls, "StatementName": $statement_name, "WithEvent": $with_event, "WorkgroupName": $workgroup_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Cancels a running query. To be canceled, a query must be running. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /
# operationId: CancelStatement
export def "cancel-statement" [
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
  id: string # The identifier of the SQL statement to cancel. This value is a universally unique identifier (UUID) generated by Amazon Redshift Data API. This identifier is returned by BatchExecuteStatment, ExecuteStatment, and ListStatements.
]: any -> oneof<record<Status: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "RedshiftData.CancelStatement")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Id": $id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Describes the details about a specific instance when a query was run by the Amazon Redshift Data API. The information includes when the query started, when it finished, the query status, the number of rows returned, and the SQL statement. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /
# operationId: DescribeStatement
export def "describe-statement" [
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
  id: string # The identifier of the SQL statement to describe. This value is a universally unique identifier (UUID) generated by Amazon Redshift Data API. A suffix indicates the number of the SQL statement. For example, d9b6c0c9-0747-4bf4-b142-e8883122f766:2 has a suffix of :2 that indicates the second SQL statement of a batch query. This identifier is returned by BatchExecuteStatment, ExecuteStatement, and ListStatements.
]: any -> oneof<record<ClusterIdentifier: string, CreatedAt: string, Database: string, DbUser: string, Duration: int, Error: string, HasResultSet: bool, Id: string, QueryParameters: table<name: string, value: string>, QueryString: string, RedshiftPid: int, RedshiftQueryId: int, ResultRows: int, ResultSize: int, SecretArn: string, Status: string, SubStatements: table<CreatedAt: string, Duration: int, Error: string, HasResultSet: bool, Id: string, QueryString: string, RedshiftQueryId: int, ResultRows: int, ResultSize: int, Status: string, UpdatedAt: string>, UpdatedAt: string, WorkgroupName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "RedshiftData.DescribeStatement")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Id": $id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Describes the detailed information about a table from metadata in the cluster. The information includes its columns. A token is returned to page through the column list. Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /
# operationId: DescribeTable
export def "describe-table" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  --cluster-identifier: string # The cluster identifier. This parameter is required when connecting to a cluster and authenticating using either Secrets Manager or temporary credentials.
  --connected-database: string # A database name. The connected database is specified when you connect with your authentication credentials.
  database: string # The name of the database that contains the tables to be described. If ConnectedDatabase is not specified, this is also the database to connect to with your authentication credentials.
  --db-user: string # The database user name. This parameter is required when connecting to a cluster as a database user and authenticating using temporary credentials.
  --body-max-results: int # The maximum number of tables to return in the response. If more tables exist than fit in one response, then NextToken is returned to page through the results. (spec name: MaxResults)
  --body-next-token: string # A value that indicates the starting point for the next set of response records in a subsequent request. If a value is returned in a response, you can retrieve the next set of records by providing this returned NextToken value in the next NextToken parameter and retrying the command. If the NextToken field is empty, all response records have been retrieved for the request. (spec name: NextToken)
  --schema: string # The schema that contains the table. If no schema is specified, then matching tables for all schemas are returned.
  --secret-arn: string # The name or ARN of the secret that enables access to the database. This parameter is required when authenticating using Secrets Manager.
  --table: string # The table name. If no table is specified, then all tables for all matching schemas are returned. If no table and no schema is specified, then all tables for all schemas in the database are returned
  --workgroup-name: string # The serverless workgroup name or Amazon Resource Name (ARN). This parameter is required when connecting to a serverless workgroup and authenticating using either Secrets Manager or temporary credentials.
]: any -> oneof<record<ColumnList: table<columnDefault: string, isCaseSensitive: bool, isCurrency: bool, isSigned: bool, label: string, length: int, name: string, nullable: int, precision: int, scale: int, schemaName: string, tableName: string, typeName: string>, NextToken: string, TableName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "RedshiftData.DescribeTable")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ClusterIdentifier": $cluster_identifier, "ConnectedDatabase": $connected_database, "Database": $database, "DbUser": $db_user, "MaxResults": $body_max_results, "NextToken": $body_next_token, "Schema": $schema, "SecretArn": $secret_arn, "Table": $table, "WorkgroupName": $workgroup_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Runs an SQL statement, which can be data manipulation language (DML) or data definition language (DDL). This statement must be a single SQL statement. Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /
# operationId: ExecuteStatement
export def "execute-statement" [
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
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --cluster-identifier: string # The cluster identifier. This parameter is required when connecting to a cluster and authenticating using either Secrets Manager or temporary credentials.
  database: string # The name of the database. This parameter is required when authenticating using either Secrets Manager or temporary credentials.
  --db-user: string # The database user name. This parameter is required when connecting to a cluster as a database user and authenticating using temporary credentials.
  --parameters: list # The parameters for the SQL statement. — item shape: {name: string, value: string}
  --secret-arn: string # The name or ARN of the secret that enables access to the database. This parameter is required when authenticating using Secrets Manager.
  sql: string # The SQL statement text to run.
  --statement-name: string # The name of the SQL statement. You can name the SQL statement when you create it to identify the query.
  --with-event: oneof<nothing, bool> # A value that indicates whether to send an event to the Amazon EventBridge event bus after the SQL statement runs.
  --workgroup-name: string # The serverless workgroup name or Amazon Resource Name (ARN). This parameter is required when connecting to a serverless workgroup and authenticating using either Secrets Manager or temporary credentials.
]: any -> oneof<record<ClusterIdentifier: string, CreatedAt: string, Database: string, DbUser: string, Id: string, SecretArn: string, WorkgroupName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "RedshiftData.ExecuteStatement")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientToken": $client_token, "ClusterIdentifier": $cluster_identifier, "Database": $database, "DbUser": $db_user, "Parameters": $parameters, "SecretArn": $secret_arn, "Sql": $sql, "StatementName": $statement_name, "WithEvent": $with_event, "WorkgroupName": $workgroup_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Fetches the temporarily cached result of an SQL statement. A token is returned to page through the statement results. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /
# operationId: GetStatementResult
export def "get-statement-result" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  id: string # The identifier of the SQL statement whose results are to be fetched. This value is a universally unique identifier (UUID) generated by Amazon Redshift Data API. A suffix indicates then number of the SQL statement. For example, d9b6c0c9-0747-4bf4-b142-e8883122f766:2 has a suffix of :2 that indicates the second SQL statement of a batch query. This identifier is returned by BatchExecuteStatment, ExecuteStatment, and ListStatements.
  --body-next-token: string # A value that indicates the starting point for the next set of response records in a subsequent request. If a value is returned in a response, you can retrieve the next set of records by providing this returned NextToken value in the next NextToken parameter and retrying the command. If the NextToken field is empty, all response records have been retrieved for the request. (spec name: NextToken)
]: any -> oneof<record<ColumnMetadata: table<columnDefault: string, isCaseSensitive: bool, isCurrency: bool, isSigned: bool, label: string, length: int, name: string, nullable: int, precision: int, scale: int, schemaName: string, tableName: string, typeName: string>, NextToken: string, Records: list<list<record>>, TotalNumRows: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "RedshiftData.GetStatementResult")
  let qp = [(serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Id": $id, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List the databases in a cluster. A token is returned to page through the database list. Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /
# operationId: ListDatabases
export def "list-databases" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  --cluster-identifier: string # The cluster identifier. This parameter is required when connecting to a cluster and authenticating using either Secrets Manager or temporary credentials.
  database: string # The name of the database. This parameter is required when authenticating using either Secrets Manager or temporary credentials.
  --db-user: string # The database user name. This parameter is required when connecting to a cluster as a database user and authenticating using temporary credentials.
  --body-max-results: int # The maximum number of databases to return in the response. If more databases exist than fit in one response, then NextToken is returned to page through the results. (spec name: MaxResults)
  --body-next-token: string # A value that indicates the starting point for the next set of response records in a subsequent request. If a value is returned in a response, you can retrieve the next set of records by providing this returned NextToken value in the next NextToken parameter and retrying the command. If the NextToken field is empty, all response records have been retrieved for the request. (spec name: NextToken)
  --secret-arn: string # The name or ARN of the secret that enables access to the database. This parameter is required when authenticating using Secrets Manager.
  --workgroup-name: string # The serverless workgroup name or Amazon Resource Name (ARN). This parameter is required when connecting to a serverless workgroup and authenticating using either Secrets Manager or temporary credentials.
]: any -> oneof<record<Databases: list<string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "RedshiftData.ListDatabases")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ClusterIdentifier": $cluster_identifier, "Database": $database, "DbUser": $db_user, "MaxResults": $body_max_results, "NextToken": $body_next_token, "SecretArn": $secret_arn, "WorkgroupName": $workgroup_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the schemas in a database. A token is returned to page through the schema list. Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /
# operationId: ListSchemas
export def "list-schemas" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  --cluster-identifier: string # The cluster identifier. This parameter is required when connecting to a cluster and authenticating using either Secrets Manager or temporary credentials.
  --connected-database: string # A database name. The connected database is specified when you connect with your authentication credentials.
  database: string # The name of the database that contains the schemas to list. If ConnectedDatabase is not specified, this is also the database to connect to with your authentication credentials.
  --db-user: string # The database user name. This parameter is required when connecting to a cluster as a database user and authenticating using temporary credentials.
  --body-max-results: int # The maximum number of schemas to return in the response. If more schemas exist than fit in one response, then NextToken is returned to page through the results. (spec name: MaxResults)
  --body-next-token: string # A value that indicates the starting point for the next set of response records in a subsequent request. If a value is returned in a response, you can retrieve the next set of records by providing this returned NextToken value in the next NextToken parameter and retrying the command. If the NextToken field is empty, all response records have been retrieved for the request. (spec name: NextToken)
  --schema-pattern: string # A pattern to filter results by schema name. Within a schema pattern, "%" means match any substring of 0 or more characters and "_" means match any one character. Only schema name entries matching the search pattern are returned.
  --secret-arn: string # The name or ARN of the secret that enables access to the database. This parameter is required when authenticating using Secrets Manager.
  --workgroup-name: string # The serverless workgroup name or Amazon Resource Name (ARN). This parameter is required when connecting to a serverless workgroup and authenticating using either Secrets Manager or temporary credentials.
]: any -> oneof<record<NextToken: string, Schemas: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "RedshiftData.ListSchemas")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ClusterIdentifier": $cluster_identifier, "ConnectedDatabase": $connected_database, "Database": $database, "DbUser": $db_user, "MaxResults": $body_max_results, "NextToken": $body_next_token, "SchemaPattern": $schema_pattern, "SecretArn": $secret_arn, "WorkgroupName": $workgroup_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List of SQL statements. By default, only finished statements are shown. A token is returned to page through the statement list. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /
# operationId: ListStatements
export def "list-statements" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  --body-max-results: int # The maximum number of SQL statements to return in the response. If more SQL statements exist than fit in one response, then NextToken is returned to page through the results. (spec name: MaxResults)
  --body-next-token: string # A value that indicates the starting point for the next set of response records in a subsequent request. If a value is returned in a response, you can retrieve the next set of records by providing this returned NextToken value in the next NextToken parameter and retrying the command. If the NextToken field is empty, all response records have been retrieved for the request. (spec name: NextToken)
  --role-level: oneof<nothing, bool> # A value that filters which statements to return in the response. If true, all statements run by the caller's IAM role are returned. If false, only statements run by the caller's IAM role in the current IAM session are returned. The default is true.
  --statement-name: string # The name of the SQL statement specified as input to BatchExecuteStatement or ExecuteStatement to identify the query. You can list multiple statements by providing a prefix that matches the beginning of the statement name. For example, to list myStatement1, myStatement2, myStatement3, and so on, then provide the a value of myStatement. Data API does a case-sensitive match of SQL statement names to the prefix value you provide.
  --status: string@status-completer # The status of the SQL statement to list. Status values are defined as follows: ABORTED - The query run was stopped by the user. ALL - A status value that includes all query statuses. This value can be used to filter results. FAILED - The query run failed. FINISHED - The query has finished running. PICKED - The query has been chosen to be run. STARTED - The query run has started. SUBMITTED - The query was submitted, but not yet processed.
]: any -> oneof<record<NextToken: string, Statements: table<CreatedAt: string, Id: string, IsBatchStatement: bool, QueryParameters: list, QueryString: string, QueryStrings: list, SecretArn: string, StatementName: string, Status: string, UpdatedAt: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "RedshiftData.ListStatements")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $body_max_results, "NextToken": $body_next_token, "RoleLevel": $role_level, "StatementName": $statement_name, "Status": $status} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List the tables in a database. If neither SchemaPattern nor TablePattern are specified, then all tables in the database are returned. A token is returned to page through the table list. Depending on the authorization method, use one of the following combinations of request parameters: Secrets Manager - when connecting to a cluster, provide the secret-arn of a secret stored in Secrets Manager which has username and password. The specified secret contains credentials to connect to the database you specify. When you are connecting to a cluster, you also supply the database name, If you provide a cluster identifier (dbClusterIdentifier), it must match the cluster identifier stored in the secret. When you are connecting to a serverless workgroup, you also supply the database name. Temporary credentials - when connecting to your data warehouse, choose one of the following options: When connecting to a serverless workgroup, specify the workgroup name and database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift-serverless:GetCredentials operation is required. When connecting to a cluster as an IAM identity, specify the cluster identifier and the database name. The database user name is derived from the IAM identity. For example, arn:iam::123456789012:user:foo has the database user name IAM:foo. Also, permission to call the redshift:GetClusterCredentialsWithIAM operation is required. When connecting to a cluster as a database user, specify the cluster identifier, the database name, and the database user name. Also, permission to call the redshift:GetClusterCredentials operation is required. For more information about the Amazon Redshift Data API and CLI usage examples, see Using the Amazon Redshift Data API (https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html) in the Amazon Redshift Management Guide.
#
# POST /
# operationId: ListTables
export def "list-tables" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  --cluster-identifier: string # The cluster identifier. This parameter is required when connecting to a cluster and authenticating using either Secrets Manager or temporary credentials.
  --connected-database: string # A database name. The connected database is specified when you connect with your authentication credentials.
  database: string # The name of the database that contains the tables to list. If ConnectedDatabase is not specified, this is also the database to connect to with your authentication credentials.
  --db-user: string # The database user name. This parameter is required when connecting to a cluster as a database user and authenticating using temporary credentials.
  --body-max-results: int # The maximum number of tables to return in the response. If more tables exist than fit in one response, then NextToken is returned to page through the results. (spec name: MaxResults)
  --body-next-token: string # A value that indicates the starting point for the next set of response records in a subsequent request. If a value is returned in a response, you can retrieve the next set of records by providing this returned NextToken value in the next NextToken parameter and retrying the command. If the NextToken field is empty, all response records have been retrieved for the request. (spec name: NextToken)
  --schema-pattern: string # A pattern to filter results by schema name. Within a schema pattern, "%" means match any substring of 0 or more characters and "_" means match any one character. Only schema name entries matching the search pattern are returned. If SchemaPattern is not specified, then all tables that match TablePattern are returned. If neither SchemaPattern or TablePattern are specified, then all tables are returned.
  --secret-arn: string # The name or ARN of the secret that enables access to the database. This parameter is required when authenticating using Secrets Manager.
  --table-pattern: string # A pattern to filter results by table name. Within a table pattern, "%" means match any substring of 0 or more characters and "_" means match any one character. Only table name entries matching the search pattern are returned. If TablePattern is not specified, then all tables that match SchemaPatternare returned. If neither SchemaPattern or TablePattern are specified, then all tables are returned.
  --workgroup-name: string # The serverless workgroup name or Amazon Resource Name (ARN). This parameter is required when connecting to a serverless workgroup and authenticating using either Secrets Manager or temporary credentials.
]: any -> oneof<record<NextToken: string, Tables: table<name: string, schema: string, type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "RedshiftData.ListTables")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ClusterIdentifier": $cluster_identifier, "ConnectedDatabase": $connected_database, "Database": $database, "DbUser": $db_user, "MaxResults": $body_max_results, "NextToken": $body_next_token, "SchemaPattern": $schema_pattern, "SecretArn": $secret_arn, "TablePattern": $table_pattern, "WorkgroupName": $workgroup_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
