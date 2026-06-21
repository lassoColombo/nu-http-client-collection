# Auto-generated client for Amazon DynamoDB v2012-08-10
# Source: https://api.apis.guru/v2/specs/amazonaws.com/dynamodb/2012-08-10/openapi.json
# Auth: --token flag or $env.AMAZON_DYNAMODB_TOKEN

const BASE_URL = "http://dynamodb.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_DYNAMODB_TOKEN | default "" }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://dynamodb.us-east-1.amazonaws.com" "http://dynamodb.us-east-2.amazonaws.com" "http://dynamodb.us-west-1.amazonaws.com" "http://dynamodb.us-west-2.amazonaws.com" "http://dynamodb.us-gov-west-1.amazonaws.com" "http://dynamodb.us-gov-east-1.amazonaws.com" "http://dynamodb.ca-central-1.amazonaws.com" "http://dynamodb.eu-north-1.amazonaws.com" "http://dynamodb.eu-west-1.amazonaws.com" "http://dynamodb.eu-west-2.amazonaws.com" "http://dynamodb.eu-west-3.amazonaws.com" "http://dynamodb.eu-central-1.amazonaws.com" "http://dynamodb.eu-south-1.amazonaws.com" "http://dynamodb.af-south-1.amazonaws.com" "http://dynamodb.ap-northeast-1.amazonaws.com" "http://dynamodb.ap-northeast-2.amazonaws.com" "http://dynamodb.ap-northeast-3.amazonaws.com" "http://dynamodb.ap-southeast-1.amazonaws.com" "http://dynamodb.ap-southeast-2.amazonaws.com" "http://dynamodb.ap-east-1.amazonaws.com" "http://dynamodb.ap-south-1.amazonaws.com" "http://dynamodb.sa-east-1.amazonaws.com" "http://dynamodb.me-south-1.amazonaws.com" "https://dynamodb.us-east-1.amazonaws.com" "https://dynamodb.us-east-2.amazonaws.com" "https://dynamodb.us-west-1.amazonaws.com" "https://dynamodb.us-west-2.amazonaws.com" "https://dynamodb.us-gov-west-1.amazonaws.com" "https://dynamodb.us-gov-east-1.amazonaws.com" "https://dynamodb.ca-central-1.amazonaws.com" "https://dynamodb.eu-north-1.amazonaws.com" "https://dynamodb.eu-west-1.amazonaws.com" "https://dynamodb.eu-west-2.amazonaws.com" "https://dynamodb.eu-west-3.amazonaws.com" "https://dynamodb.eu-central-1.amazonaws.com" "https://dynamodb.eu-south-1.amazonaws.com" "https://dynamodb.af-south-1.amazonaws.com" "https://dynamodb.ap-northeast-1.amazonaws.com" "https://dynamodb.ap-northeast-2.amazonaws.com" "https://dynamodb.ap-northeast-3.amazonaws.com" "https://dynamodb.ap-southeast-1.amazonaws.com" "https://dynamodb.ap-southeast-2.amazonaws.com" "https://dynamodb.ap-east-1.amazonaws.com" "https://dynamodb.ap-south-1.amazonaws.com" "https://dynamodb.sa-east-1.amazonaws.com" "https://dynamodb.me-south-1.amazonaws.com" "http://dynamodb.cn-north-1.amazonaws.com.cn" "http://dynamodb.cn-northwest-1.amazonaws.com.cn" "https://dynamodb.cn-north-1.amazonaws.com.cn" "https://dynamodb.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def return-consumed-capacity-completer [] { ["INDEXES" "NONE" "TOTAL"] }
def x-amz-target-completer [] { ["DynamoDB_20120810.BatchExecuteStatement"] }
def x-amz-target-completer-1 [] { ["DynamoDB_20120810.BatchGetItem"] }
def x-amz-target-completer-2 [] { ["DynamoDB_20120810.BatchWriteItem"] }
def x-amz-target-completer-3 [] { ["DynamoDB_20120810.CreateBackup"] }
def x-amz-target-completer-4 [] { ["DynamoDB_20120810.CreateGlobalTable"] }
def x-amz-target-completer-5 [] { ["DynamoDB_20120810.CreateTable"] }
def x-amz-target-completer-6 [] { ["DynamoDB_20120810.DeleteBackup"] }
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
def x-amz-target-completer-26 [] { ["DynamoDB_20120810.ExportTableToPointInTime"] }
def x-amz-target-completer-27 [] { ["DynamoDB_20120810.GetItem"] }
def x-amz-target-completer-28 [] { ["DynamoDB_20120810.ImportTable"] }
def x-amz-target-completer-29 [] { ["DynamoDB_20120810.ListBackups"] }
def x-amz-target-completer-30 [] { ["DynamoDB_20120810.ListContributorInsights"] }
def x-amz-target-completer-31 [] { ["DynamoDB_20120810.ListExports"] }
def x-amz-target-completer-32 [] { ["DynamoDB_20120810.ListGlobalTables"] }
def x-amz-target-completer-33 [] { ["DynamoDB_20120810.ListImports"] }
def x-amz-target-completer-34 [] { ["DynamoDB_20120810.ListTables"] }
def x-amz-target-completer-35 [] { ["DynamoDB_20120810.ListTagsOfResource"] }
def x-amz-target-completer-36 [] { ["DynamoDB_20120810.PutItem"] }
def x-amz-target-completer-37 [] { ["DynamoDB_20120810.Query"] }
def x-amz-target-completer-38 [] { ["DynamoDB_20120810.RestoreTableFromBackup"] }
def x-amz-target-completer-39 [] { ["DynamoDB_20120810.RestoreTableToPointInTime"] }
def x-amz-target-completer-40 [] { ["DynamoDB_20120810.Scan"] }
def x-amz-target-completer-41 [] { ["DynamoDB_20120810.TagResource"] }
def x-amz-target-completer-42 [] { ["DynamoDB_20120810.TransactGetItems"] }
def x-amz-target-completer-43 [] { ["DynamoDB_20120810.TransactWriteItems"] }
def x-amz-target-completer-44 [] { ["DynamoDB_20120810.UntagResource"] }
def x-amz-target-completer-45 [] { ["DynamoDB_20120810.UpdateContinuousBackups"] }
def x-amz-target-completer-46 [] { ["DynamoDB_20120810.UpdateContributorInsights"] }
def x-amz-target-completer-47 [] { ["DynamoDB_20120810.UpdateGlobalTable"] }
def x-amz-target-completer-48 [] { ["DynamoDB_20120810.UpdateGlobalTableSettings"] }
def x-amz-target-completer-49 [] { ["DynamoDB_20120810.UpdateItem"] }
def x-amz-target-completer-50 [] { ["DynamoDB_20120810.UpdateTable"] }
def x-amz-target-completer-51 [] { ["DynamoDB_20120810.UpdateTableReplicaAutoScaling"] }
def x-amz-target-completer-52 [] { ["DynamoDB_20120810.UpdateTimeToLive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api create-batch-execute-statement" } } | get name | first)
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

# This operation allows you to perform batch reads or writes on data stored in DynamoDB, using PartiQL. Each read statement in a BatchExecuteStatement must specify an equality condition on all key attributes. This enforces that each SELECT statement in a batch returns at most a single item. The entire batch must consist of either read statements or write statements, you cannot mix both in one batch. A HTTP 200 response does not mean that all statements in the BatchExecuteStatement succeeded. Error details for individual statements can be found under the Error (https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchStatementResponse.html#DDB-Type-BatchStatementResponse-Error) field of the BatchStatementResponse for each statement.
#
# POST /
# operationId: BatchExecuteStatement
export def "api create-batch-execute-statement" [
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
  statements: any
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
]: any -> record<Responses: record, ConsumedCapacity: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"Statements": $statements, "ReturnConsumedCapacity": $return_consumed_capacity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The BatchGetItem operation returns the attributes of one or more items from one or more tables. You identify requested items by primary key. A single operation can retrieve up to 16 MB of data, which can contain as many as 100 items. BatchGetItem returns a partial result if the response size limit is exceeded, the table's provisioned throughput is exceeded, or an internal processing failure occurs. If a partial result is returned, the operation returns a value for UnprocessedKeys. You can use this value to retry the operation starting with the next item to get. If you request more than 100 items, BatchGetItem returns a ValidationException with the message "Too many items requested for the BatchGetItem call." For example, if you ask to retrieve 100 items, but each individual item is 300 KB in size, the system returns 52 items (so as not to exceed the 16 MB limit). It also returns an appropriate UnprocessedKeys value so you can get the next page of results. If desired, your application can include its own logic to assemble the pages of results into one dataset. If none of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then BatchGetItem returns a ProvisionedThroughputExceededException. If at least one of the items is successfully processed, then BatchGetItem completes successfully, while returning the keys of the unread items in UnprocessedKeys. If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, we strongly recommend that you use an exponential backoff algorithm. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed. For more information, see Batch Operations and Error Handling (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#BatchOperations) in the Amazon DynamoDB Developer Guide. By default, BatchGetItem performs eventually consistent reads on every table in the request. If you want strongly consistent reads instead, you can set ConsistentRead to true for any or all tables. In order to minimize response latency, BatchGetItem may retrieve items in parallel. When designing your application, keep in mind that DynamoDB does not return items in any particular order. To help parse the response by item, include the primary key values for the items in your request in the ProjectionExpression parameter. If a requested item does not exist, it is not returned in the result. Requests for nonexistent items consume the minimum read capacity units according to the type of read. For more information, see Working with Tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithTables.html#CapacityUnitCalculations) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: BatchGetItem
export def "api get-batch-item" [
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
  --x-amz-target: string@x-amz-target-completer-1
  --request-items-body: any #  (body field)
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
]: any -> record<Responses: record, UnprocessedKeys: record, ConsumedCapacity: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RequestItems" $request_items "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"RequestItems": $request_items_body, "ReturnConsumedCapacity": $return_consumed_capacity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"RequestItems": $request_items} | compact), body: $req_body}
}

# The BatchWriteItem operation puts or deletes multiple items in one or more tables. A single call to BatchWriteItem can transmit up to 16MB of data over the network, consisting of up to 25 item put or delete operations. While individual items can be up to 400 KB once stored, it's important to note that an item's representation might be greater than 400KB while being sent in DynamoDB's JSON format for the API call. For more details on this distinction, see Naming Rules and Data Types (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html). BatchWriteItem cannot update items. If you perform a BatchWriteItem operation on an existing item, that item's values will be overwritten by the operation and it will appear like it was updated. To update items, we recommend you use the UpdateItem action. The individual PutItem and DeleteItem operations specified in BatchWriteItem are atomic; however BatchWriteItem as a whole is not. If any requested operations fail because the table's provisioned throughput is exceeded or an internal processing failure occurs, the failed operations are returned in the UnprocessedItems response parameter. You can investigate and optionally resend the requests. Typically, you would call BatchWriteItem in a loop. Each iteration would check for unprocessed items and submit a new BatchWriteItem request with those unprocessed items until all items have been processed. If none of the items can be processed due to insufficient provisioned throughput on all of the tables in the request, then BatchWriteItem returns a ProvisionedThroughputExceededException. If DynamoDB returns any unprocessed items, you should retry the batch operation on those items. However, we strongly recommend that you use an exponential backoff algorithm. If you retry the batch operation immediately, the underlying read or write requests can still fail due to throttling on the individual tables. If you delay the batch operation using exponential backoff, the individual requests in the batch are much more likely to succeed. For more information, see Batch Operations and Error Handling (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ErrorHandling.html#Programming.Errors.BatchOperations) in the Amazon DynamoDB Developer Guide. With BatchWriteItem, you can efficiently write or delete large amounts of data, such as from Amazon EMR, or copy data from another database into DynamoDB. In order to improve performance with these large-scale operations, BatchWriteItem does not behave in the same way as individual PutItem and DeleteItem calls would. For example, you cannot specify conditions on individual put and delete requests, and BatchWriteItem does not return deleted items in the response. If you use a programming language that supports concurrency, you can use threads to write items in parallel. Your application must include the necessary logic to manage the threads. With languages that don't support threading, you must update or delete the specified items one at a time. In both situations, BatchWriteItem performs the specified put and delete operations in parallel, giving you the power of the thread pool approach without having to introduce complexity into your application. Parallel processing reduces latency, but each specified put and delete request consumes the same number of write capacity units whether it is processed in parallel or not. Delete operations on nonexistent items consume one write capacity unit. If one or more of the following is true, DynamoDB rejects the entire batch write operation: One or more tables specified in the BatchWriteItem request does not exist. Primary key attributes specified on an item in the request do not match those in the corresponding table's primary key schema. You try to perform multiple operations on the same item in the same BatchWriteItem request. For example, you cannot put and delete the same item in the same BatchWriteItem request. Your request contains at least two items with identical hash and range keys (which essentially is two put operations). There are more than 25 requests in the batch. Any individual item in a batch exceeds 400 KB. The total request size exceeds 16 MB.
#
# POST /
# operationId: BatchWriteItem
export def "api create-batch-write-item" [
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
  request_items: any
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --return-item-collection-metrics: any
]: any -> record<UnprocessedItems: record, ItemCollectionMetrics: record, ConsumedCapacity: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"RequestItems": $request_items, "ReturnConsumedCapacity": $return_consumed_capacity, "ReturnItemCollectionMetrics": $return_item_collection_metrics} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a backup for an existing table. Each time you create an on-demand backup, the entire table data is backed up. There is no limit to the number of on-demand backups that can be taken. When you create an on-demand backup, a time marker of the request is cataloged, and the backup is created asynchronously, by applying all changes until the time of the request to the last full table snapshot. Backup requests are processed instantaneously and become available for restore within minutes. You can call CreateBackup at a maximum rate of 50 times per second. All backups in DynamoDB work without consuming any provisioned throughput on the table. If you submit a backup request on 2018-12-14 at 14:25:00, the backup is guaranteed to contain all data committed to the table up to 14:24:00, and data committed after 14:26:00 will not be. The backup might contain data modifications made between 14:24:00 and 14:26:00. On-demand backup does not support causal consistency. Along with data, the following are also included on the backups: Global secondary indexes (GSIs) Local secondary indexes (LSIs) Streams Provisioned read and write capacity
#
# POST /
# operationId: CreateBackup
export def "api create-backup" [
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
  table_name: any
  backup_name: any
]: any -> record<BackupDetails: record<BackupArn: record, BackupName: record, BackupSizeBytes: record, BackupStatus: record, BackupType: record, BackupCreationDateTime: record, BackupExpiryDateTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "BackupName": $backup_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a global table from an existing table. A global table creates a replication relationship between two or more DynamoDB tables with the same table name in the provided Regions. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html). If you want to add a new replica table to a global table, each of the following conditions must be true: The table must have the same primary key as all of the other replicas. The table must have the same name as all of the other replicas. The table must have DynamoDB Streams enabled, with the stream containing both the new and the old images of the item. None of the replica tables in the global table can contain any data. If global secondary indexes are specified, then the following conditions must also be met: The global secondary indexes must have the same name. The global secondary indexes must have the same hash key and sort key (if present). If local secondary indexes are specified, then the following conditions must also be met: The local secondary indexes must have the same name. The local secondary indexes must have the same hash key and sort key (if present). Write capacity settings should be set consistently across your replica tables and secondary indexes. DynamoDB strongly recommends enabling auto scaling to manage the write capacity settings for all of your global tables replicas and indexes. If you prefer to manage write capacity settings manually, you should provision equal replicated write capacity units to your replica tables. You should also provision equal replicated write capacity units to matching secondary indexes across your global table.
#
# POST /
# operationId: CreateGlobalTable
export def "api create-global-table" [
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
  global_table_name: any
  replication_group: any
]: any -> record<GlobalTableDescription: record<ReplicationGroup: record, GlobalTableArn: record, CreationDateTime: record, GlobalTableStatus: record, GlobalTableName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"GlobalTableName": $global_table_name, "ReplicationGroup": $replication_group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The CreateTable operation adds a new table to your account. In an Amazon Web Services account, table names must be unique within each Region. That is, you can have two tables with same name if you create the tables in different Regions. CreateTable is an asynchronous operation. Upon receiving a CreateTable request, DynamoDB immediately returns a response with a TableStatus of CREATING. After the table is created, DynamoDB sets the TableStatus to ACTIVE. You can perform read and write operations only on an ACTIVE table. You can optionally define secondary indexes on the new table, as part of the CreateTable operation. If you want to create multiple tables with secondary indexes on them, you must create the tables sequentially. Only one table with secondary indexes can be in the CREATING state at any given time. You can use the DescribeTable action to check the table status.
#
# POST /
# operationId: CreateTable
export def "api create-table" [
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
  attribute_definitions: any
  table_name: any
  key_schema: any
  --local-secondary-indexes: any
  --global-secondary-indexes: any
  --billing-mode: any
  --provisioned-throughput: any
  --stream-specification: any
  --sse-specification: any
  --tags: any
  --table-class: any
  --deletion-protection-enabled: any
]: any -> record<TableDescription: record<AttributeDefinitions: record, TableName: record, KeySchema: record, TableStatus: record, CreationDateTime: record, ProvisionedThroughput: record<LastIncreaseDateTime: record, LastDecreaseDateTime: record, NumberOfDecreasesToday: record, ReadCapacityUnits: record, WriteCapacityUnits: record>, TableSizeBytes: record, ItemCount: record, TableArn: record, TableId: record, BillingModeSummary: record<BillingMode: record, LastUpdateToPayPerRequestDateTime: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record, StreamSpecification: record<StreamEnabled: record, StreamViewType: record>, LatestStreamLabel: record, LatestStreamArn: record, GlobalTableVersion: record, Replicas: record, RestoreSummary: record<SourceBackupArn: record, SourceTableArn: record, RestoreDateTime: record, RestoreInProgress: record>, SSEDescription: record<Status: record, SSEType: record, KMSMasterKeyArn: record, InaccessibleEncryptionDateTime: record>, ArchivalSummary: record<ArchivalDateTime: record, ArchivalReason: record, ArchivalBackupArn: record>, TableClassSummary: record<TableClass: record, LastUpdateDateTime: record>, DeletionProtectionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"AttributeDefinitions": $attribute_definitions, "TableName": $table_name, "KeySchema": $key_schema, "LocalSecondaryIndexes": $local_secondary_indexes, "GlobalSecondaryIndexes": $global_secondary_indexes, "BillingMode": $billing_mode, "ProvisionedThroughput": $provisioned_throughput, "StreamSpecification": $stream_specification, "SSESpecification": $sse_specification, "Tags": $tags, "TableClass": $table_class, "DeletionProtectionEnabled": $deletion_protection_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an existing backup of a table. You can call DeleteBackup at a maximum rate of 10 times per second.
#
# POST /
# operationId: DeleteBackup
export def "api delete-backup" [
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
  backup_arn: any
]: any -> record<BackupDescription: record<BackupDetails: record<BackupArn: record, BackupName: record, BackupSizeBytes: record, BackupStatus: record, BackupType: record, BackupCreationDateTime: record, BackupExpiryDateTime: record>, SourceTableDetails: record<TableName: record, TableId: record, TableArn: record, TableSizeBytes: record, KeySchema: record, TableCreationDateTime: record, ProvisionedThroughput: record, ItemCount: record, BillingMode: record>, SourceTableFeatureDetails: record<LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record, StreamDescription: record, TimeToLiveDescription: record, SSEDescription: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"BackupArn": $backup_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a single item in a table by primary key. You can perform a conditional delete operation that deletes the item if it exists, or if it has an expected attribute value. In addition to deleting an item, you can also return the item's attribute values in the same operation, using the ReturnValues parameter. Unless you specify conditions, the DeleteItem is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. Conditional deletes are useful for deleting items only if specific conditions are met. If those conditions are met, DynamoDB performs the delete. Otherwise, the item is not deleted.
#
# POST /
# operationId: DeleteItem
export def "api delete-item" [
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
  table_name: any
  key: any
  --expected: any
  --conditional-operator: any
  --return-values: any
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --return-item-collection-metrics: any
  --condition-expression: any
  --expression-attribute-names: any
  --expression-attribute-values: any
]: any -> record<Attributes: record, ConsumedCapacity: record<TableName: record, CapacityUnits: record, ReadCapacityUnits: record, WriteCapacityUnits: record, Table: record<ReadCapacityUnits: record, WriteCapacityUnits: record, CapacityUnits: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>, ItemCollectionMetrics: record<ItemCollectionKey: record, SizeEstimateRangeGB: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "Key": $key, "Expected": $expected, "ConditionalOperator": $conditional_operator, "ReturnValues": $return_values, "ReturnConsumedCapacity": $return_consumed_capacity, "ReturnItemCollectionMetrics": $return_item_collection_metrics, "ConditionExpression": $condition_expression, "ExpressionAttributeNames": $expression_attribute_names, "ExpressionAttributeValues": $expression_attribute_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The DeleteTable operation deletes a table and all of its items. After a DeleteTable request, the specified table is in the DELETING state until DynamoDB completes the deletion. If the table is in the ACTIVE state, you can delete it. If a table is in CREATING or UPDATING states, then DynamoDB returns a ResourceInUseException. If the specified table does not exist, DynamoDB returns a ResourceNotFoundException. If table is already in the DELETING state, no error is returned. This operation only applies to Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) of global tables. DynamoDB might continue to accept data read and write operations, such as GetItem and PutItem, on a table in the DELETING state until the table deletion is complete. When you delete a table, any indexes on that table are also deleted. If you have DynamoDB Streams enabled on the table, then the corresponding stream on that table goes into the DISABLED state, and the stream is automatically deleted after 24 hours. Use the DescribeTable action to check the status of the table.
#
# POST /
# operationId: DeleteTable
export def "api delete-table" [
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
  table_name: any
]: any -> record<TableDescription: record<AttributeDefinitions: record, TableName: record, KeySchema: record, TableStatus: record, CreationDateTime: record, ProvisionedThroughput: record<LastIncreaseDateTime: record, LastDecreaseDateTime: record, NumberOfDecreasesToday: record, ReadCapacityUnits: record, WriteCapacityUnits: record>, TableSizeBytes: record, ItemCount: record, TableArn: record, TableId: record, BillingModeSummary: record<BillingMode: record, LastUpdateToPayPerRequestDateTime: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record, StreamSpecification: record<StreamEnabled: record, StreamViewType: record>, LatestStreamLabel: record, LatestStreamArn: record, GlobalTableVersion: record, Replicas: record, RestoreSummary: record<SourceBackupArn: record, SourceTableArn: record, RestoreDateTime: record, RestoreInProgress: record>, SSEDescription: record<Status: record, SSEType: record, KMSMasterKeyArn: record, InaccessibleEncryptionDateTime: record>, ArchivalSummary: record<ArchivalDateTime: record, ArchivalReason: record, ArchivalBackupArn: record>, TableClassSummary: record<TableClass: record, LastUpdateDateTime: record>, DeletionProtectionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Describes an existing backup of a table. You can call DescribeBackup at a maximum rate of 10 times per second.
#
# POST /
# operationId: DescribeBackup
export def "api get-backup" [
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
  backup_arn: any
]: any -> record<BackupDescription: record<BackupDetails: record<BackupArn: record, BackupName: record, BackupSizeBytes: record, BackupStatus: record, BackupType: record, BackupCreationDateTime: record, BackupExpiryDateTime: record>, SourceTableDetails: record<TableName: record, TableId: record, TableArn: record, TableSizeBytes: record, KeySchema: record, TableCreationDateTime: record, ProvisionedThroughput: record, ItemCount: record, BillingMode: record>, SourceTableFeatureDetails: record<LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record, StreamDescription: record, TimeToLiveDescription: record, SSEDescription: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"BackupArn": $backup_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Checks the status of continuous backups and point in time recovery on the specified table. Continuous backups are ENABLED on all tables at table creation. If point in time recovery is enabled, PointInTimeRecoveryStatus will be set to ENABLED. After continuous backups and point in time recovery are enabled, you can restore to any point in time within EarliestRestorableDateTime and LatestRestorableDateTime. LatestRestorableDateTime is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days. You can call DescribeContinuousBackups at a maximum rate of 10 times per second.
#
# POST /
# operationId: DescribeContinuousBackups
export def "api get-continuous-backups" [
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
  table_name: any
]: any -> record<ContinuousBackupsDescription: record<ContinuousBackupsStatus: record, PointInTimeRecoveryDescription: record<PointInTimeRecoveryStatus: record, EarliestRestorableDateTime: record, LatestRestorableDateTime: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns information about contributor insights for a given table or global secondary index.
#
# POST /
# operationId: DescribeContributorInsights
export def "api get-contributor-insights" [
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
  table_name: any
  --index-name: any
]: any -> record<TableName: record, IndexName: record, ContributorInsightsRuleList: record, ContributorInsightsStatus: record, LastUpdateDateTime: record, FailureException: record<ExceptionName: record, ExceptionDescription: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "IndexName": $index_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the regional endpoint information. This action must be included in your VPC endpoint policies, or access to the DescribeEndpoints API will be denied. For more information on policy permissions, please see Internetwork traffic privacy (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/inter-network-traffic-privacy.html#inter-network-traffic-DescribeEndpoints).
#
# POST /
# operationId: DescribeEndpoints
export def "api get-endpoints" [
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
  --body: record
]: any -> record<Endpoints: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Describes an existing table export.
#
# POST /
# operationId: DescribeExport
export def "api get-export" [
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
  export_arn: any
]: any -> record<ExportDescription: record<ExportArn: record, ExportStatus: record, StartTime: record, EndTime: record, ExportManifest: record, TableArn: record, TableId: record, ExportTime: record, ClientToken: record, S3Bucket: record, S3BucketOwner: record, S3Prefix: record, S3SseAlgorithm: record, S3SseKmsKeyId: record, FailureCode: record, FailureMessage: record, ExportFormat: record, BilledSizeBytes: record, ItemCount: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"ExportArn": $export_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns information about the specified global table. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html).
#
# POST /
# operationId: DescribeGlobalTable
export def "api get-global-table" [
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
  global_table_name: any
]: any -> record<GlobalTableDescription: record<ReplicationGroup: record, GlobalTableArn: record, CreationDateTime: record, GlobalTableStatus: record, GlobalTableName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"GlobalTableName": $global_table_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Describes Region-specific settings for a global table. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html).
#
# POST /
# operationId: DescribeGlobalTableSettings
export def "api get-global-table-settings" [
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
  global_table_name: any
]: any -> record<GlobalTableName: record, ReplicaSettings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"GlobalTableName": $global_table_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Represents the properties of the import.
#
# POST /
# operationId: DescribeImport
export def "api get-import" [
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
  import_arn: any
]: any -> record<ImportTableDescription: record<ImportArn: record, ImportStatus: record, TableArn: record, TableId: record, ClientToken: record, S3BucketSource: record<S3BucketOwner: record, S3Bucket: record, S3KeyPrefix: record>, ErrorCount: record, CloudWatchLogGroupArn: record, InputFormat: record, InputFormatOptions: record<Csv: record>, InputCompressionType: record, TableCreationParameters: record<TableName: record, AttributeDefinitions: record, KeySchema: record, BillingMode: record, ProvisionedThroughput: record, SSESpecification: record, GlobalSecondaryIndexes: record>, StartTime: record, EndTime: record, ProcessedSizeBytes: record, ProcessedItemCount: record, ImportedItemCount: record, FailureCode: record, FailureMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"ImportArn": $import_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns information about the status of Kinesis streaming.
#
# POST /
# operationId: DescribeKinesisStreamingDestination
export def "api get-kinesis-streaming-destination" [
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
  table_name: any
]: any -> record<TableName: record, KinesisDataStreamDestinations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the current provisioned-capacity quotas for your Amazon Web Services account in a Region, both for the Region as a whole and for any one DynamoDB table that you create there. When you establish an Amazon Web Services account, the account has initial quotas on the maximum read capacity units and write capacity units that you can provision across all of your DynamoDB tables in a given Region. Also, there are per-table quotas that apply when you create a table there. For more information, see Service, Account, and Table Quotas (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Limits.html) page in the Amazon DynamoDB Developer Guide. Although you can increase these quotas by filing a case at Amazon Web Services Support Center (https://console.aws.amazon.com/support/home#/), obtaining the increase is not instantaneous. The DescribeLimits action lets you write code to compare the capacity you are currently using to those quotas imposed by your account so that you have enough time to apply for an increase before you hit a quota. For example, you could use one of the Amazon Web Services SDKs to do the following: Call DescribeLimits for a particular Region to obtain your current account quotas on provisioned capacity there. Create a variable to hold the aggregate read capacity units provisioned for all your tables in that Region, and one to hold the aggregate write capacity units. Zero them both. Call ListTables to obtain a list of all your DynamoDB tables. For each table name listed by ListTables, do the following: Call DescribeTable with the table name. Use the data returned by DescribeTable to add the read capacity units and write capacity units provisioned for the table itself to your variables. If the table has one or more global secondary indexes (GSIs), loop over these GSIs and add their provisioned capacity values to your variables as well. Report the account quotas for that Region returned by DescribeLimits, along with the total current provisioned capacity levels you have calculated. This will let you see whether you are getting close to your account-level quotas. The per-table quotas apply only when you are creating a new table. They restrict the sum of the provisioned capacity of the new table itself and all its global secondary indexes. For existing tables and their GSIs, DynamoDB doesn't let you increase provisioned capacity extremely rapidly, but the only quota that applies is that the aggregate provisioned capacity over all your tables and GSIs cannot exceed either of the per-account quotas. DescribeLimits should only be called periodically. You can expect throttling errors if you call it more than once in a minute. The DescribeLimits Request element has no content.
#
# POST /
# operationId: DescribeLimits
export def "api get-limits" [
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
  --body: record
]: any -> record<AccountMaxReadCapacityUnits: record, AccountMaxWriteCapacityUnits: record, TableMaxReadCapacityUnits: record, TableMaxWriteCapacityUnits: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns information about the table, including the current status of the table, when it was created, the primary key schema, and any indexes on the table. This operation only applies to Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) of global tables. If you issue a DescribeTable request immediately after a CreateTable request, DynamoDB might return a ResourceNotFoundException. This is because DescribeTable uses an eventually consistent query, and the metadata for your table might not be available at that moment. Wait for a few seconds, and then try the DescribeTable request again.
#
# POST /
# operationId: DescribeTable
export def "api get-table" [
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
  table_name: any
]: any -> record<Table: record<AttributeDefinitions: record, TableName: record, KeySchema: record, TableStatus: record, CreationDateTime: record, ProvisionedThroughput: record<LastIncreaseDateTime: record, LastDecreaseDateTime: record, NumberOfDecreasesToday: record, ReadCapacityUnits: record, WriteCapacityUnits: record>, TableSizeBytes: record, ItemCount: record, TableArn: record, TableId: record, BillingModeSummary: record<BillingMode: record, LastUpdateToPayPerRequestDateTime: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record, StreamSpecification: record<StreamEnabled: record, StreamViewType: record>, LatestStreamLabel: record, LatestStreamArn: record, GlobalTableVersion: record, Replicas: record, RestoreSummary: record<SourceBackupArn: record, SourceTableArn: record, RestoreDateTime: record, RestoreInProgress: record>, SSEDescription: record<Status: record, SSEType: record, KMSMasterKeyArn: record, InaccessibleEncryptionDateTime: record>, ArchivalSummary: record<ArchivalDateTime: record, ArchivalReason: record, ArchivalBackupArn: record>, TableClassSummary: record<TableClass: record, LastUpdateDateTime: record>, DeletionProtectionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Describes auto scaling settings across replicas of the global table at once. This operation only applies to Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) of global tables.
#
# POST /
# operationId: DescribeTableReplicaAutoScaling
export def "api get-table-replica-auto-scaling" [
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
  table_name: any
]: any -> record<TableAutoScalingDescription: record<TableName: record, TableStatus: record, Replicas: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gives a description of the Time to Live (TTL) status on the specified table.
#
# POST /
# operationId: DescribeTimeToLive
export def "api get-time-to-live" [
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
  --x-amz-target: string@x-amz-target-completer-21
  table_name: any
]: any -> record<TimeToLiveDescription: record<TimeToLiveStatus: record, AttributeName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Stops replication from the DynamoDB table to the Kinesis data stream. This is done without deleting either of the resources.
#
# POST /
# operationId: DisableKinesisStreamingDestination
export def "api disable-kinesis-streaming-destination" [
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
  --x-amz-target: string@x-amz-target-completer-22
  table_name: any
  stream_arn: any
]: any -> record<TableName: record, StreamArn: record, DestinationStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "StreamArn": $stream_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Starts table data replication to the specified Kinesis data stream at a timestamp chosen during the enable workflow. If this operation doesn't return results immediately, use DescribeKinesisStreamingDestination to check if streaming to the Kinesis data stream is ACTIVE.
#
# POST /
# operationId: EnableKinesisStreamingDestination
export def "api enable-kinesis-streaming-destination" [
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
  --x-amz-target: string@x-amz-target-completer-23
  table_name: any
  stream_arn: any
]: any -> record<TableName: record, StreamArn: record, DestinationStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "StreamArn": $stream_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This operation allows you to perform reads and singleton writes on data stored in DynamoDB, using PartiQL. For PartiQL reads (SELECT statement), if the total number of processed items exceeds the maximum dataset size limit of 1 MB, the read stops and results are returned to the user as a LastEvaluatedKey value to continue the read in a subsequent operation. If the filter criteria in WHERE clause does not match any data, the read will return an empty result set. A single SELECT statement response can return up to the maximum number of items (if using the Limit parameter) or a maximum of 1 MB of data (and then apply any filtering to the results using WHERE clause). If LastEvaluatedKey is present in the response, you need to paginate the result set. If NextToken is present, you need to paginate the result set and include NextToken.
#
# POST /
# operationId: ExecuteStatement
export def "api create-execute-statement" [
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
  --x-amz-target: string@x-amz-target-completer-24
  statement: any
  --parameters: any
  --consistent-read: any
  --next-token: any
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --limit: any
]: any -> record<Items: record, NextToken: record, ConsumedCapacity: record<TableName: record, CapacityUnits: record, ReadCapacityUnits: record, WriteCapacityUnits: record, Table: record<ReadCapacityUnits: record, WriteCapacityUnits: record, CapacityUnits: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>, LastEvaluatedKey: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"Statement": $statement, "Parameters": $parameters, "ConsistentRead": $consistent_read, "NextToken": $next_token, "ReturnConsumedCapacity": $return_consumed_capacity, "Limit": $limit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This operation allows you to perform transactional reads or writes on data stored in DynamoDB, using PartiQL. The entire transaction must consist of either read statements or write statements, you cannot mix both in one transaction. The EXISTS function is an exception and can be used to check the condition of specific attributes of the item in a similar manner to ConditionCheck in the TransactWriteItems (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/transaction-apis.html#transaction-apis-txwriteitems) API.
#
# POST /
# operationId: ExecuteTransaction
export def "api create-execute-transaction" [
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
  --x-amz-target: string@x-amz-target-completer-25
  transact_statements: any
  --client-request-token: any
  --return-consumed-capacity: any
]: any -> record<Responses: record, ConsumedCapacity: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TransactStatements": $transact_statements, "ClientRequestToken": $client_request_token, "ReturnConsumedCapacity": $return_consumed_capacity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Exports table data to an S3 bucket. The table must have point in time recovery enabled, and you can export data from any time within the point in time recovery window.
#
# POST /
# operationId: ExportTableToPointInTime
export def "api export-table-to-point-in-time" [
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
  --x-amz-target: string@x-amz-target-completer-26
  table_arn: any
  --export-time: any
  --client-token: any
  s3_bucket: any
  --s3-bucket-owner: any
  --s3-prefix: any
  --s3-sse-algorithm: any
  --s3-sse-kms-key-id: any
  --export-format: any
]: any -> record<ExportDescription: record<ExportArn: record, ExportStatus: record, StartTime: record, EndTime: record, ExportManifest: record, TableArn: record, TableId: record, ExportTime: record, ClientToken: record, S3Bucket: record, S3BucketOwner: record, S3Prefix: record, S3SseAlgorithm: record, S3SseKmsKeyId: record, FailureCode: record, FailureMessage: record, ExportFormat: record, BilledSizeBytes: record, ItemCount: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableArn": $table_arn, "ExportTime": $export_time, "ClientToken": $client_token, "S3Bucket": $s3_bucket, "S3BucketOwner": $s3_bucket_owner, "S3Prefix": $s3_prefix, "S3SseAlgorithm": $s3_sse_algorithm, "S3SseKmsKeyId": $s3_sse_kms_key_id, "ExportFormat": $export_format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The GetItem operation returns a set of attributes for the item with the given primary key. If there is no matching item, GetItem does not return any data and there will be no Item element in the response. GetItem provides an eventually consistent read by default. If your application requires a strongly consistent read, set ConsistentRead to true. Although a strongly consistent read might take more time than an eventually consistent read, it always returns the last updated value.
#
# POST /
# operationId: GetItem
export def "api get-item" [
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
  table_name: any
  key: any
  --attributes-to-get: any
  --consistent-read: any
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --projection-expression: any
  --expression-attribute-names: any
]: any -> record<Item: record, ConsumedCapacity: record<TableName: record, CapacityUnits: record, ReadCapacityUnits: record, WriteCapacityUnits: record, Table: record<ReadCapacityUnits: record, WriteCapacityUnits: record, CapacityUnits: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "Key": $key, "AttributesToGet": $attributes_to_get, "ConsistentRead": $consistent_read, "ReturnConsumedCapacity": $return_consumed_capacity, "ProjectionExpression": $projection_expression, "ExpressionAttributeNames": $expression_attribute_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Imports table data from an S3 bucket.
#
# POST /
# operationId: ImportTable
export def "api import-table" [
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
  --x-amz-target: string@x-amz-target-completer-28
  --client-token: any
  s3_bucket_source: any
  input_format: any
  --input-format-options: any
  --input-compression-type: any
  table_creation_parameters: any
]: any -> record<ImportTableDescription: record<ImportArn: record, ImportStatus: record, TableArn: record, TableId: record, ClientToken: record, S3BucketSource: record<S3BucketOwner: record, S3Bucket: record, S3KeyPrefix: record>, ErrorCount: record, CloudWatchLogGroupArn: record, InputFormat: record, InputFormatOptions: record<Csv: record>, InputCompressionType: record, TableCreationParameters: record<TableName: record, AttributeDefinitions: record, KeySchema: record, BillingMode: record, ProvisionedThroughput: record, SSESpecification: record, GlobalSecondaryIndexes: record>, StartTime: record, EndTime: record, ProcessedSizeBytes: record, ProcessedItemCount: record, ImportedItemCount: record, FailureCode: record, FailureMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"ClientToken": $client_token, "S3BucketSource": $s3_bucket_source, "InputFormat": $input_format, "InputFormatOptions": $input_format_options, "InputCompressionType": $input_compression_type, "TableCreationParameters": $table_creation_parameters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List backups associated with an Amazon Web Services account. To list backups for a given table, specify TableName. ListBackups returns a paginated list of results with at most 1 MB worth of items in a page. You can also specify a maximum number of entries to be returned in a page. In the request, start time is inclusive, but end time is exclusive. Note that these boundaries are for the time at which the original backup was requested. You can call ListBackups a maximum of five times per second.
#
# POST /
# operationId: ListBackups
export def "api list-backups" [
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
  --x-amz-target: string@x-amz-target-completer-29
  --table-name: any
  --limit: any
  --time-range-lower-bound: any
  --time-range-upper-bound: any
  --exclusive-start-backup-arn: any
  --backup-type: any
]: any -> record<BackupSummaries: record, LastEvaluatedBackupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "Limit": $limit, "TimeRangeLowerBound": $time_range_lower_bound, "TimeRangeUpperBound": $time_range_upper_bound, "ExclusiveStartBackupArn": $exclusive_start_backup_arn, "BackupType": $backup_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of ContributorInsightsSummary for a table and all its global secondary indexes.
#
# POST /
# operationId: ListContributorInsights
export def "api list-contributor-insights" [
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
  --x-amz-target: string@x-amz-target-completer-30
  --table-name: any
  --next-token-body: any #  (body field)
  --max-results-body: any #  (body field)
]: any -> record<ContributorInsightsSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"TableName": $table_name, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Lists completed exports within the past 90 days.
#
# POST /
# operationId: ListExports
export def "api list-exports" [
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
  --x-amz-target: string@x-amz-target-completer-31
  --table-arn: any
  --max-results-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<ExportSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"TableArn": $table_arn, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Lists all global tables that have a replica in the specified Region. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html).
#
# POST /
# operationId: ListGlobalTables
export def "api list-global-tables" [
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
  --x-amz-target: string@x-amz-target-completer-32
  --exclusive-start-global-table-name: any
  --limit: any
  --region-name: any
]: any -> record<GlobalTables: record, LastEvaluatedGlobalTableName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"ExclusiveStartGlobalTableName": $exclusive_start_global_table_name, "Limit": $limit, "RegionName": $region_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists completed imports within the past 90 days.
#
# POST /
# operationId: ListImports
export def "api list-imports" [
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
  --x-amz-target: string@x-amz-target-completer-33
  --table-arn: any
  --page-size-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<ImportSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"TableArn": $table_arn, "PageSize": $page_size_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"PageSize": $page_size, "NextToken": $next_token} | compact), body: $req_body}
}

# Returns an array of table names associated with the current account and endpoint. The output from ListTables is paginated, with each page returning a maximum of 100 table names.
#
# POST /
# operationId: ListTables
export def "api list-tables" [
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
  --x-amz-target: string@x-amz-target-completer-34
  --exclusive-start-table-name-body: any #  (body field)
  --limit-body: any #  (body field)
]: any -> record<TableNames: record, LastEvaluatedTableName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "ExclusiveStartTableName" $exclusive_start_table_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"ExclusiveStartTableName": $exclusive_start_table_name_body, "Limit": $limit_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Limit": $limit, "ExclusiveStartTableName": $exclusive_start_table_name} | compact), body: $req_body}
}

# List all tags on an Amazon DynamoDB resource. You can call ListTagsOfResource up to 10 times per second, per account. For an overview on tagging DynamoDB resources, see Tagging for DynamoDB (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: ListTagsOfResource
export def "api list-tags-of-resource" [
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
  --x-amz-target: string@x-amz-target-completer-35
  resource_arn: any
  --next-token: any
]: any -> record<Tags: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"ResourceArn": $resource_arn, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a new item, or replaces an old item with a new item. If an item that has the same primary key as the new item already exists in the specified table, the new item completely replaces the existing item. You can perform a conditional put operation (add a new item if one with the specified primary key doesn't exist), or replace an existing item if it has certain attribute values. You can return the item's attribute values in the same operation, using the ReturnValues parameter. When you add an item, the primary key attributes are the only required attributes. Empty String and Binary attribute values are allowed. Attribute values of type String and Binary must have a length greater than zero if the attribute is used as a key attribute for a table or index. Set type attributes cannot be empty. Invalid Requests with empty values will be rejected with a ValidationException exception. To prevent a new item from replacing an existing item, use a conditional expression that contains the attribute_not_exists function with the name of the attribute being used as the partition key for the table. Since every record must contain that attribute, the attribute_not_exists function will only succeed if no matching item exists. For more information about PutItem, see Working with Items (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: PutItem
export def "api update-item" [
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
  --x-amz-target: string@x-amz-target-completer-36
  table_name: any
  item: any
  --expected: any
  --return-values: any
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --return-item-collection-metrics: any
  --conditional-operator: any
  --condition-expression: any
  --expression-attribute-names: any
  --expression-attribute-values: any
]: any -> record<Attributes: record, ConsumedCapacity: record<TableName: record, CapacityUnits: record, ReadCapacityUnits: record, WriteCapacityUnits: record, Table: record<ReadCapacityUnits: record, WriteCapacityUnits: record, CapacityUnits: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>, ItemCollectionMetrics: record<ItemCollectionKey: record, SizeEstimateRangeGB: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "Item": $item, "Expected": $expected, "ReturnValues": $return_values, "ReturnConsumedCapacity": $return_consumed_capacity, "ReturnItemCollectionMetrics": $return_item_collection_metrics, "ConditionalOperator": $conditional_operator, "ConditionExpression": $condition_expression, "ExpressionAttributeNames": $expression_attribute_names, "ExpressionAttributeValues": $expression_attribute_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# You must provide the name of the partition key attribute and a single value for that attribute. Query returns all items with that partition key value. Optionally, you can provide a sort key attribute and use a comparison operator to refine the search results. Use the KeyConditionExpression parameter to provide a specific value for the partition key. The Query operation will return all of the items from the table or index with that partition key value. You can optionally narrow the scope of the Query operation by specifying a sort key value and a comparison operator in KeyConditionExpression. To further refine the Query results, you can optionally provide a FilterExpression. A FilterExpression determines which items within the results should be returned to you. All of the other results are discarded. A Query operation always returns a result set. If no matching items are found, the result set will be empty. Queries that do not return results consume the minimum number of read capacity units for that type of read operation. DynamoDB calculates the number of read capacity units consumed based on item size, not on the amount of data that is returned to an application. The number of capacity units consumed will be the same whether you request all of the attributes (the default behavior) or just some of them (using a projection expression). The number will also be the same whether or not you use a FilterExpression. Query results are always sorted by the sort key value. If the data type of the sort key is Number, the results are returned in numeric order; otherwise, the results are returned in order of UTF-8 bytes. By default, the sort order is ascending. To reverse the order, set the ScanIndexForward parameter to false. A single Query operation will read up to the maximum number of items set (if using the Limit parameter) or a maximum of 1 MB of data and then apply any filtering to the results using FilterExpression. If LastEvaluatedKey is present in the response, you will need to paginate the result set. For more information, see Paginating the Results (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html#Query.Pagination) in the Amazon DynamoDB Developer Guide. FilterExpression is applied after a Query finishes, but before the results are returned. A FilterExpression cannot contain partition key or sort key attributes. You need to specify those attributes in the KeyConditionExpression. A Query operation can return an empty result set and a LastEvaluatedKey if all the items read for the page of results are filtered out. You can query a table, a local secondary index, or a global secondary index. For a query on a table or on a local secondary index, you can set the ConsistentRead parameter to true and obtain a strongly consistent result. Global secondary indexes support eventually consistent reads only, so do not specify ConsistentRead when querying a global secondary index.
#
# POST /
# operationId: Query
export def "api list" [
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
  --x-amz-target: string@x-amz-target-completer-37
  table_name: any
  --index-name: any
  --select: any
  --attributes-to-get: any
  --limit-body: any #  (body field)
  --consistent-read: any
  --key-conditions: any
  --query-filter: any
  --conditional-operator: any
  --scan-index-forward: any
  --exclusive-start-key-body: any #  (body field)
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --projection-expression: any
  --filter-expression: any
  --key-condition-expression: any
  --expression-attribute-names: any
  --expression-attribute-values: any
]: any -> record<Items: record, Count: record, ScannedCount: record, LastEvaluatedKey: record, ConsumedCapacity: record<TableName: record, CapacityUnits: record, ReadCapacityUnits: record, WriteCapacityUnits: record, Table: record<ReadCapacityUnits: record, WriteCapacityUnits: record, CapacityUnits: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "ExclusiveStartKey" $exclusive_start_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"TableName": $table_name, "IndexName": $index_name, "Select": $select, "AttributesToGet": $attributes_to_get, "Limit": $limit_body, "ConsistentRead": $consistent_read, "KeyConditions": $key_conditions, "QueryFilter": $query_filter, "ConditionalOperator": $conditional_operator, "ScanIndexForward": $scan_index_forward, "ExclusiveStartKey": $exclusive_start_key_body, "ReturnConsumedCapacity": $return_consumed_capacity, "ProjectionExpression": $projection_expression, "FilterExpression": $filter_expression, "KeyConditionExpression": $key_condition_expression, "ExpressionAttributeNames": $expression_attribute_names, "ExpressionAttributeValues": $expression_attribute_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Limit": $limit, "ExclusiveStartKey": $exclusive_start_key} | compact), body: $req_body}
}

# Creates a new table from an existing backup. Any number of users can execute up to 50 concurrent restores (any type of restore) in a given account. You can call RestoreTableFromBackup at a maximum rate of 10 times per second. You must manually set up the following on the restored table: Auto scaling policies IAM policies Amazon CloudWatch metrics and alarms Tags Stream settings Time to Live (TTL) settings
#
# POST /
# operationId: RestoreTableFromBackup
export def "api create-restore-table-from-backup" [
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
  --x-amz-target: string@x-amz-target-completer-38
  target_table_name: any
  backup_arn: any
  --billing-mode-override: any
  --global-secondary-index-override: any
  --local-secondary-index-override: any
  --provisioned-throughput-override: any
  --sse-specification-override: any
]: any -> record<TableDescription: record<AttributeDefinitions: record, TableName: record, KeySchema: record, TableStatus: record, CreationDateTime: record, ProvisionedThroughput: record<LastIncreaseDateTime: record, LastDecreaseDateTime: record, NumberOfDecreasesToday: record, ReadCapacityUnits: record, WriteCapacityUnits: record>, TableSizeBytes: record, ItemCount: record, TableArn: record, TableId: record, BillingModeSummary: record<BillingMode: record, LastUpdateToPayPerRequestDateTime: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record, StreamSpecification: record<StreamEnabled: record, StreamViewType: record>, LatestStreamLabel: record, LatestStreamArn: record, GlobalTableVersion: record, Replicas: record, RestoreSummary: record<SourceBackupArn: record, SourceTableArn: record, RestoreDateTime: record, RestoreInProgress: record>, SSEDescription: record<Status: record, SSEType: record, KMSMasterKeyArn: record, InaccessibleEncryptionDateTime: record>, ArchivalSummary: record<ArchivalDateTime: record, ArchivalReason: record, ArchivalBackupArn: record>, TableClassSummary: record<TableClass: record, LastUpdateDateTime: record>, DeletionProtectionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TargetTableName": $target_table_name, "BackupArn": $backup_arn, "BillingModeOverride": $billing_mode_override, "GlobalSecondaryIndexOverride": $global_secondary_index_override, "LocalSecondaryIndexOverride": $local_secondary_index_override, "ProvisionedThroughputOverride": $provisioned_throughput_override, "SSESpecificationOverride": $sse_specification_override} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Restores the specified table to the specified point in time within EarliestRestorableDateTime and LatestRestorableDateTime. You can restore your table to any point in time during the last 35 days. Any number of users can execute up to 4 concurrent restores (any type of restore) in a given account. When you restore using point in time recovery, DynamoDB restores your table data to the state based on the selected date and time (day:hour:minute:second) to a new table. Along with data, the following are also included on the new restored table using point in time recovery: Global secondary indexes (GSIs) Local secondary indexes (LSIs) Provisioned read and write capacity Encryption settings All these settings come from the current settings of the source table at the time of restore. You must manually set up the following on the restored table: Auto scaling policies IAM policies Amazon CloudWatch metrics and alarms Tags Stream settings Time to Live (TTL) settings Point in time recovery settings
#
# POST /
# operationId: RestoreTableToPointInTime
export def "api create-restore-table-to-point-in-time" [
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
  --source-table-arn: any
  --source-table-name: any
  target_table_name: any
  --use-latest-restorable-time: any
  --restore-date-time: any
  --billing-mode-override: any
  --global-secondary-index-override: any
  --local-secondary-index-override: any
  --provisioned-throughput-override: any
  --sse-specification-override: any
]: any -> record<TableDescription: record<AttributeDefinitions: record, TableName: record, KeySchema: record, TableStatus: record, CreationDateTime: record, ProvisionedThroughput: record<LastIncreaseDateTime: record, LastDecreaseDateTime: record, NumberOfDecreasesToday: record, ReadCapacityUnits: record, WriteCapacityUnits: record>, TableSizeBytes: record, ItemCount: record, TableArn: record, TableId: record, BillingModeSummary: record<BillingMode: record, LastUpdateToPayPerRequestDateTime: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record, StreamSpecification: record<StreamEnabled: record, StreamViewType: record>, LatestStreamLabel: record, LatestStreamArn: record, GlobalTableVersion: record, Replicas: record, RestoreSummary: record<SourceBackupArn: record, SourceTableArn: record, RestoreDateTime: record, RestoreInProgress: record>, SSEDescription: record<Status: record, SSEType: record, KMSMasterKeyArn: record, InaccessibleEncryptionDateTime: record>, ArchivalSummary: record<ArchivalDateTime: record, ArchivalReason: record, ArchivalBackupArn: record>, TableClassSummary: record<TableClass: record, LastUpdateDateTime: record>, DeletionProtectionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"SourceTableArn": $source_table_arn, "SourceTableName": $source_table_name, "TargetTableName": $target_table_name, "UseLatestRestorableTime": $use_latest_restorable_time, "RestoreDateTime": $restore_date_time, "BillingModeOverride": $billing_mode_override, "GlobalSecondaryIndexOverride": $global_secondary_index_override, "LocalSecondaryIndexOverride": $local_secondary_index_override, "ProvisionedThroughputOverride": $provisioned_throughput_override, "SSESpecificationOverride": $sse_specification_override} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The Scan operation returns one or more items and item attributes by accessing every item in a table or a secondary index. To have DynamoDB return fewer items, you can provide a FilterExpression operation. If the total number of scanned items exceeds the maximum dataset size limit of 1 MB, the scan stops and results are returned to the user as a LastEvaluatedKey value to continue the scan in a subsequent operation. The results also include the number of items exceeding the limit. A scan can result in no table data meeting the filter criteria. A single Scan operation reads up to the maximum number of items set (if using the Limit parameter) or a maximum of 1 MB of data and then apply any filtering to the results using FilterExpression. If LastEvaluatedKey is present in the response, you need to paginate the result set. For more information, see Paginating the Results (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.Pagination) in the Amazon DynamoDB Developer Guide. Scan operations proceed sequentially; however, for faster performance on a large table or secondary index, applications can request a parallel Scan operation by providing the Segment and TotalSegments parameters. For more information, see Parallel Scan (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan) in the Amazon DynamoDB Developer Guide. Scan uses eventually consistent reads when accessing the data in a table; therefore, the result set might not include the changes to data in the table immediately before the operation began. If you need a consistent copy of the data, as of the time that the Scan begins, you can set the ConsistentRead parameter to true.
#
# POST /
# operationId: Scan
export def "api create-scan" [
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
  --x-amz-target: string@x-amz-target-completer-40
  table_name: any
  --index-name: any
  --attributes-to-get: any
  --limit-body: any #  (body field)
  --select: any
  --scan-filter: any
  --conditional-operator: any
  --exclusive-start-key-body: any #  (body field)
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --total-segments: any
  --segment: any
  --projection-expression: any
  --filter-expression: any
  --expression-attribute-names: any
  --expression-attribute-values: any
  --consistent-read: any
]: any -> record<Items: record, Count: record, ScannedCount: record, LastEvaluatedKey: record, ConsumedCapacity: record<TableName: record, CapacityUnits: record, ReadCapacityUnits: record, WriteCapacityUnits: record, Table: record<ReadCapacityUnits: record, WriteCapacityUnits: record, CapacityUnits: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "ExclusiveStartKey" $exclusive_start_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = {"TableName": $table_name, "IndexName": $index_name, "AttributesToGet": $attributes_to_get, "Limit": $limit_body, "Select": $select, "ScanFilter": $scan_filter, "ConditionalOperator": $conditional_operator, "ExclusiveStartKey": $exclusive_start_key_body, "ReturnConsumedCapacity": $return_consumed_capacity, "TotalSegments": $total_segments, "Segment": $segment, "ProjectionExpression": $projection_expression, "FilterExpression": $filter_expression, "ExpressionAttributeNames": $expression_attribute_names, "ExpressionAttributeValues": $expression_attribute_values, "ConsistentRead": $consistent_read} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Limit": $limit, "ExclusiveStartKey": $exclusive_start_key} | compact), body: $req_body}
}

# Associate a set of tags with an Amazon DynamoDB resource. You can then activate these user-defined tags so that they appear on the Billing and Cost Management console for cost allocation tracking. You can call TagResource up to five times per second, per account. For an overview on tagging DynamoDB resources, see Tagging for DynamoDB (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: TagResource
export def "api tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-41
  resource_arn: any
  tags: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# TransactGetItems is a synchronous operation that atomically retrieves multiple items from one or more tables (but not from indexes) in a single account and Region. A TransactGetItems call can contain up to 100 TransactGetItem objects, each of which contains a Get structure that specifies an item to retrieve from a table in the account and Region. A call to TransactGetItems cannot retrieve items from tables in more than one Amazon Web Services account or Region. The aggregate size of the items in the transaction cannot exceed 4 MB. DynamoDB rejects the entire TransactGetItems request if any of the following is true: A conflicting operation is in the process of updating an item to be read. There is insufficient provisioned capacity for the transaction to be completed. There is a user error, such as an invalid data format. The aggregate size of the items in the transaction exceeded 4 MB.
#
# POST /
# operationId: TransactGetItems
export def "api get-transact-items" [
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
  --x-amz-target: string@x-amz-target-completer-42
  transact_items: any
  --return-consumed-capacity: any
]: any -> record<ConsumedCapacity: record, Responses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TransactItems": $transact_items, "ReturnConsumedCapacity": $return_consumed_capacity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# TransactWriteItems is a synchronous write operation that groups up to 100 action requests. These actions can target items in different tables, but not in different Amazon Web Services accounts or Regions, and no two actions can target the same item. For example, you cannot both ConditionCheck and Update the same item. The aggregate size of the items in the transaction cannot exceed 4 MB. The actions are completed atomically so that either all of them succeed, or all of them fail. They are defined by the following objects: Put — Initiates a PutItem operation to write a new item. This structure specifies the primary key of the item to be written, the name of the table to write it in, an optional condition expression that must be satisfied for the write to succeed, a list of the item's attributes, and a field indicating whether to retrieve the item's attributes if the condition is not met. Update — Initiates an UpdateItem operation to update an existing item. This structure specifies the primary key of the item to be updated, the name of the table where it resides, an optional condition expression that must be satisfied for the update to succeed, an expression that defines one or more attributes to be updated, and a field indicating whether to retrieve the item's attributes if the condition is not met. Delete — Initiates a DeleteItem operation to delete an existing item. This structure specifies the primary key of the item to be deleted, the name of the table where it resides, an optional condition expression that must be satisfied for the deletion to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met. ConditionCheck — Applies a condition to an item that is not being modified by the transaction. This structure specifies the primary key of the item to be checked, the name of the table where it resides, a condition expression that must be satisfied for the transaction to succeed, and a field indicating whether to retrieve the item's attributes if the condition is not met. DynamoDB rejects the entire TransactWriteItems request if any of the following is true: A condition in one of the condition expressions is not met. An ongoing operation is in the process of updating the same item. There is insufficient provisioned capacity for the transaction to be completed. An item size becomes too large (bigger than 400 KB), a local secondary index (LSI) becomes too large, or a similar validation error occurs because of changes made by the transaction. The aggregate size of the items in the transaction exceeds 4 MB. There is a user error, such as an invalid data format.
#
# POST /
# operationId: TransactWriteItems
export def "api create-transact-write-items" [
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
  --x-amz-target: string@x-amz-target-completer-43
  transact_items: any
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --return-item-collection-metrics: any
  --client-request-token: any
]: any -> record<ConsumedCapacity: record, ItemCollectionMetrics: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TransactItems": $transact_items, "ReturnConsumedCapacity": $return_consumed_capacity, "ReturnItemCollectionMetrics": $return_item_collection_metrics, "ClientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes the association of tags from an Amazon DynamoDB resource. You can call UntagResource up to five times per second, per account. For an overview on tagging DynamoDB resources, see Tagging for DynamoDB (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tagging.html) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: UntagResource
export def "api untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-44
  resource_arn: any
  tag_keys: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# UpdateContinuousBackups enables or disables point in time recovery for the specified table. A successful UpdateContinuousBackups call returns the current ContinuousBackupsDescription. Continuous backups are ENABLED on all tables at table creation. If point in time recovery is enabled, PointInTimeRecoveryStatus will be set to ENABLED. Once continuous backups and point in time recovery are enabled, you can restore to any point in time within EarliestRestorableDateTime and LatestRestorableDateTime. LatestRestorableDateTime is typically 5 minutes before the current time. You can restore your table to any point in time during the last 35 days.
#
# POST /
# operationId: UpdateContinuousBackups
export def "api update-continuous-backups" [
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
  --x-amz-target: string@x-amz-target-completer-45
  table_name: any
  point_in_time_recovery_specification: any
]: any -> record<ContinuousBackupsDescription: record<ContinuousBackupsStatus: record, PointInTimeRecoveryDescription: record<PointInTimeRecoveryStatus: record, EarliestRestorableDateTime: record, LatestRestorableDateTime: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "PointInTimeRecoverySpecification": $point_in_time_recovery_specification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the status for contributor insights for a specific table or index. CloudWatch Contributor Insights for DynamoDB graphs display the partition key and (if applicable) sort key of frequently accessed items and frequently throttled items in plaintext. If you require the use of Amazon Web Services Key Management Service (KMS) to encrypt this table’s partition key and sort key data with an Amazon Web Services managed key or customer managed key, you should not enable CloudWatch Contributor Insights for DynamoDB for this table.
#
# POST /
# operationId: UpdateContributorInsights
export def "api update-contributor-insights" [
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
  --x-amz-target: string@x-amz-target-completer-46
  table_name: any
  --index-name: any
  contributor_insights_action: any
]: any -> record<TableName: record, IndexName: record, ContributorInsightsStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "IndexName": $index_name, "ContributorInsightsAction": $contributor_insights_action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds or removes replicas in the specified global table. The global table must already exist to be able to use this operation. Any replica to be added must be empty, have the same name as the global table, have the same key schema, have DynamoDB Streams enabled, and have the same provisioned and maximum write capacity units. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html). This operation only applies to Version 2017.11.29 (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. If you are using global tables Version 2019.11.21 (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) you can use DescribeTable (https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_DescribeTable.html) instead. Although you can use UpdateGlobalTable to add replicas and remove replicas in a single request, for simplicity we recommend that you issue separate requests for adding or removing replicas. If global secondary indexes are specified, then the following conditions must also be met: The global secondary indexes must have the same name. The global secondary indexes must have the same hash key and sort key (if present). The global secondary indexes must have the same provisioned and maximum write capacity units.
#
# POST /
# operationId: UpdateGlobalTable
export def "api update-global-table" [
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
  --x-amz-target: string@x-amz-target-completer-47
  global_table_name: any
  replica_updates: any
]: any -> record<GlobalTableDescription: record<ReplicationGroup: record, GlobalTableArn: record, CreationDateTime: record, GlobalTableStatus: record, GlobalTableName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"GlobalTableName": $global_table_name, "ReplicaUpdates": $replica_updates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates settings for a global table. This operation only applies to Version 2017.11.29 (Legacy) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V1.html) of global tables. We recommend using Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) when creating new global tables, as it provides greater flexibility, higher efficiency and consumes less write capacity than 2017.11.29 (Legacy). To determine which version you are using, see Determining the version (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.DetermineVersion.html). To update existing global tables from version 2017.11.29 (Legacy) to version 2019.11.21 (Current), see Updating global tables (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/V2globaltables_upgrade.html).
#
# POST /
# operationId: UpdateGlobalTableSettings
export def "api update-global-table-settings" [
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
  --x-amz-target: string@x-amz-target-completer-48
  global_table_name: any
  --global-table-billing-mode: any
  --global-table-provisioned-write-capacity-units: any
  --global-table-provisioned-write-capacity-auto-scaling-settings-update: any
  --global-table-global-secondary-index-settings-update: any
  --replica-settings-update: any
]: any -> record<GlobalTableName: record, ReplicaSettings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"GlobalTableName": $global_table_name, "GlobalTableBillingMode": $global_table_billing_mode, "GlobalTableProvisionedWriteCapacityUnits": $global_table_provisioned_write_capacity_units, "GlobalTableProvisionedWriteCapacityAutoScalingSettingsUpdate": $global_table_provisioned_write_capacity_auto_scaling_settings_update, "GlobalTableGlobalSecondaryIndexSettingsUpdate": $global_table_global_secondary_index_settings_update, "ReplicaSettingsUpdate": $replica_settings_update} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Edits an existing item's attributes, or adds a new item to the table if it does not already exist. You can put, delete, or add attribute values. You can also perform a conditional update on an existing item (insert a new attribute name-value pair if it doesn't exist, or replace an existing name-value pair if it has certain expected attribute values). You can also return the item's attribute values in the same UpdateItem operation using the ReturnValues parameter.
#
# POST /
# operationId: UpdateItem
export def "api update-item-1" [
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
  table_name: any
  key: any
  --attribute-updates: any
  --expected: any
  --conditional-operator: any
  --return-values: any
  --return-consumed-capacity: string@return-consumed-capacity-completer # Determines the level of detail about either provisioned or on-demand throughput consumption that is returned in the response: INDEXES - The response includes the aggregate ConsumedCapacity for the operation, together with ConsumedCapacity for each table and secondary index that was accessed. Note that some operations, such as GetItem and BatchGetItem, do not access any indexes at all. In these cases, specifying INDEXES will only return ConsumedCapacity information for table(s). TOTAL - The response includes only the aggregate ConsumedCapacity for the operation. NONE - No ConsumedCapacity details are included in the response.
  --return-item-collection-metrics: any
  --update-expression: any
  --condition-expression: any
  --expression-attribute-names: any
  --expression-attribute-values: any
]: any -> record<Attributes: record, ConsumedCapacity: record<TableName: record, CapacityUnits: record, ReadCapacityUnits: record, WriteCapacityUnits: record, Table: record<ReadCapacityUnits: record, WriteCapacityUnits: record, CapacityUnits: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record>, ItemCollectionMetrics: record<ItemCollectionKey: record, SizeEstimateRangeGB: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "Key": $key, "AttributeUpdates": $attribute_updates, "Expected": $expected, "ConditionalOperator": $conditional_operator, "ReturnValues": $return_values, "ReturnConsumedCapacity": $return_consumed_capacity, "ReturnItemCollectionMetrics": $return_item_collection_metrics, "UpdateExpression": $update_expression, "ConditionExpression": $condition_expression, "ExpressionAttributeNames": $expression_attribute_names, "ExpressionAttributeValues": $expression_attribute_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Modifies the provisioned throughput settings, global secondary indexes, or DynamoDB Streams settings for a given table. This operation only applies to Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) of global tables. You can only perform one of the following operations at once: Modify the provisioned throughput settings of the table. Remove a global secondary index from the table. Create a new global secondary index on the table. After the index begins backfilling, you can use UpdateTable to perform other operations. UpdateTable is an asynchronous operation; while it is executing, the table status changes from ACTIVE to UPDATING. While it is UPDATING, you cannot issue another UpdateTable request. When the table returns to the ACTIVE state, the UpdateTable operation is complete.
#
# POST /
# operationId: UpdateTable
export def "api update-table" [
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
  --attribute-definitions: any
  table_name: any
  --billing-mode: any
  --provisioned-throughput: any
  --global-secondary-index-updates: any
  --stream-specification: any
  --sse-specification: any
  --replica-updates: any
  --table-class: any
  --deletion-protection-enabled: any
]: any -> record<TableDescription: record<AttributeDefinitions: record, TableName: record, KeySchema: record, TableStatus: record, CreationDateTime: record, ProvisionedThroughput: record<LastIncreaseDateTime: record, LastDecreaseDateTime: record, NumberOfDecreasesToday: record, ReadCapacityUnits: record, WriteCapacityUnits: record>, TableSizeBytes: record, ItemCount: record, TableArn: record, TableId: record, BillingModeSummary: record<BillingMode: record, LastUpdateToPayPerRequestDateTime: record>, LocalSecondaryIndexes: record, GlobalSecondaryIndexes: record, StreamSpecification: record<StreamEnabled: record, StreamViewType: record>, LatestStreamLabel: record, LatestStreamArn: record, GlobalTableVersion: record, Replicas: record, RestoreSummary: record<SourceBackupArn: record, SourceTableArn: record, RestoreDateTime: record, RestoreInProgress: record>, SSEDescription: record<Status: record, SSEType: record, KMSMasterKeyArn: record, InaccessibleEncryptionDateTime: record>, ArchivalSummary: record<ArchivalDateTime: record, ArchivalReason: record, ArchivalBackupArn: record>, TableClassSummary: record<TableClass: record, LastUpdateDateTime: record>, DeletionProtectionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"AttributeDefinitions": $attribute_definitions, "TableName": $table_name, "BillingMode": $billing_mode, "ProvisionedThroughput": $provisioned_throughput, "GlobalSecondaryIndexUpdates": $global_secondary_index_updates, "StreamSpecification": $stream_specification, "SSESpecification": $sse_specification, "ReplicaUpdates": $replica_updates, "TableClass": $table_class, "DeletionProtectionEnabled": $deletion_protection_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates auto scaling settings on your global tables at once. This operation only applies to Version 2019.11.21 (Current) (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/globaltables.V2.html) of global tables.
#
# POST /
# operationId: UpdateTableReplicaAutoScaling
# --ProvisionedWriteCapacityAutoScalingUpdate shape: {MinimumUnits?: any, MaximumUnits?: any, AutoScalingDisabled?: any, AutoScalingRoleArn?: any, ScalingPolicyUpdate?: any}
export def "api update-table-replica-auto-scaling" [
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
  --global-secondary-index-updates: any
  table_name: any
  --provisioned-write-capacity-auto-scaling-update: record # Represents the auto scaling settings to be modified for a global table or global secondary index. — shape: {MinimumUnits?: any, MaximumUnits?: any, AutoScalingDisabled?: any, AutoScalingRoleArn?: any, ScalingPolicyUpdate?: any}
  --replica-updates: any
]: any -> record<TableAutoScalingDescription: record<TableName: record, TableStatus: record, Replicas: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"GlobalSecondaryIndexUpdates": $global_secondary_index_updates, "TableName": $table_name, "ProvisionedWriteCapacityAutoScalingUpdate": $provisioned_write_capacity_auto_scaling_update, "ReplicaUpdates": $replica_updates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The UpdateTimeToLive method enables or disables Time to Live (TTL) for the specified table. A successful UpdateTimeToLive call returns the current TimeToLiveSpecification. It can take up to one hour for the change to fully process. Any additional UpdateTimeToLive calls for the same table during this one hour duration result in a ValidationException. TTL compares the current time in epoch time format to the time stored in the TTL attribute of an item. If the epoch time value stored in the attribute is less than the current time, the item is marked as expired and subsequently deleted. The epoch time format is the number of seconds elapsed since 12:00:00 AM January 1, 1970 UTC. DynamoDB deletes expired items on a best-effort basis to ensure availability of throughput for other data operations. DynamoDB typically deletes expired items within two days of expiration. The exact duration within which an item gets deleted after expiration is specific to the nature of the workload. Items that have expired and not been deleted will still show up in reads, queries, and scans. As items are deleted, they are removed from any local secondary index and global secondary index immediately in the same eventually consistent way as a standard delete operation. For more information, see Time To Live (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html) in the Amazon DynamoDB Developer Guide.
#
# POST /
# operationId: UpdateTimeToLive
export def "api update-time-to-live" [
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
  table_name: any
  time_to_live_specification: any
]: any -> record<TimeToLiveSpecification: record<Enabled: record, AttributeName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"TableName": $table_name, "TimeToLiveSpecification": $time_to_live_specification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
