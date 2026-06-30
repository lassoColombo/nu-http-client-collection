# Auto-generated client for Amazon Glacier v2012-06-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/glacier/2012-06-01/openapi.json
# Auth: --token flag or $env.AMAZON_GLACIER_TOKEN

const BASE_URL = "http://glacier.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_GLACIER_TOKEN | default "" }
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

def base-url-completer [] { ["http://glacier.us-east-1.amazonaws.com" "http://glacier.us-east-2.amazonaws.com" "http://glacier.us-west-1.amazonaws.com" "http://glacier.us-west-2.amazonaws.com" "http://glacier.us-gov-west-1.amazonaws.com" "http://glacier.us-gov-east-1.amazonaws.com" "http://glacier.ca-central-1.amazonaws.com" "http://glacier.eu-north-1.amazonaws.com" "http://glacier.eu-west-1.amazonaws.com" "http://glacier.eu-west-2.amazonaws.com" "http://glacier.eu-west-3.amazonaws.com" "http://glacier.eu-central-1.amazonaws.com" "http://glacier.eu-south-1.amazonaws.com" "http://glacier.af-south-1.amazonaws.com" "http://glacier.ap-northeast-1.amazonaws.com" "http://glacier.ap-northeast-2.amazonaws.com" "http://glacier.ap-northeast-3.amazonaws.com" "http://glacier.ap-southeast-1.amazonaws.com" "http://glacier.ap-southeast-2.amazonaws.com" "http://glacier.ap-east-1.amazonaws.com" "http://glacier.ap-south-1.amazonaws.com" "http://glacier.sa-east-1.amazonaws.com" "http://glacier.me-south-1.amazonaws.com" "https://glacier.us-east-1.amazonaws.com" "https://glacier.us-east-2.amazonaws.com" "https://glacier.us-west-1.amazonaws.com" "https://glacier.us-west-2.amazonaws.com" "https://glacier.us-gov-west-1.amazonaws.com" "https://glacier.us-gov-east-1.amazonaws.com" "https://glacier.ca-central-1.amazonaws.com" "https://glacier.eu-north-1.amazonaws.com" "https://glacier.eu-west-1.amazonaws.com" "https://glacier.eu-west-2.amazonaws.com" "https://glacier.eu-west-3.amazonaws.com" "https://glacier.eu-central-1.amazonaws.com" "https://glacier.eu-south-1.amazonaws.com" "https://glacier.af-south-1.amazonaws.com" "https://glacier.ap-northeast-1.amazonaws.com" "https://glacier.ap-northeast-2.amazonaws.com" "https://glacier.ap-northeast-3.amazonaws.com" "https://glacier.ap-southeast-1.amazonaws.com" "https://glacier.ap-southeast-2.amazonaws.com" "https://glacier.ap-east-1.amazonaws.com" "https://glacier.ap-south-1.amazonaws.com" "https://glacier.sa-east-1.amazonaws.com" "https://glacier.me-south-1.amazonaws.com" "http://glacier.cn-north-1.amazonaws.com.cn" "http://glacier.cn-northwest-1.amazonaws.com.cn" "https://glacier.cn-north-1.amazonaws.com.cn" "https://glacier.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def operation-completer [] { ["add"] }
def operation-completer-1 [] { ["remove"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "vaults-multipart-uploads abort" } } | get name | first)
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

# This operation aborts a multipart upload identified by the upload ID. After the Abort Multipart Upload request succeeds, you cannot upload any more parts to the multipart upload or complete the multipart upload. Aborting a completed upload fails. However, aborting an already-aborted upload will succeed, for a short time. For more information about uploading a part and completing a multipart upload, see UploadMultipartPart and CompleteMultipartUpload. This operation is idempotent. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Working with Archives in Amazon S3 Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html) and Abort Multipart Upload (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-abort-upload.html) in the Amazon Glacier Developer Guide.
#
# DELETE /{accountId}/vaults/{vaultName}/multipart-uploads/{uploadId}
# operationId: AbortMultipartUpload
export def "vaults-multipart-uploads abort" [
  account_id: string
  vault_name: string
  upload_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($upload_id | is-empty) { error make --unspanned { msg: "path parameter 'uploadId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name), upload_id: (encode-path-segment $upload_id)} | format pattern "/{account_id}/vaults/{vault_name}/multipart-uploads/{upload_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# You call this operation to inform Amazon S3 Glacier (Glacier) that all the archive parts have been uploaded and that Glacier can now assemble the archive from the uploaded parts. After assembling and saving the archive to the vault, Glacier returns the URI path of the newly created archive resource. Using the URI path, you can then access the archive. After you upload an archive, you should save the archive ID returned to retrieve the archive at a later point. You can also get the vault inventory to obtain a list of archive IDs in a vault. For more information, see InitiateJob. In the request, you must include the computed SHA256 tree hash of the entire archive you have uploaded. For information about computing a SHA256 tree hash, see Computing Checksums (https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html). On the server side, Glacier also constructs the SHA256 tree hash of the assembled archive. If the values match, Glacier saves the archive to the vault; otherwise, it returns an error, and the operation fails. The ListParts operation returns a list of parts uploaded for a specific multipart upload. It includes checksum information for each uploaded part that can be used to debug a bad checksum issue. Additionally, Glacier also checks for any missing content ranges when assembling the archive, if missing content ranges are found, Glacier returns an error and the operation fails. Complete Multipart Upload is an idempotent operation. After your first successful complete multipart upload, if you call the operation again within a short period, the operation will succeed and return the same archive ID. This is useful in the event you experience a network issue that causes an aborted connection or receive a 500 server error, in which case you can repeat your Complete Multipart Upload request and get the same archive ID without creating duplicate archives. Note, however, that after the multipart upload completes, you cannot call the List Parts operation and the multipart upload will not appear in List Multipart Uploads response, even if idempotent complete is possible. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Uploading Large Archives in Parts (Multipart Upload) (https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html) and Complete Multipart Upload (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-complete-upload.html) in the Amazon Glacier Developer Guide.
#
# POST /{accountId}/vaults/{vaultName}/multipart-uploads/{uploadId}
# operationId: CompleteMultipartUpload
export def "vaults-multipart-uploads complete" [
  account_id: string
  vault_name: string
  upload_id: string
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
  --x-amz-archive-size: string # The total size, in bytes, of the entire archive. This value should be the sum of all the sizes of the individual parts that you uploaded.
  --x-amz-sha256-tree-hash: string # The SHA256 tree hash of the entire archive. It is the tree hash of SHA256 tree hash of the individual parts. If the value you specify in the request does not match the SHA256 tree hash of the final assembled archive as computed by Amazon S3 Glacier (Glacier), Glacier returns an error and the request fails.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($upload_id | is-empty) { error make --unspanned { msg: "path parameter 'uploadId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name), upload_id: (encode-path-segment $upload_id)} | format pattern "/{account_id}/vaults/{vault_name}/multipart-uploads/{upload_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-archive-size": $x_amz_archive_size, "x-amz-sha256-tree-hash": $x_amz_sha256_tree_hash} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# This operation lists the parts of an archive that have been uploaded in a specific multipart upload. You can make this request at any time during an in-progress multipart upload before you complete the upload (see CompleteMultipartUpload. List Parts returns an error for completed uploads. The list returned in the List Parts response is sorted by part range. The List Parts operation supports pagination. By default, this operation returns up to 50 uploaded parts in the response. You should always check the response for a marker at which to continue the list; if there are no more items the marker is null. To return a list of parts that begins at a specific part, set the marker request parameter to the value you obtained from a previous List Parts request. You can also limit the number of parts returned in the response by specifying the limit parameter in the request. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and the underlying REST API, see Working with Archives in Amazon S3 Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html) and List Parts (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-list-parts.html) in the Amazon Glacier Developer Guide.
#
# GET /{accountId}/vaults/{vaultName}/multipart-uploads/{uploadId}
# operationId: ListParts
export def "vaults-multipart-uploads list-parts" [
  account_id: string
  vault_name: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # An opaque string used for pagination. This value specifies the part at which the listing of parts should begin. Get the marker value from the response of a previous List Parts response. You need only include the marker if you are continuing the pagination of results started in a previous List Parts request.
  --limit: string # The maximum number of parts to be returned. The default limit is 50. The number of parts returned might be fewer than the specified limit, but the number of returned parts never exceeds the limit.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<MultipartUploadId: record, VaultARN: record, ArchiveDescription: record, PartSizeInBytes: record, CreationDate: record, Parts: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($upload_id | is-empty) { error make --unspanned { msg: "path parameter 'uploadId' must be non-empty" } }
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name), upload_id: (encode-path-segment $upload_id)} | format pattern "/{account_id}/vaults/{vault_name}/multipart-uploads/{upload_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"marker": $marker, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This operation uploads a part of an archive. You can upload archive parts in any order. You can also upload them in parallel. You can upload up to 10,000 parts for a multipart upload. Amazon Glacier rejects your upload part request if any of the following conditions is true: SHA256 tree hash does not matchTo ensure that part data is not corrupted in transmission, you compute a SHA256 tree hash of the part and include it in your request. Upon receiving the part data, Amazon S3 Glacier also computes a SHA256 tree hash. If these hash values don't match, the operation fails. For information about computing a SHA256 tree hash, see Computing Checksums (https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html). Part size does not matchThe size of each part except the last must match the size specified in the corresponding InitiateMultipartUpload request. The size of the last part must be the same size as, or smaller than, the specified size. If you upload a part whose size is smaller than the part size you specified in your initiate multipart upload request and that part is not the last part, then the upload part request will succeed. However, the subsequent Complete Multipart Upload request will fail. Range does not alignThe byte range value in the request does not align with the part size specified in the corresponding initiate request. For example, if you specify a part size of 4194304 bytes (4 MB), then 0 to 4194303 bytes (4 MB - 1) and 4194304 (4 MB) to 8388607 (8 MB - 1) are valid part ranges. However, if you set a range value of 2 MB to 6 MB, the range does not align with the part size and the upload will fail. This operation is idempotent. If you upload the same part multiple times, the data included in the most recent request overwrites the previously uploaded data. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Uploading Large Archives in Parts (Multipart Upload) (https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html) and Upload Part (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-upload-part.html) in the Amazon Glacier Developer Guide.
#
# PUT /{accountId}/vaults/{vaultName}/multipart-uploads/{uploadId}
# operationId: UploadMultipartPart
export def "vaults-multipart-uploads upload-part" [
  account_id: string
  vault_name: string
  upload_id: string
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
  --x-amz-sha256-tree-hash: string # The SHA256 tree hash of the data being uploaded.
  --content-range: string # Identifies the range of bytes in the assembled archive that will be uploaded in this part. Amazon S3 Glacier uses this information to assemble the archive in the proper sequence. The format of this header follows RFC 2616. An example header is Content-Range:bytes 0-4194303/*.
  --body: string # The data to upload.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($upload_id | is-empty) { error make --unspanned { msg: "path parameter 'uploadId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name), upload_id: (encode-path-segment $upload_id)} | format pattern "/{account_id}/vaults/{vault_name}/multipart-uploads/{upload_id}") $auth.query)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-sha256-tree-hash": $x_amz_sha256_tree_hash, "Content-Range": $content_range} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# This operation aborts the vault locking process if the vault lock is not in the Locked state. If the vault lock is in the Locked state when this operation is requested, the operation returns an AccessDeniedException error. Aborting the vault locking process removes the vault lock policy from the specified vault. A vault lock is put into the InProgress state by calling InitiateVaultLock. A vault lock is put into the Locked state by calling CompleteVaultLock. You can get the state of a vault lock by calling GetVaultLock. For more information about the vault locking process, see Amazon Glacier Vault Lock (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html). For more information about vault lock policies, see Amazon Glacier Access Control with Vault Lock Policies (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html). This operation is idempotent. You can successfully invoke this operation multiple times, if the vault lock is in the InProgress state or if there is no policy associated with the vault.
#
# DELETE /{accountId}/vaults/{vaultName}/lock-policy
# operationId: AbortVaultLock
export def "vaults-lock-policy abort" [
  account_id: string
  vault_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/lock-policy") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation retrieves the following attributes from the lock-policy subresource set on the specified vault: The vault lock policy set on the vault. The state of the vault lock, which is either InProgess or Locked. When the lock ID expires. The lock ID is used to complete the vault locking process. When the vault lock was initiated and put into the InProgress state. A vault lock is put into the InProgress state by calling InitiateVaultLock. A vault lock is put into the Locked state by calling CompleteVaultLock. You can abort the vault locking process by calling AbortVaultLock. For more information about the vault locking process, Amazon Glacier Vault Lock (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html). If there is no vault lock policy set on the vault, the operation returns a 404 Not found error. For more information about vault lock policies, Amazon Glacier Access Control with Vault Lock Policies (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html).
#
# GET /{accountId}/vaults/{vaultName}/lock-policy
# operationId: GetVaultLock
export def "vaults-lock-policy get" [
  account_id: string
  vault_name: string
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
]: nothing -> record<Policy: record, State: record, ExpirationDate: record, CreationDate: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/lock-policy") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation initiates the vault locking process by doing the following: Installing a vault lock policy on the specified vault. Setting the lock state of vault lock to InProgress. Returning a lock ID, which is used to complete the vault locking process. You can set one vault lock policy for each vault and this policy can be up to 20 KB in size. For more information about vault lock policies, see Amazon Glacier Access Control with Vault Lock Policies (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html). You must complete the vault locking process within 24 hours after the vault lock enters the InProgress state. After the 24 hour window ends, the lock ID expires, the vault automatically exits the InProgress state, and the vault lock policy is removed from the vault. You call CompleteVaultLock to complete the vault locking process by setting the state of the vault lock to Locked. After a vault lock is in the Locked state, you cannot initiate a new vault lock for the vault. You can abort the vault locking process by calling AbortVaultLock. You can get the state of the vault lock by calling GetVaultLock. For more information about the vault locking process, Amazon Glacier Vault Lock (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html). If this operation is called when the vault lock is in the InProgress state, the operation returns an AccessDeniedException error. When the vault lock is in the InProgress state you must call AbortVaultLock before you can initiate a new vault lock policy.
#
# POST /{accountId}/vaults/{vaultName}/lock-policy
# operationId: InitiateVaultLock
# --policy shape: {Policy?: any}
export def "vaults-lock-policy lock-initiate" [
  account_id: string
  vault_name: string
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
  --policy: record # Contains the vault lock policy. — shape: {Policy?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/lock-policy") $auth.query)
  let req_body = {"policy": $policy} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# This operation adds the specified tags to a vault. Each tag is composed of a key and a value. Each vault can have up to 10 tags. If your request would cause the tag limit for the vault to be exceeded, the operation throws the LimitExceededException error. If a tag already exists on the vault under a specified key, the existing key value will be overwritten. For more information about tags, see Tagging Amazon S3 Glacier Resources (https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html).
#
# POST /{accountId}/vaults/{vaultName}/tags
# operationId: AddTagsToVault
export def "vaults-tags create" [
  account_id: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --tags: record # The tags to add to the vault. Each tag is composed of a key and a value. The value can be an empty string.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/tags") $qp $auth.query)
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# This operation completes the vault locking process by transitioning the vault lock from the InProgress state to the Locked state, which causes the vault lock policy to become unchangeable. A vault lock is put into the InProgress state by calling InitiateVaultLock. You can obtain the state of the vault lock by calling GetVaultLock. For more information about the vault locking process, Amazon Glacier Vault Lock (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html). This operation is idempotent. This request is always successful if the vault lock is in the Locked state and the provided lock ID matches the lock ID originally used to lock the vault. If an invalid lock ID is passed in the request when the vault lock is in the Locked state, the operation returns an AccessDeniedException error. If an invalid lock ID is passed in the request when the vault lock is in the InProgress state, the operation throws an InvalidParameter error.
#
# POST /{accountId}/vaults/{vaultName}/lock-policy/{lockId}
# operationId: CompleteVaultLock
export def "vaults-lock-policy complete" [
  account_id: string
  vault_name: string
  lock_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($lock_id | is-empty) { error make --unspanned { msg: "path parameter 'lockId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name), lock_id: (encode-path-segment $lock_id)} | format pattern "/{account_id}/vaults/{vault_name}/lock-policy/{lock_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# This operation creates a new vault with the specified name. The name of the vault must be unique within a region for an AWS account. You can create up to 1,000 vaults per account. If you need to create more vaults, contact Amazon S3 Glacier. You must use the following guidelines when naming a vault. Names can be between 1 and 255 characters long. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), and '.' (period). This operation is idempotent. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Creating a Vault in Amazon Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/creating-vaults.html) and Create Vault (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-put.html) in the Amazon Glacier Developer Guide.
#
# PUT /{accountId}/vaults/{vaultName}
# operationId: CreateVault
export def "vaults create" [
  account_id: string
  vault_name: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [201]
}

# This operation deletes a vault. Amazon S3 Glacier will delete a vault only if there are no archives in the vault as of the last inventory and there have been no writes to the vault since the last inventory. If either of these conditions is not satisfied, the vault deletion fails (that is, the vault is not removed) and Amazon S3 Glacier returns an error. You can use DescribeVault to return the number of archives in a vault, and you can use Initiate a Job (POST jobs) (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html) to initiate a new inventory retrieval for a vault. The inventory contains the archive IDs you use to delete archives using Delete Archive (DELETE archive) (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-delete.html). This operation is idempotent. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Deleting a Vault in Amazon Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/deleting-vaults.html) and Delete Vault (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-delete.html) in the Amazon S3 Glacier Developer Guide.
#
# DELETE /{accountId}/vaults/{vaultName}
# operationId: DeleteVault
export def "vaults delete" [
  account_id: string
  vault_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation returns information about a vault, including the vault's Amazon Resource Name (ARN), the date the vault was created, the number of archives it contains, and the total size of all the archives in the vault. The number of archives and their total size are as of the last inventory generation. This means that if you add or remove an archive from a vault, and then immediately use Describe Vault, the change in contents will not be immediately reflected. If you want to retrieve the latest inventory of the vault, use InitiateJob. Amazon S3 Glacier generates vault inventories approximately daily. For more information, see Downloading a Vault Inventory in Amazon S3 Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-inventory.html). An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Retrieving Vault Metadata in Amazon S3 Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/retrieving-vault-info.html) and Describe Vault (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-get.html) in the Amazon Glacier Developer Guide.
#
# GET /{accountId}/vaults/{vaultName}
# operationId: DescribeVault
export def "vaults get" [
  account_id: string
  vault_name: string
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
]: nothing -> record<VaultARN: record, VaultName: record, CreationDate: record, LastInventoryDate: record, NumberOfArchives: record, SizeInBytes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation deletes an archive from a vault. Subsequent requests to initiate a retrieval of this archive will fail. Archive retrievals that are in progress for this archive ID may or may not succeed according to the following scenarios: If the archive retrieval job is actively preparing the data for download when Amazon S3 Glacier receives the delete archive request, the archival retrieval operation might fail. If the archive retrieval job has successfully prepared the archive for download when Amazon S3 Glacier receives the delete archive request, you will be able to download the output. This operation is idempotent. Attempting to delete an already-deleted archive does not result in an error. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Deleting an Archive in Amazon Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/deleting-an-archive.html) and Delete Archive (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-delete.html) in the Amazon Glacier Developer Guide.
#
# DELETE /{accountId}/vaults/{vaultName}/archives/{archiveId}
# operationId: DeleteArchive
export def "vaults-archives delete" [
  account_id: string
  vault_name: string
  archive_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($archive_id | is-empty) { error make --unspanned { msg: "path parameter 'archiveId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name), archive_id: (encode-path-segment $archive_id)} | format pattern "/{account_id}/vaults/{vault_name}/archives/{archive_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation deletes the access policy associated with the specified vault. The operation is eventually consistent; that is, it might take some time for Amazon S3 Glacier to completely remove the access policy, and you might still see the effect of the policy for a short time after you send the delete request. This operation is idempotent. You can invoke delete multiple times, even if there is no policy associated with the vault. For more information about vault access policies, see Amazon Glacier Access Control with Vault Access Policies (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html).
#
# DELETE /{accountId}/vaults/{vaultName}/access-policy
# operationId: DeleteVaultAccessPolicy
export def "vaults-access-policy delete" [
  account_id: string
  vault_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/access-policy") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation retrieves the access-policy subresource set on the vault; for more information on setting this subresource, see Set Vault Access Policy (PUT access-policy) (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-SetVaultAccessPolicy.html). If there is no access policy set on the vault, the operation returns a 404 Not found error. For more information about vault access policies, see Amazon Glacier Access Control with Vault Access Policies (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html).
#
# GET /{accountId}/vaults/{vaultName}/access-policy
# operationId: GetVaultAccessPolicy
export def "vaults-access-policy get" [
  account_id: string
  vault_name: string
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
]: nothing -> record<policy: record<Policy: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/access-policy") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation configures an access policy for a vault and will overwrite an existing policy. To configure a vault access policy, send a PUT request to the access-policy subresource of the vault. An access policy is specific to a vault and is also called a vault subresource. You can set one access policy per vault and the policy can be up to 20 KB in size. For more information about vault access policies, see Amazon Glacier Access Control with Vault Access Policies (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html).
#
# PUT /{accountId}/vaults/{vaultName}/access-policy
# operationId: SetVaultAccessPolicy
# --policy shape: {Policy?: any}
export def "vaults-access-policy update" [
  account_id: string
  vault_name: string
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
  --policy: record # Contains the vault access policy. — shape: {Policy?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/access-policy") $auth.query)
  let req_body = {"policy": $policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# This operation deletes the notification configuration set for a vault. The operation is eventually consistent; that is, it might take some time for Amazon S3 Glacier to completely disable the notifications and you might still receive some notifications for a short time after you send the delete request. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Configuring Vault Notifications in Amazon S3 Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html) and Delete Vault Notification Configuration (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-delete.html) in the Amazon S3 Glacier Developer Guide.
#
# DELETE /{accountId}/vaults/{vaultName}/notification-configuration
# operationId: DeleteVaultNotifications
export def "vaults-notification-configuration delete" [
  account_id: string
  vault_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/notification-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation retrieves the notification-configuration subresource of the specified vault. For information about setting a notification configuration on a vault, see SetVaultNotifications. If a notification configuration for a vault is not set, the operation returns a 404 Not Found error. For more information about vault notifications, see Configuring Vault Notifications in Amazon S3 Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html). An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Configuring Vault Notifications in Amazon S3 Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html) and Get Vault Notification Configuration (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-get.html) in the Amazon Glacier Developer Guide.
#
# GET /{accountId}/vaults/{vaultName}/notification-configuration
# operationId: GetVaultNotifications
export def "vaults-notification-configuration get" [
  account_id: string
  vault_name: string
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
]: nothing -> record<vaultNotificationConfig: record<SNSTopic: record, Events: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/notification-configuration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation configures notifications that will be sent when specific events happen to a vault. By default, you don't get any notifications. To configure vault notifications, send a PUT request to the notification-configuration subresource of the vault. The request should include a JSON document that provides an Amazon SNS topic and specific events for which you want Amazon S3 Glacier to send notifications to the topic. Amazon SNS topics must grant permission to the vault to be allowed to publish notifications to the topic. You can configure a vault to publish a notification for the following vault events: ArchiveRetrievalCompleted This event occurs when a job that was initiated for an archive retrieval is completed (InitiateJob). The status of the completed job can be "Succeeded" or "Failed". The notification sent to the SNS topic is the same output as returned from DescribeJob. InventoryRetrievalCompleted This event occurs when a job that was initiated for an inventory retrieval is completed (InitiateJob). The status of the completed job can be "Succeeded" or "Failed". The notification sent to the SNS topic is the same output as returned from DescribeJob. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Configuring Vault Notifications in Amazon S3 Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html) and Set Vault Notification Configuration (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-put.html) in the Amazon Glacier Developer Guide.
#
# PUT /{accountId}/vaults/{vaultName}/notification-configuration
# operationId: SetVaultNotifications
# --vaultNotificationConfig shape: {SNSTopic?: any, Events?: any}
export def "vaults-notification-configuration update" [
  account_id: string
  vault_name: string
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
  --vault-notification-config: record # Represents a vault's notification configuration. — shape: {SNSTopic?: any, Events?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/notification-configuration") $auth.query)
  let req_body = {"vaultNotificationConfig": $vault_notification_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# This operation returns information about a job you previously initiated, including the job initiation date, the user who initiated the job, the job status code/message and the Amazon SNS topic to notify after Amazon S3 Glacier (Glacier) completes the job. For more information about initiating a job, see InitiateJob. This operation enables you to check the status of your job. However, it is strongly recommended that you set up an Amazon SNS topic and specify it in your initiate job request so that Glacier can notify the topic after it completes the job. A job ID will not expire for at least 24 hours after Glacier completes the job. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For more information about using this operation, see the documentation for the underlying REST API Describe Job (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-describe-job-get.html) in the Amazon Glacier Developer Guide.
#
# GET /{accountId}/vaults/{vaultName}/jobs/{jobId}
# operationId: DescribeJob
export def "vaults-jobs get" [
  account_id: string
  vault_name: string
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
]: nothing -> record<JobId: record, JobDescription: record, Action: record, ArchiveId: record, VaultARN: record, CreationDate: record, Completed: record, StatusCode: record, StatusMessage: record, ArchiveSizeInBytes: record, InventorySizeInBytes: record, SNSTopic: record, CompletionDate: record, SHA256TreeHash: record, ArchiveSHA256TreeHash: record, RetrievalByteRange: record, Tier: record, InventoryRetrievalParameters: record<Format: record, StartDate: record, EndDate: record, Limit: record, Marker: record>, JobOutputPath: record, SelectParameters: record<InputSerialization: record<csv: record>, ExpressionType: record, Expression: record, OutputSerialization: record<csv: record>>, OutputLocation: record<S3: record<BucketName: record, Prefix: record, Encryption: record, CannedACL: record, AccessControlList: record, Tagging: record, UserMetadata: record, StorageClass: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name), job_id: (encode-path-segment $job_id)} | format pattern "/{account_id}/vaults/{vault_name}/jobs/{job_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation returns the current data retrieval policy for the account and region specified in the GET request. For more information about data retrieval policies, see Amazon Glacier Data Retrieval Policies (https://docs.aws.amazon.com/amazonglacier/latest/dev/data-retrieval-policy.html).
#
# GET /{accountId}/policies/data-retrieval
# operationId: GetDataRetrievalPolicy
export def "policies-data-retrieval get-policy" [
  account_id: string
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
]: nothing -> record<Policy: record<Rules: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/{account_id}/policies/data-retrieval") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation sets and then enacts a data retrieval policy in the region specified in the PUT request. You can set one policy per region for an AWS account. The policy is enacted within a few minutes of a successful PUT operation. The set policy operation does not affect retrieval jobs that were in progress before the policy was enacted. For more information about data retrieval policies, see Amazon Glacier Data Retrieval Policies (https://docs.aws.amazon.com/amazonglacier/latest/dev/data-retrieval-policy.html).
#
# PUT /{accountId}/policies/data-retrieval
# operationId: SetDataRetrievalPolicy
# --Policy shape: {Rules?: any}
export def "policies-data-retrieval update-policy" [
  account_id: string
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
  --policy: record # Data retrieval policy. — shape: {Rules?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/{account_id}/policies/data-retrieval") $auth.query)
  let req_body = {"Policy": $policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# This operation downloads the output of the job you initiated using InitiateJob. Depending on the job type you specified when you initiated the job, the output will be either the content of an archive or a vault inventory. You can download all the job output or download a portion of the output by specifying a byte range. In the case of an archive retrieval job, depending on the byte range you specify, Amazon S3 Glacier (Glacier) returns the checksum for the portion of the data. You can compute the checksum on the client and verify that the values match to ensure the portion you downloaded is the correct data. A job ID will not expire for at least 24 hours after Glacier completes the job. That a byte range. For both archive and inventory retrieval jobs, you should verify the downloaded size against the size returned in the headers from the Get Job Output response. For archive retrieval jobs, you should also verify that the size is what you expected. If you download a portion of the output, the expected size is based on the range of bytes you specified. For example, if you specify a range of bytes=0-1048575, you should verify your download size is 1,048,576 bytes. If you download an entire archive, the expected size is the size of the archive when you uploaded it to Amazon S3 Glacier The expected size is also returned in the headers from the Get Job Output response. In the case of an archive retrieval job, depending on the byte range you specify, Glacier returns the checksum for the portion of the data. To ensure the portion you downloaded is the correct data, compute the checksum on the client, verify that the values match, and verify that the size is what you expected. A job ID does not expire for at least 24 hours after Glacier completes the job. That is, you can download the job output within the 24 hours period after Amazon Glacier completes the job. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and the underlying REST API, see Downloading a Vault Inventory (https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-inventory.html), Downloading an Archive (https://docs.aws.amazon.com/amazonglacier/latest/dev/downloading-an-archive.html), and Get Job Output (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-job-output-get.html)
#
# GET /{accountId}/vaults/{vaultName}/jobs/{jobId}/output
# operationId: GetJobOutput
export def "vaults-jobs-output get" [
  account_id: string
  vault_name: string
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
  --range: string # The range of bytes to retrieve from the output. For example, if you want to download the first 1,048,576 bytes, specify the range as bytes=0-1048575. By default, this operation downloads the entire output. If the job output is large, then you can use a range to retrieve a portion of the output. This allows you to download the entire output in smaller chunks of bytes. For example, suppose you have 1 GB of job output you want to download and you decide to download 128 MB chunks of data at a time, which is a total of eight Get Job Output requests. You use the following process to download the job output: Download a 128 MB chunk of output by specifying the appropriate byte range. Verify that all 128 MB of data was received. Along with the data, the response includes a SHA256 tree hash of the payload. You compute the checksum of the payload on the client and compare it with the checksum you received in the response to ensure you received all the expected data. Repeat steps 1 and 2 for all the eight 128 MB chunks of output data, each time specifying the appropriate byte range. After downloading all the parts of the job output, you have a list of eight checksum values. Compute the tree hash of these values to find the checksum of the entire output. Using the DescribeJob API, obtain job information of the job that provided you the output. The response includes the checksum of the entire archive stored in Amazon S3 Glacier. You compare this value with the checksum you computed to ensure you have downloaded the entire archive content with no errors.
]: nothing -> record<body: record, status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name), job_id: (encode-path-segment $job_id)} | format pattern "/{account_id}/vaults/{vault_name}/jobs/{job_id}/output") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Range": $range} | compact
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

# This operation initiates a job of the specified type, which can be a select, an archival retrieval, or a vault retrieval. For more information about using this operation, see the documentation for the underlying REST API Initiate a Job (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html).
#
# POST /{accountId}/vaults/{vaultName}/jobs
# operationId: InitiateJob
# --jobParameters shape: {Format?: any, Type?: any, ArchiveId?: any, Description?: any, SNSTopic?: any, RetrievalByteRange?: any, Tier?: any, InventoryRetrievalParameters?: any, SelectParameters?: any, OutputLocation?: any}
export def "vaults-jobs create-initiate" [
  account_id: string
  vault_name: string
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
  --job-parameters: record # Provides options for defining a job. — shape: {Format?: any, Type?: any, ArchiveId?: any, Description?: any, SNSTopic?: any, RetrievalByteRange?: any, Tier?: any, InventoryRetrievalParameters?: any, SelectParameters?: any, OutputLocation?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/jobs") $auth.query)
  let req_body = {"jobParameters": $job_parameters} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# This operation lists jobs for a vault, including jobs that are in-progress and jobs that have recently finished. The List Job operation returns a list of these jobs sorted by job initiation time. Amazon Glacier retains recently completed jobs for a period before deleting them; however, it eventually removes completed jobs. The output of completed jobs can be retrieved. Retaining completed jobs for a period of time after they have completed enables you to get a job output in the event you miss the job completion notification or your first attempt to download it fails. For example, suppose you start an archive retrieval job to download an archive. After the job completes, you start to download the archive but encounter a network error. In this scenario, you can retry and download the archive while the job exists. The List Jobs operation supports pagination. You should always check the response Marker field. If there are no more jobs to list, the Marker field is set to null. If there are more jobs to list, the Marker field is set to a non-null value, which you can use to continue the pagination of the list. To return a list of jobs that begins at a specific job, set the marker request parameter to the Marker value for that job that you obtained from a previous List Jobs request. You can set a maximum limit for the number of jobs returned in the response by specifying the limit parameter in the request. The default limit is 50. The number of jobs returned might be fewer than the limit, but the number of returned jobs never exceeds the limit. Additionally, you can filter the jobs list returned by specifying the optional statuscode parameter or completed parameter, or both. Using the statuscode parameter, you can specify to return only jobs that match either the InProgress, Succeeded, or Failed status. Using the completed parameter, you can specify to return only jobs that were completed (true) or jobs that were not completed (false). For more information about using this operation, see the documentation for the underlying REST API List Jobs (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-jobs-get.html).
#
# GET /{accountId}/vaults/{vaultName}/jobs
# operationId: ListJobs
export def "vaults-jobs list" [
  account_id: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # The maximum number of jobs to be returned. The default limit is 50. The number of jobs returned might be fewer than the specified limit, but the number of returned jobs never exceeds the limit.
  --marker: string # An opaque string used for pagination. This value specifies the job at which the listing of jobs should begin. Get the marker value from a previous List Jobs response. You only need to include the marker if you are continuing the pagination of results started in a previous List Jobs request.
  --statuscode: string # The type of job status to return. You can specify the following values: InProgress, Succeeded, or Failed.
  --completed: string # The state of the jobs to return. You can specify true or false.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<JobList: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "statuscode" $statuscode "scalar") (serialize-qp "completed" $completed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/jobs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "marker": $marker, "statuscode": $statuscode, "completed": $completed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This operation initiates a multipart upload. Amazon S3 Glacier creates a multipart upload resource and returns its ID in the response. The multipart upload ID is used in subsequent requests to upload parts of an archive (see UploadMultipartPart). When you initiate a multipart upload, you specify the part size in number of bytes. The part size must be a megabyte (1024 KB) multiplied by a power of 2-for example, 1048576 (1 MB), 2097152 (2 MB), 4194304 (4 MB), 8388608 (8 MB), and so on. The minimum allowable part size is 1 MB, and the maximum is 4 GB. Every part you upload to this resource (see UploadMultipartPart), except the last one, must have the same size. The last one can be the same size or smaller. For example, suppose you want to upload a 16.2 MB file. If you initiate the multipart upload with a part size of 4 MB, you will upload four parts of 4 MB each and one part of 0.2 MB. You don't need to know the size of the archive when you start a multipart upload because Amazon S3 Glacier does not require you to specify the overall archive size. After you complete the multipart upload, Amazon S3 Glacier (Glacier) removes the multipart upload resource referenced by the ID. Glacier also removes the multipart upload resource if you cancel the multipart upload or it may be removed if there is no activity for a period of 24 hours. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Uploading Large Archives in Parts (Multipart Upload) (https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html) and Initiate Multipart Upload (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-initiate-upload.html) in the Amazon Glacier Developer Guide.
#
# POST /{accountId}/vaults/{vaultName}/multipart-uploads
# operationId: InitiateMultipartUpload
export def "vaults-multipart-uploads upload-initiate" [
  account_id: string
  vault_name: string
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
  --x-amz-archive-description: string # The archive description that you are uploading in parts. The part size must be a megabyte (1024 KB) multiplied by a power of 2, for example 1048576 (1 MB), 2097152 (2 MB), 4194304 (4 MB), 8388608 (8 MB), and so on. The minimum allowable part size is 1 MB, and the maximum is 4 GB (4096 MB).
  --x-amz-part-size: string # The size of each part except the last, in bytes. The last part can be smaller than this part size.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/multipart-uploads") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-archive-description": $x_amz_archive_description, "x-amz-part-size": $x_amz_part_size} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# This operation lists in-progress multipart uploads for the specified vault. An in-progress multipart upload is a multipart upload that has been initiated by an InitiateMultipartUpload request, but has not yet been completed or aborted. The list returned in the List Multipart Upload response has no guaranteed order. The List Multipart Uploads operation supports pagination. By default, this operation returns up to 50 multipart uploads in the response. You should always check the response for a marker at which to continue the list; if there are no more items the marker is null. To return a list of multipart uploads that begins at a specific upload, set the marker request parameter to the value you obtained from a previous List Multipart Upload request. You can also limit the number of uploads returned in the response by specifying the limit parameter in the request. Note the difference between this operation and listing parts (ListParts). The List Multipart Uploads operation lists all multipart uploads for a vault and does not require a multipart upload ID. The List Parts operation requires a multipart upload ID since parts are associated with a single upload. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and the underlying REST API, see Working with Archives in Amazon S3 Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html) and List Multipart Uploads (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-list-uploads.html) in the Amazon Glacier Developer Guide.
#
# GET /{accountId}/vaults/{vaultName}/multipart-uploads
# operationId: ListMultipartUploads
export def "vaults-multipart-uploads list" [
  account_id: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # An opaque string used for pagination. This value specifies the upload at which the listing of uploads should begin. Get the marker value from a previous List Uploads response. You need only include the marker if you are continuing the pagination of results started in a previous List Uploads request.
  --limit: string # Specifies the maximum number of uploads returned in the response body. If this value is not specified, the List Uploads operation returns up to 50 uploads.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<UploadsList: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/multipart-uploads") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"marker": $marker, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This operation lists the provisioned capacity units for the specified AWS account.
#
# GET /{accountId}/provisioned-capacity
# operationId: ListProvisionedCapacity
export def "provisioned-capacity list" [
  account_id: string
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
]: nothing -> record<ProvisionedCapacityList: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/{account_id}/provisioned-capacity") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation purchases a provisioned capacity unit for an AWS account.
#
# POST /{accountId}/provisioned-capacity
# operationId: PurchaseProvisionedCapacity
export def "provisioned-capacity create-purchase" [
  account_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/{account_id}/provisioned-capacity") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# This operation lists all the tags attached to a vault. The operation returns an empty map if there are no tags. For more information about tags, see Tagging Amazon S3 Glacier Resources (https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html).
#
# GET /{accountId}/vaults/{vaultName}/tags
# operationId: ListTagsForVault
export def "vaults-tags list" [
  account_id: string
  vault_name: string
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
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/tags") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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

# This operation lists all vaults owned by the calling user's account. The list returned in the response is ASCII-sorted by vault name. By default, this operation returns up to 10 items. If there are more vaults to list, the response marker field contains the vault Amazon Resource Name (ARN) at which to continue the list with a new List Vaults request; otherwise, the marker field is null. To return a list of vaults that begins at a specific vault, set the marker request parameter to the vault ARN you obtained from a previous List Vaults request. You can also limit the number of vaults returned in the response by specifying the limit parameter in the request. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Retrieving Vault Metadata in Amazon S3 Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/retrieving-vault-info.html) and List Vaults (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vaults-get.html) in the Amazon Glacier Developer Guide.
#
# GET /{accountId}/vaults
# operationId: ListVaults
export def "vaults list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # A string used for pagination. The marker specifies the vault ARN after which the listing of vaults should begin.
  --limit: string # The maximum number of vaults to be returned. The default limit is 10. The number of vaults returned might be fewer than the specified limit, but the number of returned vaults never exceeds the limit.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<VaultList: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/{account_id}/vaults") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"marker": $marker, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This operation removes one or more tags from the set of tags attached to a vault. For more information about tags, see Tagging Amazon S3 Glacier Resources (https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html). This operation is idempotent. The operation will be successful, even if there are no tags attached to the vault.
#
# POST /{accountId}/vaults/{vaultName}/tags
# operationId: RemoveTagsFromVault
export def "vaults-tags delete" [
  account_id: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string@operation-completer-1
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --tag-keys: list<string> # A list of tag keys. Each corresponding tag is removed from the vault.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let qp = [(serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/tags") $qp $auth.query)
  let req_body = {"TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"operation": $operation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# This operation adds an archive to a vault. This is a synchronous operation, and for a successful upload, your data is durably persisted. Amazon S3 Glacier returns the archive ID in the x-amz-archive-id header of the response. You must use the archive ID to access your data in Amazon S3 Glacier. After you upload an archive, you should save the archive ID returned so that you can retrieve or delete the archive later. Besides saving the archive ID, you can also index it and give it a friendly name to allow for better searching. You can also use the optional archive description field to specify how the archive is referred to in an external index of archives, such as you might create in Amazon DynamoDB. You can also get the vault inventory to obtain a list of archive IDs in a vault. For more information, see InitiateJob. You must provide a SHA256 tree hash of the data you are uploading. For information about computing a SHA256 tree hash, see Computing Checksums (https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html). You can optionally specify an archive description of up to 1,024 printable ASCII characters. You can get the archive description when you either retrieve the archive or get the vault inventory. For more information, see InitiateJob. Amazon Glacier does not interpret the description in any way. An archive description does not need to be unique. You cannot use the description to retrieve or sort the archive list. Archives are immutable. After you upload an archive, you cannot edit the archive or its description. An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see Access Control Using AWS Identity and Access Management (IAM) (https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html). For conceptual information and underlying REST API, see Uploading an Archive in Amazon Glacier (https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-an-archive.html) and Upload Archive (https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-post.html) in the Amazon Glacier Developer Guide.
#
# POST /{accountId}/vaults/{vaultName}/archives
# operationId: UploadArchive
export def "vaults-archives upload" [
  account_id: string
  vault_name: string
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
  --x-amz-archive-description: string # The optional description of the archive you are uploading.
  --x-amz-sha256-tree-hash: string # The SHA256 tree hash of the data being uploaded.
  --body: string # The data to upload.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), vault_name: (encode-path-segment $vault_name)} | format pattern "/{account_id}/vaults/{vault_name}/archives") $auth.query)
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-archive-description": $x_amz_archive_description, "x-amz-sha256-tree-hash": $x_amz_sha256_tree_hash} | compact
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
