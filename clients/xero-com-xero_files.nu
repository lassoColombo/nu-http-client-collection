# Auto-generated client for Xero Files API v2.9.4
# Source: https://api.apis.guru/v2/specs/xero.com/xero_files/2.9.4/openapi.json
# Auth: --token flag or $env.XERO_FILES_API_TOKEN

const BASE_URL = "https://api.xero.com/files.xro/1.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o XERO_FILES_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.xero.com/files.xro/1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["CreatedDateUTC" "Name" "Size"] }
def object-group-completer [] { ["Account" "BankTransaction" "Contact" "CreditNote" "Invoice" "Item" "ManualJournal" "Overpayment" "Payment" "Prepayment" "Receipt"] }
def object-type-completer [] { ["AccPayCredit" "AccPayPayment" "AccRec" "AccRecCredit" "AccRecPayment" "Account" "Accpay" "Adjustment" "ApCreditPayment" "ApOverPayment" "ApOverPaymentPayment" "ApOverPaymentSourcePayment" "ApPrepayment" "ApPrepaymentPayment" "ApPrepaymentSourcePayment" "ArCreditPayment" "ArOverPayment" "ArOverpaymentPayment" "ArOverpaymentSourcePayment" "ArPrepayment" "ArPrepaymentPayment" "ArPrepaymentSourcePayment" "Bank" "Business" "CashPaid" "CashRec" "Contact" "Current" "Currliab" "Depreciatn" "DirectCosts" "Employee" "Equity" "ExpPayment" "Expense" "Fixed" "FixedAsset" "Liability" "ManJournal" "NonCurrent" "Org" "OtherIncome" "Overheads" "PayRun" "Person" "Prepayment" "PriceListItem" "PurchaseOrder" "Receipt" "Revenue" "Sales" "Termliab" "Transfer" "Unknown" "User"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "associations get-by-object" } } | get name | first)
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

# Retrieves an association object using a unique object ID
#
# GET /Associations/{ObjectId}
# operationId: getAssociationsByObject
export def "associations get-by-object" [
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> table<FileId: string, ObjectGroup: string, ObjectId: string, ObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({object_id: (encode-path-segment $object_id)} | format pattern "/Associations/{object_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves files
#
# GET /Files
# operationId: getFiles
export def "files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # pass an optional page size value (e.g. 50)
  --page: int # number of records to skip for pagination (e.g. 2)
  --qp-sort: string@sort-completer # values to sort by (e.g. CreatedDateUTC DESC)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Items: table<CreatedDateUtc: string, FolderId: string, Id: string, MimeType: string, Name: string, Size: int, UpdatedDateUtc: string, User: record>, Page: int, PerPage: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads a File
#
# POST /Files
# operationId: uploadFile
export def "files upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --folder-id: string # pass an optional folder id to save file to specific folder (format: uuid, e.g. 4ff1e5cc-9835-40d5-bb18-09fdb118db9c)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string # format: byte
  --filename: string
  --mime-type: string
  --name: string # exact name of the file you are uploading
]: any -> record<CreatedDateUtc: string, FolderId: string, Id: string, MimeType: string, Name: string, Size: int, UpdatedDateUtc: string, User: record<FirstName: string, FullName: string, Id: string, LastName: string, Name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FolderId" $folder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Files" $qp)
  let req_body = {"body": $body, "filename": $filename, "mimeType": $mime_type, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Deletes a specific file
#
# DELETE /Files/{FileId}
# operationId: deleteFile
export def "files delete" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a file by a unique file ID
#
# GET /Files/{FileId}
# operationId: getFile
export def "files get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<CreatedDateUtc: string, FolderId: string, Id: string, MimeType: string, Name: string, Size: int, UpdatedDateUtc: string, User: record<FirstName: string, FullName: string, Id: string, LastName: string, Name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a file
#
# PUT /Files/{FileId}
# operationId: updateFile
# --User shape: {FirstName?: string, FullName?: string, Id: string, LastName?: string, Name?: string}
export def "files update" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --created-date-utc: string # Created date in UTC (e.g. 2020-12-03T19:04:58.6970000)
  --folder-id: string # Folder relation object's UUID (format: uuid, e.g. 0f8ccf21-7267-4268-9167-a1e2c40c84c8)
  --id: string # File object's UUID (format: uuid, e.g. d290f1ee-6c54-4b01-90e6-d701748f0851)
  --mime-type: string # MimeType of the file (image/png, image/jpeg, application/pdf, etc..) (e.g. image/jpeg)
  --name: string # File Name (e.g. File2.jpg)
  --size: int # Numeric value in bytes (e.g. 3615)
  --updated-date-utc: string # Updated date in UTC (e.g. 2020-12-03T19:04:58.6970000)
  --user: record # shape: {FirstName?: string, FullName?: string, Id: string, LastName?: string, Name?: string}
]: any -> record<CreatedDateUtc: string, FolderId: string, Id: string, MimeType: string, Name: string, Size: int, UpdatedDateUtc: string, User: record<FirstName: string, FullName: string, Id: string, LastName: string, Name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}"))
  let req_body = {"CreatedDateUtc": $created_date_utc, "FolderId": $folder_id, "Id": $id, "MimeType": $mime_type, "Name": $name, "Size": $size, "UpdatedDateUtc": $updated_date_utc, "User": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a specific file associations
#
# GET /Files/{FileId}/Associations
# operationId: getFileAssociations
export def "files-associations get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> table<FileId: string, ObjectGroup: string, ObjectId: string, ObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}/Associations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new file association
#
# POST /Files/{FileId}/Associations
# operationId: createFileAssociation
export def "files-associations create" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body-file-id: string # The unique identifier of the file (format: uuid)
  --object-group: string@object-group-completer # The Object Group that the object is in. These roughly correlate to the endpoints that can be used to retrieve the object via the core accounting API.
  --object-id: string # The identifier of the object that the file is being associated with (e.g. InvoiceID, BankTransactionID, ContactID) (format: uuid)
  --object-type: string@object-type-completer # The Object Type
]: any -> record<FileId: string, ObjectGroup: string, ObjectId: string, ObjectType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}/Associations"))
  let req_body = {"FileId": $body_file_id, "ObjectGroup": $object_group, "ObjectId": $object_id, "ObjectType": $object_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an existing file association
#
# DELETE /Files/{FileId}/Associations/{ObjectId}
# operationId: deleteFileAssociation
export def "files-associations delete" [
  file_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id), object_id: (encode-path-segment $object_id)} | format pattern "/Files/{file_id}/Associations/{object_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the content of a specific file
#
# GET /Files/{FileId}/Content
# operationId: getFileContent
export def "files-content get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}/Content"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves folders
#
# GET /Folders
# operationId: getFolders
export def "folders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string@sort-completer # values to sort by (e.g. CreatedDateUTC DESC)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> table<Email: string, FileCount: int, Id: string, IsInbox: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new folder
#
# POST /Folders
# operationId: createFolder
export def "folders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --email: string # The email address used to email files to the inbox. Only the inbox will have this element. (e.g. foo@bar.com)
  --file-count: int # The number of files in the folder (e.g. 5)
  --id: string # Xero unique identifier for a folder Files (format: uuid, e.g. 4ff1e5cc-9835-40d5-bb18-09fdb118db9c)
  --is-inbox: oneof<nothing, bool> # to indicate if the folder is the Inbox. The Inbox cannot be renamed or deleted. (e.g. true)
  --name: string # The name of the folder (e.g. assets)
]: any -> record<Email: string, FileCount: int, Id: string, IsInbox: bool, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Folders")
  let req_body = {"Email": $email, "FileCount": $file_count, "Id": $id, "IsInbox": $is_inbox, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a folder
#
# DELETE /Folders/{FolderId}
# operationId: deleteFolder
export def "folders delete" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/Folders/{folder_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves specific folder by using a unique folder ID
#
# GET /Folders/{FolderId}
# operationId: getFolder
export def "folders get" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Email: string, FileCount: int, Id: string, IsInbox: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/Folders/{folder_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing folder
#
# PUT /Folders/{FolderId}
# operationId: updateFolder
export def "folders update" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --email: string # The email address used to email files to the inbox. Only the inbox will have this element. (e.g. foo@bar.com)
  --file-count: int # The number of files in the folder (e.g. 5)
  --id: string # Xero unique identifier for a folder Files (format: uuid, e.g. 4ff1e5cc-9835-40d5-bb18-09fdb118db9c)
  --is-inbox: oneof<nothing, bool> # to indicate if the folder is the Inbox. The Inbox cannot be renamed or deleted. (e.g. true)
  --name: string # The name of the folder (e.g. assets)
]: any -> record<Email: string, FileCount: int, Id: string, IsInbox: bool, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/Folders/{folder_id}"))
  let req_body = {"Email": $email, "FileCount": $file_count, "Id": $id, "IsInbox": $is_inbox, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves inbox folder
#
# GET /Inbox
# operationId: getInbox
export def "inbox get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Email: string, FileCount: int, Id: string, IsInbox: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Inbox")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
