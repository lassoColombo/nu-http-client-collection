# Auto-generated client for Amazon DynamoDB v2012-08-10
# Source: https://api.apis.guru/v2/specs/amazonaws.com/dynamodb/2012-08-10/openapi.json
# Auth: --token flag or $env.AMAZON_DYNAMODB_TOKEN

const BASE_URL = "http://dynamodb.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_DYNAMODB_TOKEN | default "" }
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

def base-url-completer [] { ["http://dynamodb.us-east-1.amazonaws.com" "http://dynamodb.us-east-2.amazonaws.com" "http://dynamodb.us-west-1.amazonaws.com" "http://dynamodb.us-west-2.amazonaws.com" "http://dynamodb.us-gov-west-1.amazonaws.com" "http://dynamodb.us-gov-east-1.amazonaws.com" "http://dynamodb.ca-central-1.amazonaws.com" "http://dynamodb.eu-north-1.amazonaws.com" "http://dynamodb.eu-west-1.amazonaws.com" "http://dynamodb.eu-west-2.amazonaws.com" "http://dynamodb.eu-west-3.amazonaws.com" "http://dynamodb.eu-central-1.amazonaws.com" "http://dynamodb.eu-south-1.amazonaws.com" "http://dynamodb.af-south-1.amazonaws.com" "http://dynamodb.ap-northeast-1.amazonaws.com" "http://dynamodb.ap-northeast-2.amazonaws.com" "http://dynamodb.ap-northeast-3.amazonaws.com" "http://dynamodb.ap-southeast-1.amazonaws.com" "http://dynamodb.ap-southeast-2.amazonaws.com" "http://dynamodb.ap-east-1.amazonaws.com" "http://dynamodb.ap-south-1.amazonaws.com" "http://dynamodb.sa-east-1.amazonaws.com" "http://dynamodb.me-south-1.amazonaws.com" "https://dynamodb.us-east-1.amazonaws.com" "https://dynamodb.us-east-2.amazonaws.com" "https://dynamodb.us-west-1.amazonaws.com" "https://dynamodb.us-west-2.amazonaws.com" "https://dynamodb.us-gov-west-1.amazonaws.com" "https://dynamodb.us-gov-east-1.amazonaws.com" "https://dynamodb.ca-central-1.amazonaws.com" "https://dynamodb.eu-north-1.amazonaws.com" "https://dynamodb.eu-west-1.amazonaws.com" "https://dynamodb.eu-west-2.amazonaws.com" "https://dynamodb.eu-west-3.amazonaws.com" "https://dynamodb.eu-central-1.amazonaws.com" "https://dynamodb.eu-south-1.amazonaws.com" "https://dynamodb.af-south-1.amazonaws.com" "https://dynamodb.ap-northeast-1.amazonaws.com" "https://dynamodb.ap-northeast-2.amazonaws.com" "https://dynamodb.ap-northeast-3.amazonaws.com" "https://dynamodb.ap-southeast-1.amazonaws.com" "https://dynamodb.ap-southeast-2.amazonaws.com" "https://dynamodb.ap-east-1.amazonaws.com" "https://dynamodb.ap-south-1.amazonaws.com" "https://dynamodb.sa-east-1.amazonaws.com" "https://dynamodb.me-south-1.amazonaws.com" "http://dynamodb.cn-north-1.amazonaws.com.cn" "http://dynamodb.cn-northwest-1.amazonaws.com.cn" "https://dynamodb.cn-north-1.amazonaws.com.cn" "https://dynamodb.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def return-consumed-capacity-completer [] { ["INDEXES" "NONE" "TOTAL"] }
def x-amz-target-completer [] { ["DynamoDB_20120810.BatchExecuteStatement"] }
def x-amz-target-completer-1 [] { ["DynamoDB_20120810.BatchGetItem"] }
def return-item-collection-metrics-completer [] { ["NONE" "SIZE"] }
def x-amz-target-completer-2 [] { ["DynamoDB_20120810.BatchWriteItem"] }
def x-amz-target-completer-3 [] { ["DynamoDB_20120810.CreateBackup"] }
def x-amz-target-completer-4 [] { ["DynamoDB_20120810.CreateGlobalTable"] }
def billing-mode-completer [] { ["PAY_PER_REQUEST" "PROVISIONED"] }
def table-class-completer [] { ["STANDARD" "STANDARD_INFREQUENT_ACCESS"] }
def x-amz-target-completer-5 [] { ["DynamoDB_20120810.CreateTable"] }
def x-amz-target-completer-6 [] { ["DynamoDB_20120810.DeleteBackup"] }
def conditional-operator-completer [] { ["AND" "OR"] }
def return-values-completer [] { ["ALL_NEW" "ALL_OLD" "NONE" "UPDATED_NEW" "UPDATED_OLD"] }
def x-amz-target-completer-7 [] { ["DynamoDB_20120810.DeleteItem"] }
def x-amz-target-completer-8 [] { ["DynamoDB_20120810.DeleteTable"] }
def x-amz-target-completer-9 [] { ["DynamoDB_20120810.DescribeBackup"] }
def x-amz-target-completer-10 [] { ["DynamoDB_20120810.DescribeContinuousBackups"] }
def x-amz-target-completer-11 [] { ["DynamoDB_20120810.DescribeContributorInsights"] }
def x-amz-target-completer-12 [] { ["DynamoDB_20120810.DescribeEndpoints"] }
def x-amz-target-completer-13 [] { ["DynamoDB_20120810.DescribeExport"] }
def x-amz-target-completer-14 [] { ["DynamoDB_20120810.DescribeGlobalTable"] }
def x-amz-target-completer-15 [] { ["DynamoDB_20120810.DescribeGlobalTableSettings"] }
def x-amz-target-completer-16 [] { ["DynamoDB_20120810.DescribeImport"] }
def x-amz-target-completer-17 [] { ["DynamoDB_20120810.DescribeKinesisStreamingDestination"] }
def x-amz-target-completer-18 [] { ["DynamoDB_20120810.DescribeLimits"] }
def x-amz-target-completer-19 [] { ["DynamoDB_20120810.DescribeTable"] }
def x-amz-target-completer-20 [] { ["DynamoDB_20120810.DescribeTableReplicaAutoScaling"] }
def x-amz-target-completer-21 [] { ["DynamoDB_20120810.DescribeTimeToLive"] }
def x-amz-target-completer-22 [] { ["DynamoDB_20120810.DisableKinesisStreamingDestination"] }
def x-amz-target-completer-23 [] { ["DynamoDB_20120810.EnableKinesisStreamingDestination"] }
def x-amz-target-completer-24 [] { ["DynamoDB_20120810.ExecuteStatement"] }
def x-amz-target-completer-25 [] { ["DynamoDB_20120810.ExecuteTransaction"] }
def s3-sse-algorithm-completer [] { ["AES256" "KMS"] }
def export-format-completer [] { ["DYNAMODB_JSON" "ION"] }
def x-amz-target-completer-26 [] { ["DynamoDB_20120810.ExportTableToPointInTime"] }
def x-amz-target-completer-27 [] { ["DynamoDB_20120810.GetItem"] }
def input-format-completer [] { ["CSV" "DYNAMODB_JSON" "ION"] }
def input-compression-type-completer [] { ["GZIP" "NONE" "ZSTD"] }
def x-amz-target-completer-28 [] { ["DynamoDB_20120810.ImportTable"] }
def backup-type-completer [] { ["ALL" "AWS_BACKUP" "SYSTEM" "USER"] }
def x-amz-target-completer-29 [] { ["DynamoDB_20120810.ListBackups"] }
def x-amz-target-completer-30 [] { ["DynamoDB_20120810.ListContributorInsights"] }
def x-amz-target-completer-31 [] { ["DynamoDB_20120810.ListExports"] }
def x-amz-target-completer-32 [] { ["DynamoDB_20120810.ListGlobalTables"] }
def x-amz-target-completer-33 [] { ["DynamoDB_20120810.ListImports"] }
def x-amz-target-completer-34 [] { ["DynamoDB_20120810.ListTables"] }
def x-amz-target-completer-35 [] { ["DynamoDB_20120810.ListTagsOfResource"] }
def x-amz-target-completer-36 [] { ["DynamoDB_20120810.PutItem"] }
def select-completer [] { ["ALL_ATTRIBUTES" "ALL_PROJECTED_ATTRIBUTES" "COUNT" "SPECIFIC_ATTRIBUTES"] }
def x-amz-target-completer-37 [] { ["DynamoDB_20120810.Query"] }
def billing-mode-override-completer [] { ["PAY_PER_REQUEST" "PROVISIONED"] }
def x-amz-target-completer-38 [] { ["DynamoDB_20120810.RestoreTableFromBackup"] }
def x-amz-target-completer-39 [] { ["DynamoDB_20120810.RestoreTableToPointInTime"] }
def x-amz-target-completer-40 [] { ["DynamoDB_20120810.Scan"] }
def x-amz-target-completer-41 [] { ["DynamoDB_20120810.TagResource"] }
def x-amz-target-completer-42 [] { ["DynamoDB_20120810.TransactGetItems"] }
def x-amz-target-completer-43 [] { ["DynamoDB_20120810.TransactWriteItems"] }
def x-amz-target-completer-44 [] { ["DynamoDB_20120810.UntagResource"] }
def x-amz-target-completer-45 [] { ["DynamoDB_20120810.UpdateContinuousBackups"] }
def contributor-insights-action-completer [] { ["DISABLE" "ENABLE"] }
def x-amz-target-completer-46 [] { ["DynamoDB_20120810.UpdateContributorInsights"] }
def x-amz-target-completer-47 [] { ["DynamoDB_20120810.UpdateGlobalTable"] }
def global-table-billing-mode-completer [] { ["PAY_PER_REQUEST" "PROVISIONED"] }
def x-amz-target-completer-48 [] { ["DynamoDB_20120810.UpdateGlobalTableSettings"] }
def x-amz-target-completer-49 [] { ["DynamoDB_20120810.UpdateItem"] }
def x-amz-target-completer-50 [] { ["DynamoDB_20120810.UpdateTable"] }
def x-amz-target-completer-51 [] { ["DynamoDB_20120810.UpdateTableReplicaAutoScaling"] }
def x-amz-target-completer-52 [] { ["DynamoDB_20120810.UpdateTimeToLive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["batch-execute-statement" "batch-get-item" "batch-write-item" "create-backup" "create-global-table" "create-table" "delete-backup" "delete-item" "delete-table" "describe-backup" "describe-continuous-backups" "describe-contributor-insights" "describe-endpoints" "describe-export" "describe-global-table" "describe-global-table-settings" "describe-import" "describe-kinesis-streaming-destination" "describe-limits" "describe-table" "describe-table-replica-auto-scaling" "describe-time-to-live" "disable-kinesis-streaming-destination" "enable-kinesis-streaming-destination" "execute-statement" "execute-transaction" "export-table-to-point-in-time" "get-item" "import-table" "list-backups" "list-contributor-insights" "list-exports" "list-global-tables" "list-imports" "list-tables" "list-tags-of-resource" "put-item" "query" "restore-table-from-backup" "restore-table-to-point-in-time" "scan" "tag-resource" "transact-get-items" "transact-write-items" "untag-resource" "update-continuous-backups" "update-contributor-insights" "update-global-table" "update-global-table-settings" "update-item" "update-table" "update-table-replica-auto-scaling" "update-time-to-live" "commands"] | sort) } | get name | first)
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

# This operation allows you to perform batch reads or writes on data stored in DynamoDB, using PartiQL. Each read statement in a BatchExecuteStatement must specify an equality condition on all key attributes. This enforces that each SELECT statement in a batch returns at most a single item. The entire batch must consist of either read statements or write statements, you cannot mix both in one batch. A HTTP 200 response does not mean that all statements in the BatchExecuteStatement succeeded. Error details for individual statements can be found under the Error (https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchStatementResponse.html#DDB-Type-BatchStatementResponse-Error) field of the BatchStatementResponse for each statement.
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
  statements: list # The list of PartiQL statements representing the batch to run. — item shape: {Statement: string, Parameters?: list, ConsistentRead?: bool}
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
]: any -> oneof<record<Responses: table<Error: record, TableName: string, Item: record>, ConsumedCapacity: table<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.BatchExecuteStatement")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Statements": $statements, "ReturnConsumedCapacity": $return_consumed_capacity} | compact
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

# The BatchGetItem operation returns the attributes of one or more items from one or more tables. You identify requested items by primary key. A single operation can retrieve up to 16 MB of data, which can contain as many as 100 items. BatchGetItem returns a partial result if the response size limit is exceeded, the table's provisioned throughput is exceeded, or an internal processing failure occurs. If a partial result is returned, the operation returns a value for UnprocessedKeys. You can use this value to retry the operation starting with the next item to get. If you request more than 100 items, BatchGetItem returns a ValidationException with the message "Too many items requested for the BatchGetItem call." For example, if you ask to retrieve 100 items, but each individual item is 300 KB in size, the system returns 52 items (so as not to exceed the 16 MB limit). It also returns an appropriate UnprocessedKeys value so you can get the next page of results. If desired, your application can include its own logic to assemble the pages of results into one dataset. If none of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then BatchGetItem returns a ProvisionedThroughputExceededException. If at least one of the items is successfully processed, then BatchGetItem completes successfully, while returning the keys of the unread items in UnprocessedKeys. If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, we strongly recommend that you use an exponential backoff algorithm. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed. For more information, see Batch Operations and Error Handling (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#BatchOperations) in the Amazon DynamoDB Developer Guide. By default, BatchGetItem performs eventually consistent reads on every table in the request. If you want strongly consistent reads instead, you can set ConsistentRead to true for any or all tables. In order to minimize response latency, BatchGetItem may retrieve items in parallel. When designing your application, keep in mind that DynamoDB does not return items in any particular order. To help parse the response by item, include the primary key values for the items in your request in the ProjectionExpression parameter. If a requested item does not exist, it is not returned in the result. Requests for nonexistent items consume the minimum read capacity units according to the type of read. For more information, see Working with Tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithTables.html#CapacityUnitCalculations) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: BatchGetItem
export def "batch-get-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --request-items: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1 # required
  --request-items-body: record # A map of one or more table names and, for each table, a map that describes one or more items to retrieve from that table. Each table name can be used only once per BatchGetItem request. Each element in the map of items to retrieve consists of the following: ConsistentRead - If true, a strongly consistent read is used; if false (the default), an eventually consistent read is used. ExpressionAttributeNames - One or more substitution tokens for attribute names in the ProjectionExpression parameter. The following are some use cases for using ExpressionAttributeNames: To access an attribute whose name conflicts with a DynamoDB reserved word. To create a placeholder for repeating occurrences of an attribute name in an expression. To prevent special characters in an attribute name from being misinterpreted in an expression. Use the # character in an expression to dereference an attribute name. For example, consider the following attribute name: Percentile The name of this attribute conflicts with a reserved word, so it cannot be used directly in an expression. (For the complete list of reserved words, see Reserved Words (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ReservedWords.html) in the Amazon DynamoDB Developer Guide). To work around this, you could specify the following for ExpressionAttributeNames: {"#P":"Percentile"} You could then use this substitution in an expression, as in this example: #P = :val Tokens that begin with the : character are expression attribute values, which are placeholders for the actual value at runtime. For more information about expression attribute names, see Accessing Item Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html) in the Amazon DynamoDB Developer Guide. Keys - An array of primary key attribute values that define specific items in the table. For each primary key, you must provide all of the key attributes. For example, with a simple primary key, you only need to provide the partition key value. For a composite key, you must provide both the partition key value and the sort key value. ProjectionExpression - A string that identifies one or more attributes to retrieve from the table. These attributes can include scalars, sets, or elements of a JSON document. The attributes in the expression must be separated by commas. If no attribute names are specified, then all attributes are returned. If any of the requested attributes are not found, they do not appear in the result. For more information, see Accessing Item Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html) in the Amazon DynamoDB Developer Guide. AttributesToGet - This is a legacy parameter. Use ProjectionExpression instead. For more information, see AttributesToGet (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.AttributesToGet.html) in the Amazon DynamoDB Developer Guide. (body field)
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
]: any -> oneof<record<Responses: record, UnprocessedKeys: record, ConsumedCapacity: table<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.BatchGetItem")
  let qp = [(serialize-qp "RequestItems" $request_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"RequestItems": $request_items_body, "ReturnConsumedCapacity": $return_consumed_capacity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "RequestItems") == null) { error make --unspanned { msg: "required body field 'RequestItems' missing: pass --request-items-body or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"RequestItems": $request_items} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# The BatchWriteItem operation puts or deletes multiple items in one or more tables. A single call to BatchWriteItem can transmit up to 16MB of data over the network, consisting of up to 25 item put or delete operations. While individual items can be up to 400 KB once stored, it's important to note that an item's representation might be greater than 400KB while being sent in DynamoDB's JSON format for the API call. For more details on this distinction, see Naming Rules and Data Types (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html). BatchWriteItem cannot update items. If you perform a BatchWriteItem operation on an existing item, that item's values will be overwritten by the operation and it will appear like it was updated. To update items, we recommend you use the UpdateItem action. The individual PutItem and DeleteItem operations specified in BatchWriteItem are atomic; however BatchWriteItem as a whole is not. If any requested operations fail because the table's provisioned throughput is exceeded or an internal processing failure occurs, the failed operations are returned in the UnprocessedItems response parameter. You can investigate and optionally resend the requests. Typically, you would call BatchWriteItem in a loop. Each iteration would check for unprocessed items and submit a new BatchWriteItem request with those unprocessed items until all items have been processed. If none of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then BatchWriteItem returns a ProvisionedThroughputExceededException. If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, we strongly recommend that you use an exponential backoff algorithm. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed. For more information, see Batch Operations and Error Handling (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#Programming.Errors.BatchOperations) in the Amazon DynamoDB Developer Guide. With BatchWriteItem, you can efficiently write or delete large amounts of data, such as from Amazon EMR, or copy data from another database into DynamoDB. In order to improve performance with these large-scale operations, BatchWriteItem does not behave in the same way as individual PutItem and DeleteItem calls would. For example, you cannot specify conditions on individual put and delete requests, and BatchWriteItem does not return deleted items in the response. If you use a programming language that supports concurrency, you can use threads to write items in parallel. Your application must include the necessary logic to manage the threads. With languages that don't support threading, you must update or delete the specified items one at a time. In both situations, BatchWriteItem performs the specified put and delete operations in parallel, giving you the power of the thread pool approach without having to introduce complexity into your application. Parallel processing reduces latency, but each specified put and delete request consumes the same number of write capacity units whether it is processed in parallel or not. Delete operations on nonexistent items consume one write capacity unit. If one or more of the following is true, DynamoDB rejects the entire batch write operation: One or more tables specified in the BatchWriteItem request does not exist. Primary key attributes specified on an item in the request do not match those in the corresponding table's primary key schema. You try to perform multiple operations on the same item in the same BatchWriteItem request. For example, you cannot put and delete the same item in the same BatchWriteItem request. Your request contains at least two items with identical hash and range keys (which essentially is two put operations). There are more than 25 requests in the batch. Any individual item in a batch exceeds 400 KB. The total request size exceeds 16 MB.
#
# POST /
# operationId: BatchWriteItem
export def "batch-write-item" [
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
  request_items: record # A map of one or more table names and, for each table, a list of operations to be performed (DeleteRequest or PutRequest). Each element in the map consists of the following: DeleteRequest - Perform a DeleteItem operation on the specified item. The item to be deleted is identified by a Key subelement: Key - A map of primary key attribute values that uniquely identify the item. Each entry in this map consists of an attribute name and an attribute value. For each primary key, you must provide all of the key attributes. For example, with a simple primary key, you only need to provide a value for the partition key. For a composite primary key, you must provide values for both the partition key and the sort key. PutRequest - Perform a PutItem operation on the specified item. The item to be put is identified by an Item subelement: Item - A map of attributes and their values. Each entry in this map consists of an attribute name and an attribute value. Attribute values must not be null; string and binary type attributes must have lengths greater than zero; and set type attributes must not be empty. Requests that contain empty values are rejected with a ValidationException exception. If you specify any attributes that are part of an index key, then the data types for those attributes must match those of the schema in the table's attribute definition.
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --return-item-collection-metrics: string@return-item-collection-metrics-completer # Determines whether item collection metrics are returned. If set to SIZE, the response includes statistics about item collections, if any, that were modified during the operation are returned in the response. If set to NONE (the default), no statistics are returned.
]: any -> oneof<record<UnprocessedItems: record, ItemCollectionMetrics: record, ConsumedCapacity: table<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.BatchWriteItem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RequestItems": $request_items, "ReturnConsumedCapacity": $return_consumed_capacity, "ReturnItemCollectionMetrics": $return_item_collection_metrics} | compact
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

# Creates a backup for an existing table. Each time you create an on-demand backup, the entire table data is backed up. There is no limit to the number of on-demand backups that can be taken. When you create an on-demand backup, a time marker of the request is cataloged, and the backup is created asynchronously, by applying all changes until the time of the request to the last full table snapshot. Backup requests are processed instantaneously and become available for restore within minutes. You can call CreateBackup at a maximum rate of 50 times per second. All backups in DynamoDB work without consuming any provisioned throughput on the table. If you submit a backup request on 2018-12-14 at 14:25:00, the backup is guaranteed to contain all data committed to the table up to 14:24:00, and data committed after 14:26:00 will not be. The backup might contain data modifications made between 14:24:00 and 14:26:00. On-demand backup does not support causal consistency. Along with data, the following are also included on the backups: Global secondary indexes (GSIs) Local secondary indexes (LSIs) Streams Provisioned read and write capacity
#
# POST /
# operationId: CreateBackup
export def "create-backup" [
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
  table_name: string # The name of the table.
  backup_name: string # Specified name for the backup.
]: any -> oneof<record<BackupDetails: record<BackupArn: string, BackupName: string, BackupSizeBytes: int, BackupStatus: string, BackupType: string, BackupCreationDateTime: string, BackupExpiryDateTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.CreateBackup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "BackupName": $backup_name} | compact
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

# Creates a global table from an existing table. A global table creates a replication relationship between two or more DynamoDB tables with the same table name in the provided Regions. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html). If you want to add a new replica table to a global table, each of the following conditions must be true: The table must have the same primary key as all of the other replicas. The table must have the same name as all of the other replicas. The table must have DynamoDB Streams enabled, with the stream containing both the new and the old images of the item. None of the replica tables in the global table can contain any data. If global secondary indexes are specified, then the following conditions must also be met: The global secondary indexes must have the same name. The global secondary indexes must have the same hash key and sort key (if present). If local secondary indexes are specified, then the following conditions must also be met: The local secondary indexes must have the same name. The local secondary indexes must have the same hash key and sort key (if present). Write capacity settings should be set consistently across your replica tables and secondary indexes. DynamoDB strongly recommends enabling auto scaling to manage the write capacity settings for all of your global tables replicas and indexes. If you prefer to manage write capacity settings manually, you should provision equal replicated write capacity units to your replica tables. You should also provision equal replicated write capacity units to matching secondary indexes across your global table.
#
# POST /
# operationId: CreateGlobalTable
export def "create-global-table" [
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
  global_table_name: string # The global table name.
  replication_group: list # The Regions where the global table needs to be created. — item shape: {RegionName?: string}
]: any -> oneof<record<GlobalTableDescription: record<ReplicationGroup: list<record>, GlobalTableArn: string, CreationDateTime: string, GlobalTableStatus: string, GlobalTableName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.CreateGlobalTable")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GlobalTableName": $global_table_name, "ReplicationGroup": $replication_group} | compact
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

# The CreateTable operation adds a new table to your account. In an Amazon Web Services account, table names must be unique within each Region. That is, you can have two tables with same name if you create the tables in different Regions. CreateTable is an asynchronous operation. Upon receiving a CreateTable request, DynamoDB immediately returns a response with a TableStatus of CREATING. After the table is created, DynamoDB sets the TableStatus to ACTIVE. You can perform read and write operations only on an ACTIVE table. You can optionally define secondary indexes on the new table, as part of the CreateTable operation. If you want to create multiple tables with secondary indexes on them, you must create the tables sequentially. Only one table with secondary indexes can be in the CREATING state at any given time. You can use the DescribeTable action to check the table status.
#
# POST /
# operationId: CreateTable
export def "create-table" [
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
  attribute_definitions: list # An array of attributes that describe the key schema for the table and indexes. — item shape: {AttributeName: string, AttributeType: "S"|"N"|"B"}
  table_name: string # The name of the table to create.
  key_schema: list # Specifies the attributes that make up the primary key for a table or an index. The attributes in KeySchema must also be defined in the AttributeDefinitions array. For more information, see Data Model (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DataModel.html) in the Amazon DynamoDB Developer Guide. Each KeySchemaElement in the array is composed of: AttributeName - The name of this key attribute. KeyType - The role that the key attribute will assume: HASH - partition key RANGE - sort key The partition key of an item is also known as its hash attribute. The term "hash attribute" derives from the DynamoDB usage of an internal hash function to evenly distribute data items across partitions, based on their partition key values. The sort key of an item is also known as its range attribute. The term "range attribute" derives from the way DynamoDB stores items with the same partition key physically close together, in sorted order by the sort key value. For a simple primary key (partition key), you must provide exactly one element with a KeyType of HASH. For a composite primary key (partition key and sort key), you must provide exactly two elements, in this order: The first element must have a KeyType of HASH, and the second element must have a KeyType of RANGE. For more information, see Working with Tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithTables.html#WorkingWithTables.primary.key) in the Amazon DynamoDB Developer Guide. — item shape: {AttributeName: string, KeyType: "HASH"|"RANGE"}
  --local-secondary-indexes: list # One or more local secondary indexes (the maximum is 5) to be created on the table. Each index is scoped to a given partition key value. There is a 10 GB size limit per partition key value; otherwise, the size of a local secondary index is unconstrained. Each local secondary index in the array includes the following: IndexName - The name of the local secondary index. Must be unique only for this table. KeySchema - Specifies the key schema for the local secondary index. The key schema must begin with the same partition key as the table. Projection - Specifies attributes that are copied (projected) from the table into the index. These are in addition to the primary key attributes and index key attributes, which are automatically projected. Each attribute specification is composed of: ProjectionType - One of the following: KEYS_ONLY - Only the index and primary keys are projected into the index. INCLUDE - Only the specified table attributes are projected into the index. The list of projected attributes is in NonKeyAttributes. ALL - All of the table attributes are projected into the index. NonKeyAttributes - A list of one or more non-key attribute names that are projected into the secondary index. The total count of attributes provided in NonKeyAttributes, summed across all of the secondary indexes, must not exceed 100. If you project the same attribute into two different indexes, this counts as two distinct attributes when determining the total. — item shape: {IndexName: string, KeySchema: list, Projection: record}
  --global-secondary-indexes: list # One or more global secondary indexes (the maximum is 20) to be created on the table. Each global secondary index in the array includes the following: IndexName - The name of the global secondary index. Must be unique only for this table. KeySchema - Specifies the key schema for the global secondary index. Projection - Specifies attributes that are copied (projected) from the table into the index. These are in addition to the primary key attributes and index key attributes, which are automatically projected. Each attribute specification is composed of: ProjectionType - One of the following: KEYS_ONLY - Only the index and primary keys are projected into the index. INCLUDE - Only the specified table attributes are projected into the index. The list of projected attributes is in NonKeyAttributes. ALL - All of the table attributes are projected into the index. NonKeyAttributes - A list of one or more non-key attribute names that are projected into the secondary index. The total count of attributes provided in NonKeyAttributes, summed across all of the secondary indexes, must not exceed 100. If you project the same attribute into two different indexes, this counts as two distinct attributes when determining the total. ProvisionedThroughput - The provisioned throughput settings for the global secondary index, consisting of read and write capacity units. — item shape: {IndexName: string, KeySchema: list, Projection: record, ProvisionedThroughput?: record}
  --billing-mode: string@billing-mode-completer # Controls how you are charged for read and write throughput and how you manage capacity. This setting can be changed later. PROVISIONED - We recommend using PROVISIONED for predictable workloads. PROVISIONED sets the billing mode to Provisioned Mode (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadWriteCapacityMode.html#HowItWorks.ProvisionedThroughput.Manual). PAY_PER_REQUEST - We recommend using PAY_PER_REQUEST for unpredictable workloads. PAY_PER_REQUEST sets the billing mode to On-Demand Mode (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadWriteCapacityMode.html#HowItWorks.OnDemand).
  --provisioned-throughput: record # Represents the provisioned throughput settings for a specified table or index. The settings can be modified using the UpdateTable operation. For current minimum and maximum provisioned throughput values, see Service, Account, and Table Quotas (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html) in the Amazon DynamoDB Developer Guide. — shape: {ReadCapacityUnits: int, WriteCapacityUnits: int}
  --stream-specification: record # Represents the DynamoDB Streams configuration for a table in DynamoDB. — shape: {StreamEnabled: bool, StreamViewType?: "NEW_IMAGE"|"OLD_IMAGE"|"NEW_AND_OLD_IMAGES"|"KEYS_ONLY"}
  --sse-specification: record # Represents the settings used to enable server-side encryption. — shape: {Enabled?: bool, SSEType?: "AES256"|"KMS", KMSMasterKeyId?: string}
  --tags: list # A list of key-value pairs to label the table. For more information, see Tagging for DynamoDB (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html). — item shape: {Key: string, Value: string}
  --table-class: string@table-class-completer # The table class of the new table. Valid values are STANDARD and STANDARD_INFREQUENT_ACCESS.
  --deletion-protection-enabled: oneof<nothing, bool> # Indicates whether deletion protection is to be enabled (true) or disabled (false) on the table.
]: any -> oneof<record<TableDescription: record<AttributeDefinitions: list<record>, TableName: string, KeySchema: list<record>, TableStatus: string, CreationDateTime: string, ProvisionedThroughput: record<LastIncreaseDateTime: string, LastDecreaseDateTime: string, NumberOfDecreasesToday: int, ReadCapacityUnits: int, WriteCapacityUnits: int>, TableSizeBytes: int, ItemCount: int, TableArn: string, TableId: string, BillingModeSummary: record<BillingMode: string, LastUpdateToPayPerRequestDateTime: string>, LocalSecondaryIndexes: list<record>, GlobalSecondaryIndexes: list<record>, StreamSpecification: record<StreamEnabled: bool, StreamViewType: string>, LatestStreamLabel: string, LatestStreamArn: string, GlobalTableVersion: string, Replicas: list<record>, RestoreSummary: record<SourceBackupArn: string, SourceTableArn: string, RestoreDateTime: string, RestoreInProgress: bool>, SSEDescription: record<Status: string, SSEType: string, KMSMasterKeyArn: string, InaccessibleEncryptionDateTime: string>, ArchivalSummary: record<ArchivalDateTime: string, ArchivalReason: string, ArchivalBackupArn: string>, TableClassSummary: record<TableClass: string, LastUpdateDateTime: string>, DeletionProtectionEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.CreateTable")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AttributeDefinitions": $attribute_definitions, "TableName": $table_name, "KeySchema": $key_schema, "LocalSecondaryIndexes": $local_secondary_indexes, "GlobalSecondaryIndexes": $global_secondary_indexes, "BillingMode": $billing_mode, "ProvisionedThroughput": $provisioned_throughput, "StreamSpecification": $stream_specification, "SSESpecification": $sse_specification, "Tags": $tags, "TableClass": $table_class, "DeletionProtectionEnabled": $deletion_protection_enabled} | compact
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

# Deletes an existing backup of a table. You can call DeleteBackup at a maximum rate of 10 times per second.
#
# POST /
# operationId: DeleteBackup
export def "delete-backup" [
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
  backup_arn: string # The ARN associated with the backup.
]: any -> oneof<record<BackupDescription: record<BackupDetails: record<BackupArn: string, BackupName: string, BackupSizeBytes: int, BackupStatus: string, BackupType: string, BackupCreationDateTime: string, BackupExpiryDateTime: string>, SourceTableDetails: record<TableName: string, TableId: string, TableArn: string, TableSizeBytes: int, KeySchema: list, TableCreationDateTime: string, ProvisionedThroughput: record, ItemCount: int, BillingMode: string>, SourceTableFeatureDetails: record<LocalSecondaryIndexes: list, GlobalSecondaryIndexes: list, StreamDescription: record, TimeToLiveDescription: record, SSEDescription: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DeleteBackup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BackupArn": $backup_arn} | compact
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

# Deletes a single item in a table by primary key. You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value. In addition to deleting an item, you can also return the item's attribute values in the same operation, using the ReturnValues parameter. Unless you specify conditions, the DeleteItem is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. Conditional deletes are useful for deleting items only if specific conditions are met. If those conditions are met, DynamoDB performs the delete. Otherwise, the item is not deleted.
#
# POST /
# operationId: DeleteItem
export def "delete-item" [
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
  table_name: string # The name of the table from which to delete the item.
  key: record # A map of attribute names to AttributeValue objects, representing the primary key of the item to delete. For the primary key, you must provide all of the key attributes. For example, with a simple primary key, you only need to provide a value for the partition key. For a composite primary key, you must provide values for both the partition key and the sort key.
  --expected: record # This is a legacy parameter. Use ConditionExpression instead. For more information, see Expected (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.Expected.html) in the Amazon DynamoDB Developer Guide.
  --conditional-operator: string@conditional-operator-completer # This is a legacy parameter. Use ConditionExpression instead. For more information, see ConditionalOperator (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.ConditionalOperator.html) in the Amazon DynamoDB Developer Guide.
  --return-values: string@return-values-completer # Use ReturnValues if you want to get the item attributes as they appeared before they were deleted. For DeleteItem, the valid values are: NONE - If ReturnValues is not specified, or if its value is NONE, then nothing is returned. (This setting is the default for ReturnValues.) ALL_OLD - The content of the old item is returned. There is no additional cost associated with requesting a return value aside from the small network and processing overhead of receiving a larger response. No read capacity units are consumed. The ReturnValues parameter is used by several DynamoDB operations; however, DeleteItem does not recognize any values other than NONE or ALL_OLD.
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --return-item-collection-metrics: string@return-item-collection-metrics-completer # Determines whether item collection metrics are returned. If set to SIZE, the response includes statistics about item collections, if any, that were modified during the operation are returned in the response. If set to NONE (the default), no statistics are returned.
  --condition-expression: string # A condition that must be satisfied in order for a conditional DeleteItem to succeed. An expression can contain any of the following: Functions: attribute_exists | attribute_not_exists | attribute_type | contains | begins_with | size These function names are case-sensitive. Comparison operators: = | <> | < | > | <= | >= | BETWEEN | IN Logical operators: AND | OR | NOT For more information about condition expressions, see Condition Expressions (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.SpecifyingConditions.html) in the Amazon DynamoDB Developer Guide.
  --expression-attribute-names: record # One or more substitution tokens for attribute names in an expression. The following are some use cases for using ExpressionAttributeNames: To access an attribute whose name conflicts with a DynamoDB reserved word. To create a placeholder for repeating occurrences of an attribute name in an expression. To prevent special characters in an attribute name from being misinterpreted in an expression. Use the # character in an expression to dereference an attribute name. For example, consider the following attribute name: Percentile The name of this attribute conflicts with a reserved word, so it cannot be used directly in an expression. (For the complete list of reserved words, see Reserved Words (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ReservedWords.html) in the Amazon DynamoDB Developer Guide). To work around this, you could specify the following for ExpressionAttributeNames: {"#P":"Percentile"} You could then use this substitution in an expression, as in this example: #P = :val Tokens that begin with the : character are expression attribute values, which are placeholders for the actual value at runtime. For more information on expression attribute names, see Specifying Item Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html) in the Amazon DynamoDB Developer Guide.
  --expression-attribute-values: record # One or more values that can be substituted in an expression. Use the : (colon) character in an expression to dereference an attribute value. For example, suppose that you wanted to check whether the value of the ProductStatus attribute was one of the following: Available | Backordered | Discontinued You would first need to specify ExpressionAttributeValues as follows: { ":avail":{"S":"Available"}, ":back":{"S":"Backordered"}, ":disc":{"S":"Discontinued"} } You could then use these values in an expression, such as this: ProductStatus IN (:avail, :back, :disc) For more information on expression attribute values, see Condition Expressions (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.SpecifyingConditions.html) in the Amazon DynamoDB Developer Guide.
]: any -> oneof<record<Attributes: record, ConsumedCapacity: record<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record<ReadCapacityUnits: float, WriteCapacityUnits: float, CapacityUnits: float>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>, ItemCollectionMetrics: record<ItemCollectionKey: record, SizeEstimateRangeGB: list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DeleteItem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "Key": $key, "Expected": $expected, "ConditionalOperator": $conditional_operator, "ReturnValues": $return_values, "ReturnConsumedCapacity": $return_consumed_capacity, "ReturnItemCollectionMetrics": $return_item_collection_metrics, "ConditionExpression": $condition_expression, "ExpressionAttributeNames": $expression_attribute_names, "ExpressionAttributeValues": $expression_attribute_values} | compact
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

# The DeleteTable operation deletes a table and all of its items. After a DeleteTable request, the specified table is in the DELETING state until DynamoDB completes the deletion. If the table is in the ACTIVE state, you can delete it. If a table is in CREATING or UPDATING states, then DynamoDB returns a ResourceInUseException. If the specified table does not exist, DynamoDB returns a ResourceNotFoundException. If table is already in the DELETING state, no error is returned. This operation only applies to Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) of global tables. DynamoDB might continue to accept data read and write operations, such as GetItem and PutItem, on a table in the DELETING state until the table deletion is complete. When you delete a table, any indexes on that table are also deleted. If you have DynamoDB Streams enabled on the table, then the corresponding stream on that table goes into the DISABLED state, and the stream is automatically deleted after 24 hours. Use the DescribeTable action to check the status of the table.
#
# POST /
# operationId: DeleteTable
export def "delete-table" [
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
  table_name: string # The name of the table to delete.
]: any -> oneof<record<TableDescription: record<AttributeDefinitions: list<record>, TableName: string, KeySchema: list<record>, TableStatus: string, CreationDateTime: string, ProvisionedThroughput: record<LastIncreaseDateTime: string, LastDecreaseDateTime: string, NumberOfDecreasesToday: int, ReadCapacityUnits: int, WriteCapacityUnits: int>, TableSizeBytes: int, ItemCount: int, TableArn: string, TableId: string, BillingModeSummary: record<BillingMode: string, LastUpdateToPayPerRequestDateTime: string>, LocalSecondaryIndexes: list<record>, GlobalSecondaryIndexes: list<record>, StreamSpecification: record<StreamEnabled: bool, StreamViewType: string>, LatestStreamLabel: string, LatestStreamArn: string, GlobalTableVersion: string, Replicas: list<record>, RestoreSummary: record<SourceBackupArn: string, SourceTableArn: string, RestoreDateTime: string, RestoreInProgress: bool>, SSEDescription: record<Status: string, SSEType: string, KMSMasterKeyArn: string, InaccessibleEncryptionDateTime: string>, ArchivalSummary: record<ArchivalDateTime: string, ArchivalReason: string, ArchivalBackupArn: string>, TableClassSummary: record<TableClass: string, LastUpdateDateTime: string>, DeletionProtectionEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DeleteTable")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name} | compact
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

# Describes an existing backup of a table. You can call DescribeBackup at a maximum rate of 10 times per second.
#
# POST /
# operationId: DescribeBackup
export def "describe-backup" [
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
  backup_arn: string # The Amazon Resource Name (ARN) associated with the backup.
]: any -> oneof<record<BackupDescription: record<BackupDetails: record<BackupArn: string, BackupName: string, BackupSizeBytes: int, BackupStatus: string, BackupType: string, BackupCreationDateTime: string, BackupExpiryDateTime: string>, SourceTableDetails: record<TableName: string, TableId: string, TableArn: string, TableSizeBytes: int, KeySchema: list, TableCreationDateTime: string, ProvisionedThroughput: record, ItemCount: int, BillingMode: string>, SourceTableFeatureDetails: record<LocalSecondaryIndexes: list, GlobalSecondaryIndexes: list, StreamDescription: record, TimeToLiveDescription: record, SSEDescription: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeBackup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BackupArn": $backup_arn} | compact
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

# Checks the status of continuous backups and point in time recovery on the specified table. Continuous backups are ENABLED on all tables at table creation. If point in time recovery is enabled, PointInTimeRecoveryStatus will be set to ENABLED. After continuous backups and point in time recovery are enabled, you can restore to any point in time within EarliestRestorableDateTime and LatestRestorableDateTime. LatestRestorableDateTime is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. You can call DescribeContinuousBackups at a maximum rate of 10 times per second.
#
# POST /
# operationId: DescribeContinuousBackups
export def "describe-continuous-backups" [
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
  table_name: string # Name of the table for which the customer wants to check the continuous backups and point in time recovery settings.
]: any -> oneof<record<ContinuousBackupsDescription: record<ContinuousBackupsStatus: string, PointInTimeRecoveryDescription: record<PointInTimeRecoveryStatus: string, EarliestRestorableDateTime: string, LatestRestorableDateTime: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeContinuousBackups")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name} | compact
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

# Returns information about contributor insights for a given table or global secondary index.
#
# POST /
# operationId: DescribeContributorInsights
export def "describe-contributor-insights" [
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
  table_name: string # The name of the table to describe.
  --index-name: string # The name of the global secondary index to describe, if applicable.
]: any -> oneof<record<TableName: string, IndexName: string, ContributorInsightsRuleList: list<string>, ContributorInsightsStatus: string, LastUpdateDateTime: string, FailureException: record<ExceptionName: string, ExceptionDescription: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeContributorInsights")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "IndexName": $index_name} | compact
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

# Returns the regional endpoint information. This action must be included in your VPC endpoint policies, or access to the DescribeEndpoints API will be denied. For more information on policy permissions, please see Internetwork traffic privacy (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/inter-network-traffic-privacy.html#inter-network-traffic-DescribeEndpoints).
#
# POST /
# operationId: DescribeEndpoints
export def "describe-endpoints" [
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
  --body: record
]: any -> oneof<record<Endpoints: table<Address: string, CachePeriodInMinutes: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeEndpoints")
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

# Describes an existing table export.
#
# POST /
# operationId: DescribeExport
export def "describe-export" [
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
  export_arn: string # The Amazon Resource Name (ARN) associated with the export.
]: any -> oneof<record<ExportDescription: record<ExportArn: string, ExportStatus: string, StartTime: string, EndTime: string, ExportManifest: string, TableArn: string, TableId: string, ExportTime: string, ClientToken: string, S3Bucket: string, S3BucketOwner: string, S3Prefix: string, S3SseAlgorithm: string, S3SseKmsKeyId: string, FailureCode: string, FailureMessage: string, ExportFormat: string, BilledSizeBytes: int, ItemCount: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeExport")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ExportArn": $export_arn} | compact
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

# Returns information about the specified global table. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html).
#
# POST /
# operationId: DescribeGlobalTable
export def "describe-global-table" [
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
  global_table_name: string # The name of the global table.
]: any -> oneof<record<GlobalTableDescription: record<ReplicationGroup: list<record>, GlobalTableArn: string, CreationDateTime: string, GlobalTableStatus: string, GlobalTableName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeGlobalTable")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GlobalTableName": $global_table_name} | compact
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

# Describes Region-specific settings for a global table. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html).
#
# POST /
# operationId: DescribeGlobalTableSettings
export def "describe-global-table-settings" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  global_table_name: string # The name of the global table to describe.
]: any -> oneof<record<GlobalTableName: string, ReplicaSettings: table<RegionName: string, ReplicaStatus: string, ReplicaBillingModeSummary: record, ReplicaProvisionedReadCapacityUnits: int, ReplicaProvisionedReadCapacityAutoScalingSettings: record, ReplicaProvisionedWriteCapacityUnits: int, ReplicaProvisionedWriteCapacityAutoScalingSettings: record, ReplicaGlobalSecondaryIndexSettings: list, ReplicaTableClassSummary: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeGlobalTableSettings")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GlobalTableName": $global_table_name} | compact
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

# Represents the properties of the import.
#
# POST /
# operationId: DescribeImport
export def "describe-import" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  import_arn: string # The Amazon Resource Name (ARN) associated with the table you're importing to.
]: any -> oneof<record<ImportTableDescription: record<ImportArn: string, ImportStatus: string, TableArn: string, TableId: string, ClientToken: string, S3BucketSource: record<S3BucketOwner: string, S3Bucket: string, S3KeyPrefix: string>, ErrorCount: int, CloudWatchLogGroupArn: string, InputFormat: string, InputFormatOptions: record<Csv: record>, InputCompressionType: string, TableCreationParameters: record<TableName: string, AttributeDefinitions: list, KeySchema: list, BillingMode: string, ProvisionedThroughput: record, SSESpecification: record, GlobalSecondaryIndexes: list>, StartTime: string, EndTime: string, ProcessedSizeBytes: int, ProcessedItemCount: int, ImportedItemCount: int, FailureCode: string, FailureMessage: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeImport")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ImportArn": $import_arn} | compact
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

# Returns information about the status of Kinesis streaming.
#
# POST /
# operationId: DescribeKinesisStreamingDestination
export def "describe-kinesis-streaming-destination" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  table_name: string # The name of the table being described.
]: any -> oneof<record<TableName: string, KinesisDataStreamDestinations: table<StreamArn: string, DestinationStatus: string, DestinationStatusDescription: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeKinesisStreamingDestination")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name} | compact
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

# Returns the current provisioned-capacity quotas for your Amazon Web Services account in a Region, both for the Region as a whole and for any one DynamoDB table that you create there. When you establish an Amazon Web Services account, the account has initial quotas on the maximum read capacity units and write capacity units that you can provision across all of your DynamoDB tables in a given Region. Also, there are per-table quotas that apply when you create a table there. For more information, see Service, Account, and Table Quotas (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html) page in the Amazon DynamoDB Developer Guide. Although you can increase these quotas by filing a case at Amazon Web Services Support Center (https://console.aws.amazon.com/support/home#/), obtaining the increase is not instantaneous. The DescribeLimits action lets you write code to compare the capacity you are currently using to those quotas imposed by your account so that you have enough time to apply for an increase before you hit a quota. For example, you could use one of the Amazon Web Services SDKs to do the following: Call DescribeLimits for a particular Region to obtain your current account quotas on provisioned capacity there. Create a variable to hold the aggregate read capacity units provisioned for all your tables in that Region, and one to hold the aggregate write capacity units. Zero them both. Call ListTables to obtain a list of all your DynamoDB tables. For each table name listed by ListTables, do the following: Call DescribeTable with the table name. Use the data returned by DescribeTable to add the read capacity units and write capacity units provisioned for the table itself to your variables. If the table has one or more global secondary indexes (GSIs), loop over these GSIs and add their provisioned capacity values to your variables as well. Report the account quotas for that Region returned by DescribeLimits, along with the total current provisioned capacity levels you have calculated. This will let you see whether you are getting close to your account-level quotas. The per-table quotas apply only when you are creating a new table. They restrict the sum of the provisioned capacity of the new table itself and all its global secondary indexes. For existing tables and their GSIs, DynamoDB doesn't let you increase provisioned capacity extremely rapidly, but the only quota that applies is that the aggregate provisioned capacity over all your tables and GSIs cannot exceed either of the per-account quotas. DescribeLimits should only be called periodically. You can expect throttling errors if you call it more than once in a minute. The DescribeLimits Request element has no content.
#
# POST /
# operationId: DescribeLimits
export def "describe-limits" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  --body: record
]: any -> oneof<record<AccountMaxReadCapacityUnits: int, AccountMaxWriteCapacityUnits: int, TableMaxReadCapacityUnits: int, TableMaxWriteCapacityUnits: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeLimits")
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

# Returns information about the table, including the current status of the table, when it was created, the primary key schema, and any indexes on the table. This operation only applies to Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) of global tables. If you issue a DescribeTable request immediately after a CreateTable request, DynamoDB might return a ResourceNotFoundException. This is because DescribeTable uses an eventually consistent query, and the metadata for your table might not be available at that moment. Wait for a few seconds, and then try the DescribeTable request again.
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19 # required
  table_name: string # The name of the table to describe.
]: any -> oneof<record<Table: record<AttributeDefinitions: list<record>, TableName: string, KeySchema: list<record>, TableStatus: string, CreationDateTime: string, ProvisionedThroughput: record<LastIncreaseDateTime: string, LastDecreaseDateTime: string, NumberOfDecreasesToday: int, ReadCapacityUnits: int, WriteCapacityUnits: int>, TableSizeBytes: int, ItemCount: int, TableArn: string, TableId: string, BillingModeSummary: record<BillingMode: string, LastUpdateToPayPerRequestDateTime: string>, LocalSecondaryIndexes: list<record>, GlobalSecondaryIndexes: list<record>, StreamSpecification: record<StreamEnabled: bool, StreamViewType: string>, LatestStreamLabel: string, LatestStreamArn: string, GlobalTableVersion: string, Replicas: list<record>, RestoreSummary: record<SourceBackupArn: string, SourceTableArn: string, RestoreDateTime: string, RestoreInProgress: bool>, SSEDescription: record<Status: string, SSEType: string, KMSMasterKeyArn: string, InaccessibleEncryptionDateTime: string>, ArchivalSummary: record<ArchivalDateTime: string, ArchivalReason: string, ArchivalBackupArn: string>, TableClassSummary: record<TableClass: string, LastUpdateDateTime: string>, DeletionProtectionEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeTable")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name} | compact
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

# Describes auto scaling settings across replicas of the global table at once. This operation only applies to Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) of global tables.
#
# POST /
# operationId: DescribeTableReplicaAutoScaling
export def "describe-table-replica-auto-scaling" [
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
  table_name: string # The name of the table.
]: any -> oneof<record<TableAutoScalingDescription: record<TableName: string, TableStatus: string, Replicas: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeTableReplicaAutoScaling")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name} | compact
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

# Gives a description of the Time to Live (TTL) status on the specified table.
#
# POST /
# operationId: DescribeTimeToLive
export def "describe-time-to-live" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  table_name: string # The name of the table to be described.
]: any -> oneof<record<TimeToLiveDescription: record<TimeToLiveStatus: string, AttributeName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DescribeTimeToLive")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name} | compact
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

# Stops replication from the DynamoDB table to the Kinesis data stream. This is done without deleting either of the resources.
#
# POST /
# operationId: DisableKinesisStreamingDestination
export def "disable-kinesis-streaming-destination" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  table_name: string # The name of the DynamoDB table.
  stream_arn: string # The ARN for a Kinesis data stream.
]: any -> oneof<record<TableName: string, StreamArn: string, DestinationStatus: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.DisableKinesisStreamingDestination")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "StreamArn": $stream_arn} | compact
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

# Starts table data replication to the specified Kinesis data stream at a timestamp chosen during the enable workflow. If this operation doesn't return results immediately, use DescribeKinesisStreamingDestination to check if streaming to the Kinesis data stream is ACTIVE.
#
# POST /
# operationId: EnableKinesisStreamingDestination
export def "enable-kinesis-streaming-destination" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  table_name: string # The name of the DynamoDB table.
  stream_arn: string # The ARN for a Kinesis data stream.
]: any -> oneof<record<TableName: string, StreamArn: string, DestinationStatus: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.EnableKinesisStreamingDestination")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "StreamArn": $stream_arn} | compact
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

# This operation allows you to perform reads and singleton writes on data stored in DynamoDB, using PartiQL. For PartiQL reads (SELECT statement), if the total number of processed items exceeds the maximum dataset size limit of 1 MB, the read stops and results are returned to the user as a LastEvaluatedKey value to continue the read in a subsequent operation. If the filter criteria in WHERE clause does not match any data, the read will return an empty result set. A single SELECT statement response can return up to the maximum number of items (if using the Limit parameter) or a maximum of 1 MB of data (and then apply any filtering to the results using WHERE clause). If LastEvaluatedKey is present in the response, you need to paginate the result set. If NextToken is present, you need to paginate the result set and include NextToken.
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  statement: string # The PartiQL statement representing the operation to run.
  --parameters: list # The parameters for the PartiQL statement, if any. — item shape: {S?: string, N?: string, B?: string, SS?: list<string>, NS?: list<string>, BS?: list<string>, M?: record, L?: list, NULL?: bool, BOOL?: bool}
  --consistent-read: oneof<nothing, bool> # The consistency of a read operation. If set to true, then a strongly consistent read is used; otherwise, an eventually consistent read is used.
  --next-token: string # Set this value to get remaining results, if NextToken was returned in the statement response.
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --limit: int # The maximum number of items to evaluate (not necessarily the number of matching items). If DynamoDB processes the number of items up to the limit while processing the results, it stops the operation and returns the matching values up to that point, along with a key in LastEvaluatedKey to apply in a subsequent operation so you can pick up where you left off. Also, if the processed dataset size exceeds 1 MB before DynamoDB reaches this limit, it stops the operation and returns the matching values up to the limit, and a key in LastEvaluatedKey to apply in a subsequent operation to continue the operation.
]: any -> oneof<record<Items: list<record>, NextToken: string, ConsumedCapacity: record<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record<ReadCapacityUnits: float, WriteCapacityUnits: float, CapacityUnits: float>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>, LastEvaluatedKey: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.ExecuteStatement")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Statement": $statement, "Parameters": $parameters, "ConsistentRead": $consistent_read, "NextToken": $next_token, "ReturnConsumedCapacity": $return_consumed_capacity, "Limit": $limit} | compact
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

# This operation allows you to perform transactional reads or writes on data stored in DynamoDB, using PartiQL. The entire transaction must consist of either read statements or write statements, you cannot mix both in one transaction. The EXISTS function is an exception and can be used to check the condition of specific attributes of the item in a similar manner to ConditionCheck in the TransactWriteItems (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/transaction-apis.html#transaction-apis-txwriteitems) API.
#
# POST /
# operationId: ExecuteTransaction
export def "execute-transaction" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  transact_statements: list # The list of PartiQL statements representing the transaction to run. — item shape: {Statement: string, Parameters?: list}
  --client-request-token: string # Set this value to get remaining results, if NextToken was returned in the statement response.
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
]: any -> oneof<record<Responses: table<Item: record>, ConsumedCapacity: table<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.ExecuteTransaction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TransactStatements": $transact_statements, "ClientRequestToken": $client_request_token, "ReturnConsumedCapacity": $return_consumed_capacity} | compact
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

# Exports table data to an S3 bucket. The table must have point in time recovery enabled, and you can export data from any time within the point in time recovery window.
#
# POST /
# operationId: ExportTableToPointInTime
export def "export-table-to-point-in-time" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  table_arn: string # The Amazon Resource Name (ARN) associated with the table to export.
  --export-time: string # Time in the past from which to export table data, counted in seconds from the start of the Unix epoch. The table export will be a snapshot of the table's state at this point in time. (format: date-time)
  --client-token: string # Providing a ClientToken makes the call to ExportTableToPointInTimeInput idempotent, meaning that multiple identical calls have the same effect as one single call. A client token is valid for 8 hours after the first request that uses it is completed. After 8 hours, any request with the same client token is treated as a new request. Do not resubmit the same request with the same client token for more than 8 hours, or the result might not be idempotent. If you submit a request with the same client token but a change in other parameters within the 8-hour idempotency window, DynamoDB returns an ImportConflictException.
  s3_bucket: string # The name of the Amazon S3 bucket to export the snapshot to.
  --s3-bucket-owner: string # The ID of the Amazon Web Services account that owns the bucket the export will be stored in.
  --s3-prefix: string # The Amazon S3 bucket prefix to use as the file name and path of the exported snapshot.
  --s3-sse-algorithm: string@s3-sse-algorithm-completer # Type of encryption used on the bucket where export data will be stored. Valid values for S3SseAlgorithm are: AES256 - server-side encryption with Amazon S3 managed keys KMS - server-side encryption with KMS managed keys
  --s3-sse-kms-key-id: string # The ID of the KMS managed key used to encrypt the S3 bucket where export data will be stored (if applicable).
  --export-format: string@export-format-completer # The format for the exported data. Valid values for ExportFormat are DYNAMODB_JSON or ION.
]: any -> oneof<record<ExportDescription: record<ExportArn: string, ExportStatus: string, StartTime: string, EndTime: string, ExportManifest: string, TableArn: string, TableId: string, ExportTime: string, ClientToken: string, S3Bucket: string, S3BucketOwner: string, S3Prefix: string, S3SseAlgorithm: string, S3SseKmsKeyId: string, FailureCode: string, FailureMessage: string, ExportFormat: string, BilledSizeBytes: int, ItemCount: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.ExportTableToPointInTime")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableArn": $table_arn, "ExportTime": $export_time, "ClientToken": $client_token, "S3Bucket": $s3_bucket, "S3BucketOwner": $s3_bucket_owner, "S3Prefix": $s3_prefix, "S3SseAlgorithm": $s3_sse_algorithm, "S3SseKmsKeyId": $s3_sse_kms_key_id, "ExportFormat": $export_format} | compact
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

# The GetItem operation returns a set of attributes for the item with the given primary key. If there is no matching item, GetItem does not return any data and there will be no Item element in the response. GetItem provides an eventually consistent read by default. If your application requires a strongly consistent read, set ConsistentRead to true. Although a strongly consistent read might take more time than an eventually consistent read, it always returns the last updated value.
#
# POST /
# operationId: GetItem
export def "get-item" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  table_name: string # The name of the table containing the requested item.
  key: record # A map of attribute names to AttributeValue objects, representing the primary key of the item to retrieve. For the primary key, you must provide all of the attributes. For example, with a simple primary key, you only need to provide a value for the partition key. For a composite primary key, you must provide values for both the partition key and the sort key.
  --attributes-to-get: list<string> # This is a legacy parameter. Use ProjectionExpression instead. For more information, see AttributesToGet (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.AttributesToGet.html) in the Amazon DynamoDB Developer Guide.
  --consistent-read: oneof<nothing, bool> # Determines the read consistency model: If set to true, then the operation uses strongly consistent reads; otherwise, the operation uses eventually consistent reads.
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --projection-expression: string # A string that identifies one or more attributes to retrieve from the table. These attributes can include scalars, sets, or elements of a JSON document. The attributes in the expression must be separated by commas. If no attribute names are specified, then all attributes are returned. If any of the requested attributes are not found, they do not appear in the result. For more information, see Specifying Item Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html) in the Amazon DynamoDB Developer Guide.
  --expression-attribute-names: record # One or more substitution tokens for attribute names in an expression. The following are some use cases for using ExpressionAttributeNames: To access an attribute whose name conflicts with a DynamoDB reserved word. To create a placeholder for repeating occurrences of an attribute name in an expression. To prevent special characters in an attribute name from being misinterpreted in an expression. Use the # character in an expression to dereference an attribute name. For example, consider the following attribute name: Percentile The name of this attribute conflicts with a reserved word, so it cannot be used directly in an expression. (For the complete list of reserved words, see Reserved Words (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ReservedWords.html) in the Amazon DynamoDB Developer Guide). To work around this, you could specify the following for ExpressionAttributeNames: {"#P":"Percentile"} You could then use this substitution in an expression, as in this example: #P = :val Tokens that begin with the : character are expression attribute values, which are placeholders for the actual value at runtime. For more information on expression attribute names, see Specifying Item Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html) in the Amazon DynamoDB Developer Guide.
]: any -> oneof<record<Item: record, ConsumedCapacity: record<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record<ReadCapacityUnits: float, WriteCapacityUnits: float, CapacityUnits: float>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.GetItem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "Key": $key, "AttributesToGet": $attributes_to_get, "ConsistentRead": $consistent_read, "ReturnConsumedCapacity": $return_consumed_capacity, "ProjectionExpression": $projection_expression, "ExpressionAttributeNames": $expression_attribute_names} | compact
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

# Imports table data from an S3 bucket.
#
# POST /
# operationId: ImportTable
export def "import-table" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  --client-token: string # Providing a ClientToken makes the call to ImportTableInput idempotent, meaning that multiple identical calls have the same effect as one single call. A client token is valid for 8 hours after the first request that uses it is completed. After 8 hours, any request with the same client token is treated as a new request. Do not resubmit the same request with the same client token for more than 8 hours, or the result might not be idempotent. If you submit a request with the same client token but a change in other parameters within the 8-hour idempotency window, DynamoDB returns an IdempotentParameterMismatch exception.
  s3_bucket_source: record # The S3 bucket that is being imported from. — shape: {S3BucketOwner?: string, S3Bucket: string, S3KeyPrefix?: string}
  input_format: string@input-format-completer # The format of the source data. Valid values for ImportFormat are CSV, DYNAMODB_JSON or ION.
  --input-format-options: record # The format options for the data that was imported into the target table. There is one value, CsvOption. — shape: {Csv?: record}
  --input-compression-type: string@input-compression-type-completer # Type of compression to be used on the input coming from the imported table.
  table_creation_parameters: record # The parameters for the table created as part of the import operation. — shape: {TableName: string, AttributeDefinitions: list, KeySchema: list, BillingMode?: "PROVISIONED"|"PAY_PER_REQUEST", ProvisionedThroughput?: record, SSESpecification?: record, GlobalSecondaryIndexes?: list}
]: any -> oneof<record<ImportTableDescription: record<ImportArn: string, ImportStatus: string, TableArn: string, TableId: string, ClientToken: string, S3BucketSource: record<S3BucketOwner: string, S3Bucket: string, S3KeyPrefix: string>, ErrorCount: int, CloudWatchLogGroupArn: string, InputFormat: string, InputFormatOptions: record<Csv: record>, InputCompressionType: string, TableCreationParameters: record<TableName: string, AttributeDefinitions: list, KeySchema: list, BillingMode: string, ProvisionedThroughput: record, SSESpecification: record, GlobalSecondaryIndexes: list>, StartTime: string, EndTime: string, ProcessedSizeBytes: int, ProcessedItemCount: int, ImportedItemCount: int, FailureCode: string, FailureMessage: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.ImportTable")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ClientToken": $client_token, "S3BucketSource": $s3_bucket_source, "InputFormat": $input_format, "InputFormatOptions": $input_format_options, "InputCompressionType": $input_compression_type, "TableCreationParameters": $table_creation_parameters} | compact
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

# List backups associated with an Amazon Web Services account. To list backups for a given table, specify TableName. ListBackups returns a paginated list of results with at most 1 MB worth of items in a page. You can also specify a maximum number of entries to be returned in a page. In the request, start time is inclusive, but end time is exclusive. Note that these boundaries are for the time at which the original backup was requested. You can call ListBackups a maximum of five times per second.
#
# POST /
# operationId: ListBackups
export def "list-backups" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  --table-name: string # The backups from the table specified by TableName are listed.
  --limit: int # Maximum number of backups to return at once.
  --time-range-lower-bound: string # Only backups created after this time are listed. TimeRangeLowerBound is inclusive. (format: date-time)
  --time-range-upper-bound: string # Only backups created before this time are listed. TimeRangeUpperBound is exclusive. (format: date-time)
  --exclusive-start-backup-arn: string # LastEvaluatedBackupArn is the Amazon Resource Name (ARN) of the backup last evaluated when the current page of results was returned, inclusive of the current page of results. This value may be specified as the ExclusiveStartBackupArn of a new ListBackups operation in order to fetch the next page of results.
  --backup-type: string@backup-type-completer # The backups from the table specified by BackupType are listed. Where BackupType can be: USER - On-demand backup created by you. (The default setting if no other backup types are specified.) SYSTEM - On-demand backup automatically created by DynamoDB. ALL - All types of on-demand backups (USER and SYSTEM).
]: any -> oneof<record<BackupSummaries: table<TableName: string, TableId: string, TableArn: string, BackupArn: string, BackupName: string, BackupCreationDateTime: string, BackupExpiryDateTime: string, BackupStatus: string, BackupType: string, BackupSizeBytes: int>, LastEvaluatedBackupArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.ListBackups")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "Limit": $limit, "TimeRangeLowerBound": $time_range_lower_bound, "TimeRangeUpperBound": $time_range_upper_bound, "ExclusiveStartBackupArn": $exclusive_start_backup_arn, "BackupType": $backup_type} | compact
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

# Returns a list of ContributorInsightsSummary for a table and all its global secondary indexes.
#
# POST /
# operationId: ListContributorInsights
export def "list-contributor-insights" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  --table-name: string # The name of the table.
  --next-token-body: string # A token to for the desired page, if there is one. (body field)
  --max-results-body: int # Maximum number of results to return per page. (body field)
]: any -> oneof<record<ContributorInsightsSummaries: table<TableName: string, IndexName: string, ContributorInsightsStatus: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.ListContributorInsights")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TableName": $table_name, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists completed exports within the past 90 days.
#
# POST /
# operationId: ListExports
export def "list-exports" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  --table-arn: string # The Amazon Resource Name (ARN) associated with the exported table.
  --max-results-body: int # Maximum number of results to return per page. (body field)
  --next-token-body: string # An optional string that, if supplied, must be copied from the output of a previous call to ListExports. When provided in this manner, the API fetches the next page of results. (body field)
]: any -> oneof<record<ExportSummaries: table<ExportArn: string, ExportStatus: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.ListExports")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TableArn": $table_arn, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists all global tables that have a replica in the specified Region. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html).
#
# POST /
# operationId: ListGlobalTables
export def "list-global-tables" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  --exclusive-start-global-table-name: string # The first global table name that this operation will evaluate.
  --limit: int # The maximum number of table names to return, if the parameter is not specified DynamoDB defaults to 100. If the number of global tables DynamoDB finds reaches this limit, it stops the operation and returns the table names collected up to that point, with a table name in the LastEvaluatedGlobalTableName to apply in a subsequent operation to the ExclusiveStartGlobalTableName parameter.
  --region-name: string # Lists the global tables in a specific Region.
]: any -> oneof<record<GlobalTables: table<GlobalTableName: string, ReplicationGroup: list>, LastEvaluatedGlobalTableName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.ListGlobalTables")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ExclusiveStartGlobalTableName": $exclusive_start_global_table_name, "Limit": $limit, "RegionName": $region_name} | compact
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

# Lists completed imports within the past 90 days.
#
# POST /
# operationId: ListImports
export def "list-imports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33 # required
  --table-arn: string # The Amazon Resource Name (ARN) associated with the table that was imported to.
  --page-size-body: int # The number of ImportSummary objects returned in a single page. (body field)
  --next-token-body: string # An optional string that, if supplied, must be copied from the output of a previous call to ListImports. When provided in this manner, the API fetches the next page of results. (body field)
]: any -> oneof<record<ImportSummaryList: table<ImportArn: string, ImportStatus: string, TableArn: string, S3BucketSource: record, CloudWatchLogGroupArn: string, InputFormat: string, StartTime: string, EndTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.ListImports")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TableArn": $table_arn, "PageSize": $page_size_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns an array of table names associated with the current account and endpoint. The output from ListTables is paginated, with each page returning a maximum of 100 table names.
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
  --limit: string # Pagination limit
  --exclusive-start-table-name: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34 # required
  --exclusive-start-table-name-body: string # The first table name that this operation will evaluate. Use the value that was returned for LastEvaluatedTableName in a previous operation, so that you can obtain the next page of results. (body field)
  --limit-body: int # A maximum number of table names to return. If this parameter is not specified, the limit is 100. (body field)
]: any -> oneof<record<TableNames: list<string>, LastEvaluatedTableName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.ListTables")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "ExclusiveStartTableName" $exclusive_start_table_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ExclusiveStartTableName": $exclusive_start_table_name_body, "Limit": $limit_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "ExclusiveStartTableName": $exclusive_start_table_name} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List all tags on an Amazon DynamoDB resource. You can call ListTagsOfResource up to 10 times per second, per account. For an overview on tagging DynamoDB resources, see Tagging for DynamoDB (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: ListTagsOfResource
export def "list-tags-of-resource" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  resource_arn: string # The Amazon DynamoDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  --next-token: string # An optional string that, if supplied, must be copied from the output of a previous call to ListTagOfResource. When provided in this manner, this API fetches the next page of results.
]: any -> oneof<record<Tags: table<Key: string, Value: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.ListTagsOfResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "NextToken": $next_token} | compact
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

# Creates a new item, or replaces an old item with a new item. If an item that has the same primary key as the new item already exists in the specified table, the new item completely replaces the existing item. You can perform a conditional put operation (add a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values. You can return the item's attribute values in the same operation, using the ReturnValues parameter. When you add an item, the primary key attributes are the only required attributes. Empty String and Binary attribute values are allowed. Attribute values of type String and Binary must have a length greater than zero if the attribute is used as a key attribute for a table or index. Set type attributes cannot be empty. Invalid Requests with empty values will be rejected with a ValidationException exception. To prevent a new item from replacing an existing item, use a conditional expression that contains the attribute_not_exists function with the name of the attribute being used as the partition key for the table. Since every record must contain that attribute, the attribute_not_exists function will only succeed if no matching item exists. For more information about PutItem, see Working with Items (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: PutItem
export def "put-item" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  table_name: string # The name of the table to contain the item.
  item: record # A map of attribute name/value pairs, one for each attribute. Only the primary key attributes are required; you can optionally provide other attribute name-value pairs for the item. You must provide all of the attributes for the primary key. For example, with a simple primary key, you only need to provide a value for the partition key. For a composite primary key, you must provide both values for both the partition key and the sort key. If you specify any attributes that are part of an index key, then the data types for those attributes must match those of the schema in the table's attribute definition. Empty String and Binary attribute values are allowed. Attribute values of type String and Binary must have a length greater than zero if the attribute is used as a key attribute for a table or index. For more information about primary keys, see Primary Key (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html#HowItWorks.CoreComponents.PrimaryKey) in the Amazon DynamoDB Developer Guide. Each element in the Item map is an AttributeValue object.
  --expected: record # This is a legacy parameter. Use ConditionExpression instead. For more information, see Expected (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.Expected.html) in the Amazon DynamoDB Developer Guide.
  --return-values: string@return-values-completer # Use ReturnValues if you want to get the item attributes as they appeared before they were updated with the PutItem request. For PutItem, the valid values are: NONE - If ReturnValues is not specified, or if its value is NONE, then nothing is returned. (This setting is the default for ReturnValues.) ALL_OLD - If PutItem overwrote an attribute name-value pair, then the content of the old item is returned. The values returned are strongly consistent. There is no additional cost associated with requesting a return value aside from the small network and processing overhead of receiving a larger response. No read capacity units are consumed. The ReturnValues parameter is used by several DynamoDB operations; however, PutItem does not recognize any values other than NONE or ALL_OLD.
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --return-item-collection-metrics: string@return-item-collection-metrics-completer # Determines whether item collection metrics are returned. If set to SIZE, the response includes statistics about item collections, if any, that were modified during the operation are returned in the response. If set to NONE (the default), no statistics are returned.
  --conditional-operator: string@conditional-operator-completer # This is a legacy parameter. Use ConditionExpression instead. For more information, see ConditionalOperator (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.ConditionalOperator.html) in the Amazon DynamoDB Developer Guide.
  --condition-expression: string # A condition that must be satisfied in order for a conditional PutItem operation to succeed. An expression can contain any of the following: Functions: attribute_exists | attribute_not_exists | attribute_type | contains | begins_with | size These function names are case-sensitive. Comparison operators: = | <> | < | > | <= | >= | BETWEEN | IN Logical operators: AND | OR | NOT For more information on condition expressions, see Condition Expressions (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.SpecifyingConditions.html) in the Amazon DynamoDB Developer Guide.
  --expression-attribute-names: record # One or more substitution tokens for attribute names in an expression. The following are some use cases for using ExpressionAttributeNames: To access an attribute whose name conflicts with a DynamoDB reserved word. To create a placeholder for repeating occurrences of an attribute name in an expression. To prevent special characters in an attribute name from being misinterpreted in an expression. Use the # character in an expression to dereference an attribute name. For example, consider the following attribute name: Percentile The name of this attribute conflicts with a reserved word, so it cannot be used directly in an expression. (For the complete list of reserved words, see Reserved Words (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ReservedWords.html) in the Amazon DynamoDB Developer Guide). To work around this, you could specify the following for ExpressionAttributeNames: {"#P":"Percentile"} You could then use this substitution in an expression, as in this example: #P = :val Tokens that begin with the : character are expression attribute values, which are placeholders for the actual value at runtime. For more information on expression attribute names, see Specifying Item Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html) in the Amazon DynamoDB Developer Guide.
  --expression-attribute-values: record # One or more values that can be substituted in an expression. Use the : (colon) character in an expression to dereference an attribute value. For example, suppose that you wanted to check whether the value of the ProductStatus attribute was one of the following: Available | Backordered | Discontinued You would first need to specify ExpressionAttributeValues as follows: { ":avail":{"S":"Available"}, ":back":{"S":"Backordered"}, ":disc":{"S":"Discontinued"} } You could then use these values in an expression, such as this: ProductStatus IN (:avail, :back, :disc) For more information on expression attribute values, see Condition Expressions (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.SpecifyingConditions.html) in the Amazon DynamoDB Developer Guide.
]: any -> oneof<record<Attributes: record, ConsumedCapacity: record<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record<ReadCapacityUnits: float, WriteCapacityUnits: float, CapacityUnits: float>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>, ItemCollectionMetrics: record<ItemCollectionKey: record, SizeEstimateRangeGB: list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.PutItem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "Item": $item, "Expected": $expected, "ReturnValues": $return_values, "ReturnConsumedCapacity": $return_consumed_capacity, "ReturnItemCollectionMetrics": $return_item_collection_metrics, "ConditionalOperator": $conditional_operator, "ConditionExpression": $condition_expression, "ExpressionAttributeNames": $expression_attribute_names, "ExpressionAttributeValues": $expression_attribute_values} | compact
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

# You must provide the name of the partition key attribute and a single value for that attribute. Query returns all items with that partition key value. Optionally, you can provide a sort key attribute and use a comparison operator to refine the search results. Use the KeyConditionExpression parameter to provide a specific value for the partition key. The Query operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the Query operation by specifying a sort key value and a comparison operator in KeyConditionExpression. To further refine the Query results, you can optionally provide a FilterExpression. A FilterExpression determines which items within the results should be returned to you. All of the other results are discarded. A Query operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a FilterExpression. Query results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the ScanIndexForward parameter to false. A single Query operation will read up to the maximum number of items set (if using the Limit parameter) or a maximum of 1 MB of data and then apply any filtering to the results using FilterExpression. If LastEvaluatedKey is present in the response, you will need to paginate the result set. For more information, see Paginating the Results (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination) in the Amazon DynamoDB Developer Guide. FilterExpression is applied after a Query finishes, but before the results are returned. A FilterExpression cannot contain partition key or sort key attributes. You need to specify those attributes in the KeyConditionExpression. A Query operation can return an empty result set and a LastEvaluatedKey if all the items read for the page of results are filtered out. You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the ConsistentRead parameter to true and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify ConsistentRead when querying a global secondary index.
#
# POST /
# operationId: Query
export def "query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --exclusive-start-key: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37 # required
  table_name: string # The name of the table containing the requested items.
  --index-name: string # The name of an index to query. This index can be any local secondary index or global secondary index on the table. Note that if you use the IndexName parameter, you must also provide TableName.
  --select: string@select-completer # The attributes to be returned in the result. You can retrieve all item attributes, specific item attributes, the count of matching items, or in the case of an index, some or all of the attributes projected into the index. ALL_ATTRIBUTES - Returns all of the item attributes from the specified table or index. If you query a local secondary index, then for each matching item in the index, DynamoDB fetches the entire item from the parent table. If the index is configured to project all item attributes, then all of the data can be obtained from the local secondary index, and no fetching is required. ALL_PROJECTED_ATTRIBUTES - Allowed only when querying an index. Retrieves all attributes that have been projected into the index. If the index is configured to project all attributes, this return value is equivalent to specifying ALL_ATTRIBUTES. COUNT - Returns the number of matching items, rather than the matching items themselves. Note that this uses the same quantity of read capacity units as getting the items, and is subject to the same item size calculations. SPECIFIC_ATTRIBUTES - Returns only the attributes listed in ProjectionExpression. This return value is equivalent to specifying ProjectionExpression without specifying any value for Select. If you query or scan a local secondary index and request only attributes that are projected into that index, the operation will read only the index and not the table. If any of the requested attributes are not projected into the local secondary index, DynamoDB fetches each of these attributes from the parent table. This extra fetching incurs additional throughput cost and latency. If you query or scan a global secondary index, you can only request attributes that are projected into the index. Global secondary index queries cannot fetch attributes from the parent table. If neither Select nor ProjectionExpression are specified, DynamoDB defaults to ALL_ATTRIBUTES when accessing a table, and ALL_PROJECTED_ATTRIBUTES when accessing an index. You cannot use both Select and ProjectionExpression together in a single request, unless the value for Select is SPECIFIC_ATTRIBUTES. (This usage is equivalent to specifying ProjectionExpression without any value for Select.) If you use the ProjectionExpression parameter, then the value for Select can only be SPECIFIC_ATTRIBUTES. Any other value for Select will return an error.
  --attributes-to-get: list<string> # This is a legacy parameter. Use ProjectionExpression instead. For more information, see AttributesToGet (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.AttributesToGet.html) in the Amazon DynamoDB Developer Guide.
  --limit-body: int # The maximum number of items to evaluate (not necessarily the number of matching items). If DynamoDB processes the number of items up to the limit while processing the results, it stops the operation and returns the matching values up to that point, and a key in LastEvaluatedKey to apply in a subsequent operation, so that you can pick up where you left off. Also, if the processed dataset size exceeds 1 MB before DynamoDB reaches this limit, it stops the operation and returns the matching values up to the limit, and a key in LastEvaluatedKey to apply in a subsequent operation to continue the operation. For more information, see Query and Scan (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/QueryAndScan.html) in the Amazon DynamoDB Developer Guide. (body field)
  --consistent-read: oneof<nothing, bool> # Determines the read consistency model: If set to true, then the operation uses strongly consistent reads; otherwise, the operation uses eventually consistent reads. Strongly consistent reads are not supported on global secondary indexes. If you query a global secondary index with ConsistentRead set to true, you will receive a ValidationException.
  --key-conditions: record # This is a legacy parameter. Use KeyConditionExpression instead. For more information, see KeyConditions (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.KeyConditions.html) in the Amazon DynamoDB Developer Guide.
  --query-filter: record # This is a legacy parameter. Use FilterExpression instead. For more information, see QueryFilter (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.QueryFilter.html) in the Amazon DynamoDB Developer Guide.
  --conditional-operator: string@conditional-operator-completer # This is a legacy parameter. Use FilterExpression instead. For more information, see ConditionalOperator (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.ConditionalOperator.html) in the Amazon DynamoDB Developer Guide.
  --scan-index-forward: oneof<nothing, bool> # Specifies the order for index traversal: If true (default), the traversal is performed in ascending order; if false, the traversal is performed in descending order. Items with the same partition key value are stored in sorted order by sort key. If the sort key data type is Number, the results are stored in numeric order. For type String, the results are stored in order of UTF-8 bytes. For type Binary, DynamoDB treats each byte of the binary data as unsigned. If ScanIndexForward is true, DynamoDB returns the results in the order in which they are stored (by sort key value). This is the default behavior. If ScanIndexForward is false, DynamoDB reads the results in reverse order by sort key value, and then returns the results to the client.
  --exclusive-start-key-body: record # The primary key of the first item that this operation will evaluate. Use the value that was returned for LastEvaluatedKey in the previous operation. The data type for ExclusiveStartKey must be String, Number, or Binary. No set data types are allowed. (body field)
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --projection-expression: string # A string that identifies one or more attributes to retrieve from the table. These attributes can include scalars, sets, or elements of a JSON document. The attributes in the expression must be separated by commas. If no attribute names are specified, then all attributes will be returned. If any of the requested attributes are not found, they will not appear in the result. For more information, see Accessing Item Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html) in the Amazon DynamoDB Developer Guide.
  --filter-expression: string # A string that contains conditions that DynamoDB applies after the Query operation, but before the data is returned to you. Items that do not satisfy the FilterExpression criteria are not returned. A FilterExpression does not allow key attributes. You cannot define a filter expression based on a partition key or a sort key. A FilterExpression is applied after the items have already been read; the process of filtering does not consume any additional read capacity units. For more information, see Filter Expressions (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/QueryAndScan.html#Query.FilterExpression) in the Amazon DynamoDB Developer Guide.
  --key-condition-expression: string # The condition that specifies the key values for items to be retrieved by the Query action. The condition must perform an equality test on a single partition key value. The condition can optionally perform one of several comparison tests on a single sort key value. This allows Query to retrieve one item with a given partition key value and sort key value, or several items that have the same partition key value but different sort key values. The partition key equality test is required, and must be specified in the following format: partitionKeyName = :partitionkeyval If you also want to provide a condition for the sort key, it must be combined using AND with the condition for the sort key. Following is an example, using the = comparison operator for the sort key: partitionKeyName = :partitionkeyval AND sortKeyName = :sortkeyval Valid comparisons for the sort key condition are as follows: sortKeyName = :sortkeyval - true if the sort key value is equal to :sortkeyval. sortKeyName < :sortkeyval - true if the sort key value is less than :sortkeyval. sortKeyName <= :sortkeyval - true if the sort key value is less than or equal to :sortkeyval. sortKeyName > :sortkeyval - true if the sort key value is greater than :sortkeyval. sortKeyName >= :sortkeyval - true if the sort key value is greater than or equal to :sortkeyval. sortKeyName BETWEEN :sortkeyval1 AND :sortkeyval2 - true if the sort key value is greater than or equal to :sortkeyval1, and less than or equal to :sortkeyval2. begins_with ( sortKeyName, :sortkeyval ) - true if the sort key value begins with a particular operand. (You cannot use this function with a sort key that is of type Number.) Note that the function name begins_with is case-sensitive. Use the ExpressionAttributeValues parameter to replace tokens such as :partitionval and :sortval with actual values at runtime. You can optionally use the ExpressionAttributeNames parameter to replace the names of the partition key and sort key with placeholder tokens. This option might be necessary if an attribute name conflicts with a DynamoDB reserved word. For example, the following KeyConditionExpression parameter causes an error because Size is a reserved word: Size = :myval To work around this, define a placeholder (such a #S) to represent the attribute name Size. KeyConditionExpression then is as follows: #S = :myval For a list of reserved words, see Reserved Words (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ReservedWords.html) in the Amazon DynamoDB Developer Guide. For more information on ExpressionAttributeNames and ExpressionAttributeValues, see Using Placeholders for Attribute Names and Values (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ExpressionPlaceholders.html) in the Amazon DynamoDB Developer Guide.
  --expression-attribute-names: record # One or more substitution tokens for attribute names in an expression. The following are some use cases for using ExpressionAttributeNames: To access an attribute whose name conflicts with a DynamoDB reserved word. To create a placeholder for repeating occurrences of an attribute name in an expression. To prevent special characters in an attribute name from being misinterpreted in an expression. Use the # character in an expression to dereference an attribute name. For example, consider the following attribute name: Percentile The name of this attribute conflicts with a reserved word, so it cannot be used directly in an expression. (For the complete list of reserved words, see Reserved Words (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ReservedWords.html) in the Amazon DynamoDB Developer Guide). To work around this, you could specify the following for ExpressionAttributeNames: {"#P":"Percentile"} You could then use this substitution in an expression, as in this example: #P = :val Tokens that begin with the : character are expression attribute values, which are placeholders for the actual value at runtime. For more information on expression attribute names, see Specifying Item Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html) in the Amazon DynamoDB Developer Guide.
  --expression-attribute-values: record # One or more values that can be substituted in an expression. Use the : (colon) character in an expression to dereference an attribute value. For example, suppose that you wanted to check whether the value of the ProductStatus attribute was one of the following: Available | Backordered | Discontinued You would first need to specify ExpressionAttributeValues as follows: { ":avail":{"S":"Available"}, ":back":{"S":"Backordered"}, ":disc":{"S":"Discontinued"} } You could then use these values in an expression, such as this: ProductStatus IN (:avail, :back, :disc) For more information on expression attribute values, see Specifying Conditions (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.SpecifyingConditions.html) in the Amazon DynamoDB Developer Guide.
]: any -> oneof<record<Items: list<record>, Count: int, ScannedCount: int, LastEvaluatedKey: record, ConsumedCapacity: record<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record<ReadCapacityUnits: float, WriteCapacityUnits: float, CapacityUnits: float>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.Query")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "ExclusiveStartKey" $exclusive_start_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TableName": $table_name, "IndexName": $index_name, "Select": $select, "AttributesToGet": $attributes_to_get, "Limit": $limit_body, "ConsistentRead": $consistent_read, "KeyConditions": $key_conditions, "QueryFilter": $query_filter, "ConditionalOperator": $conditional_operator, "ScanIndexForward": $scan_index_forward, "ExclusiveStartKey": $exclusive_start_key_body, "ReturnConsumedCapacity": $return_consumed_capacity, "ProjectionExpression": $projection_expression, "FilterExpression": $filter_expression, "KeyConditionExpression": $key_condition_expression, "ExpressionAttributeNames": $expression_attribute_names, "ExpressionAttributeValues": $expression_attribute_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "ExclusiveStartKey": $exclusive_start_key} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new table from an existing backup. Any number of users can execute up to 50 concurrent restores (any type of restore) in a given account. You can call RestoreTableFromBackup at a maximum rate of 10 times per second. You must manually set up the following on the restored table: Auto scaling policies IAM policies Amazon CloudWatch metrics and alarms Tags Stream settings Time to Live (TTL) settings
#
# POST /
# operationId: RestoreTableFromBackup
export def "restore-table-from-backup" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  target_table_name: string # The name of the new table to which the backup must be restored.
  backup_arn: string # The Amazon Resource Name (ARN) associated with the backup.
  --billing-mode-override: string@billing-mode-override-completer # The billing mode of the restored table.
  --global-secondary-index-override: list # List of global secondary indexes for the restored table. The indexes provided should match existing secondary indexes. You can choose to exclude some or all of the indexes at the time of restore. — item shape: {IndexName: string, KeySchema: list, Projection: record, ProvisionedThroughput?: record}
  --local-secondary-index-override: list # List of local secondary indexes for the restored table. The indexes provided should match existing secondary indexes. You can choose to exclude some or all of the indexes at the time of restore. — item shape: {IndexName: string, KeySchema: list, Projection: record}
  --provisioned-throughput-override: record # Represents the provisioned throughput settings for a specified table or index. The settings can be modified using the UpdateTable operation. For current minimum and maximum provisioned throughput values, see Service, Account, and Table Quotas (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html) in the Amazon DynamoDB Developer Guide. — shape: {ReadCapacityUnits: int, WriteCapacityUnits: int}
  --sse-specification-override: record # Represents the settings used to enable server-side encryption. — shape: {Enabled?: bool, SSEType?: "AES256"|"KMS", KMSMasterKeyId?: string}
]: any -> oneof<record<TableDescription: record<AttributeDefinitions: list<record>, TableName: string, KeySchema: list<record>, TableStatus: string, CreationDateTime: string, ProvisionedThroughput: record<LastIncreaseDateTime: string, LastDecreaseDateTime: string, NumberOfDecreasesToday: int, ReadCapacityUnits: int, WriteCapacityUnits: int>, TableSizeBytes: int, ItemCount: int, TableArn: string, TableId: string, BillingModeSummary: record<BillingMode: string, LastUpdateToPayPerRequestDateTime: string>, LocalSecondaryIndexes: list<record>, GlobalSecondaryIndexes: list<record>, StreamSpecification: record<StreamEnabled: bool, StreamViewType: string>, LatestStreamLabel: string, LatestStreamArn: string, GlobalTableVersion: string, Replicas: list<record>, RestoreSummary: record<SourceBackupArn: string, SourceTableArn: string, RestoreDateTime: string, RestoreInProgress: bool>, SSEDescription: record<Status: string, SSEType: string, KMSMasterKeyArn: string, InaccessibleEncryptionDateTime: string>, ArchivalSummary: record<ArchivalDateTime: string, ArchivalReason: string, ArchivalBackupArn: string>, TableClassSummary: record<TableClass: string, LastUpdateDateTime: string>, DeletionProtectionEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.RestoreTableFromBackup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TargetTableName": $target_table_name, "BackupArn": $backup_arn, "BillingModeOverride": $billing_mode_override, "GlobalSecondaryIndexOverride": $global_secondary_index_override, "LocalSecondaryIndexOverride": $local_secondary_index_override, "ProvisionedThroughputOverride": $provisioned_throughput_override, "SSESpecificationOverride": $sse_specification_override} | compact
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

# Restores the specified table to the specified point in time within EarliestRestorableDateTime and LatestRestorableDateTime. You can restore your table to any point in time during the last 35 days. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. When you restore using point in time recovery, DynamoDB restores your table data to the state based on the selected date and time (day:hour:minute:second) to a new table. Along with data, the following are also included on the new restored table using point in time recovery: Global secondary indexes (GSIs) Local secondary indexes (LSIs) Provisioned read and write capacity Encryption settings All these settings come from the current settings of the source table at the time of restore. You must manually set up the following on the restored table: Auto scaling policies IAM policies Amazon CloudWatch metrics and alarms Tags Stream settings Time to Live (TTL) settings Point in time recovery settings
#
# POST /
# operationId: RestoreTableToPointInTime
export def "restore-table-to-point-in-time" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  --source-table-arn: string # The DynamoDB table that will be restored. This value is an Amazon Resource Name (ARN).
  --source-table-name: string # Name of the source table that is being restored.
  target_table_name: string # The name of the new table to which it must be restored to.
  --use-latest-restorable-time: oneof<nothing, bool> # Restore the table to the latest possible time. LatestRestorableDateTime is typically 5 minutes before the current time.
  --restore-date-time: string # Time in the past to restore the table to. (format: date-time)
  --billing-mode-override: string@billing-mode-override-completer # The billing mode of the restored table.
  --global-secondary-index-override: list # List of global secondary indexes for the restored table. The indexes provided should match existing secondary indexes. You can choose to exclude some or all of the indexes at the time of restore. — item shape: {IndexName: string, KeySchema: list, Projection: record, ProvisionedThroughput?: record}
  --local-secondary-index-override: list # List of local secondary indexes for the restored table. The indexes provided should match existing secondary indexes. You can choose to exclude some or all of the indexes at the time of restore. — item shape: {IndexName: string, KeySchema: list, Projection: record}
  --provisioned-throughput-override: record # Represents the provisioned throughput settings for a specified table or index. The settings can be modified using the UpdateTable operation. For current minimum and maximum provisioned throughput values, see Service, Account, and Table Quotas (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html) in the Amazon DynamoDB Developer Guide. — shape: {ReadCapacityUnits: int, WriteCapacityUnits: int}
  --sse-specification-override: record # Represents the settings used to enable server-side encryption. — shape: {Enabled?: bool, SSEType?: "AES256"|"KMS", KMSMasterKeyId?: string}
]: any -> oneof<record<TableDescription: record<AttributeDefinitions: list<record>, TableName: string, KeySchema: list<record>, TableStatus: string, CreationDateTime: string, ProvisionedThroughput: record<LastIncreaseDateTime: string, LastDecreaseDateTime: string, NumberOfDecreasesToday: int, ReadCapacityUnits: int, WriteCapacityUnits: int>, TableSizeBytes: int, ItemCount: int, TableArn: string, TableId: string, BillingModeSummary: record<BillingMode: string, LastUpdateToPayPerRequestDateTime: string>, LocalSecondaryIndexes: list<record>, GlobalSecondaryIndexes: list<record>, StreamSpecification: record<StreamEnabled: bool, StreamViewType: string>, LatestStreamLabel: string, LatestStreamArn: string, GlobalTableVersion: string, Replicas: list<record>, RestoreSummary: record<SourceBackupArn: string, SourceTableArn: string, RestoreDateTime: string, RestoreInProgress: bool>, SSEDescription: record<Status: string, SSEType: string, KMSMasterKeyArn: string, InaccessibleEncryptionDateTime: string>, ArchivalSummary: record<ArchivalDateTime: string, ArchivalReason: string, ArchivalBackupArn: string>, TableClassSummary: record<TableClass: string, LastUpdateDateTime: string>, DeletionProtectionEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.RestoreTableToPointInTime")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SourceTableArn": $source_table_arn, "SourceTableName": $source_table_name, "TargetTableName": $target_table_name, "UseLatestRestorableTime": $use_latest_restorable_time, "RestoreDateTime": $restore_date_time, "BillingModeOverride": $billing_mode_override, "GlobalSecondaryIndexOverride": $global_secondary_index_override, "LocalSecondaryIndexOverride": $local_secondary_index_override, "ProvisionedThroughputOverride": $provisioned_throughput_override, "SSESpecificationOverride": $sse_specification_override} | compact
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

# The Scan operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a FilterExpression operation. If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a LastEvaluatedKey value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria. A single Scan operation reads up to the maximum number of items set (if using the Limit parameter) or a maximum of 1 MB of data and then apply any filtering to the results using FilterExpression. If LastEvaluatedKey is present in the response, you need to paginate the result set. For more information, see Paginating the Results (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination) in the Amazon DynamoDB Developer Guide. Scan operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel Scan operation by providing the Segment and TotalSegments parameters. For more information, see Parallel Scan (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan) in the Amazon DynamoDB Developer Guide. Scan uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the Scan begins, you can set the ConsistentRead parameter to true.
#
# POST /
# operationId: Scan
export def "scan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --exclusive-start-key: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40 # required
  table_name: string # The name of the table containing the requested items; or, if you provide IndexName, the name of the table to which that index belongs.
  --index-name: string # The name of a secondary index to scan. This index can be any local secondary index or global secondary index. Note that if you use the IndexName parameter, you must also provide TableName.
  --attributes-to-get: list<string> # This is a legacy parameter. Use ProjectionExpression instead. For more information, see AttributesToGet (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.AttributesToGet.html) in the Amazon DynamoDB Developer Guide.
  --limit-body: int # The maximum number of items to evaluate (not necessarily the number of matching items). If DynamoDB processes the number of items up to the limit while processing the results, it stops the operation and returns the matching values up to that point, and a key in LastEvaluatedKey to apply in a subsequent operation, so that you can pick up where you left off. Also, if the processed dataset size exceeds 1 MB before DynamoDB reaches this limit, it stops the operation and returns the matching values up to the limit, and a key in LastEvaluatedKey to apply in a subsequent operation to continue the operation. For more information, see Working with Queries (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/QueryAndScan.html) in the Amazon DynamoDB Developer Guide. (body field)
  --select: string@select-completer # The attributes to be returned in the result. You can retrieve all item attributes, specific item attributes, the count of matching items, or in the case of an index, some or all of the attributes projected into the index. ALL_ATTRIBUTES - Returns all of the item attributes from the specified table or index. If you query a local secondary index, then for each matching item in the index, DynamoDB fetches the entire item from the parent table. If the index is configured to project all item attributes, then all of the data can be obtained from the local secondary index, and no fetching is required. ALL_PROJECTED_ATTRIBUTES - Allowed only when querying an index. Retrieves all attributes that have been projected into the index. If the index is configured to project all attributes, this return value is equivalent to specifying ALL_ATTRIBUTES. COUNT - Returns the number of matching items, rather than the matching items themselves. Note that this uses the same quantity of read capacity units as getting the items, and is subject to the same item size calculations. SPECIFIC_ATTRIBUTES - Returns only the attributes listed in ProjectionExpression. This return value is equivalent to specifying ProjectionExpression without specifying any value for Select. If you query or scan a local secondary index and request only attributes that are projected into that index, the operation reads only the index and not the table. If any of the requested attributes are not projected into the local secondary index, DynamoDB fetches each of these attributes from the parent table. This extra fetching incurs additional throughput cost and latency. If you query or scan a global secondary index, you can only request attributes that are projected into the index. Global secondary index queries cannot fetch attributes from the parent table. If neither Select nor ProjectionExpression are specified, DynamoDB defaults to ALL_ATTRIBUTES when accessing a table, and ALL_PROJECTED_ATTRIBUTES when accessing an index. You cannot use both Select and ProjectionExpression together in a single request, unless the value for Select is SPECIFIC_ATTRIBUTES. (This usage is equivalent to specifying ProjectionExpression without any value for Select.) If you use the ProjectionExpression parameter, then the value for Select can only be SPECIFIC_ATTRIBUTES. Any other value for Select will return an error.
  --scan-filter: record # This is a legacy parameter. Use FilterExpression instead. For more information, see ScanFilter (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.ScanFilter.html) in the Amazon DynamoDB Developer Guide.
  --conditional-operator: string@conditional-operator-completer # This is a legacy parameter. Use FilterExpression instead. For more information, see ConditionalOperator (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.ConditionalOperator.html) in the Amazon DynamoDB Developer Guide.
  --exclusive-start-key-body: record # The primary key of the first item that this operation will evaluate. Use the value that was returned for LastEvaluatedKey in the previous operation. The data type for ExclusiveStartKey must be String, Number or Binary. No set data types are allowed. In a parallel scan, a Scan request that includes ExclusiveStartKey must specify the same segment whose previous Scan returned the corresponding value of LastEvaluatedKey. (body field)
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --total-segments: int # For a parallel Scan request, TotalSegments represents the total number of segments into which the Scan operation will be divided. The value of TotalSegments corresponds to the number of application workers that will perform the parallel scan. For example, if you want to use four application threads to scan a table or an index, specify a TotalSegments value of 4. The value for TotalSegments must be greater than or equal to 1, and less than or equal to 1000000. If you specify a TotalSegments value of 1, the Scan operation will be sequential rather than parallel. If you specify TotalSegments, you must also specify Segment.
  --segment: int # For a parallel Scan request, Segment identifies an individual segment to be scanned by an application worker. Segment IDs are zero-based, so the first segment is always 0. For example, if you want to use four application threads to scan a table or an index, then the first thread specifies a Segment value of 0, the second thread specifies 1, and so on. The value of LastEvaluatedKey returned from a parallel Scan request must be used as ExclusiveStartKey with the same segment ID in a subsequent Scan operation. The value for Segment must be greater than or equal to 0, and less than the value provided for TotalSegments. If you provide Segment, you must also provide TotalSegments.
  --projection-expression: string # A string that identifies one or more attributes to retrieve from the specified table or index. These attributes can include scalars, sets, or elements of a JSON document. The attributes in the expression must be separated by commas. If no attribute names are specified, then all attributes will be returned. If any of the requested attributes are not found, they will not appear in the result. For more information, see Specifying Item Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html) in the Amazon DynamoDB Developer Guide.
  --filter-expression: string # A string that contains conditions that DynamoDB applies after the Scan operation, but before the data is returned to you. Items that do not satisfy the FilterExpression criteria are not returned. A FilterExpression is applied after the items have already been read; the process of filtering does not consume any additional read capacity units. For more information, see Filter Expressions (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/QueryAndScan.html#Query.FilterExpression) in the Amazon DynamoDB Developer Guide.
  --expression-attribute-names: record # One or more substitution tokens for attribute names in an expression. The following are some use cases for using ExpressionAttributeNames: To access an attribute whose name conflicts with a DynamoDB reserved word. To create a placeholder for repeating occurrences of an attribute name in an expression. To prevent special characters in an attribute name from being misinterpreted in an expression. Use the # character in an expression to dereference an attribute name. For example, consider the following attribute name: Percentile The name of this attribute conflicts with a reserved word, so it cannot be used directly in an expression. (For the complete list of reserved words, see Reserved Words (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ReservedWords.html) in the Amazon DynamoDB Developer Guide). To work around this, you could specify the following for ExpressionAttributeNames: {"#P":"Percentile"} You could then use this substitution in an expression, as in this example: #P = :val Tokens that begin with the : character are expression attribute values, which are placeholders for the actual value at runtime. For more information on expression attribute names, see Specifying Item Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html) in the Amazon DynamoDB Developer Guide.
  --expression-attribute-values: record # One or more values that can be substituted in an expression. Use the : (colon) character in an expression to dereference an attribute value. For example, suppose that you wanted to check whether the value of the ProductStatus attribute was one of the following: Available | Backordered | Discontinued You would first need to specify ExpressionAttributeValues as follows: { ":avail":{"S":"Available"}, ":back":{"S":"Backordered"}, ":disc":{"S":"Discontinued"} } You could then use these values in an expression, such as this: ProductStatus IN (:avail, :back, :disc) For more information on expression attribute values, see Condition Expressions (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.SpecifyingConditions.html) in the Amazon DynamoDB Developer Guide.
  --consistent-read: oneof<nothing, bool> # A Boolean value that determines the read consistency model during the scan: If ConsistentRead is false, then the data returned from Scan might not contain the results from other recently completed write operations (PutItem, UpdateItem, or DeleteItem). If ConsistentRead is true, then all of the write operations that completed before the Scan began are guaranteed to be contained in the Scan response. The default setting for ConsistentRead is false. The ConsistentRead parameter is not supported on global secondary indexes. If you scan a global secondary index with ConsistentRead set to true, you will receive a ValidationException.
]: any -> oneof<record<Items: list<record>, Count: int, ScannedCount: int, LastEvaluatedKey: record, ConsumedCapacity: record<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record<ReadCapacityUnits: float, WriteCapacityUnits: float, CapacityUnits: float>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.Scan")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "ExclusiveStartKey" $exclusive_start_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TableName": $table_name, "IndexName": $index_name, "AttributesToGet": $attributes_to_get, "Limit": $limit_body, "Select": $select, "ScanFilter": $scan_filter, "ConditionalOperator": $conditional_operator, "ExclusiveStartKey": $exclusive_start_key_body, "ReturnConsumedCapacity": $return_consumed_capacity, "TotalSegments": $total_segments, "Segment": $segment, "ProjectionExpression": $projection_expression, "FilterExpression": $filter_expression, "ExpressionAttributeNames": $expression_attribute_names, "ExpressionAttributeValues": $expression_attribute_values, "ConsistentRead": $consistent_read} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "ExclusiveStartKey": $exclusive_start_key} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Associate a set of tags with an Amazon DynamoDB resource. You can then activate these user-defined tags so that they appear on the Billing and Cost Management console for cost allocation tracking. You can call TagResource up to five times per second, per account. For an overview on tagging DynamoDB resources, see Tagging for DynamoDB (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: TagResource
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  resource_arn: string # Identifies the Amazon DynamoDB resource to which tags should be added. This value is an Amazon Resource Name (ARN).
  tags: list # The tags to be assigned to the Amazon DynamoDB resource. — item shape: {Key: string, Value: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
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

# TransactGetItems is a synchronous operation that atomically retrieves multiple items from one or more tables (but not from indexes) in a single account and Region. A TransactGetItems call can contain up to 100 TransactGetItem objects, each of which contains a Get structure that specifies an item to retrieve from a table in the account and Region. A call to TransactGetItems cannot retrieve items from tables in more than one Amazon Web Services account or Region. The aggregate size of the items in the transaction cannot exceed 4 MB. DynamoDB rejects the entire TransactGetItems request if any of the following is true: A conflicting operation is in the process of updating an item to be read. There is insufficient provisioned capacity for the transaction to be completed. There is a user error, such as an invalid data format. The aggregate size of the items in the transaction exceeded 4 MB.
#
# POST /
# operationId: TransactGetItems
export def "transact-get-items" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  transact_items: list # An ordered array of up to 100 TransactGetItem objects, each of which contains a Get structure. — item shape: {Get: record}
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
]: any -> oneof<record<ConsumedCapacity: table<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>, Responses: table<Item: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.TransactGetItems")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TransactItems": $transact_items, "ReturnConsumedCapacity": $return_consumed_capacity} | compact
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

# TransactWriteItems is a synchronous write operation that groups up to 100 action requests. These actions can target items in different tables, but not in different Amazon Web Services accounts or Regions, and no two actions can target the same item. For example, you cannot both ConditionCheck and Update the same item. The aggregate size of the items in the transaction cannot exceed 4 MB. The actions are completed atomically so that either all of them succeed, or all of them fail. They are defined by the following objects: Put — Initiates a PutItem operation to write a new item. This structure specifies the primary key of the item to be written, the name of the table to write it in, an optional condition expression that must be satisfied for the write to succeed, a list of the item's attributes, and a field indicating whether to retrieve the item's attributes if the condition is not met. Update — Initiates an UpdateItem operation to update an existing item. This structure specifies the primary key of the item to be updated, the name of the table where it resides, an optional condition expression that must be satisfied for the update to succeed, an expression that defines one or more attributes to be updated, and a field indicating whether to retrieve the item's attributes if the condition is not met. Delete — Initiates a DeleteItem operation to delete an existing item. This structure specifies the primary key of the item to be deleted, the name of the table where it resides, an optional condition expression that must be satisfied for the deletion to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met. ConditionCheck — Applies a condition to an item that is not being modified by the transaction. This structure specifies the primary key of the item to be checked, the name of the table where it resides, a condition expression that must be satisfied for the transaction to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met. DynamoDB rejects the entire TransactWriteItems request if any of the following is true: A condition in one of the condition expressions is not met. An ongoing operation is in the process of updating the same item. There is insufficient provisioned capacity for the transaction to be completed. An item size becomes too large (bigger than 400 KB), a local secondary index (LSI) becomes too large, or a similar validation error occurs because of changes made by the transaction. The aggregate size of the items in the transaction exceeds 4 MB. There is a user error, such as an invalid data format.
#
# POST /
# operationId: TransactWriteItems
export def "transact-write-items" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  transact_items: list # An ordered array of up to 100 TransactWriteItem objects, each of which contains a ConditionCheck, Put, Update, or Delete object. These can operate on items in different tables, but the tables must reside in the same Amazon Web Services account and Region, and no two of them can operate on the same item. — item shape: {ConditionCheck?: record, Put?: record, Delete?: record, Update?: record}
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --return-item-collection-metrics: string@return-item-collection-metrics-completer # Determines whether item collection metrics are returned. If set to SIZE, the response includes statistics about item collections (if any), that were modified during the operation and are returned in the response. If set to NONE (the default), no statistics are returned.
  --client-request-token: string # Providing a ClientRequestToken makes the call to TransactWriteItems idempotent, meaning that multiple identical calls have the same effect as one single call. Although multiple identical calls using the same client request token produce the same result on the server (no side effects), the responses to the calls might not be the same. If the ReturnConsumedCapacity parameter is set, then the initial TransactWriteItems call returns the amount of write capacity units consumed in making the changes. Subsequent TransactWriteItems calls with the same client token return the number of read capacity units consumed in reading the item. A client request token is valid for 10 minutes after the first request that uses it is completed. After 10 minutes, any request with the same client token is treated as a new request. Do not resubmit the same request with the same client token for more than 10 minutes, or the result might not be idempotent. If you submit a request with the same client token but a change in other parameters within the 10-minute idempotency window, DynamoDB returns an IdempotentParameterMismatch exception.
]: any -> oneof<record<ConsumedCapacity: table<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>, ItemCollectionMetrics: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.TransactWriteItems")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TransactItems": $transact_items, "ReturnConsumedCapacity": $return_consumed_capacity, "ReturnItemCollectionMetrics": $return_item_collection_metrics, "ClientRequestToken": $client_request_token} | compact
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

# Removes the association of tags from an Amazon DynamoDB resource. You can call UntagResource up to five times per second, per account. For an overview on tagging DynamoDB resources, see Tagging for DynamoDB (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: UntagResource
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  resource_arn: string # The DynamoDB resource that the tags will be removed from. This value is an Amazon Resource Name (ARN).
  tag_keys: list<string> # A list of tag keys. Existing tags of the resource whose keys are members of this list will be removed from the DynamoDB resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
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

# UpdateContinuousBackups enables or disables point in time recovery for the specified table. A successful UpdateContinuousBackups call returns the current ContinuousBackupsDescription. Continuous backups are ENABLED on all tables at table creation. If point in time recovery is enabled, PointInTimeRecoveryStatus will be set to ENABLED. Once continuous backups and point in time recovery are enabled, you can restore to any point in time within EarliestRestorableDateTime and LatestRestorableDateTime. LatestRestorableDateTime is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days.
#
# POST /
# operationId: UpdateContinuousBackups
export def "update-continuous-backups" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  table_name: string # The name of the table.
  point_in_time_recovery_specification: record # Represents the settings used to enable point in time recovery. — shape: {PointInTimeRecoveryEnabled: bool}
]: any -> oneof<record<ContinuousBackupsDescription: record<ContinuousBackupsStatus: string, PointInTimeRecoveryDescription: record<PointInTimeRecoveryStatus: string, EarliestRestorableDateTime: string, LatestRestorableDateTime: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.UpdateContinuousBackups")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "PointInTimeRecoverySpecification": $point_in_time_recovery_specification} | compact
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

# Updates the status for contributor insights for a specific table or index. CloudWatch Contributor Insights for DynamoDB graphs display the partition key and (if applicable) sort key of frequently accessed items and frequently throttled items in plaintext. If you require the use of Amazon Web Services Key Management Service (KMS) to encrypt this table’s partition key and sort key data with an Amazon Web Services managed key or customer managed key, you should not enable CloudWatch Contributor Insights for DynamoDB for this table.
#
# POST /
# operationId: UpdateContributorInsights
export def "update-contributor-insights" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  table_name: string # The name of the table.
  --index-name: string # The global secondary index name, if applicable.
  contributor_insights_action: string@contributor-insights-action-completer # Represents the contributor insights action.
]: any -> oneof<record<TableName: string, IndexName: string, ContributorInsightsStatus: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.UpdateContributorInsights")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "IndexName": $index_name, "ContributorInsightsAction": $contributor_insights_action} | compact
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

# Adds or removes replicas in the specified global table. The global table must already exist to be able to use this operation. Any replica to be added must be empty, have the same name as the global table, have the same key schema, have DynamoDB Streams enabled, and have the same provisioned and maximum write capacity units. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html). This operation only applies to Version 2017.11.29 (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. If you are using global tables Version 2019.11.21 (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) you can use DescribeTable (https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_DescribeTable.html) instead. Although you can use UpdateGlobalTable to add replicas and remove replicas in a single request, for simplicity we recommend that you issue separate requests for adding or removing replicas. If global secondary indexes are specified, then the following conditions must also be met: The global secondary indexes must have the same name. The global secondary indexes must have the same hash key and sort key (if present). The global secondary indexes must have the same provisioned and maximum write capacity units.
#
# POST /
# operationId: UpdateGlobalTable
export def "update-global-table" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  global_table_name: string # The global table name.
  replica_updates: list # A list of Regions that should be added or removed from the global table. — item shape: {Create?: record, Delete?: record}
]: any -> oneof<record<GlobalTableDescription: record<ReplicationGroup: list<record>, GlobalTableArn: string, CreationDateTime: string, GlobalTableStatus: string, GlobalTableName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.UpdateGlobalTable")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GlobalTableName": $global_table_name, "ReplicaUpdates": $replica_updates} | compact
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

# Updates settings for a global table. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html).
#
# POST /
# operationId: UpdateGlobalTableSettings
export def "update-global-table-settings" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  global_table_name: string # The name of the global table
  --global-table-billing-mode: string@global-table-billing-mode-completer # The billing mode of the global table. If GlobalTableBillingMode is not specified, the global table defaults to PROVISIONED capacity billing mode. PROVISIONED - We recommend using PROVISIONED for predictable workloads. PROVISIONED sets the billing mode to Provisioned Mode (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadWriteCapacityMode.html#HowItWorks.ProvisionedThroughput.Manual). PAY_PER_REQUEST - We recommend using PAY_PER_REQUEST for unpredictable workloads. PAY_PER_REQUEST sets the billing mode to On-Demand Mode (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadWriteCapacityMode.html#HowItWorks.OnDemand).
  --global-table-provisioned-write-capacity-units: int # The maximum number of writes consumed per second before DynamoDB returns a ThrottlingException.
  --global-table-provisioned-write-capacity-auto-scaling-settings-update: record # Represents the auto scaling settings to be modified for a global table or global secondary index. — shape: {MinimumUnits?: int, MaximumUnits?: int, AutoScalingDisabled?: bool, AutoScalingRoleArn?: string, ScalingPolicyUpdate?: record}
  --global-table-global-secondary-index-settings-update: list # Represents the settings of a global secondary index for a global table that will be modified. — item shape: {IndexName: string, ProvisionedWriteCapacityUnits?: int, ProvisionedWriteCapacityAutoScalingSettingsUpdate?: record}
  --replica-settings-update: list # Represents the settings for a global table in a Region that will be modified. — item shape: {RegionName: string, ReplicaProvisionedReadCapacityUnits?: int, ReplicaProvisionedReadCapacityAutoScalingSettingsUpdate?: record, ReplicaGlobalSecondaryIndexSettingsUpdate?: list, ReplicaTableClass?: "STANDARD"|"STANDARD_INFREQUENT_ACCESS"}
]: any -> oneof<record<GlobalTableName: string, ReplicaSettings: table<RegionName: string, ReplicaStatus: string, ReplicaBillingModeSummary: record, ReplicaProvisionedReadCapacityUnits: int, ReplicaProvisionedReadCapacityAutoScalingSettings: record, ReplicaProvisionedWriteCapacityUnits: int, ReplicaProvisionedWriteCapacityAutoScalingSettings: record, ReplicaGlobalSecondaryIndexSettings: list, ReplicaTableClassSummary: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.UpdateGlobalTableSettings")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GlobalTableName": $global_table_name, "GlobalTableBillingMode": $global_table_billing_mode, "GlobalTableProvisionedWriteCapacityUnits": $global_table_provisioned_write_capacity_units, "GlobalTableProvisionedWriteCapacityAutoScalingSettingsUpdate": $global_table_provisioned_write_capacity_auto_scaling_settings_update, "GlobalTableGlobalSecondaryIndexSettingsUpdate": $global_table_global_secondary_index_settings_update, "ReplicaSettingsUpdate": $replica_settings_update} | compact
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

# Edits an existing item's attributes, or adds a new item to the table if it does not already exist. You can put, delete, or add attribute values. You can also perform a conditional update on an existing item (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values). You can also return the item's attribute values in the same UpdateItem operation using the ReturnValues parameter.
#
# POST /
# operationId: UpdateItem
export def "update-item" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  table_name: string # The name of the table containing the item to update.
  key: record # The primary key of the item to be updated. Each element consists of an attribute name and a value for that attribute. For the primary key, you must provide all of the attributes. For example, with a simple primary key, you only need to provide a value for the partition key. For a composite primary key, you must provide values for both the partition key and the sort key.
  --attribute-updates: record # This is a legacy parameter. Use UpdateExpression instead. For more information, see AttributeUpdates (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.AttributeUpdates.html) in the Amazon DynamoDB Developer Guide.
  --expected: record # This is a legacy parameter. Use ConditionExpression instead. For more information, see Expected (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.Expected.html) in the Amazon DynamoDB Developer Guide.
  --conditional-operator: string@conditional-operator-completer # This is a legacy parameter. Use ConditionExpression instead. For more information, see ConditionalOperator (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LegacyConditionalParameters.ConditionalOperator.html) in the Amazon DynamoDB Developer Guide.
  --return-values: string@return-values-completer # Use ReturnValues if you want to get the item attributes as they appear before or after they are successfully updated. For UpdateItem, the valid values are: NONE - If ReturnValues is not specified, or if its value is NONE, then nothing is returned. (This setting is the default for ReturnValues.) ALL_OLD - Returns all of the attributes of the item, as they appeared before the UpdateItem operation. UPDATED_OLD - Returns only the updated attributes, as they appeared before the UpdateItem operation. ALL_NEW - Returns all of the attributes of the item, as they appear after the UpdateItem operation. UPDATED_NEW - Returns only the updated attributes, as they appear after the UpdateItem operation. There is no additional cost associated with requesting a return value aside from the small network and processing overhead of receiving a larger response. No read capacity units are consumed. The values returned are strongly consistent.
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --return-item-collection-metrics: string@return-item-collection-metrics-completer # Determines whether item collection metrics are returned. If set to SIZE, the response includes statistics about item collections, if any, that were modified during the operation are returned in the response. If set to NONE (the default), no statistics are returned.
  --update-expression: string # An expression that defines one or more attributes to be updated, the action to be performed on them, and new values for them. The following action values are available for UpdateExpression. SET - Adds one or more attributes and values to an item. If any of these attributes already exist, they are replaced by the new values. You can also use SET to add or subtract from an attribute that is of type Number. For example: SET myNum = myNum + :val SET supports the following functions: if_not_exists (path, operand) - if the item does not contain an attribute at the specified path, then if_not_exists evaluates to operand; otherwise, it evaluates to path. You can use this function to avoid overwriting an attribute that may already be present in the item. list_append (operand, operand) - evaluates to a list with a new element added to it. You can append the new element to the start or the end of the list by reversing the order of the operands. These function names are case-sensitive. REMOVE - Removes one or more attributes from an item. ADD - Adds the specified value to the item, if the attribute does not already exist. If the attribute does exist, then the behavior of ADD depends on the data type of the attribute: If the existing attribute is a number, and if Value is also a number, then Value is mathematically added to the existing attribute. If Value is a negative number, then it is subtracted from the existing attribute. If you use ADD to increment or decrement a number value for an item that doesn't exist before the update, DynamoDB uses 0 as the initial value. Similarly, if you use ADD for an existing item to increment or decrement an attribute value that doesn't exist before the update, DynamoDB uses 0 as the initial value. For example, suppose that the item you want to update doesn't have an attribute named itemcount, but you decide to ADD the number 3 to this attribute anyway. DynamoDB will create the itemcount attribute, set its initial value to 0, and finally add 3 to it. The result will be a new itemcount attribute in the item, with a value of 3. If the existing data type is a set and if Value is also a set, then Value is added to the existing set. For example, if the attribute value is the set [1,2], and the ADD action specified [3], then the final attribute value is [1,2,3]. An error occurs if an ADD action is specified for a set attribute and the attribute type specified does not match the existing set type. Both sets must have the same primitive data type. For example, if the existing data type is a set of strings, the Value must also be a set of strings. The ADD action only supports Number and set data types. In addition, ADD can only be used on top-level attributes, not nested attributes. DELETE - Deletes an element from a set. If a set of values is specified, then those values are subtracted from the old set. For example, if the attribute value was the set [a,b,c] and the DELETE action specifies [a,c], then the final attribute value is [b]. Specifying an empty set is an error. The DELETE action only supports set data types. In addition, DELETE can only be used on top-level attributes, not nested attributes. You can have many actions in a single expression, such as the following: SET a=:value1, b=:value2 DELETE :value3, :value4, :value5 For more information on update expressions, see Modifying Items and Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.Modifying.html) in the Amazon DynamoDB Developer Guide.
  --condition-expression: string # A condition that must be satisfied in order for a conditional update to succeed. An expression can contain any of the following: Functions: attribute_exists | attribute_not_exists | attribute_type | contains | begins_with | size These function names are case-sensitive. Comparison operators: = | <> | < | > | <= | >= | BETWEEN | IN Logical operators: AND | OR | NOT For more information about condition expressions, see Specifying Conditions (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.SpecifyingConditions.html) in the Amazon DynamoDB Developer Guide.
  --expression-attribute-names: record # One or more substitution tokens for attribute names in an expression. The following are some use cases for using ExpressionAttributeNames: To access an attribute whose name conflicts with a DynamoDB reserved word. To create a placeholder for repeating occurrences of an attribute name in an expression. To prevent special characters in an attribute name from being misinterpreted in an expression. Use the # character in an expression to dereference an attribute name. For example, consider the following attribute name: Percentile The name of this attribute conflicts with a reserved word, so it cannot be used directly in an expression. (For the complete list of reserved words, see Reserved Words (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ReservedWords.html) in the Amazon DynamoDB Developer Guide.) To work around this, you could specify the following for ExpressionAttributeNames: {"#P":"Percentile"} You could then use this substitution in an expression, as in this example: #P = :val Tokens that begin with the : character are expression attribute values, which are placeholders for the actual value at runtime. For more information about expression attribute names, see Specifying Item Attributes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html) in the Amazon DynamoDB Developer Guide.
  --expression-attribute-values: record # One or more values that can be substituted in an expression. Use the : (colon) character in an expression to dereference an attribute value. For example, suppose that you wanted to check whether the value of the ProductStatus attribute was one of the following: Available | Backordered | Discontinued You would first need to specify ExpressionAttributeValues as follows: { ":avail":{"S":"Available"}, ":back":{"S":"Backordered"}, ":disc":{"S":"Discontinued"} } You could then use these values in an expression, such as this: ProductStatus IN (:avail, :back, :disc) For more information on expression attribute values, see Condition Expressions (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.SpecifyingConditions.html) in the Amazon DynamoDB Developer Guide.
]: any -> oneof<record<Attributes: record, ConsumedCapacity: record<TableName: string, CapacityUnits: float, ReadCapacityUnits: float, WriteCapacityUnits: float, Table: record<ReadCapacityUnits: float, WriteCapacityUnits: float, CapacityUnits: float>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>, ItemCollectionMetrics: record<ItemCollectionKey: record, SizeEstimateRangeGB: list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.UpdateItem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "Key": $key, "AttributeUpdates": $attribute_updates, "Expected": $expected, "ConditionalOperator": $conditional_operator, "ReturnValues": $return_values, "ReturnConsumedCapacity": $return_consumed_capacity, "ReturnItemCollectionMetrics": $return_item_collection_metrics, "UpdateExpression": $update_expression, "ConditionExpression": $condition_expression, "ExpressionAttributeNames": $expression_attribute_names, "ExpressionAttributeValues": $expression_attribute_values} | compact
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

# Modifies the provisioned throughput settings, global secondary indexes, or DynamoDB Streams settings for a given table. This operation only applies to Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) of global tables. You can only perform one of the following operations at once: Modify the provisioned throughput settings of the table. Remove a global secondary index from the table. Create a new global secondary index on the table. After the index begins backfilling, you can use UpdateTable to perform other operations. UpdateTable is an asynchronous operation; while it is executing, the table status changes from ACTIVE to UPDATING. While it is UPDATING, you cannot issue another UpdateTable request. When the table returns to the ACTIVE state, the UpdateTable operation is complete.
#
# POST /
# operationId: UpdateTable
export def "update-table" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  --attribute-definitions: list # An array of attributes that describe the key schema for the table and indexes. If you are adding a new global secondary index to the table, AttributeDefinitions must include the key element(s) of the new index. — item shape: {AttributeName: string, AttributeType: "S"|"N"|"B"}
  table_name: string # The name of the table to be updated.
  --billing-mode: string@billing-mode-completer # Controls how you are charged for read and write throughput and how you manage capacity. When switching from pay-per-request to provisioned capacity, initial provisioned capacity values must be set. The initial provisioned capacity values are estimated based on the consumed read and write capacity of your table and global secondary indexes over the past 30 minutes. PROVISIONED - We recommend using PROVISIONED for predictable workloads. PROVISIONED sets the billing mode to Provisioned Mode (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadWriteCapacityMode.html#HowItWorks.ProvisionedThroughput.Manual). PAY_PER_REQUEST - We recommend using PAY_PER_REQUEST for unpredictable workloads. PAY_PER_REQUEST sets the billing mode to On-Demand Mode (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadWriteCapacityMode.html#HowItWorks.OnDemand).
  --provisioned-throughput: record # Represents the provisioned throughput settings for a specified table or index. The settings can be modified using the UpdateTable operation. For current minimum and maximum provisioned throughput values, see Service, Account, and Table Quotas (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html) in the Amazon DynamoDB Developer Guide. — shape: {ReadCapacityUnits: int, WriteCapacityUnits: int}
  --global-secondary-index-updates: list # An array of one or more global secondary indexes for the table. For each index in the array, you can request one action: Create - add a new global secondary index to the table. Update - modify the provisioned throughput settings of an existing global secondary index. Delete - remove a global secondary index from the table. You can create or delete only one global secondary index per UpdateTable operation. For more information, see Managing Global Secondary Indexes (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.OnlineOps.html) in the Amazon DynamoDB Developer Guide. — item shape: {Update?: record, Create?: record, Delete?: record}
  --stream-specification: record # Represents the DynamoDB Streams configuration for a table in DynamoDB. — shape: {StreamEnabled: bool, StreamViewType?: "NEW_IMAGE"|"OLD_IMAGE"|"NEW_AND_OLD_IMAGES"|"KEYS_ONLY"}
  --sse-specification: record # Represents the settings used to enable server-side encryption. — shape: {Enabled?: bool, SSEType?: "AES256"|"KMS", KMSMasterKeyId?: string}
  --replica-updates: list # A list of replica update actions (create, delete, or update) for the table. This property only applies to Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) of global tables. — item shape: {Create?: record, Update?: record, Delete?: record}
  --table-class: string@table-class-completer # The table class of the table to be updated. Valid values are STANDARD and STANDARD_INFREQUENT_ACCESS.
  --deletion-protection-enabled: oneof<nothing, bool> # Indicates whether deletion protection is to be enabled (true) or disabled (false) on the table.
]: any -> oneof<record<TableDescription: record<AttributeDefinitions: list<record>, TableName: string, KeySchema: list<record>, TableStatus: string, CreationDateTime: string, ProvisionedThroughput: record<LastIncreaseDateTime: string, LastDecreaseDateTime: string, NumberOfDecreasesToday: int, ReadCapacityUnits: int, WriteCapacityUnits: int>, TableSizeBytes: int, ItemCount: int, TableArn: string, TableId: string, BillingModeSummary: record<BillingMode: string, LastUpdateToPayPerRequestDateTime: string>, LocalSecondaryIndexes: list<record>, GlobalSecondaryIndexes: list<record>, StreamSpecification: record<StreamEnabled: bool, StreamViewType: string>, LatestStreamLabel: string, LatestStreamArn: string, GlobalTableVersion: string, Replicas: list<record>, RestoreSummary: record<SourceBackupArn: string, SourceTableArn: string, RestoreDateTime: string, RestoreInProgress: bool>, SSEDescription: record<Status: string, SSEType: string, KMSMasterKeyArn: string, InaccessibleEncryptionDateTime: string>, ArchivalSummary: record<ArchivalDateTime: string, ArchivalReason: string, ArchivalBackupArn: string>, TableClassSummary: record<TableClass: string, LastUpdateDateTime: string>, DeletionProtectionEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.UpdateTable")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AttributeDefinitions": $attribute_definitions, "TableName": $table_name, "BillingMode": $billing_mode, "ProvisionedThroughput": $provisioned_throughput, "GlobalSecondaryIndexUpdates": $global_secondary_index_updates, "StreamSpecification": $stream_specification, "SSESpecification": $sse_specification, "ReplicaUpdates": $replica_updates, "TableClass": $table_class, "DeletionProtectionEnabled": $deletion_protection_enabled} | compact
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

# Updates auto scaling settings on your global tables at once. This operation only applies to Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) of global tables.
#
# POST /
# operationId: UpdateTableReplicaAutoScaling
export def "update-table-replica-auto-scaling" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  --global-secondary-index-updates: list # Represents the auto scaling settings of the global secondary indexes of the replica to be updated. — item shape: {IndexName?: string, ProvisionedWriteCapacityAutoScalingUpdate?: record}
  table_name: string # The name of the global table to be updated.
  --provisioned-write-capacity-auto-scaling-update: record # Represents the auto scaling settings to be modified for a global table or global secondary index. — shape: {MinimumUnits?: int, MaximumUnits?: int, AutoScalingDisabled?: bool, AutoScalingRoleArn?: string, ScalingPolicyUpdate?: record}
  --replica-updates: list # Represents the auto scaling settings of replicas of the table that will be modified. — item shape: {RegionName: string, ReplicaGlobalSecondaryIndexUpdates?: list, ReplicaProvisionedReadCapacityAutoScalingUpdate?: record}
]: any -> oneof<record<TableAutoScalingDescription: record<TableName: string, TableStatus: string, Replicas: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.UpdateTableReplicaAutoScaling")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GlobalSecondaryIndexUpdates": $global_secondary_index_updates, "TableName": $table_name, "ProvisionedWriteCapacityAutoScalingUpdate": $provisioned_write_capacity_auto_scaling_update, "ReplicaUpdates": $replica_updates} | compact
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

# The UpdateTimeToLive method enables or disables Time to Live (TTL) for the specified table. A successful UpdateTimeToLive call returns the current TimeToLiveSpecification. It can take up to one hour for the change to fully process. Any additional UpdateTimeToLive calls for the same table during this one hour duration result in a ValidationException. TTL compares the current time in epoch time format to the time stored in the TTL attribute of an item. If the epoch time value stored in the attribute is less than the current time, the item is marked as expired and subsequently deleted. The epoch time format is the number of seconds elapsed since 12:00:00 AM January 1, 1970 UTC. DynamoDB deletes expired items on a best-effort basis to ensure availability of throughput for other data operations. DynamoDB typically deletes expired items within two days of expiration. The exact duration within which an item gets deleted after expiration is specific to the nature of the workload. Items that have expired and not been deleted will still show up in reads, queries, and scans. As items are deleted, they are removed from any local secondary index and global secondary index immediately in the same eventually consistent way as a standard delete operation. For more information, see Time To Live (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: UpdateTimeToLive
export def "update-time-to-live" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  table_name: string # The name of the table to be configured.
  time_to_live_specification: record # Represents the settings used to enable or disable Time to Live (TTL) for the specified table. — shape: {Enabled: bool, AttributeName: string}
]: any -> oneof<record<TimeToLiveSpecification: record<Enabled: bool, AttributeName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "DynamoDB_20120810.UpdateTimeToLive")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TableName": $table_name, "TimeToLiveSpecification": $time_to_live_specification} | compact
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
