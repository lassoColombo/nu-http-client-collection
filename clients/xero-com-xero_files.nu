# Auto-generated client for Xero Files API v2.9.4
# Source: https://api.apis.guru/v2/specs/xero.com/xero_files/2.9.4/openapi.json
# Auth: --token flag or $env.XERO_FILES_API_TOKEN

const BASE_URL = "https://api.xero.com/files.xro/1.0"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o XERO_FILES_API_TOKEN | default "" }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.xero.com/files.xro/1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["CreatedDateUTC" "Name" "Size"] }
def object-group-completer [] { ["Account" "BankTransaction" "Contact" "CreditNote" "Invoice" "Item" "ManualJournal" "Overpayment" "Payment" "Prepayment" "Receipt"] }
def object-type-completer [] { ["AccPayCredit" "AccPayPayment" "AccRec" "AccRecCredit" "AccRecPayment" "Account" "Accpay" "Adjustment" "ApCreditPayment" "ApOverPayment" "ApOverPaymentPayment" "ApOverPaymentSourcePayment" "ApPrepayment" "ApPrepaymentPayment" "ApPrepaymentSourcePayment" "ArCreditPayment" "ArOverPayment" "ArOverpaymentPayment" "ArOverpaymentSourcePayment" "ArPrepayment" "ArPrepaymentPayment" "ArPrepaymentSourcePayment" "Bank" "Business" "CashPaid" "CashRec" "Contact" "Current" "Currliab" "Depreciatn" "DirectCosts" "Employee" "Equity" "ExpPayment" "Expense" "Fixed" "FixedAsset" "Liability" "ManJournal" "NonCurrent" "Org" "OtherIncome" "Overheads" "PayRun" "Person" "Prepayment" "PriceListItem" "PurchaseOrder" "Receipt" "Revenue" "Sales" "Termliab" "Transfer" "Unknown" "User"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> table<FileId: string, ObjectGroup: string, ObjectId: string, ObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'ObjectId' must be non-empty" } }
  let full_url = (build-url $base ({object_id: (encode-path-segment $object_id)} | format pattern "/Associations/{object_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # pass an optional page size value (e.g. 50)
  --page: int # number of records to skip for pagination (e.g. 2)
  --qp-sort: string@sort-completer # values to sort by (e.g. CreatedDateUTC DESC)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Items: table<CreatedDateUtc: string, FolderId: string, Id: string, MimeType: string, Name: string, Size: int, UpdatedDateUtc: string, User: record>, Page: int, PerPage: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Files" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pagesize": $pagesize, "page": $page, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base "/Files" $qp $auth.query)
  let req_body = {"body": $body, "filename": $filename, "mimeType": $mime_type, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: ({"FolderId": $folder_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [201]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'FileId' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<CreatedDateUtc: string, FolderId: string, Id: string, MimeType: string, Name: string, Size: int, UpdatedDateUtc: string, User: record<FirstName: string, FullName: string, Id: string, LastName: string, Name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'FileId' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'FileId' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}") $auth.query)
  let req_body = {"CreatedDateUtc": $created_date_utc, "FolderId": $folder_id, "Id": $id, "MimeType": $mime_type, "Name": $name, "Size": $size, "UpdatedDateUtc": $updated_date_utc, "User": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> table<FileId: string, ObjectGroup: string, ObjectId: string, ObjectType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'FileId' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}/Associations") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'FileId' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}/Associations") $auth.query)
  let req_body = {"FileId": $body_file_id, "ObjectGroup": $object_group, "ObjectId": $object_id, "ObjectType": $object_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'FileId' must be non-empty" } }
  if ($object_id | is-empty) { error make --unspanned { msg: "path parameter 'ObjectId' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id), object_id: (encode-path-segment $object_id)} | format pattern "/Files/{file_id}/Associations/{object_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'FileId' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/Files/{file_id}/Content") $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string@sort-completer # values to sort by (e.g. CreatedDateUTC DESC)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> table<Email: string, FileCount: int, Id: string, IsInbox: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Folders" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base "/Folders" $auth.query)
  let req_body = {"Email": $email, "FileCount": $file_count, "Id": $id, "IsInbox": $is_inbox, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'FolderId' must be non-empty" } }
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/Folders/{folder_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Email: string, FileCount: int, Id: string, IsInbox: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'FolderId' must be non-empty" } }
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/Folders/{folder_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'FolderId' must be non-empty" } }
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/Folders/{folder_id}") $auth.query)
  let req_body = {"Email": $email, "FileCount": $file_count, "Id": $id, "IsInbox": $is_inbox, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Email: string, FileCount: int, Id: string, IsInbox: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Inbox" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
