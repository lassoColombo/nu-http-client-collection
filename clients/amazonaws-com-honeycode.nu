# Auto-generated client for Amazon Honeycode v2020-03-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/honeycode/2020-03-01/openapi.json
# Auth: --token flag or $env.AMAZON_HONEYCODE_TOKEN

const BASE_URL = "http://honeycode.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_HONEYCODE_TOKEN | default "" }
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

def base-url-completer [] { ["http://honeycode.us-east-1.amazonaws.com" "http://honeycode.us-east-2.amazonaws.com" "http://honeycode.us-west-1.amazonaws.com" "http://honeycode.us-west-2.amazonaws.com" "http://honeycode.us-gov-west-1.amazonaws.com" "http://honeycode.us-gov-east-1.amazonaws.com" "http://honeycode.ca-central-1.amazonaws.com" "http://honeycode.eu-north-1.amazonaws.com" "http://honeycode.eu-west-1.amazonaws.com" "http://honeycode.eu-west-2.amazonaws.com" "http://honeycode.eu-west-3.amazonaws.com" "http://honeycode.eu-central-1.amazonaws.com" "http://honeycode.eu-south-1.amazonaws.com" "http://honeycode.af-south-1.amazonaws.com" "http://honeycode.ap-northeast-1.amazonaws.com" "http://honeycode.ap-northeast-2.amazonaws.com" "http://honeycode.ap-northeast-3.amazonaws.com" "http://honeycode.ap-southeast-1.amazonaws.com" "http://honeycode.ap-southeast-2.amazonaws.com" "http://honeycode.ap-east-1.amazonaws.com" "http://honeycode.ap-south-1.amazonaws.com" "http://honeycode.sa-east-1.amazonaws.com" "http://honeycode.me-south-1.amazonaws.com" "https://honeycode.us-east-1.amazonaws.com" "https://honeycode.us-east-2.amazonaws.com" "https://honeycode.us-west-1.amazonaws.com" "https://honeycode.us-west-2.amazonaws.com" "https://honeycode.us-gov-west-1.amazonaws.com" "https://honeycode.us-gov-east-1.amazonaws.com" "https://honeycode.ca-central-1.amazonaws.com" "https://honeycode.eu-north-1.amazonaws.com" "https://honeycode.eu-west-1.amazonaws.com" "https://honeycode.eu-west-2.amazonaws.com" "https://honeycode.eu-west-3.amazonaws.com" "https://honeycode.eu-central-1.amazonaws.com" "https://honeycode.eu-south-1.amazonaws.com" "https://honeycode.af-south-1.amazonaws.com" "https://honeycode.ap-northeast-1.amazonaws.com" "https://honeycode.ap-northeast-2.amazonaws.com" "https://honeycode.ap-northeast-3.amazonaws.com" "https://honeycode.ap-southeast-1.amazonaws.com" "https://honeycode.ap-southeast-2.amazonaws.com" "https://honeycode.ap-east-1.amazonaws.com" "https://honeycode.ap-south-1.amazonaws.com" "https://honeycode.sa-east-1.amazonaws.com" "https://honeycode.me-south-1.amazonaws.com" "http://honeycode.cn-north-1.amazonaws.com.cn" "http://honeycode.cn-northwest-1.amazonaws.com.cn" "https://honeycode.cn-north-1.amazonaws.com.cn" "https://honeycode.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def data-format-completer [] { ["DELIMITED_TEXT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "workbooks-tables-rows-batchcreate create-batch" } } | get name | first)
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

# The BatchCreateTableRows API allows you to create one or more rows at the end of a table in a workbook. The API allows you to specify the values to set in some or all of the columns in the new rows. If a column is not explicitly set in a specific row, then the column level formula specified in the table will be applied to the new row. If there is no column level formula but the last row of the table has a formula, then that formula will be copied down to the new row. If there is no column level formula and no formula in the last row of the table, then that column will be left blank for the new rows.
#
# POST /workbooks/{workbookId}/tables/{tableId}/rows/batchcreate
# operationId: BatchCreateTableRows
# --rowsToCreate item shape: {batchItemId: any, cellsToCreate: any}
export def "workbooks-tables-rows-batchcreate create-batch" [
  workbook_id: string
  table_id: string
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
  rows_to_create: list # The list of rows to create at the end of the table. Each item in this list needs to have a batch item id to uniquely identify the element in the request and the cells to create for that row. You need to specify at least one item in this list. Note that if one of the column ids in any of the rows in the request does not exist in the table, then the request fails and no updates are made to the table. — item shape: {batchItemId: any, cellsToCreate: any}
  --client-request-token: string # The request token for performing the batch create operation. Request tokens help to identify duplicate requests. If a call times out or fails due to a transient error like a failed network connection, you can retry the call with the same request token. The service ensures that if the first call using that request token is successfully performed, the second call will not perform the operation again. Note that request tokens are valid only for a few minutes. You cannot use request tokens to dedupe requests spanning hours or days.
]: any -> record<workbookCursor: record, createdRows: record, failedBatchItems: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workbook_id | is-empty) { error make --unspanned { msg: "path parameter 'workbookId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let full_url = (build-url $base ({workbook_id: (encode-path-segment $workbook_id), table_id: (encode-path-segment $table_id)} | format pattern "/workbooks/{workbook_id}/tables/{table_id}/rows/batchcreate"))
  let req_body = {"rowsToCreate": $rows_to_create, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The BatchDeleteTableRows API allows you to delete one or more rows from a table in a workbook. You need to specify the ids of the rows that you want to delete from the table.
#
# POST /workbooks/{workbookId}/tables/{tableId}/rows/batchdelete
# operationId: BatchDeleteTableRows
export def "workbooks-tables-rows-batchdelete delete-batch" [
  workbook_id: string
  table_id: string
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
  row_ids: list<string> # The list of row ids to delete from the table. You need to specify at least one row id in this list. Note that if one of the row ids provided in the request does not exist in the table, then the request fails and no rows are deleted from the table.
  --client-request-token: string # The request token for performing the delete action. Request tokens help to identify duplicate requests. If a call times out or fails due to a transient error like a failed network connection, you can retry the call with the same request token. The service ensures that if the first call using that request token is successfully performed, the second call will not perform the action again. Note that request tokens are valid only for a few minutes. You cannot use request tokens to dedupe requests spanning hours or days.
]: any -> record<workbookCursor: record, failedBatchItems: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workbook_id | is-empty) { error make --unspanned { msg: "path parameter 'workbookId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let full_url = (build-url $base ({workbook_id: (encode-path-segment $workbook_id), table_id: (encode-path-segment $table_id)} | format pattern "/workbooks/{workbook_id}/tables/{table_id}/rows/batchdelete"))
  let req_body = {"rowIds": $row_ids, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The BatchUpdateTableRows API allows you to update one or more rows in a table in a workbook. You can specify the values to set in some or all of the columns in the table for the specified rows. If a column is not explicitly specified in a particular row, then that column will not be updated for that row. To clear out the data in a specific cell, you need to set the value as an empty string ("").
#
# POST /workbooks/{workbookId}/tables/{tableId}/rows/batchupdate
# operationId: BatchUpdateTableRows
# --rowsToUpdate item shape: {rowId: any, cellsToUpdate: any}
export def "workbooks-tables-rows-batchupdate update-batch" [
  workbook_id: string
  table_id: string
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
  rows_to_update: list # The list of rows to update in the table. Each item in this list needs to contain the row id to update along with the map of column id to cell values for each column in that row that needs to be updated. You need to specify at least one row in this list, and for each row, you need to specify at least one column to update. Note that if one of the row or column ids in the request does not exist in the table, then the request fails and no updates are made to the table. — item shape: {rowId: any, cellsToUpdate: any}
  --client-request-token: string # The request token for performing the update action. Request tokens help to identify duplicate requests. If a call times out or fails due to a transient error like a failed network connection, you can retry the call with the same request token. The service ensures that if the first call using that request token is successfully performed, the second call will not perform the action again. Note that request tokens are valid only for a few minutes. You cannot use request tokens to dedupe requests spanning hours or days.
]: any -> record<workbookCursor: record, failedBatchItems: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workbook_id | is-empty) { error make --unspanned { msg: "path parameter 'workbookId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let full_url = (build-url $base ({workbook_id: (encode-path-segment $workbook_id), table_id: (encode-path-segment $table_id)} | format pattern "/workbooks/{workbook_id}/tables/{table_id}/rows/batchupdate"))
  let req_body = {"rowsToUpdate": $rows_to_update, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The BatchUpsertTableRows API allows you to upsert one or more rows in a table. The upsert operation takes a filter expression as input and evaluates it to find matching rows on the destination table. If matching rows are found, it will update the cells in the matching rows to new values specified in the request. If no matching rows are found, a new row is added at the end of the table and the cells in that row are set to the new values specified in the request. You can specify the values to set in some or all of the columns in the table for the matching or newly appended rows. If a column is not explicitly specified for a particular row, then that column will not be updated for that row. To clear out the data in a specific cell, you need to set the value as an empty string ("").
#
# POST /workbooks/{workbookId}/tables/{tableId}/rows/batchupsert
# operationId: BatchUpsertTableRows
# --rowsToUpsert item shape: {batchItemId: any, filter: any, cellsToUpdate: any}
export def "workbooks-tables-rows-batchupsert update-batch" [
  workbook_id: string
  table_id: string
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
  rows_to_upsert: list # The list of rows to upsert in the table. Each item in this list needs to have a batch item id to uniquely identify the element in the request, a filter expression to find the rows to update for that element and the cell values to set for each column in the upserted rows. You need to specify at least one item in this list. Note that if one of the filter formulas in the request fails to evaluate because of an error or one of the column ids in any of the rows does not exist in the table, then the request fails and no updates are made to the table. — item shape: {batchItemId: any, filter: any, cellsToUpdate: any}
  --client-request-token: string # The request token for performing the update action. Request tokens help to identify duplicate requests. If a call times out or fails due to a transient error like a failed network connection, you can retry the call with the same request token. The service ensures that if the first call using that request token is successfully performed, the second call will not perform the action again. Note that request tokens are valid only for a few minutes. You cannot use request tokens to dedupe requests spanning hours or days.
]: any -> record<rows: record, workbookCursor: record, failedBatchItems: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workbook_id | is-empty) { error make --unspanned { msg: "path parameter 'workbookId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let full_url = (build-url $base ({workbook_id: (encode-path-segment $workbook_id), table_id: (encode-path-segment $table_id)} | format pattern "/workbooks/{workbook_id}/tables/{table_id}/rows/batchupsert"))
  let req_body = {"rowsToUpsert": $rows_to_upsert, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The DescribeTableDataImportJob API allows you to retrieve the status and details of a table data import job.
#
# GET /workbooks/{workbookId}/tables/{tableId}/import/{jobId}
# operationId: DescribeTableDataImportJob
export def "workbooks-tables-import get-data-job" [
  workbook_id: string
  table_id: string
  job_id: string
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
]: nothing -> record<jobStatus: record, message: record, jobMetadata: record<submitter: record<email: record, userArn: record>, submitTime: record, importOptions: record<destinationOptions: record, delimitedTextOptions: record>, dataSource: record<dataSourceConfig: record>>, errorCode: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workbook_id | is-empty) { error make --unspanned { msg: "path parameter 'workbookId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({workbook_id: (encode-path-segment $workbook_id), table_id: (encode-path-segment $table_id), job_id: (encode-path-segment $job_id)} | format pattern "/workbooks/{workbook_id}/tables/{table_id}/import/{job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# The GetScreenData API allows retrieval of data from a screen in a Honeycode app. The API allows setting local variables in the screen to filter, sort or otherwise affect what will be displayed on the screen.
#
# POST /screendata
# operationId: GetScreenData
export def "screendata get-screen-data" [
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
  workbook_id: string # The ID of the workbook that contains the screen.
  app_id: string # The ID of the app that contains the screen.
  screen_id: string # The ID of the screen.
  --variables: record # Variables are optional and are needed only if the screen requires them to render correctly. Variables are specified as a map where the key is the name of the variable as defined on the screen. The value is an object which currently has only one property, rawValue, which holds the value of the variable to be passed to the screen.
  --max-results: int # The number of results to be returned on a single page. Specify a number between 1 and 100. The maximum value is 100. This parameter is optional. If you don't specify this parameter, the default page size is 100.
  --next-token: string # This parameter is optional. If a nextToken is not specified, the API returns the first page of data. Pagination tokens expire after 1 hour. If you use a token that was returned more than an hour back, the API will throw ValidationException.
]: any -> record<results: record, workbookCursor: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/screendata")
  let req_body = {"workbookId": $workbook_id, "appId": $app_id, "screenId": $screen_id, "variables": $variables, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The InvokeScreenAutomation API allows invoking an action defined in a screen in a Honeycode app. The API allows setting local variables, which can then be used in the automation being invoked. This allows automating the Honeycode app interactions to write, update or delete data in the workbook.
#
# POST /workbooks/{workbookId}/apps/{appId}/screens/{screenId}/automations/{automationId}
# operationId: InvokeScreenAutomation
export def "workbooks-apps-screens-automations create-invoke" [
  workbook_id: string
  app_id: string
  screen_id: string
  automation_id: string
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
  --variables: record # Variables are specified as a map where the key is the name of the variable as defined on the screen. The value is an object which currently has only one property, rawValue, which holds the value of the variable to be passed to the screen. Any variables defined in a screen are required to be passed in the call.
  --row-id: string # The row ID for the automation if the automation is defined inside a block with source or list.
  --client-request-token: string # The request token for performing the automation action. Request tokens help to identify duplicate requests. If a call times out or fails due to a transient error like a failed network connection, you can retry the call with the same request token. The service ensures that if the first call using that request token is successfully performed, the second call will return the response of the previous call rather than performing the action again. Note that request tokens are valid only for a few minutes. You cannot use request tokens to dedupe requests spanning hours or days.
]: any -> record<workbookCursor: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workbook_id | is-empty) { error make --unspanned { msg: "path parameter 'workbookId' must be non-empty" } }
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($screen_id | is-empty) { error make --unspanned { msg: "path parameter 'screenId' must be non-empty" } }
  if ($automation_id | is-empty) { error make --unspanned { msg: "path parameter 'automationId' must be non-empty" } }
  let full_url = (build-url $base ({workbook_id: (encode-path-segment $workbook_id), app_id: (encode-path-segment $app_id), screen_id: (encode-path-segment $screen_id), automation_id: (encode-path-segment $automation_id)} | format pattern "/workbooks/{workbook_id}/apps/{app_id}/screens/{screen_id}/automations/{automation_id}"))
  let req_body = {"variables": $variables, "rowId": $row_id, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The ListTableColumns API allows you to retrieve a list of all the columns in a table in a workbook.
#
# GET /workbooks/{workbookId}/tables/{tableId}/columns
# operationId: ListTableColumns
export def "workbooks-tables-columns list" [
  workbook_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # This parameter is optional. If a nextToken is not specified, the API returns the first page of data. Pagination tokens expire after 1 hour. If you use a token that was returned more than an hour back, the API will throw ValidationException.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<tableColumns: record, nextToken: record, workbookCursor: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workbook_id | is-empty) { error make --unspanned { msg: "path parameter 'workbookId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workbook_id: (encode-path-segment $workbook_id), table_id: (encode-path-segment $table_id)} | format pattern "/workbooks/{workbook_id}/tables/{table_id}/columns") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"nextToken": $next_token} | compact), body: null}
}

# The ListTableRows API allows you to retrieve a list of all the rows in a table in a workbook.
#
# POST /workbooks/{workbookId}/tables/{tableId}/rows/list
# operationId: ListTableRows
export def "workbooks-tables-rows-list list" [
  workbook_id: string
  table_id: string
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
  --row-ids: list<string> # This parameter is optional. If one or more row ids are specified in this list, then only the specified row ids are returned in the result. If no row ids are specified here, then all the rows in the table are returned.
  --max-results-body: int # The maximum number of rows to return in each page of the results. (body field)
  --next-token-body: string # This parameter is optional. If a nextToken is not specified, the API returns the first page of data. Pagination tokens expire after 1 hour. If you use a token that was returned more than an hour back, the API will throw ValidationException. (body field)
]: any -> record<columnIds: record, rows: record, rowIdsNotFound: record, nextToken: record, workbookCursor: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workbook_id | is-empty) { error make --unspanned { msg: "path parameter 'workbookId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workbook_id: (encode-path-segment $workbook_id), table_id: (encode-path-segment $table_id)} | format pattern "/workbooks/{workbook_id}/tables/{table_id}/rows/list") $qp)
  let req_body = {"rowIds": $row_ids, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# The ListTables API allows you to retrieve a list of all the tables in a workbook.
#
# GET /workbooks/{workbookId}/tables
# operationId: ListTables
export def "workbooks-tables list" [
  workbook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of tables to return in each page of the results.
  --next-token: string # This parameter is optional. If a nextToken is not specified, the API returns the first page of data. Pagination tokens expire after 1 hour. If you use a token that was returned more than an hour back, the API will throw ValidationException.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<tables: record, nextToken: record, workbookCursor: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workbook_id | is-empty) { error make --unspanned { msg: "path parameter 'workbookId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workbook_id: (encode-path-segment $workbook_id)} | format pattern "/workbooks/{workbook_id}/tables") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: null}
}

# The ListTagsForResource API allows you to return a resource's tags.
#
# GET /tags/{resourceArn}
# operationId: ListTagsForResource
export def "tags list-for-resource" [
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
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# The TagResource API allows you to add tags to an ARN-able resource. Resource includes workbook, table, screen and screen-automation.
#
# POST /tags/{resourceArn}
# operationId: TagResource
export def "tags tag-resource" [
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
  tags: record # A string to string map representing tags
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The QueryTableRows API allows you to use a filter formula to query for specific rows in a table.
#
# POST /workbooks/{workbookId}/tables/{tableId}/rows/query
# operationId: QueryTableRows
# --filterFormula shape: {formula?: any, contextRowId?: any}
export def "workbooks-tables-rows-query list" [
  workbook_id: string
  table_id: string
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
  filter_formula: record # An object that represents a filter formula along with the id of the context row under which the filter function needs to evaluate. — shape: {formula?: any, contextRowId?: any}
  --max-results-body: int # The maximum number of rows to return in each page of the results. (body field)
  --next-token-body: string # This parameter is optional. If a nextToken is not specified, the API returns the first page of data. Pagination tokens expire after 1 hour. If you use a token that was returned more than an hour back, the API will throw ValidationException. (body field)
]: any -> record<columnIds: record, rows: record, nextToken: record, workbookCursor: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workbook_id | is-empty) { error make --unspanned { msg: "path parameter 'workbookId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workbook_id: (encode-path-segment $workbook_id), table_id: (encode-path-segment $table_id)} | format pattern "/workbooks/{workbook_id}/tables/{table_id}/rows/query") $qp)
  let req_body = {"filterFormula": $filter_formula, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# The StartTableDataImportJob API allows you to start an import job on a table. This API will only return the id of the job that was started. To find out the status of the import request, you need to call the DescribeTableDataImportJob API.
#
# POST /workbooks/{workbookId}/tables/{tableId}/import
# operationId: StartTableDataImportJob
# --dataSource shape: {dataSourceConfig?: any}
# --importOptions shape: {destinationOptions?: any, delimitedTextOptions?: any}
export def "workbooks-tables-import start-data-job" [
  workbook_id: string
  table_id: string
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
  data_source: record # An object that has details about the source of the data that was submitted for import. — shape: {dataSourceConfig?: any}
  data_format: string@data-format-completer # The format of the data that is being imported. Currently the only option supported is "DELIMITED_TEXT".
  import_options: record # An object that contains the options specified by the sumitter of the import request. — shape: {destinationOptions?: any, delimitedTextOptions?: any}
  client_request_token: string # The request token for performing the update action. Request tokens help to identify duplicate requests. If a call times out or fails due to a transient error like a failed network connection, you can retry the call with the same request token. The service ensures that if the first call using that request token is successfully performed, the second call will not perform the action again. Note that request tokens are valid only for a few minutes. You cannot use request tokens to dedupe requests spanning hours or days.
]: any -> record<jobId: record, jobStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workbook_id | is-empty) { error make --unspanned { msg: "path parameter 'workbookId' must be non-empty" } }
  if ($table_id | is-empty) { error make --unspanned { msg: "path parameter 'tableId' must be non-empty" } }
  let full_url = (build-url $base ({workbook_id: (encode-path-segment $workbook_id), table_id: (encode-path-segment $table_id)} | format pattern "/workbooks/{workbook_id}/tables/{table_id}/import"))
  let req_body = {"dataSource": $data_source, "dataFormat": $data_format, "importOptions": $import_options, "clientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The UntagResource API allows you to removes tags from an ARN-able resource. Resource includes workbook, table, screen and screen-automation.
#
# DELETE /tags/{resourceArn}
# operationId: UntagResource
export def "tags untag-resource" [
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
  --tag-keys: list # A list of tag keys to remove from the resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}
