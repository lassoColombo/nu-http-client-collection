# Auto-generated client for Amazon Simple Storage Service v2006-03-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/s3/2006-03-01/openapi.json
# Auth: --token flag or $env.AMAZON_SIMPLE_STORAGE_SERVICE_TOKEN

const BASE_URL = "http://s3.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_SIMPLE_STORAGE_SERVICE_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://s3.us-east-1.amazonaws.com" "http://s3.us-west-1.amazonaws.com" "http://s3.us-west-2.amazonaws.com" "http://s3.us-gov-west-1.amazonaws.com" "http://s3.eu-west-1.amazonaws.com" "http://s3.ap-northeast-1.amazonaws.com" "http://s3.ap-southeast-1.amazonaws.com" "http://s3.ap-southeast-2.amazonaws.com" "http://s3.sa-east-1.amazonaws.com" "http://s3-us-east-1.amazonaws.com" "https://s3.us-east-1.amazonaws.com" "https://s3.us-west-1.amazonaws.com" "https://s3.us-west-2.amazonaws.com" "https://s3.us-gov-west-1.amazonaws.com" "https://s3.eu-west-1.amazonaws.com" "https://s3.ap-northeast-1.amazonaws.com" "https://s3.ap-southeast-1.amazonaws.com" "https://s3.ap-southeast-2.amazonaws.com" "https://s3.sa-east-1.amazonaws.com" "https://s3-us-east-1.amazonaws.com" "http://s3.amazonaws.com" "https://s3.amazonaws.com" "http://s3.us-east-2.amazonaws.com" "http://s3.us-gov-east-1.amazonaws.com" "http://s3.ca-central-1.amazonaws.com" "http://s3.eu-north-1.amazonaws.com" "http://s3.eu-west-2.amazonaws.com" "http://s3.eu-west-3.amazonaws.com" "http://s3.eu-central-1.amazonaws.com" "http://s3.eu-south-1.amazonaws.com" "http://s3.af-south-1.amazonaws.com" "http://s3.ap-northeast-2.amazonaws.com" "http://s3.ap-northeast-3.amazonaws.com" "http://s3.ap-east-1.amazonaws.com" "http://s3.ap-south-1.amazonaws.com" "http://s3.me-south-1.amazonaws.com" "https://s3.us-east-2.amazonaws.com" "https://s3.us-gov-east-1.amazonaws.com" "https://s3.ca-central-1.amazonaws.com" "https://s3.eu-north-1.amazonaws.com" "https://s3.eu-west-2.amazonaws.com" "https://s3.eu-west-3.amazonaws.com" "https://s3.eu-central-1.amazonaws.com" "https://s3.eu-south-1.amazonaws.com" "https://s3.af-south-1.amazonaws.com" "https://s3.ap-northeast-2.amazonaws.com" "https://s3.ap-northeast-3.amazonaws.com" "https://s3.ap-east-1.amazonaws.com" "https://s3.ap-south-1.amazonaws.com" "https://s3.me-south-1.amazonaws.com" "http://s3.cn-north-1.amazonaws.com.cn" "http://s3.cn-northwest-1.amazonaws.com.cn" "https://s3.cn-north-1.amazonaws.com.cn" "https://s3.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-request-payer-completer [] { ["requester"] }
def x-amz-acl-completer [] { ["authenticated-read" "aws-exec-read" "bucket-owner-full-control" "bucket-owner-read" "private" "public-read" "public-read-write"] }
def x-amz-checksum-algorithm-completer [] { ["CRC32" "CRC32C" "SHA1" "SHA256"] }
def x-amz-metadata-directive-completer [] { ["COPY" "REPLACE"] }
def x-amz-tagging-directive-completer [] { ["COPY" "REPLACE"] }
def x-amz-server-side-encryption-completer [] { ["AES256" "aws:kms"] }
def x-amz-storage-class-completer [] { ["DEEP_ARCHIVE" "GLACIER" "GLACIER_IR" "INTELLIGENT_TIERING" "ONEZONE_IA" "OUTPOSTS" "REDUCED_REDUNDANCY" "SNOW" "STANDARD" "STANDARD_IA"] }
def x-amz-object-lock-mode-completer [] { ["COMPLIANCE" "GOVERNANCE"] }
def x-amz-object-lock-legal-hold-completer [] { ["OFF" "ON"] }
def x-amz-acl-completer-1 [] { ["authenticated-read" "private" "public-read" "public-read-write"] }
def x-amz-object-ownership-completer [] { ["BucketOwnerEnforced" "BucketOwnerPreferred" "ObjectWriter"] }
def encoding-type-completer [] { ["url"] }
def uploads-completer [] { ["true"] }
def analytics-completer [] { ["true"] }
def cors-completer [] { ["true"] }
def x-amz-sdk-checksum-algorithm-completer [] { ["CRC32" "CRC32C" "SHA1" "SHA256"] }
def encryption-completer [] { ["true"] }
def intelligent-tiering-completer [] { ["true"] }
def inventory-completer [] { ["true"] }
def lifecycle-completer [] { ["true"] }
def metrics-completer [] { ["true"] }
def ownershipControls-completer [] { ["true"] }
def policy-completer [] { ["true"] }
def replication-completer [] { ["true"] }
def tagging-completer [] { ["true"] }
def website-completer [] { ["true"] }
def x-amz-checksum-mode-completer [] { ["ENABLED"] }
def delete-completer [] { ["true"] }
def publicAccessBlock-completer [] { ["true"] }
def accelerate-completer [] { ["true"] }
def acl-completer [] { ["true"] }
def location-completer [] { ["true"] }
def logging-completer [] { ["true"] }
def notification-completer [] { ["true"] }
def policyStatus-completer [] { ["true"] }
def requestPayment-completer [] { ["true"] }
def versioning-completer [] { ["true"] }
def attributes-completer [] { ["true"] }
def legal-hold-completer [] { ["true"] }
def object-lock-completer [] { ["true"] }
def retention-completer [] { ["true"] }
def torrent-completer [] { ["true"] }
def versions-completer [] { ["true"] }
def list-type-completer [] { ["2"] }
def restore-completer [] { ["true"] }
def select-completer [] { ["true"] }
def select-type-completer [] { ["2"] }
def x-amz-fwd-header-x-amz-object-lock-mode-completer [] { ["COMPLIANCE" "GOVERNANCE"] }
def x-amz-fwd-header-x-amz-object-lock-legal-hold-completer [] { ["OFF" "ON"] }
def x-amz-fwd-header-x-amz-replication-status-completer [] { ["COMPLETE" "FAILED" "PENDING" "REPLICA"] }
def x-amz-fwd-header-x-amz-request-charged-completer [] { ["requester"] }
def x-amz-fwd-header-x-amz-server-side-encryption-completer [] { ["AES256" "aws:kms"] }
def x-amz-fwd-header-x-amz-storage-class-completer [] { ["DEEP_ARCHIVE" "GLACIER" "GLACIER_IR" "INTELLIGENT_TIERING" "ONEZONE_IA" "OUTPOSTS" "REDUCED_REDUNDANCY" "SNOW" "STANDARD" "STANDARD_IA"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api AbortMultipartUpload" } } | get name | first)
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

# <p>This action aborts a multipart upload. After a multipart upload is aborted, no additional parts can be uploaded using that upload ID. The storage consumed by any previously uploaded parts will be freed. However, if any part uploads are currently in progress, those part uploads might or might not succeed. As a result, it might be necessary to abort a given multipart upload multiple times in order to completely free all storage consumed by all parts. </p> <p>To verify that all parts have been removed, so you don't get charged for the part storage, you should call the <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html">ListParts</a> action and ensure that the parts list is empty.</p> <p>For information about permissions required to use the multipart upload, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html">Multipart Upload and Permissions</a>.</p> <p>The following operations are related to <code>AbortMultipartUpload</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html">CreateMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html">CompleteMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html">ListParts</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html">ListMultipartUploads</a> </p> </li> </ul>
#
# DELETE /{Bucket}/{Key}#uploadId
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html
# operationId: AbortMultipartUpload
export def "api AbortMultipartUpload" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uploadId: string # Upload ID that identifies the multipart upload.
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uploadId" $uploadId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#uploadId" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Completes a multipart upload by assembling previously uploaded parts.</p> <p>You first initiate the multipart upload and then upload all parts using the <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a> operation. After successfully uploading all relevant parts of an upload, you call this action to complete the upload. Upon receiving this request, Amazon S3 concatenates all the parts in ascending order by part number to create a new object. In the Complete Multipart Upload request, you must provide the parts list. You must ensure that the parts list is complete. This action concatenates the parts that you provide in the list. For each part in the list, you must provide the part number and the <code>ETag</code> value, returned after that part was uploaded.</p> <p>Processing of a Complete Multipart Upload request could take several minutes to complete. After Amazon S3 begins processing the request, it sends an HTTP response header that specifies a 200 OK response. While processing is in progress, Amazon S3 periodically sends white space characters to keep the connection from timing out. Because a request could fail after the initial 200 OK response has been sent, it is important that you check the response body to determine whether the request succeeded.</p> <p>Note that if <code>CompleteMultipartUpload</code> fails, applications should be prepared to retry the failed requests. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ErrorBestPractices.html">Amazon S3 Error Best Practices</a>.</p> <important> <p>You cannot use <code>Content-Type: application/x-www-form-urlencoded</code> with Complete Multipart Upload requests. Also, if you do not provide a <code>Content-Type</code> header, <code>CompleteMultipartUpload</code> returns a 200 OK response.</p> </important> <p>For more information about multipart uploads, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/uploadobjusingmpu.html">Uploading Objects Using Multipart Upload</a>.</p> <p>For information about permissions required to use the multipart upload API, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html">Multipart Upload and Permissions</a>.</p> <p> <code>CompleteMultipartUpload</code> has the following special errors:</p> <ul> <li> <p>Error code: <code>EntityTooSmall</code> </p> <ul> <li> <p>Description: Your proposed upload is smaller than the minimum allowed object size. Each part must be at least 5 MB in size, except the last part.</p> </li> <li> <p>400 Bad Request</p> </li> </ul> </li> <li> <p>Error code: <code>InvalidPart</code> </p> <ul> <li> <p>Description: One or more of the specified parts could not be found. The part might not have been uploaded, or the specified entity tag might not have matched the part's entity tag.</p> </li> <li> <p>400 Bad Request</p> </li> </ul> </li> <li> <p>Error code: <code>InvalidPartOrder</code> </p> <ul> <li> <p>Description: The list of parts was not in ascending order. The parts list must be specified in order by part number.</p> </li> <li> <p>400 Bad Request</p> </li> </ul> </li> <li> <p>Error code: <code>NoSuchUpload</code> </p> <ul> <li> <p>Description: The specified multipart upload does not exist. The upload ID might be invalid, or the multipart upload might have been aborted or completed.</p> </li> <li> <p>404 Not Found</p> </li> </ul> </li> </ul> <p>The following operations are related to <code>CompleteMultipartUpload</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html">CreateMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html">AbortMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html">ListParts</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html">ListMultipartUploads</a> </p> </li> </ul>
#
# POST /{Bucket}/{Key}#uploadId
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html
# operationId: CompleteMultipartUpload
export def "api CompleteMultipartUpload" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uploadId: string # ID for the initiated multipart upload.
  --x-amz-security-token: string
  --x-amz-checksum-crc32: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 32-bit CRC32 checksum of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-checksum-crc32c: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 32-bit CRC32C checksum of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-checksum-sha1: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 160-bit SHA-1 digest of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-checksum-sha256: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 256-bit SHA-256 digest of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-server-side-encryption-customer-algorithm: string # The server-side encryption (SSE) algorithm used to encrypt the object. This parameter is needed only when the object was created using a checksum algorithm. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Protecting data using SSE-C keys</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-server-side-encryption-customer-key: string # The server-side encryption (SSE) customer managed key. This parameter is needed only when the object was created using a checksum algorithm. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Protecting data using SSE-C keys</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-server-side-encryption-customer-key-MD5: string # The MD5 server-side encryption (SSE) customer managed key. This parameter is needed only when the object was created using a checksum algorithm. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Protecting data using SSE-C keys</a> in the <i>Amazon S3 User Guide</i>.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uploadId" $uploadId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#uploadId" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-checksum-crc32": $x_amz_checksum_crc32, "x-amz-checksum-crc32c": $x_amz_checksum_crc32c, "x-amz-checksum-sha1": $x_amz_checksum_sha1, "x-amz-checksum-sha256": $x_amz_checksum_sha256, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-server-side-encryption-customer-algorithm": $x_amz_server_side_encryption_customer_algorithm, "x-amz-server-side-encryption-customer-key": $x_amz_server_side_encryption_customer_key, "x-amz-server-side-encryption-customer-key-MD5": $x_amz_server_side_encryption_customer_key_MD5} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Lists the parts that have been uploaded for a specific multipart upload. This operation must include the upload ID, which you obtain by sending the initiate multipart upload request (see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html">CreateMultipartUpload</a>). This request returns a maximum of 1,000 uploaded parts. The default number of parts returned is 1,000 parts. You can restrict the number of parts returned by specifying the <code>max-parts</code> request parameter. If your multipart upload consists of more than 1,000 parts, the response returns an <code>IsTruncated</code> field with the value of true, and a <code>NextPartNumberMarker</code> element. In subsequent <code>ListParts</code> requests you can include the part-number-marker query string parameter and set its value to the <code>NextPartNumberMarker</code> field value from the previous response.</p> <p>If the upload was created using a checksum algorithm, you will need to have permission to the <code>kms:Decrypt</code> action for the request to succeed. </p> <p>For more information on multipart uploads, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/uploadobjusingmpu.html">Uploading Objects Using Multipart Upload</a>.</p> <p>For information on permissions required to use the multipart upload API, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html">Multipart Upload and Permissions</a>.</p> <p>The following operations are related to <code>ListParts</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html">CreateMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html">CompleteMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html">AbortMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html">GetObjectAttributes</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html">ListMultipartUploads</a> </p> </li> </ul>
#
# GET /{Bucket}/{Key}#uploadId
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html
# operationId: ListParts
export def "api ListParts" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-parts: int # Sets the maximum number of parts to return.
  --part-number-marker: int # Specifies the part after which listing should begin. Only parts with higher part numbers will be listed.
  --uploadId: string # Upload ID identifying the multipart upload whose parts are being listed.
  --MaxParts: string # Pagination limit
  --PartNumberMarker: string # Pagination token
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-server-side-encryption-customer-algorithm: string # The server-side encryption (SSE) algorithm used to encrypt the object. This parameter is needed only when the object was created using a checksum algorithm. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Protecting data using SSE-C keys</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-server-side-encryption-customer-key: string # The server-side encryption (SSE) customer managed key. This parameter is needed only when the object was created using a checksum algorithm. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Protecting data using SSE-C keys</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-server-side-encryption-customer-key-MD5: string # The MD5 server-side encryption (SSE) customer managed key. This parameter is needed only when the object was created using a checksum algorithm. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Protecting data using SSE-C keys</a> in the <i>Amazon S3 User Guide</i>.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max-parts" $max_parts "scalar") (serialize-qp "part-number-marker" $part_number_marker "scalar") (serialize-qp "uploadId" $uploadId "scalar") (serialize-qp "MaxParts" $MaxParts "scalar") (serialize-qp "PartNumberMarker" $PartNumberMarker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#uploadId" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-server-side-encryption-customer-algorithm": $x_amz_server_side_encryption_customer_algorithm, "x-amz-server-side-encryption-customer-key": $x_amz_server_side_encryption_customer_key, "x-amz-server-side-encryption-customer-key-MD5": $x_amz_server_side_encryption_customer_key_MD5} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Creates a copy of an object that is already stored in Amazon S3.</p> <note> <p>You can store individual objects of up to 5 TB in Amazon S3. You create a copy of your object up to 5 GB in size in a single atomic action using this API. However, to copy an object greater than 5 GB, you must use the multipart upload Upload Part - Copy (UploadPartCopy) API. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/CopyingObjctsUsingRESTMPUapi.html">Copy Object Using the REST Multipart Upload API</a>.</p> </note> <p>All copy requests must be authenticated. Additionally, you must have <i>read</i> access to the source object and <i>write</i> access to the destination bucket. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html">REST Authentication</a>. Both the Region that you want to copy the object from and the Region that you want to copy the object to must be enabled for your account.</p> <p>A copy request might return an error when Amazon S3 receives the copy request or while Amazon S3 is copying the files. If the error occurs before the copy action starts, you receive a standard Amazon S3 error. If the error occurs during the copy operation, the error response is embedded in the <code>200 OK</code> response. This means that a <code>200 OK</code> response can contain either a success or an error. Design your application to parse the contents of the response and handle it appropriately.</p> <p>If the copy is successful, you receive a response with information about the copied object.</p> <note> <p>If the request is an HTTP 1.1 request, the response is chunk encoded. If it were not, it would not contain the content-length, and you would need to read the entire body.</p> </note> <p>The copy request charge is based on the storage class and Region that you specify for the destination object. For pricing information, see <a href="http://aws.amazon.com/s3/pricing/">Amazon S3 pricing</a>.</p> <important> <p>Amazon S3 transfer acceleration does not support cross-Region copies. If you request a cross-Region copy using a transfer acceleration endpoint, you get a 400 <code>Bad Request</code> error. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html">Transfer Acceleration</a>.</p> </important> <p> <b>Metadata</b> </p> <p>When copying an object, you can preserve all metadata (default) or specify new metadata. However, the ACL is not preserved and is set to private for the user making the request. To override the default ACL setting, specify a new ACL when generating a copy request. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_ACLs_UsingACLs.html">Using ACLs</a>. </p> <p>To specify whether you want the object metadata copied from the source object or replaced with metadata provided in the request, you can optionally add the <code>x-amz-metadata-directive</code> header. When you grant permissions, you can use the <code>s3:x-amz-metadata-directive</code> condition key to enforce certain metadata behavior when objects are uploaded. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/amazon-s3-policy-keys.html">Specifying Conditions in a Policy</a> in the <i>Amazon S3 User Guide</i>. For a complete list of Amazon S3-specific condition keys, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/list_amazons3.html">Actions, Resources, and Condition Keys for Amazon S3</a>.</p> <p> <b>x-amz-copy-source-if Headers</b> </p> <p>To only copy an object under certain conditions, such as whether the <code>Etag</code> matches or whether the object was modified before or after a specified date, use the following request parameters:</p> <ul> <li> <p> <code>x-amz-copy-source-if-match</code> </p> </li> <li> <p> <code>x-amz-copy-source-if-none-match</code> </p> </li> <li> <p> <code>x-amz-copy-source-if-unmodified-since</code> </p> </li> <li> <p> <code>x-amz-copy-source-if-modified-since</code> </p> </li> </ul> <p> If both the <code>x-amz-copy-source-if-match</code> and <code>x-amz-copy-source-if-unmodified-since</code> headers are present in the request and evaluate as follows, Amazon S3 returns <code>200 OK</code> and copies the data:</p> <ul> <li> <p> <code>x-amz-copy-source-if-match</code> condition evaluates to true</p> </li> <li> <p> <code>x-amz-copy-source-if-unmodified-since</code> condition evaluates to false</p> </li> </ul> <p>If both the <code>x-amz-copy-source-if-none-match</code> and <code>x-amz-copy-source-if-modified-since</code> headers are present in the request and evaluate as follows, Amazon S3 returns the <code>412 Precondition Failed</code> response code:</p> <ul> <li> <p> <code>x-amz-copy-source-if-none-match</code> condition evaluates to false</p> </li> <li> <p> <code>x-amz-copy-source-if-modified-since</code> condition evaluates to true</p> </li> </ul> <note> <p>All headers with the <code>x-amz-</code> prefix, including <code>x-amz-copy-source</code>, must be signed.</p> </note> <p> <b>Server-side encryption</b> </p> <p>When you perform a CopyObject operation, you can optionally use the appropriate encryption-related headers to encrypt the object using server-side encryption with Amazon Web Services managed encryption keys (SSE-S3 or SSE-KMS) or a customer-provided encryption key. With server-side encryption, Amazon S3 encrypts your data as it writes it to disks in its data centers and decrypts the data when you access it. For more information about server-side encryption, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html">Using Server-Side Encryption</a>.</p> <p>If a target object uses SSE-KMS, you can enable an S3 Bucket Key for the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-key.html">Amazon S3 Bucket Keys</a> in the <i>Amazon S3 User Guide</i>.</p> <p> <b>Access Control List (ACL)-Specific Request Headers</b> </p> <p>When copying an object, you can optionally use headers to grant ACL-based permissions. By default, all objects are private. Only the owner has full access control. When adding a new object, you can grant permissions to individual Amazon Web Services accounts or to predefined groups defined by Amazon S3. These permissions are then added to the ACL on the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html">Access Control List (ACL) Overview</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-using-rest-api.html">Managing ACLs Using the REST API</a>. </p> <p>If the bucket that you're copying objects to uses the bucket owner enforced setting for S3 Object Ownership, ACLs are disabled and no longer affect permissions. Buckets that use this setting only accept PUT requests that don't specify an ACL or PUT requests that specify bucket owner full control ACLs, such as the <code>bucket-owner-full-control</code> canned ACL or an equivalent form of this ACL expressed in the XML format.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html"> Controlling ownership of objects and disabling ACLs</a> in the <i>Amazon S3 User Guide</i>.</p> <note> <p>If your bucket uses the bucket owner enforced setting for Object Ownership, all objects written to the bucket by any account will be owned by the bucket owner.</p> </note> <p> <b>Checksums</b> </p> <p>When copying an object, if it has a checksum, that checksum will be copied to the new object by default. When you copy the object over, you may optionally specify a different checksum algorithm to use with the <code>x-amz-checksum-algorithm</code> header.</p> <p> <b>Storage Class Options</b> </p> <p>You can use the <code>CopyObject</code> action to change the storage class of an object that is already stored in Amazon S3 using the <code>StorageClass</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html">Storage Classes</a> in the <i>Amazon S3 User Guide</i>.</p> <p> <b>Versioning</b> </p> <p>By default, <code>x-amz-copy-source</code> identifies the current version of an object to copy. If the current version is a delete marker, Amazon S3 behaves as if the object was deleted. To copy a different version, use the <code>versionId</code> subresource.</p> <p>If you enable versioning on the target bucket, Amazon S3 generates a unique version ID for the object being copied. This version ID is different from the version ID of the source object. Amazon S3 returns the version ID of the copied object in the <code>x-amz-version-id</code> response header in the response.</p> <p>If you do not enable versioning or suspend it on the target bucket, the version ID that Amazon S3 generates is always null.</p> <p>If the source object's storage class is GLACIER, you must restore a copy of this object before you can use it as a source object for the copy operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html">RestoreObject</a>.</p> <p>The following operations are related to <code>CopyObject</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html">PutObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/CopyingObjectsExamples.html">Copying Objects</a>.</p>
#
# PUT /{Bucket}/{Key}#x-amz-copy-source
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
# operationId: CopyObject
export def "api CopyObject" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-amz-security-token: string
  --x-amz-acl: string@x-amz-acl-completer # <p>The canned ACL to apply to the object.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --Cache-Control: string # Specifies caching behavior along the request/reply chain.
  --x-amz-checksum-algorithm: string@x-amz-checksum-algorithm-completer # Indicates the algorithm you want Amazon S3 to use to create the checksum for the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --Content-Disposition: string # Specifies presentational information for the object.
  --Content-Encoding: string # Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field.
  --Content-Language: string # The language the content is in.
  --Content-Type: string # A standard MIME type describing the format of the object data.
  --x-amz-copy-source: string # <p>Specifies the source object for the copy operation. You specify the value in one of two formats, depending on whether you want to access the source object through an <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html">access point</a>:</p> <ul> <li> <p>For objects not accessed through an access point, specify the name of the source bucket and the key of the source object, separated by a slash (/). For example, to copy the object <code>reports/january.pdf</code> from the bucket <code>awsexamplebucket</code>, use <code>awsexamplebucket/reports/january.pdf</code>. The value must be URL-encoded.</p> </li> <li> <p>For objects accessed through access points, specify the Amazon Resource Name (ARN) of the object as accessed through the access point, in the format <code>arn:aws:s3:&lt;Region&gt;:&lt;account-id&gt;:accesspoint/&lt;access-point-name&gt;/object/&lt;key&gt;</code>. For example, to copy the object <code>reports/january.pdf</code> through access point <code>my-access-point</code> owned by account <code>123456789012</code> in Region <code>us-west-2</code>, use the URL encoding of <code>arn:aws:s3:us-west-2:123456789012:accesspoint/my-access-point/object/reports/january.pdf</code>. The value must be URL encoded.</p> <note> <p>Amazon S3 supports copy operations using access points only when the source and destination buckets are in the same Amazon Web Services Region.</p> </note> <p>Alternatively, for objects accessed through Amazon S3 on Outposts, specify the ARN of the object as accessed in the format <code>arn:aws:s3-outposts:&lt;Region&gt;:&lt;account-id&gt;:outpost/&lt;outpost-id&gt;/object/&lt;key&gt;</code>. For example, to copy the object <code>reports/january.pdf</code> through outpost <code>my-outpost</code> owned by account <code>123456789012</code> in Region <code>us-west-2</code>, use the URL encoding of <code>arn:aws:s3-outposts:us-west-2:123456789012:outpost/my-outpost/object/reports/january.pdf</code>. The value must be URL-encoded. </p> </li> </ul> <p>To copy a specific version of an object, append <code>?versionId=&lt;version-id&gt;</code> to the value (for example, <code>awsexamplebucket/reports/january.pdf?versionId=QUpfdndhfd8438MNFDN93jdnJFkdmqnh893</code>). If you don't specify a version ID, Amazon S3 copies the latest version of the source object.</p>
  --x-amz-copy-source-if-match: string # Copies the object if its entity tag (ETag) matches the specified tag.
  --x-amz-copy-source-if-modified-since: string # Copies the object if it has been modified since the specified time.
  --x-amz-copy-source-if-none-match: string # Copies the object if its entity tag (ETag) is different than the specified ETag.
  --x-amz-copy-source-if-unmodified-since: string # Copies the object if it hasn't been modified since the specified time.
  --Expires: string # The date and time at which the object is no longer cacheable.
  --x-amz-grant-full-control: string # <p>Gives the grantee READ, READ_ACP, and WRITE_ACP permissions on the object.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-read: string # <p>Allows grantee to read the object data and its metadata.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-read-acp: string # <p>Allows grantee to read the object ACL.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-write-acp: string # <p>Allows grantee to write the ACL for the applicable object.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-metadata-directive: string@x-amz-metadata-directive-completer # Specifies whether the metadata is copied from the source object or replaced with metadata provided in the request.
  --x-amz-tagging-directive: string@x-amz-tagging-directive-completer # Specifies whether the object tag-set are copied from the source object or replaced with tag-set provided in the request.
  --x-amz-server-side-encryption: string@x-amz-server-side-encryption-completer # The server-side encryption algorithm used when storing this object in Amazon S3 (for example, AES256, aws:kms).
  --x-amz-storage-class: string@x-amz-storage-class-completer # By default, Amazon S3 uses the STANDARD Storage Class to store newly created objects. The STANDARD storage class provides high durability and high availability. Depending on performance needs, you can specify a different Storage Class. Amazon S3 on Outposts only uses the OUTPOSTS Storage Class. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html">Storage Classes</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-website-redirect-location: string # If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata.
  --x-amz-server-side-encryption-customer-algorithm: string # Specifies the algorithm to use to when encrypting the object (for example, AES256).
  --x-amz-server-side-encryption-customer-key: string # Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon S3 does not store the encryption key. The key must be appropriate for use with the algorithm specified in the <code>x-amz-server-side-encryption-customer-algorithm</code> header.
  --x-amz-server-side-encryption-customer-key-MD5: string # Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
  --x-amz-server-side-encryption-aws-kms-key-id: string # Specifies the Amazon Web Services KMS key ID to use for object encryption. All GET and PUT requests for an object protected by Amazon Web Services KMS will fail if not made via SSL or using SigV4. For information about configuring using any of the officially supported Amazon Web Services SDKs and Amazon Web Services CLI, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version">Specifying the Signature Version in Request Authentication</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-server-side-encryption-context: string # Specifies the Amazon Web Services KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs.
  --x-amz-server-side-encryption-bucket-key-enabled: string@bool-completer # <p>Specifies whether Amazon S3 should use an S3 Bucket Key for object encryption with server-side encryption using AWS KMS (SSE-KMS). Setting this header to <code>true</code> causes Amazon S3 to use an S3 Bucket Key for object encryption with SSE-KMS. </p> <p>Specifying this header with a COPY action doesn’t affect bucket-level settings for S3 Bucket Key.</p>
  --x-amz-copy-source-server-side-encryption-customer-algorithm: string # Specifies the algorithm to use when decrypting the source object (for example, AES256).
  --x-amz-copy-source-server-side-encryption-customer-key: string # Specifies the customer-provided encryption key for Amazon S3 to use to decrypt the source object. The encryption key provided in this header must be one that was used when the source object was created.
  --x-amz-copy-source-server-side-encryption-customer-key-MD5: string # Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-tagging: string # The tag-set for the object destination object this value must be used in conjunction with the <code>TaggingDirective</code>. The tag-set must be encoded as URL Query parameters.
  --x-amz-object-lock-mode: string@x-amz-object-lock-mode-completer # The Object Lock mode that you want to apply to the copied object.
  --x-amz-object-lock-retain-until-date: string # The date and time when you want the copied object's Object Lock to expire.
  --x-amz-object-lock-legal-hold: string@x-amz-object-lock-legal-hold-completer # Specifies whether you want to apply a legal hold to the copied object.
  --x-amz-expected-bucket-owner: string # The account ID of the expected destination bucket owner. If the destination bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-source-expected-bucket-owner: string # The account ID of the expected source bucket owner. If the source bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($Bucket)/($Key)#x-amz-copy-source")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-acl": $x_amz_acl, "Cache-Control": $Cache_Control, "x-amz-checksum-algorithm": $x_amz_checksum_algorithm, "Content-Disposition": $Content_Disposition, "Content-Encoding": $Content_Encoding, "Content-Language": $Content_Language, "Content-Type": $Content_Type, "x-amz-copy-source": $x_amz_copy_source, "x-amz-copy-source-if-match": $x_amz_copy_source_if_match, "x-amz-copy-source-if-modified-since": $x_amz_copy_source_if_modified_since, "x-amz-copy-source-if-none-match": $x_amz_copy_source_if_none_match, "x-amz-copy-source-if-unmodified-since": $x_amz_copy_source_if_unmodified_since, "Expires": $Expires, "x-amz-grant-full-control": $x_amz_grant_full_control, "x-amz-grant-read": $x_amz_grant_read, "x-amz-grant-read-acp": $x_amz_grant_read_acp, "x-amz-grant-write-acp": $x_amz_grant_write_acp, "x-amz-metadata-directive": $x_amz_metadata_directive, "x-amz-tagging-directive": $x_amz_tagging_directive, "x-amz-server-side-encryption": $x_amz_server_side_encryption, "x-amz-storage-class": $x_amz_storage_class, "x-amz-website-redirect-location": $x_amz_website_redirect_location, "x-amz-server-side-encryption-customer-algorithm": $x_amz_server_side_encryption_customer_algorithm, "x-amz-server-side-encryption-customer-key": $x_amz_server_side_encryption_customer_key, "x-amz-server-side-encryption-customer-key-MD5": $x_amz_server_side_encryption_customer_key_MD5, "x-amz-server-side-encryption-aws-kms-key-id": $x_amz_server_side_encryption_aws_kms_key_id, "x-amz-server-side-encryption-context": $x_amz_server_side_encryption_context, "x-amz-server-side-encryption-bucket-key-enabled": $x_amz_server_side_encryption_bucket_key_enabled, "x-amz-copy-source-server-side-encryption-customer-algorithm": $x_amz_copy_source_server_side_encryption_customer_algorithm, "x-amz-copy-source-server-side-encryption-customer-key": $x_amz_copy_source_server_side_encryption_customer_key, "x-amz-copy-source-server-side-encryption-customer-key-MD5": $x_amz_copy_source_server_side_encryption_customer_key_MD5, "x-amz-request-payer": $x_amz_request_payer, "x-amz-tagging": $x_amz_tagging, "x-amz-object-lock-mode": $x_amz_object_lock_mode, "x-amz-object-lock-retain-until-date": $x_amz_object_lock_retain_until_date, "x-amz-object-lock-legal-hold": $x_amz_object_lock_legal_hold, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-source-expected-bucket-owner": $x_amz_source_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Creates a new S3 bucket. To create a bucket, you must register with Amazon S3 and have a valid Amazon Web Services Access Key ID to authenticate requests. Anonymous requests are never allowed to create buckets. By creating the bucket, you become the bucket owner.</p> <p>Not every string is an acceptable bucket name. For information about bucket naming restrictions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html">Bucket naming rules</a>.</p> <p>If you want to create an Amazon S3 on Outposts bucket, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateBucket.html">Create Bucket</a>. </p> <p>By default, the bucket is created in the US East (N. Virginia) Region. You can optionally specify a Region in the request body. You might choose a Region to optimize latency, minimize costs, or address regulatory requirements. For example, if you reside in Europe, you will probably find it advantageous to create buckets in the Europe (Ireland) Region. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html#access-bucket-intro">Accessing a bucket</a>.</p> <note> <p>If you send your create bucket request to the <code>s3.amazonaws.com</code> endpoint, the request goes to the us-east-1 Region. Accordingly, the signature calculations in Signature Version 4 must use us-east-1 as the Region, even if the location constraint in the request specifies another Region where the bucket is to be created. If you create a bucket in a Region other than US East (N. Virginia), your application must be able to handle 307 redirect. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/VirtualHosting.html">Virtual hosting of buckets</a>.</p> </note> <p> <b>Access control lists (ACLs)</b> </p> <p>When creating a bucket using this operation, you can optionally configure the bucket ACL to specify the accounts or groups that should be granted specific permissions on the bucket.</p> <important> <p>If your CreateBucket request sets bucket owner enforced for S3 Object Ownership and specifies a bucket ACL that provides access to an external Amazon Web Services account, your request fails with a <code>400</code> error and returns the <code>InvalidBucketAclWithObjectOwnership</code> error code. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html">Controlling object ownership</a> in the <i>Amazon S3 User Guide</i>.</p> </important> <p>There are two ways to grant the appropriate permissions using the request headers.</p> <ul> <li> <p>Specify a canned ACL using the <code>x-amz-acl</code> request header. Amazon S3 supports a set of predefined ACLs, known as <i>canned ACLs</i>. Each canned ACL has a predefined set of grantees and permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL">Canned ACL</a>.</p> </li> <li> <p>Specify access permissions explicitly using the <code>x-amz-grant-read</code>, <code>x-amz-grant-write</code>, <code>x-amz-grant-read-acp</code>, <code>x-amz-grant-write-acp</code>, and <code>x-amz-grant-full-control</code> headers. These headers map to the set of permissions Amazon S3 supports in an ACL. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html">Access control list (ACL) overview</a>.</p> <p>You specify each grantee as a type=value pair, where the type is one of the following:</p> <ul> <li> <p> <code>id</code> – if the value specified is the canonical user ID of an Amazon Web Services account</p> </li> <li> <p> <code>uri</code> – if you are granting permissions to a predefined group</p> </li> <li> <p> <code>emailAddress</code> – if the value specified is the email address of an Amazon Web Services account</p> <note> <p>Using email addresses to specify a grantee is only supported in the following Amazon Web Services Regions: </p> <ul> <li> <p>US East (N. Virginia)</p> </li> <li> <p>US West (N. California)</p> </li> <li> <p> US West (Oregon)</p> </li> <li> <p> Asia Pacific (Singapore)</p> </li> <li> <p>Asia Pacific (Sydney)</p> </li> <li> <p>Asia Pacific (Tokyo)</p> </li> <li> <p>Europe (Ireland)</p> </li> <li> <p>South America (São Paulo)</p> </li> </ul> <p>For a list of all the Amazon S3 supported Regions and endpoints, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region">Regions and Endpoints</a> in the Amazon Web Services General Reference.</p> </note> </li> </ul> <p>For example, the following <code>x-amz-grant-read</code> header grants the Amazon Web Services accounts identified by account IDs permissions to read object data and its metadata:</p> <p> <code>x-amz-grant-read: id="11112222333", id="444455556666" </code> </p> </li> </ul> <note> <p>You can use either a canned ACL or specify access permissions explicitly. You cannot do both.</p> </note> <p> <b>Permissions</b> </p> <p>In addition to <code>s3:CreateBucket</code>, the following permissions are required when your CreateBucket includes specific headers:</p> <ul> <li> <p> <b>ACLs</b> - If your <code>CreateBucket</code> request specifies ACL permissions and the ACL is public-read, public-read-write, authenticated-read, or if you specify access permissions explicitly through any other ACL, both <code>s3:CreateBucket</code> and <code>s3:PutBucketAcl</code> permissions are needed. If the ACL the <code>CreateBucket</code> request is private or doesn't specify any ACLs, only <code>s3:CreateBucket</code> permission is needed. </p> </li> <li> <p> <b>Object Lock</b> - If <code>ObjectLockEnabledForBucket</code> is set to true in your <code>CreateBucket</code> request, <code>s3:PutBucketObjectLockConfiguration</code> and <code>s3:PutBucketVersioning</code> permissions are required.</p> </li> <li> <p> <b>S3 Object Ownership</b> - If your CreateBucket request includes the the <code>x-amz-object-ownership</code> header, <code>s3:PutBucketOwnershipControls</code> permission is required.</p> </li> </ul> <p>The following operations are related to <code>CreateBucket</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html">PutObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html">DeleteBucket</a> </p> </li> </ul>
#
# PUT /{Bucket}
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUT.html
# operationId: CreateBucket
export def "api CreateBucket" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-amz-security-token: string
  --x-amz-acl: string@x-amz-acl-completer-1 # The canned ACL to apply to the bucket.
  --x-amz-grant-full-control: string # Allows grantee the read, write, read ACP, and write ACP permissions on the bucket.
  --x-amz-grant-read: string # Allows grantee to list the objects in the bucket.
  --x-amz-grant-read-acp: string # Allows grantee to read the bucket ACL.
  --x-amz-grant-write: string # <p>Allows grantee to create new objects in the bucket.</p> <p>For the bucket and object owners of existing objects, also allows deletions and overwrites of those objects.</p>
  --x-amz-grant-write-acp: string # Allows grantee to write the ACL for the applicable bucket.
  --x-amz-bucket-object-lock-enabled: string@bool-completer # Specifies whether you want S3 Object Lock to be enabled for the new bucket.
  --x-amz-object-ownership: string@x-amz-object-ownership-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($Bucket)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-acl": $x_amz_acl, "x-amz-grant-full-control": $x_amz_grant_full_control, "x-amz-grant-read": $x_amz_grant_read, "x-amz-grant-read-acp": $x_amz_grant_read_acp, "x-amz-grant-write": $x_amz_grant_write, "x-amz-grant-write-acp": $x_amz_grant_write_acp, "x-amz-bucket-object-lock-enabled": $x_amz_bucket_object_lock_enabled, "x-amz-object-ownership": $x_amz_object_ownership} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Deletes the S3 bucket. All objects (including all object versions and delete markers) in the bucket must be deleted before the bucket itself can be deleted.</p> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html">DeleteObject</a> </p> </li> </ul>
#
# DELETE /{Bucket}
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETE.html
# operationId: DeleteBucket
export def "api DeleteBucket" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($Bucket)")
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>This action is useful to determine if a bucket exists and you have permission to access it. The action returns a <code>200 OK</code> if the bucket exists and you have permission to access it.</p> <p>If the bucket does not exist or you do not have permission to access it, the <code>HEAD</code> request returns a generic <code>404 Not Found</code> or <code>403 Forbidden</code> code. A message body is not included, so you cannot determine the exception beyond these error codes.</p> <p>To use this operation, you must have permissions to perform the <code>s3:ListBucket</code> action. The bucket owner has this permission by default and can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>To use this API against an access point, you must provide the alias of the access point in place of the bucket name or specify the access point ARN. When using the access point ARN, you must direct requests to the access point hostname. The access point hostname takes the form AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com. When using the Amazon Web Services SDKs, you provide the ARN in place of the bucket name. For more information see, <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html">Using access points</a>.</p>
#
# HEAD /{Bucket}
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketHEAD.html
# operationId: HeadBucket
export def "api HeadBucket" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($Bucket)")
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns some or all (up to 1,000) of the objects in a bucket. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. A 200 OK response can contain valid or invalid XML. Be sure to design your application to parse the contents of the response and handle it appropriately.</p> <important> <p>This action has been revised. We recommend that you use the newer version, <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjectsV2.html">ListObjectsV2</a>, when developing applications. For backward compatibility, Amazon S3 continues to support <code>ListObjects</code>.</p> </important> <p>The following operations are related to <code>ListObjects</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjectsV2.html">ListObjectsV2</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html">PutObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBuckets.html">ListBuckets</a> </p> </li> </ul>
#
# GET /{Bucket}
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGET.html
# operationId: ListObjects
export def "api ListObjects" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delimiter: string # A delimiter is a character you use to group keys.
  --encoding-type: string@encoding-type-completer
  --marker: string # Marker is where you want Amazon S3 to start listing from. Amazon S3 starts listing after this specified key. Marker can be any key in the bucket.
  --max-keys: int # Sets the maximum number of keys returned in the response. By default the action returns up to 1,000 key names. The response might contain fewer keys but will never contain more. 
  --prefix: string # Limits the response to keys that begin with the specified prefix.
  --MaxKeys: string # Pagination limit
  --Marker: string # Pagination token
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer # Confirms that the requester knows that she or he will be charged for the list objects request. Bucket owners need not specify this parameter in their requests.
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "encoding-type" $encoding_type "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "max-keys" $max_keys "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "MaxKeys" $MaxKeys "scalar") (serialize-qp "Marker" $Marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>This action initiates a multipart upload and returns an upload ID. This upload ID is used to associate all of the parts in the specific multipart upload. You specify this upload ID in each of your subsequent upload part requests (see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a>). You also include this upload ID in the final request to either complete or abort the multipart upload request.</p> <p>For more information about multipart uploads, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html">Multipart Upload Overview</a>.</p> <p>If you have configured a lifecycle rule to abort incomplete multipart uploads, the upload must complete within the number of days specified in the bucket lifecycle configuration. Otherwise, the incomplete multipart upload becomes eligible for an abort action and Amazon S3 aborts the multipart upload. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config">Aborting Incomplete Multipart Uploads Using a Bucket Lifecycle Policy</a>.</p> <p>For information about the permissions required to use the multipart upload API, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html">Multipart Upload and Permissions</a>.</p> <p>For request signing, multipart upload is just a series of regular requests. You initiate a multipart upload, send one or more requests to upload parts, and then complete the multipart upload process. You sign each request individually. There is nothing special about signing multipart upload requests. For more information about signing, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html">Authenticating Requests (Amazon Web Services Signature Version 4)</a>.</p> <note> <p> After you initiate a multipart upload and upload one or more parts, to stop being charged for storing the uploaded parts, you must either complete or abort the multipart upload. Amazon S3 frees up the space used to store the parts and stop charging you for storing them only after you either complete or abort a multipart upload. </p> </note> <p>You can optionally request server-side encryption. For server-side encryption, Amazon S3 encrypts your data as it writes it to disks in its data centers and decrypts it when you access it. You can provide your own encryption key, or use Amazon Web Services KMS keys or Amazon S3-managed encryption keys. If you choose to provide your own encryption key, the request headers you provide in <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html">UploadPartCopy</a> requests must match the headers you used in the request to initiate the upload by using <code>CreateMultipartUpload</code>. </p> <p>To perform a multipart upload with encryption using an Amazon Web Services KMS key, the requester must have permission to the <code>kms:Decrypt</code> and <code>kms:GenerateDataKey*</code> actions on the key. These permissions are required because Amazon S3 must decrypt and read data from the encrypted file parts before it completes the multipart upload. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/mpuoverview.html#mpuAndPermissions">Multipart upload API and permissions</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If your Identity and Access Management (IAM) user or role is in the same Amazon Web Services account as the KMS key, then you must have these permissions on the key policy. If your IAM user or role belongs to a different account than the key, then you must have the permissions on both the key policy and your IAM user or role.</p> <p> For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html">Protecting Data Using Server-Side Encryption</a>.</p> <dl> <dt>Access Permissions</dt> <dd> <p>When copying an object, you can optionally specify the accounts or groups that should be granted specific permissions on the new object. There are two ways to grant the permissions using the request headers:</p> <ul> <li> <p>Specify a canned ACL with the <code>x-amz-acl</code> request header. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL">Canned ACL</a>.</p> </li> <li> <p>Specify access permissions explicitly with the <code>x-amz-grant-read</code>, <code>x-amz-grant-read-acp</code>, <code>x-amz-grant-write-acp</code>, and <code>x-amz-grant-full-control</code> headers. These parameters map to the set of permissions that Amazon S3 supports in an ACL. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html">Access Control List (ACL) Overview</a>.</p> </li> </ul> <p>You can use either a canned ACL or specify access permissions explicitly. You cannot do both.</p> </dd> <dt>Server-Side- Encryption-Specific Request Headers</dt> <dd> <p>You can optionally tell Amazon S3 to encrypt data at rest using server-side encryption. Server-side encryption is for data encryption at rest. Amazon S3 encrypts your data as it writes it to disks in its data centers and decrypts it when you access it. The option you use depends on whether you want to use Amazon Web Services managed encryption keys or provide your own encryption key. </p> <ul> <li> <p>Use encryption keys managed by Amazon S3 or customer managed key stored in Amazon Web Services Key Management Service (Amazon Web Services KMS) – If you want Amazon Web Services to manage the keys used to encrypt data, specify the following headers in the request.</p> <ul> <li> <p> <code>x-amz-server-side-encryption</code> </p> </li> <li> <p> <code>x-amz-server-side-encryption-aws-kms-key-id</code> </p> </li> <li> <p> <code>x-amz-server-side-encryption-context</code> </p> </li> </ul> <note> <p>If you specify <code>x-amz-server-side-encryption:aws:kms</code>, but don't provide <code>x-amz-server-side-encryption-aws-kms-key-id</code>, Amazon S3 uses the Amazon Web Services managed key in Amazon Web Services KMS to protect the data.</p> </note> <important> <p>All GET and PUT requests for an object protected by Amazon Web Services KMS fail if you don't make them with SSL or by using SigV4.</p> </important> <p>For more information about server-side encryption with KMS key (SSE-KMS), see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingKMSEncryption.html">Protecting Data Using Server-Side Encryption with KMS keys</a>.</p> </li> <li> <p>Use customer-provided encryption keys – If you want to manage your own encryption keys, provide all the following headers in the request.</p> <ul> <li> <p> <code>x-amz-server-side-encryption-customer-algorithm</code> </p> </li> <li> <p> <code>x-amz-server-side-encryption-customer-key</code> </p> </li> <li> <p> <code>x-amz-server-side-encryption-customer-key-MD5</code> </p> </li> </ul> <p>For more information about server-side encryption with KMS keys (SSE-KMS), see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingKMSEncryption.html">Protecting Data Using Server-Side Encryption with KMS keys</a>.</p> </li> </ul> </dd> <dt>Access-Control-List (ACL)-Specific Request Headers</dt> <dd> <p>You also can use the following access control–related headers with this operation. By default, all objects are private. Only the owner has full access control. When adding a new object, you can grant permissions to individual Amazon Web Services accounts or to predefined groups defined by Amazon S3. These permissions are then added to the access control list (ACL) on the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_ACLs_UsingACLs.html">Using ACLs</a>. With this operation, you can grant access permissions using one of the following two methods:</p> <ul> <li> <p>Specify a canned ACL (<code>x-amz-acl</code>) — Amazon S3 supports a set of predefined ACLs, known as <i>canned ACLs</i>. Each canned ACL has a predefined set of grantees and permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL">Canned ACL</a>.</p> </li> <li> <p>Specify access permissions explicitly — To explicitly grant access permissions to specific Amazon Web Services accounts or groups, use the following headers. Each header maps to specific permissions that Amazon S3 supports in an ACL. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html">Access Control List (ACL) Overview</a>. In the header, you specify a list of grantees who get the specific permission. To grant permissions explicitly, use:</p> <ul> <li> <p> <code>x-amz-grant-read</code> </p> </li> <li> <p> <code>x-amz-grant-write</code> </p> </li> <li> <p> <code>x-amz-grant-read-acp</code> </p> </li> <li> <p> <code>x-amz-grant-write-acp</code> </p> </li> <li> <p> <code>x-amz-grant-full-control</code> </p> </li> </ul> <p>You specify each grantee as a type=value pair, where the type is one of the following:</p> <ul> <li> <p> <code>id</code> – if the value specified is the canonical user ID of an Amazon Web Services account</p> </li> <li> <p> <code>uri</code> – if you are granting permissions to a predefined group</p> </li> <li> <p> <code>emailAddress</code> – if the value specified is the email address of an Amazon Web Services account</p> <note> <p>Using email addresses to specify a grantee is only supported in the following Amazon Web Services Regions: </p> <ul> <li> <p>US East (N. Virginia)</p> </li> <li> <p>US West (N. California)</p> </li> <li> <p> US West (Oregon)</p> </li> <li> <p> Asia Pacific (Singapore)</p> </li> <li> <p>Asia Pacific (Sydney)</p> </li> <li> <p>Asia Pacific (Tokyo)</p> </li> <li> <p>Europe (Ireland)</p> </li> <li> <p>South America (São Paulo)</p> </li> </ul> <p>For a list of all the Amazon S3 supported Regions and endpoints, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region">Regions and Endpoints</a> in the Amazon Web Services General Reference.</p> </note> </li> </ul> <p>For example, the following <code>x-amz-grant-read</code> header grants the Amazon Web Services accounts identified by account IDs permissions to read object data and its metadata:</p> <p> <code>x-amz-grant-read: id="11112222333", id="444455556666" </code> </p> </li> </ul> </dd> </dl> <p>The following operations are related to <code>CreateMultipartUpload</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html">CompleteMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html">AbortMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html">ListParts</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html">ListMultipartUploads</a> </p> </li> </ul>
#
# POST /{Bucket}/{Key}#uploads
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html
# operationId: CreateMultipartUpload
export def "api CreateMultipartUpload" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uploads: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-acl: string@x-amz-acl-completer # <p>The canned ACL to apply to the object.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --Cache-Control: string # Specifies caching behavior along the request/reply chain.
  --Content-Disposition: string # Specifies presentational information for the object.
  --Content-Encoding: string # Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field.
  --Content-Language: string # The language the content is in.
  --Content-Type: string # A standard MIME type describing the format of the object data.
  --Expires: string # The date and time at which the object is no longer cacheable.
  --x-amz-grant-full-control: string # <p>Gives the grantee READ, READ_ACP, and WRITE_ACP permissions on the object.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-read: string # <p>Allows grantee to read the object data and its metadata.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-read-acp: string # <p>Allows grantee to read the object ACL.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-write-acp: string # <p>Allows grantee to write the ACL for the applicable object.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-server-side-encryption: string@x-amz-server-side-encryption-completer # The server-side encryption algorithm used when storing this object in Amazon S3 (for example, AES256, aws:kms).
  --x-amz-storage-class: string@x-amz-storage-class-completer # By default, Amazon S3 uses the STANDARD Storage Class to store newly created objects. The STANDARD storage class provides high durability and high availability. Depending on performance needs, you can specify a different Storage Class. Amazon S3 on Outposts only uses the OUTPOSTS Storage Class. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html">Storage Classes</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-website-redirect-location: string # If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata.
  --x-amz-server-side-encryption-customer-algorithm: string # Specifies the algorithm to use to when encrypting the object (for example, AES256).
  --x-amz-server-side-encryption-customer-key: string # Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon S3 does not store the encryption key. The key must be appropriate for use with the algorithm specified in the <code>x-amz-server-side-encryption-customer-algorithm</code> header.
  --x-amz-server-side-encryption-customer-key-MD5: string # Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
  --x-amz-server-side-encryption-aws-kms-key-id: string # Specifies the ID of the symmetric customer managed key to use for object encryption. All GET and PUT requests for an object protected by Amazon Web Services KMS will fail if not made via SSL or using SigV4. For information about configuring using any of the officially supported Amazon Web Services SDKs and Amazon Web Services CLI, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version">Specifying the Signature Version in Request Authentication</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-server-side-encryption-context: string # Specifies the Amazon Web Services KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs.
  --x-amz-server-side-encryption-bucket-key-enabled: string@bool-completer # <p>Specifies whether Amazon S3 should use an S3 Bucket Key for object encryption with server-side encryption using AWS KMS (SSE-KMS). Setting this header to <code>true</code> causes Amazon S3 to use an S3 Bucket Key for object encryption with SSE-KMS.</p> <p>Specifying this header with an object action doesn’t affect bucket-level settings for S3 Bucket Key.</p>
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-tagging: string # The tag-set for the object. The tag-set must be encoded as URL Query parameters.
  --x-amz-object-lock-mode: string@x-amz-object-lock-mode-completer # Specifies the Object Lock mode that you want to apply to the uploaded object.
  --x-amz-object-lock-retain-until-date: string # Specifies the date and time when you want the Object Lock to expire.
  --x-amz-object-lock-legal-hold: string@x-amz-object-lock-legal-hold-completer # Specifies whether you want to apply a legal hold to the uploaded object.
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-checksum-algorithm: string@x-amz-checksum-algorithm-completer # Indicates the algorithm you want Amazon S3 to use to create the checksum for the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uploads" $uploads "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#uploads" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-acl": $x_amz_acl, "Cache-Control": $Cache_Control, "Content-Disposition": $Content_Disposition, "Content-Encoding": $Content_Encoding, "Content-Language": $Content_Language, "Content-Type": $Content_Type, "Expires": $Expires, "x-amz-grant-full-control": $x_amz_grant_full_control, "x-amz-grant-read": $x_amz_grant_read, "x-amz-grant-read-acp": $x_amz_grant_read_acp, "x-amz-grant-write-acp": $x_amz_grant_write_acp, "x-amz-server-side-encryption": $x_amz_server_side_encryption, "x-amz-storage-class": $x_amz_storage_class, "x-amz-website-redirect-location": $x_amz_website_redirect_location, "x-amz-server-side-encryption-customer-algorithm": $x_amz_server_side_encryption_customer_algorithm, "x-amz-server-side-encryption-customer-key": $x_amz_server_side_encryption_customer_key, "x-amz-server-side-encryption-customer-key-MD5": $x_amz_server_side_encryption_customer_key_MD5, "x-amz-server-side-encryption-aws-kms-key-id": $x_amz_server_side_encryption_aws_kms_key_id, "x-amz-server-side-encryption-context": $x_amz_server_side_encryption_context, "x-amz-server-side-encryption-bucket-key-enabled": $x_amz_server_side_encryption_bucket_key_enabled, "x-amz-request-payer": $x_amz_request_payer, "x-amz-tagging": $x_amz_tagging, "x-amz-object-lock-mode": $x_amz_object_lock_mode, "x-amz-object-lock-retain-until-date": $x_amz_object_lock_retain_until_date, "x-amz-object-lock-legal-hold": $x_amz_object_lock_legal_hold, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-checksum-algorithm": $x_amz_checksum_algorithm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Deletes an analytics configuration for the bucket (specified by the analytics configuration ID).</p> <p>To use this operation, you must have permissions to perform the <code>s3:PutAnalyticsConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>For information about the Amazon S3 analytics feature, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/analytics-storage-class.html">Amazon S3 Analytics – Storage Class Analysis</a>. </p> <p>The following operations are related to <code>DeleteBucketAnalyticsConfiguration</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAnalyticsConfiguration.html">GetBucketAnalyticsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketAnalyticsConfigurations.html">ListBucketAnalyticsConfigurations</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketAnalyticsConfiguration.html">PutBucketAnalyticsConfiguration</a> </p> </li> </ul>
#
# DELETE /{Bucket}#analytics&id
# operationId: DeleteBucketAnalyticsConfiguration
export def "api DeleteBucketAnalyticsConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID that identifies the analytics configuration.
  --analytics: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "analytics" $analytics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#analytics&id" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>This implementation of the GET action returns an analytics configuration (identified by the analytics configuration ID) from the bucket.</p> <p>To use this operation, you must have permissions to perform the <code>s3:GetAnalyticsConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources"> Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a> in the <i>Amazon S3 User Guide</i>. </p> <p>For information about Amazon S3 analytics feature, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/analytics-storage-class.html">Amazon S3 Analytics – Storage Class Analysis</a> in the <i>Amazon S3 User Guide</i>.</p> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketAnalyticsConfiguration.html">DeleteBucketAnalyticsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketAnalyticsConfigurations.html">ListBucketAnalyticsConfigurations</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketAnalyticsConfiguration.html">PutBucketAnalyticsConfiguration</a> </p> </li> </ul>
#
# GET /{Bucket}#analytics&id
# operationId: GetBucketAnalyticsConfiguration
export def "api GetBucketAnalyticsConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID that identifies the analytics configuration.
  --analytics: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "analytics" $analytics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#analytics&id" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Sets an analytics configuration for the bucket (specified by the analytics configuration ID). You can have up to 1,000 analytics configurations per bucket.</p> <p>You can choose to have storage class analysis export analysis reports sent to a comma-separated values (CSV) flat file. See the <code>DataExport</code> request element. Reports are updated daily and are based on the object filters that you configure. When selecting data export, you specify a destination bucket and an optional destination prefix where the file is written. You can export the data to a destination bucket in a different account. However, the destination bucket must be in the same Region as the bucket that you are making the PUT analytics configuration to. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/analytics-storage-class.html">Amazon S3 Analytics – Storage Class Analysis</a>. </p> <important> <p>You must create a bucket policy on the destination bucket where the exported file is written to grant permissions to Amazon S3 to write objects to the bucket. For an example policy, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/example-bucket-policies.html#example-bucket-policies-use-case-9">Granting Permissions for Amazon S3 Inventory and Storage Class Analysis</a>.</p> </important> <p>To use this operation, you must have permissions to perform the <code>s3:PutAnalyticsConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p class="title"> <b>Special Errors</b> </p> <ul> <li> <ul> <li> <p> <i>HTTP Error: HTTP 400 Bad Request</i> </p> </li> <li> <p> <i>Code: InvalidArgument</i> </p> </li> <li> <p> <i>Cause: Invalid argument.</i> </p> </li> </ul> </li> <li> <ul> <li> <p> <i>HTTP Error: HTTP 400 Bad Request</i> </p> </li> <li> <p> <i>Code: TooManyConfigurations</i> </p> </li> <li> <p> <i>Cause: You are attempting to create a new configuration but have already reached the 1,000-configuration limit.</i> </p> </li> </ul> </li> <li> <ul> <li> <p> <i>HTTP Error: HTTP 403 Forbidden</i> </p> </li> <li> <p> <i>Code: AccessDenied</i> </p> </li> <li> <p> <i>Cause: You are not the owner of the specified bucket, or you do not have the s3:PutAnalyticsConfiguration bucket permission to set the configuration on the bucket.</i> </p> </li> </ul> </li> </ul> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAnalyticsConfiguration.html">GetBucketAnalyticsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketAnalyticsConfiguration.html">DeleteBucketAnalyticsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketAnalyticsConfigurations.html">ListBucketAnalyticsConfigurations</a> </p> </li> </ul>
#
# PUT /{Bucket}#analytics&id
# operationId: PutBucketAnalyticsConfiguration
export def "api PutBucketAnalyticsConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID that identifies the analytics configuration.
  --analytics: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "analytics" $analytics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#analytics&id" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Deletes the <code>cors</code> configuration information set for the bucket.</p> <p>To use this operation, you must have permission to perform the <code>s3:PutBucketCORS</code> action. The bucket owner has this permission by default and can grant this permission to others. </p> <p>For information about <code>cors</code>, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html">Enabling Cross-Origin Resource Sharing</a> in the <i>Amazon S3 User Guide</i>.</p> <p class="title"> <b>Related Resources:</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketCors.html">PutBucketCors</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/RESTOPTIONSobject.html">RESTOPTIONSobject</a> </p> </li> </ul>
#
# DELETE /{Bucket}#cors
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEcors.html
# operationId: DeleteBucketCors
export def "api DeleteBucketCors" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cors: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cors" $cors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#cors" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns the Cross-Origin Resource Sharing (CORS) configuration information set for the bucket.</p> <p> To use this operation, you must have permission to perform the <code>s3:GetBucketCORS</code> action. By default, the bucket owner has this permission and can grant it to others.</p> <p> For more information about CORS, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html"> Enabling Cross-Origin Resource Sharing</a>.</p> <p>The following operations are related to <code>GetBucketCors</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketCors.html">PutBucketCors</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketCors.html">DeleteBucketCors</a> </p> </li> </ul>
#
# GET /{Bucket}#cors
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETcors.html
# operationId: GetBucketCors
export def "api GetBucketCors" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cors: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cors" $cors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#cors" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Sets the <code>cors</code> configuration for your bucket. If the configuration exists, Amazon S3 replaces it.</p> <p>To use this operation, you must be allowed to perform the <code>s3:PutBucketCORS</code> action. By default, the bucket owner has this permission and can grant it to others.</p> <p>You set this configuration on a bucket so that the bucket can service cross-origin requests. For example, you might want to enable a request whose origin is <code>http://www.example.com</code> to access your Amazon S3 bucket at <code>my.example.bucket.com</code> by using the browser's <code>XMLHttpRequest</code> capability.</p> <p>To enable cross-origin resource sharing (CORS) on a bucket, you add the <code>cors</code> subresource to the bucket. The <code>cors</code> subresource is an XML document in which you configure rules that identify origins and the HTTP methods that can be executed on your bucket. The document is limited to 64 KB in size. </p> <p>When Amazon S3 receives a cross-origin request (or a pre-flight OPTIONS request) against a bucket, it evaluates the <code>cors</code> configuration on the bucket and uses the first <code>CORSRule</code> rule that matches the incoming browser request to enable a cross-origin request. For a rule to match, the following conditions must be met:</p> <ul> <li> <p>The request's <code>Origin</code> header must match <code>AllowedOrigin</code> elements.</p> </li> <li> <p>The request method (for example, GET, PUT, HEAD, and so on) or the <code>Access-Control-Request-Method</code> header in case of a pre-flight <code>OPTIONS</code> request must be one of the <code>AllowedMethod</code> elements. </p> </li> <li> <p>Every header specified in the <code>Access-Control-Request-Headers</code> request header of a pre-flight request must match an <code>AllowedHeader</code> element. </p> </li> </ul> <p> For more information about CORS, go to <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html">Enabling Cross-Origin Resource Sharing</a> in the <i>Amazon S3 User Guide</i>.</p> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketCors.html">GetBucketCors</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketCors.html">DeleteBucketCors</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/RESTOPTIONSobject.html">RESTOPTIONSobject</a> </p> </li> </ul>
#
# PUT /{Bucket}#cors
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTcors.html
# operationId: PutBucketCors
export def "api PutBucketCors" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cors: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The base64-encoded 128-bit MD5 digest of the data. This header must be used as a message integrity check to verify that the request body was not corrupted in transit. For more information, go to <a href="http://www.ietf.org/rfc/rfc1864.txt">RFC 1864.</a> </p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cors" $cors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#cors" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>This implementation of the DELETE action removes default encryption from the bucket. For information about the Amazon S3 default encryption feature, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 Default Bucket Encryption</a> in the <i>Amazon S3 User Guide</i>.</p> <p>To use this operation, you must have permissions to perform the <code>s3:PutEncryptionConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to your Amazon S3 Resources</a> in the <i>Amazon S3 User Guide</i>.</p> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketEncryption.html">PutBucketEncryption</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketEncryption.html">GetBucketEncryption</a> </p> </li> </ul>
#
# DELETE /{Bucket}#encryption
# operationId: DeleteBucketEncryption
export def "api DeleteBucketEncryption" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --encryption: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "encryption" $encryption "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#encryption" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns the default encryption configuration for an Amazon S3 bucket. If the bucket does not have a default encryption configuration, GetBucketEncryption returns <code>ServerSideEncryptionConfigurationNotFoundError</code>. </p> <p>For information about the Amazon S3 default encryption feature, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 Default Bucket Encryption</a>.</p> <p> To use this operation, you must have permission to perform the <code>s3:GetEncryptionConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>The following operations are related to <code>GetBucketEncryption</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketEncryption.html">PutBucketEncryption</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketEncryption.html">DeleteBucketEncryption</a> </p> </li> </ul>
#
# GET /{Bucket}#encryption
# operationId: GetBucketEncryption
export def "api GetBucketEncryption" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --encryption: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "encryption" $encryption "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#encryption" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>This action uses the <code>encryption</code> subresource to configure default encryption and Amazon S3 Bucket Key for an existing bucket.</p> <p>Default encryption for a bucket can use server-side encryption with Amazon S3-managed keys (SSE-S3) or customer managed keys (SSE-KMS). If you specify default encryption using SSE-KMS, you can also configure Amazon S3 Bucket Key. When the default encryption is SSE-KMS, if you upload an object to the bucket and do not specify the KMS key to use for encryption, Amazon S3 uses the default Amazon Web Services managed KMS key for your account. For information about default encryption, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html">Amazon S3 default bucket encryption</a> in the <i>Amazon S3 User Guide</i>. For more information about S3 Bucket Keys, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-key.html">Amazon S3 Bucket Keys</a> in the <i>Amazon S3 User Guide</i>.</p> <important> <p>This action requires Amazon Web Services Signature Version 4. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html"> Authenticating Requests (Amazon Web Services Signature Version 4)</a>. </p> </important> <p>To use this operation, you must have permissions to perform the <code>s3:PutEncryptionConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a> in the Amazon S3 User Guide. </p> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketEncryption.html">GetBucketEncryption</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketEncryption.html">DeleteBucketEncryption</a> </p> </li> </ul>
#
# PUT /{Bucket}#encryption
# operationId: PutBucketEncryption
export def "api PutBucketEncryption" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --encryption: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The base64-encoded 128-bit MD5 digest of the server-side encryption configuration.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "encryption" $encryption "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#encryption" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Deletes the S3 Intelligent-Tiering configuration from the specified bucket.</p> <p>The S3 Intelligent-Tiering storage class is designed to optimize storage costs by automatically moving data to the most cost-effective storage access tier, without performance impact or operational overhead. S3 Intelligent-Tiering delivers automatic cost savings in three low latency and high throughput access tiers. To get the lowest storage cost on data that can be accessed in minutes to hours, you can choose to activate additional archiving capabilities.</p> <p>The S3 Intelligent-Tiering storage class is the ideal storage class for data with unknown, changing, or unpredictable access patterns, independent of object size or retention period. If the size of an object is less than 128 KB, it is not monitored and not eligible for auto-tiering. Smaller objects can be stored, but they are always charged at the Frequent Access tier rates in the S3 Intelligent-Tiering storage class.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-dynamic-data-access">Storage class for automatically optimizing frequently and infrequently accessed objects</a>.</p> <p>Operations related to <code>DeleteBucketIntelligentTieringConfiguration</code> include: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketIntelligentTieringConfiguration.html">GetBucketIntelligentTieringConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketIntelligentTieringConfiguration.html">PutBucketIntelligentTieringConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketIntelligentTieringConfigurations.html">ListBucketIntelligentTieringConfigurations</a> </p> </li> </ul>
#
# DELETE /{Bucket}#intelligent-tiering&id
# operationId: DeleteBucketIntelligentTieringConfiguration
export def "api DeleteBucketIntelligentTieringConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID used to identify the S3 Intelligent-Tiering configuration.
  --intelligent-tiering: string@bool-completer # allows empty value
  --x-amz-security-token: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "intelligent-tiering" $intelligent_tiering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#intelligent-tiering&id" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Gets the S3 Intelligent-Tiering configuration from the specified bucket.</p> <p>The S3 Intelligent-Tiering storage class is designed to optimize storage costs by automatically moving data to the most cost-effective storage access tier, without performance impact or operational overhead. S3 Intelligent-Tiering delivers automatic cost savings in three low latency and high throughput access tiers. To get the lowest storage cost on data that can be accessed in minutes to hours, you can choose to activate additional archiving capabilities.</p> <p>The S3 Intelligent-Tiering storage class is the ideal storage class for data with unknown, changing, or unpredictable access patterns, independent of object size or retention period. If the size of an object is less than 128 KB, it is not monitored and not eligible for auto-tiering. Smaller objects can be stored, but they are always charged at the Frequent Access tier rates in the S3 Intelligent-Tiering storage class.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-dynamic-data-access">Storage class for automatically optimizing frequently and infrequently accessed objects</a>.</p> <p>Operations related to <code>GetBucketIntelligentTieringConfiguration</code> include: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketIntelligentTieringConfiguration.html">DeleteBucketIntelligentTieringConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketIntelligentTieringConfiguration.html">PutBucketIntelligentTieringConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketIntelligentTieringConfigurations.html">ListBucketIntelligentTieringConfigurations</a> </p> </li> </ul>
#
# GET /{Bucket}#intelligent-tiering&id
# operationId: GetBucketIntelligentTieringConfiguration
export def "api GetBucketIntelligentTieringConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID used to identify the S3 Intelligent-Tiering configuration.
  --intelligent-tiering: string@bool-completer # allows empty value
  --x-amz-security-token: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "intelligent-tiering" $intelligent_tiering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#intelligent-tiering&id" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Puts a S3 Intelligent-Tiering configuration to the specified bucket. You can have up to 1,000 S3 Intelligent-Tiering configurations per bucket.</p> <p>The S3 Intelligent-Tiering storage class is designed to optimize storage costs by automatically moving data to the most cost-effective storage access tier, without performance impact or operational overhead. S3 Intelligent-Tiering delivers automatic cost savings in three low latency and high throughput access tiers. To get the lowest storage cost on data that can be accessed in minutes to hours, you can choose to activate additional archiving capabilities.</p> <p>The S3 Intelligent-Tiering storage class is the ideal storage class for data with unknown, changing, or unpredictable access patterns, independent of object size or retention period. If the size of an object is less than 128 KB, it is not monitored and not eligible for auto-tiering. Smaller objects can be stored, but they are always charged at the Frequent Access tier rates in the S3 Intelligent-Tiering storage class.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-dynamic-data-access">Storage class for automatically optimizing frequently and infrequently accessed objects</a>.</p> <p>Operations related to <code>PutBucketIntelligentTieringConfiguration</code> include: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketIntelligentTieringConfiguration.html">DeleteBucketIntelligentTieringConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketIntelligentTieringConfiguration.html">GetBucketIntelligentTieringConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketIntelligentTieringConfigurations.html">ListBucketIntelligentTieringConfigurations</a> </p> </li> </ul> <note> <p>You only need S3 Intelligent-Tiering enabled on a bucket if you want to automatically move objects stored in the S3 Intelligent-Tiering storage class to the Archive Access or Deep Archive Access tier.</p> </note> <p class="title"> <b>Special Errors</b> </p> <ul> <li> <p class="title"> <b>HTTP 400 Bad Request Error</b> </p> <ul> <li> <p> <i>Code:</i> InvalidArgument</p> </li> <li> <p> <i>Cause:</i> Invalid Argument</p> </li> </ul> </li> <li> <p class="title"> <b>HTTP 400 Bad Request Error</b> </p> <ul> <li> <p> <i>Code:</i> TooManyConfigurations</p> </li> <li> <p> <i>Cause:</i> You are attempting to create a new configuration but have already reached the 1,000-configuration limit. </p> </li> </ul> </li> <li> <p class="title"> <b>HTTP 403 Forbidden Error</b> </p> <ul> <li> <p> <i>Code:</i> AccessDenied</p> </li> <li> <p> <i>Cause:</i> You are not the owner of the specified bucket, or you do not have the <code>s3:PutIntelligentTieringConfiguration</code> bucket permission to set the configuration on the bucket. </p> </li> </ul> </li> </ul>
#
# PUT /{Bucket}#intelligent-tiering&id
# operationId: PutBucketIntelligentTieringConfiguration
export def "api PutBucketIntelligentTieringConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID used to identify the S3 Intelligent-Tiering configuration.
  --intelligent-tiering: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "intelligent-tiering" $intelligent_tiering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#intelligent-tiering&id" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Deletes an inventory configuration (identified by the inventory ID) from the bucket.</p> <p>To use this operation, you must have permissions to perform the <code>s3:PutInventoryConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>For information about the Amazon S3 inventory feature, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-inventory.html">Amazon S3 Inventory</a>.</p> <p>Operations related to <code>DeleteBucketInventoryConfiguration</code> include: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketInventoryConfiguration.html">GetBucketInventoryConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketInventoryConfiguration.html">PutBucketInventoryConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketInventoryConfigurations.html">ListBucketInventoryConfigurations</a> </p> </li> </ul>
#
# DELETE /{Bucket}#inventory&id
# operationId: DeleteBucketInventoryConfiguration
export def "api DeleteBucketInventoryConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID used to identify the inventory configuration.
  --inventory: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "inventory" $inventory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#inventory&id" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns an inventory configuration (identified by the inventory configuration ID) from the bucket.</p> <p>To use this operation, you must have permissions to perform the <code>s3:GetInventoryConfiguration</code> action. The bucket owner has this permission by default and can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>For information about the Amazon S3 inventory feature, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-inventory.html">Amazon S3 Inventory</a>.</p> <p>The following operations are related to <code>GetBucketInventoryConfiguration</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketInventoryConfiguration.html">DeleteBucketInventoryConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketInventoryConfigurations.html">ListBucketInventoryConfigurations</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketInventoryConfiguration.html">PutBucketInventoryConfiguration</a> </p> </li> </ul>
#
# GET /{Bucket}#inventory&id
# operationId: GetBucketInventoryConfiguration
export def "api GetBucketInventoryConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID used to identify the inventory configuration.
  --inventory: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "inventory" $inventory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#inventory&id" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>This implementation of the <code>PUT</code> action adds an inventory configuration (identified by the inventory ID) to the bucket. You can have up to 1,000 inventory configurations per bucket. </p> <p>Amazon S3 inventory generates inventories of the objects in the bucket on a daily or weekly basis, and the results are published to a flat file. The bucket that is inventoried is called the <i>source</i> bucket, and the bucket where the inventory flat file is stored is called the <i>destination</i> bucket. The <i>destination</i> bucket must be in the same Amazon Web Services Region as the <i>source</i> bucket. </p> <p>When you configure an inventory for a <i>source</i> bucket, you specify the <i>destination</i> bucket where you want the inventory to be stored, and whether to generate the inventory daily or weekly. You can also configure what object metadata to include and whether to inventory all object versions or only current versions. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-inventory.html">Amazon S3 Inventory</a> in the Amazon S3 User Guide.</p> <important> <p>You must create a bucket policy on the <i>destination</i> bucket to grant permissions to Amazon S3 to write objects to the bucket in the defined location. For an example policy, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/example-bucket-policies.html#example-bucket-policies-use-case-9"> Granting Permissions for Amazon S3 Inventory and Storage Class Analysis</a>.</p> </important> <p>To use this operation, you must have permissions to perform the <code>s3:PutInventoryConfiguration</code> action. The bucket owner has this permission by default and can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a> in the Amazon S3 User Guide.</p> <p class="title"> <b>Special Errors</b> </p> <ul> <li> <p class="title"> <b>HTTP 400 Bad Request Error</b> </p> <ul> <li> <p> <i>Code:</i> InvalidArgument</p> </li> <li> <p> <i>Cause:</i> Invalid Argument</p> </li> </ul> </li> <li> <p class="title"> <b>HTTP 400 Bad Request Error</b> </p> <ul> <li> <p> <i>Code:</i> TooManyConfigurations</p> </li> <li> <p> <i>Cause:</i> You are attempting to create a new configuration but have already reached the 1,000-configuration limit. </p> </li> </ul> </li> <li> <p class="title"> <b>HTTP 403 Forbidden Error</b> </p> <ul> <li> <p> <i>Code:</i> AccessDenied</p> </li> <li> <p> <i>Cause:</i> You are not the owner of the specified bucket, or you do not have the <code>s3:PutInventoryConfiguration</code> bucket permission to set the configuration on the bucket. </p> </li> </ul> </li> </ul> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketInventoryConfiguration.html">GetBucketInventoryConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketInventoryConfiguration.html">DeleteBucketInventoryConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketInventoryConfigurations.html">ListBucketInventoryConfigurations</a> </p> </li> </ul>
#
# PUT /{Bucket}#inventory&id
# operationId: PutBucketInventoryConfiguration
export def "api PutBucketInventoryConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID used to identify the inventory configuration.
  --inventory: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "inventory" $inventory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#inventory&id" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Deletes the lifecycle configuration from the specified bucket. Amazon S3 removes all the lifecycle configuration rules in the lifecycle subresource associated with the bucket. Your objects never expire, and Amazon S3 no longer automatically deletes any objects on the basis of rules contained in the deleted lifecycle configuration.</p> <p>To use this operation, you must have permission to perform the <code>s3:PutLifecycleConfiguration</code> action. By default, the bucket owner has this permission and the bucket owner can grant this permission to others.</p> <p>There is usually some time lag before lifecycle configuration deletion is fully propagated to all the Amazon S3 systems.</p> <p>For more information about the object expiration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#intro-lifecycle-rules-actions">Elements to Describe Lifecycle Actions</a>.</p> <p>Related actions include:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html">PutBucketLifecycleConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html">GetBucketLifecycleConfiguration</a> </p> </li> </ul>
#
# DELETE /{Bucket}#lifecycle
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
# operationId: DeleteBucketLifecycle
export def "api DeleteBucketLifecycle" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lifecycle: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lifecycle" $lifecycle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#lifecycle" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <note> <p>Bucket lifecycle configuration now supports specifying a lifecycle rule using an object key name prefix, one or more object tags, or a combination of both. Accordingly, this section describes the latest API. The response describes the new filter element that you can use to specify a filter to select a subset of objects to which the rule applies. If you are using a previous version of the lifecycle configuration, it still works. For the earlier action, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycle.html">GetBucketLifecycle</a>.</p> </note> <p>Returns the lifecycle configuration information set on the bucket. For information about lifecycle configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html">Object Lifecycle Management</a>.</p> <p>To use this operation, you must have permission to perform the <code>s3:GetLifecycleConfiguration</code> action. The bucket owner has this permission, by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p> <code>GetBucketLifecycleConfiguration</code> has the following special error:</p> <ul> <li> <p>Error code: <code>NoSuchLifecycleConfiguration</code> </p> <ul> <li> <p>Description: The lifecycle configuration does not exist.</p> </li> <li> <p>HTTP Status Code: 404 Not Found</p> </li> <li> <p>SOAP Fault Code Prefix: Client</p> </li> </ul> </li> </ul> <p>The following operations are related to <code>GetBucketLifecycleConfiguration</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycle.html">GetBucketLifecycle</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycle.html">PutBucketLifecycle</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketLifecycle.html">DeleteBucketLifecycle</a> </p> </li> </ul>
#
# GET /{Bucket}#lifecycle
# operationId: GetBucketLifecycleConfiguration
export def "api GetBucketLifecycleConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lifecycle: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lifecycle" $lifecycle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#lifecycle" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Creates a new lifecycle configuration for the bucket or replaces an existing lifecycle configuration. Keep in mind that this will overwrite an existing lifecycle configuration, so if you want to retain any configuration details, they must be included in the new lifecycle configuration. For information about lifecycle configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html">Managing your storage lifecycle</a>.</p> <note> <p>Bucket lifecycle configuration now supports specifying a lifecycle rule using an object key name prefix, one or more object tags, or a combination of both. Accordingly, this section describes the latest API. The previous version of the API supported filtering based only on an object key name prefix, which is supported for backward compatibility. For the related API description, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycle.html">PutBucketLifecycle</a>.</p> </note> <p> <b>Rules</b> </p> <p>You specify the lifecycle configuration in your request body. The lifecycle configuration is specified as XML consisting of one or more rules. An Amazon S3 Lifecycle configuration can have up to 1,000 rules. This limit is not adjustable. Each rule consists of the following:</p> <ul> <li> <p>Filter identifying a subset of objects to which the rule applies. The filter can be based on a key name prefix, object tags, or a combination of both.</p> </li> <li> <p>Status whether the rule is in effect.</p> </li> <li> <p>One or more lifecycle transition and expiration actions that you want Amazon S3 to perform on the objects identified by the filter. If the state of your bucket is versioning-enabled or versioning-suspended, you can have many versions of the same object (one current version and zero or more noncurrent versions). Amazon S3 provides predefined actions that you can specify for current and noncurrent object versions.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html">Object Lifecycle Management</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html">Lifecycle Configuration Elements</a>.</p> <p> <b>Permissions</b> </p> <p>By default, all Amazon S3 resources are private, including buckets, objects, and related subresources (for example, lifecycle configuration and website configuration). Only the resource owner (that is, the Amazon Web Services account that created it) can access the resource. The resource owner can optionally grant access permissions to others by writing an access policy. For this operation, a user must get the <code>s3:PutLifecycleConfiguration</code> permission.</p> <p>You can also explicitly deny permissions. Explicit deny also supersedes any other permissions. If you want to block users or accounts from removing or deleting objects from your bucket, you must deny them permissions for the following actions:</p> <ul> <li> <p> <code>s3:DeleteObject</code> </p> </li> <li> <p> <code>s3:DeleteObjectVersion</code> </p> </li> <li> <p> <code>s3:PutLifecycleConfiguration</code> </p> </li> </ul> <p>For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>The following are related to <code>PutBucketLifecycleConfiguration</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/lifecycle-configuration-examples.html">Examples of Lifecycle Configuration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html">GetBucketLifecycleConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketLifecycle.html">DeleteBucketLifecycle</a> </p> </li> </ul>
#
# PUT /{Bucket}#lifecycle
# operationId: PutBucketLifecycleConfiguration
export def "api PutBucketLifecycleConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lifecycle: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lifecycle" $lifecycle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#lifecycle" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Deletes a metrics configuration for the Amazon CloudWatch request metrics (specified by the metrics configuration ID) from the bucket. Note that this doesn't include the daily storage metrics.</p> <p> To use this operation, you must have permissions to perform the <code>s3:PutMetricsConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>For information about CloudWatch request metrics for Amazon S3, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/cloudwatch-monitoring.html">Monitoring Metrics with Amazon CloudWatch</a>. </p> <p>The following operations are related to <code>DeleteBucketMetricsConfiguration</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketMetricsConfiguration.html">GetBucketMetricsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketMetricsConfiguration.html">PutBucketMetricsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketMetricsConfigurations.html">ListBucketMetricsConfigurations</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/cloudwatch-monitoring.html">Monitoring Metrics with Amazon CloudWatch</a> </p> </li> </ul>
#
# DELETE /{Bucket}#metrics&id
# operationId: DeleteBucketMetricsConfiguration
export def "api DeleteBucketMetricsConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID used to identify the metrics configuration.
  --metrics: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "metrics" $metrics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#metrics&id" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Gets a metrics configuration (specified by the metrics configuration ID) from the bucket. Note that this doesn't include the daily storage metrics.</p> <p> To use this operation, you must have permissions to perform the <code>s3:GetMetricsConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p> For information about CloudWatch request metrics for Amazon S3, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/cloudwatch-monitoring.html">Monitoring Metrics with Amazon CloudWatch</a>.</p> <p>The following operations are related to <code>GetBucketMetricsConfiguration</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketMetricsConfiguration.html">PutBucketMetricsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketMetricsConfiguration.html">DeleteBucketMetricsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketMetricsConfigurations.html">ListBucketMetricsConfigurations</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/cloudwatch-monitoring.html">Monitoring Metrics with Amazon CloudWatch</a> </p> </li> </ul>
#
# GET /{Bucket}#metrics&id
# operationId: GetBucketMetricsConfiguration
export def "api GetBucketMetricsConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID used to identify the metrics configuration.
  --metrics: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "metrics" $metrics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#metrics&id" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Sets a metrics configuration (specified by the metrics configuration ID) for the bucket. You can have up to 1,000 metrics configurations per bucket. If you're updating an existing metrics configuration, note that this is a full replacement of the existing metrics configuration. If you don't include the elements you want to keep, they are erased.</p> <p>To use this operation, you must have permissions to perform the <code>s3:PutMetricsConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>For information about CloudWatch request metrics for Amazon S3, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/cloudwatch-monitoring.html">Monitoring Metrics with Amazon CloudWatch</a>.</p> <p>The following operations are related to <code>PutBucketMetricsConfiguration</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketMetricsConfiguration.html">DeleteBucketMetricsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketMetricsConfiguration.html">GetBucketMetricsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketMetricsConfigurations.html">ListBucketMetricsConfigurations</a> </p> </li> </ul> <p> <code>GetBucketLifecycle</code> has the following special error:</p> <ul> <li> <p>Error code: <code>TooManyConfigurations</code> </p> <ul> <li> <p>Description: You are attempting to create a new configuration but have already reached the 1,000-configuration limit.</p> </li> <li> <p>HTTP Status Code: HTTP 400 Bad Request</p> </li> </ul> </li> </ul>
#
# PUT /{Bucket}#metrics&id
# operationId: PutBucketMetricsConfiguration
export def "api PutBucketMetricsConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID used to identify the metrics configuration.
  --metrics: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "metrics" $metrics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#metrics&id" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Removes <code>OwnershipControls</code> for an Amazon S3 bucket. To use this operation, you must have the <code>s3:PutBucketOwnershipControls</code> permission. For more information about Amazon S3 permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html">Specifying Permissions in a Policy</a>.</p> <p>For information about Amazon S3 Object Ownership, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/about-object-ownership.html">Using Object Ownership</a>. </p> <p>The following operations are related to <code>DeleteBucketOwnershipControls</code>:</p> <ul> <li> <p> <a>GetBucketOwnershipControls</a> </p> </li> <li> <p> <a>PutBucketOwnershipControls</a> </p> </li> </ul>
#
# DELETE /{Bucket}#ownershipControls
# operationId: DeleteBucketOwnershipControls
export def "api DeleteBucketOwnershipControls" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownershipControls: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownershipControls" $ownershipControls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#ownershipControls" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Retrieves <code>OwnershipControls</code> for an Amazon S3 bucket. To use this operation, you must have the <code>s3:GetBucketOwnershipControls</code> permission. For more information about Amazon S3 permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html">Specifying permissions in a policy</a>. </p> <p>For information about Amazon S3 Object Ownership, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html">Using Object Ownership</a>. </p> <p>The following operations are related to <code>GetBucketOwnershipControls</code>:</p> <ul> <li> <p> <a>PutBucketOwnershipControls</a> </p> </li> <li> <p> <a>DeleteBucketOwnershipControls</a> </p> </li> </ul>
#
# GET /{Bucket}#ownershipControls
# operationId: GetBucketOwnershipControls
export def "api GetBucketOwnershipControls" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownershipControls: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownershipControls" $ownershipControls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#ownershipControls" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Creates or modifies <code>OwnershipControls</code> for an Amazon S3 bucket. To use this operation, you must have the <code>s3:PutBucketOwnershipControls</code> permission. For more information about Amazon S3 permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/user-guide/using-with-s3-actions.html">Specifying permissions in a policy</a>. </p> <p>For information about Amazon S3 Object Ownership, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/user-guide/about-object-ownership.html">Using object ownership</a>. </p> <p>The following operations are related to <code>PutBucketOwnershipControls</code>:</p> <ul> <li> <p> <a>GetBucketOwnershipControls</a> </p> </li> <li> <p> <a>DeleteBucketOwnershipControls</a> </p> </li> </ul>
#
# PUT /{Bucket}#ownershipControls
# operationId: PutBucketOwnershipControls
export def "api PutBucketOwnershipControls" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownershipControls: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The MD5 hash of the <code>OwnershipControls</code> request body. </p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownershipControls" $ownershipControls "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#ownershipControls" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>This implementation of the DELETE action uses the policy subresource to delete the policy of a specified bucket. If you are using an identity other than the root user of the Amazon Web Services account that owns the bucket, the calling identity must have the <code>DeleteBucketPolicy</code> permissions on the specified bucket and belong to the bucket owner's account to use this operation. </p> <p>If you don't have <code>DeleteBucketPolicy</code> permissions, Amazon S3 returns a <code>403 Access Denied</code> error. If you have the correct permissions, but you're not using an identity that belongs to the bucket owner's account, Amazon S3 returns a <code>405 Method Not Allowed</code> error. </p> <important> <p>As a security precaution, the root user of the Amazon Web Services account that owns a bucket can always use this operation, even if the policy explicitly denies the root user the ability to perform this action.</p> </important> <p>For more information about bucket policies, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html">Using Bucket Policies and UserPolicies</a>. </p> <p>The following operations are related to <code>DeleteBucketPolicy</code> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html">DeleteObject</a> </p> </li> </ul>
#
# DELETE /{Bucket}#policy
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEpolicy.html
# operationId: DeleteBucketPolicy
export def "api DeleteBucketPolicy" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --policy: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy" $policy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#policy" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns the policy of a specified bucket. If you are using an identity other than the root user of the Amazon Web Services account that owns the bucket, the calling identity must have the <code>GetBucketPolicy</code> permissions on the specified bucket and belong to the bucket owner's account in order to use this operation.</p> <p>If you don't have <code>GetBucketPolicy</code> permissions, Amazon S3 returns a <code>403 Access Denied</code> error. If you have the correct permissions, but you're not using an identity that belongs to the bucket owner's account, Amazon S3 returns a <code>405 Method Not Allowed</code> error.</p> <important> <p>As a security precaution, the root user of the Amazon Web Services account that owns a bucket can always use this operation, even if the policy explicitly denies the root user the ability to perform this action.</p> </important> <p>For more information about bucket policies, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html">Using Bucket Policies and User Policies</a>.</p> <p>The following action is related to <code>GetBucketPolicy</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> </ul>
#
# GET /{Bucket}#policy
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETpolicy.html
# operationId: GetBucketPolicy
export def "api GetBucketPolicy" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --policy: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy" $policy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#policy" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Applies an Amazon S3 bucket policy to an Amazon S3 bucket. If you are using an identity other than the root user of the Amazon Web Services account that owns the bucket, the calling identity must have the <code>PutBucketPolicy</code> permissions on the specified bucket and belong to the bucket owner's account in order to use this operation.</p> <p>If you don't have <code>PutBucketPolicy</code> permissions, Amazon S3 returns a <code>403 Access Denied</code> error. If you have the correct permissions, but you're not using an identity that belongs to the bucket owner's account, Amazon S3 returns a <code>405 Method Not Allowed</code> error.</p> <important> <p> As a security precaution, the root user of the Amazon Web Services account that owns a bucket can always use this operation, even if the policy explicitly denies the root user the ability to perform this action. </p> </important> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies.html">Bucket policy examples</a>.</p> <p>The following operations are related to <code>PutBucketPolicy</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html">DeleteBucket</a> </p> </li> </ul>
#
# PUT /{Bucket}#policy
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html
# operationId: PutBucketPolicy
export def "api PutBucketPolicy" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --policy: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The MD5 hash of the request body.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-confirm-remove-self-bucket-access: string@bool-completer # Set this parameter to true to confirm that you want to remove your permissions to change this bucket policy in the future.
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy" $policy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#policy" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-confirm-remove-self-bucket-access": $x_amz_confirm_remove_self_bucket_access, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p> Deletes the replication configuration from the bucket.</p> <p>To use this operation, you must have permissions to perform the <code>s3:PutReplicationConfiguration</code> action. The bucket owner has these permissions by default and can grant it to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>. </p> <note> <p>It can take a while for the deletion of a replication configuration to fully propagate.</p> </note> <p> For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/replication.html">Replication</a> in the <i>Amazon S3 User Guide</i>.</p> <p>The following operations are related to <code>DeleteBucketReplication</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketReplication.html">PutBucketReplication</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketReplication.html">GetBucketReplication</a> </p> </li> </ul>
#
# DELETE /{Bucket}#replication
# operationId: DeleteBucketReplication
export def "api DeleteBucketReplication" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replication: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replication" $replication "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#replication" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns the replication configuration of a bucket.</p> <note> <p> It can take a while to propagate the put or delete a replication configuration to all Amazon S3 systems. Therefore, a get request soon after put or delete can return a wrong result. </p> </note> <p> For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/replication.html">Replication</a> in the <i>Amazon S3 User Guide</i>.</p> <p>This action requires permissions for the <code>s3:GetReplicationConfiguration</code> action. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html">Using Bucket Policies and User Policies</a>.</p> <p>If you include the <code>Filter</code> element in a replication configuration, you must also include the <code>DeleteMarkerReplication</code> and <code>Priority</code> elements. The response also returns those elements.</p> <p>For information about <code>GetBucketReplication</code> errors, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ReplicationErrorCodeList">List of replication-related error codes</a> </p> <p>The following operations are related to <code>GetBucketReplication</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketReplication.html">PutBucketReplication</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketReplication.html">DeleteBucketReplication</a> </p> </li> </ul>
#
# GET /{Bucket}#replication
# operationId: GetBucketReplication
export def "api GetBucketReplication" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replication: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replication" $replication "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#replication" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p> Creates a replication configuration or replaces an existing one. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/replication.html">Replication</a> in the <i>Amazon S3 User Guide</i>. </p> <p>Specify the replication configuration in the request body. In the replication configuration, you provide the name of the destination bucket or buckets where you want Amazon S3 to replicate objects, the IAM role that Amazon S3 can assume to replicate objects on your behalf, and other relevant information.</p> <p>A replication configuration must include at least one rule, and can contain a maximum of 1,000. Each rule identifies a subset of objects to replicate by filtering the objects in the source bucket. To choose additional subsets of objects to replicate, add a rule for each subset.</p> <p>To specify a subset of the objects in the source bucket to apply a replication rule to, add the Filter element as a child of the Rule element. You can filter objects based on an object key prefix, one or more object tags, or both. When you add the Filter element in the configuration, you must also add the following elements: <code>DeleteMarkerReplication</code>, <code>Status</code>, and <code>Priority</code>.</p> <note> <p>If you are using an earlier version of the replication configuration, Amazon S3 handles replication of delete markers differently. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-add-config.html#replication-backward-compat-considerations">Backward Compatibility</a>.</p> </note> <p>For information about enabling versioning on a bucket, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html">Using Versioning</a>.</p> <p> <b>Handling Replication of Encrypted Objects</b> </p> <p>By default, Amazon S3 doesn't replicate objects that are stored at rest using server-side encryption with KMS keys. To replicate Amazon Web Services KMS-encrypted objects, add the following: <code>SourceSelectionCriteria</code>, <code>SseKmsEncryptedObjects</code>, <code>Status</code>, <code>EncryptionConfiguration</code>, and <code>ReplicaKmsKeyID</code>. For information about replication configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-config-for-kms-objects.html">Replicating Objects Created with SSE Using KMS keys</a>.</p> <p>For information on <code>PutBucketReplication</code> errors, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ReplicationErrorCodeList">List of replication-related error codes</a> </p> <p> <b>Permissions</b> </p> <p>To create a <code>PutBucketReplication</code> request, you must have <code>s3:PutReplicationConfiguration</code> permissions for the bucket. </p> <p>By default, a resource owner, in this case the Amazon Web Services account that created the bucket, can perform this operation. The resource owner can also grant others permissions to perform the operation. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html">Specifying Permissions in a Policy</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <note> <p>To perform this operation, the user or role performing the action must have the <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_passrole.html">iam:PassRole</a> permission.</p> </note> <p>The following operations are related to <code>PutBucketReplication</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketReplication.html">GetBucketReplication</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketReplication.html">DeleteBucketReplication</a> </p> </li> </ul>
#
# PUT /{Bucket}#replication
# operationId: PutBucketReplication
export def "api PutBucketReplication" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replication: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit. For more information, see <a href="http://www.ietf.org/rfc/rfc1864.txt">RFC 1864</a>.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-bucket-object-lock-token: string # A token to allow Object Lock to be enabled for an existing bucket.
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replication" $replication "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#replication" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-bucket-object-lock-token": $x_amz_bucket_object_lock_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Deletes the tags from the bucket.</p> <p>To use this operation, you must have permission to perform the <code>s3:PutBucketTagging</code> action. By default, the bucket owner has this permission and can grant this permission to others. </p> <p>The following operations are related to <code>DeleteBucketTagging</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketTagging.html">GetBucketTagging</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketTagging.html">PutBucketTagging</a> </p> </li> </ul>
#
# DELETE /{Bucket}#tagging
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEtagging.html
# operationId: DeleteBucketTagging
export def "api DeleteBucketTagging" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tagging: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagging" $tagging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#tagging" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns the tag set associated with the bucket.</p> <p>To use this operation, you must have permission to perform the <code>s3:GetBucketTagging</code> action. By default, the bucket owner has this permission and can grant this permission to others.</p> <p> <code>GetBucketTagging</code> has the following special error:</p> <ul> <li> <p>Error code: <code>NoSuchTagSet</code> </p> <ul> <li> <p>Description: There is no tag set associated with the bucket.</p> </li> </ul> </li> </ul> <p>The following operations are related to <code>GetBucketTagging</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketTagging.html">PutBucketTagging</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketTagging.html">DeleteBucketTagging</a> </p> </li> </ul>
#
# GET /{Bucket}#tagging
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETtagging.html
# operationId: GetBucketTagging
export def "api GetBucketTagging" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tagging: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagging" $tagging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#tagging" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Sets the tags for a bucket.</p> <p>Use tags to organize your Amazon Web Services bill to reflect your own cost structure. To do this, sign up to get your Amazon Web Services account bill with tag key values included. Then, to see the cost of combined resources, organize your billing information according to resources with the same tag key values. For example, you can tag several resources with a specific application name, and then organize your billing information to see the total cost of that application across several services. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Cost Allocation and Tagging</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/CostAllocTagging.html">Using Cost Allocation in Amazon S3 Bucket Tags</a>.</p> <note> <p> When this operation sets the tags for a bucket, it will overwrite any current tags the bucket already has. You cannot use this operation to add tags to an existing list of tags.</p> </note> <p>To use this operation, you must have permissions to perform the <code>s3:PutBucketTagging</code> action. The bucket owner has this permission by default and can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p> <code>PutBucketTagging</code> has the following special errors:</p> <ul> <li> <p>Error code: <code>InvalidTagError</code> </p> <ul> <li> <p>Description: The tag provided was not a valid tag. This error can occur if the tag did not pass input validation. For information about tag restrictions, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> and <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/aws-tag-restrictions.html">Amazon Web Services-Generated Cost Allocation Tag Restrictions</a>.</p> </li> </ul> </li> <li> <p>Error code: <code>MalformedXMLError</code> </p> <ul> <li> <p>Description: The XML provided does not match the schema.</p> </li> </ul> </li> <li> <p>Error code: <code>OperationAbortedError </code> </p> <ul> <li> <p>Description: A conflicting conditional action is currently in progress against this resource. Please try again.</p> </li> </ul> </li> <li> <p>Error code: <code>InternalError</code> </p> <ul> <li> <p>Description: The service was unable to apply the provided tag to the bucket.</p> </li> </ul> </li> </ul> <p>The following operations are related to <code>PutBucketTagging</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketTagging.html">GetBucketTagging</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketTagging.html">DeleteBucketTagging</a> </p> </li> </ul>
#
# PUT /{Bucket}#tagging
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
# operationId: PutBucketTagging
export def "api PutBucketTagging" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tagging: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit. For more information, see <a href="http://www.ietf.org/rfc/rfc1864.txt">RFC 1864</a>.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagging" $tagging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#tagging" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>This action removes the website configuration for a bucket. Amazon S3 returns a <code>200 OK</code> response upon successfully deleting a website configuration on the specified bucket. You will get a <code>200 OK</code> response if the website configuration you are trying to delete does not exist on the bucket. Amazon S3 returns a <code>404</code> response if the bucket specified in the request does not exist.</p> <p>This DELETE action requires the <code>S3:DeleteBucketWebsite</code> permission. By default, only the bucket owner can delete the website configuration attached to a bucket. However, bucket owners can grant other users permission to delete the website configuration by writing a bucket policy granting them the <code>S3:DeleteBucketWebsite</code> permission. </p> <p>For more information about hosting websites, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html">Hosting Websites on Amazon S3</a>. </p> <p>The following operations are related to <code>DeleteBucketWebsite</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketWebsite.html">GetBucketWebsite</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketWebsite.html">PutBucketWebsite</a> </p> </li> </ul>
#
# DELETE /{Bucket}#website
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketDELETEwebsite.html
# operationId: DeleteBucketWebsite
export def "api DeleteBucketWebsite" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --website: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "website" $website "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#website" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns the website configuration for a bucket. To host website on Amazon S3, you can configure a bucket as website by adding a website configuration. For more information about hosting websites, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html">Hosting Websites on Amazon S3</a>. </p> <p>This GET action requires the <code>S3:GetBucketWebsite</code> permission. By default, only the bucket owner can read the bucket website configuration. However, bucket owners can allow other users to read the website configuration by writing a bucket policy granting them the <code>S3:GetBucketWebsite</code> permission.</p> <p>The following operations are related to <code>DeleteBucketWebsite</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketWebsite.html">DeleteBucketWebsite</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketWebsite.html">PutBucketWebsite</a> </p> </li> </ul>
#
# GET /{Bucket}#website
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETwebsite.html
# operationId: GetBucketWebsite
export def "api GetBucketWebsite" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --website: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "website" $website "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#website" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Sets the configuration of the website that is specified in the <code>website</code> subresource. To configure a bucket as a website, you can add this subresource on the bucket with website configuration information such as the file name of the index document and any redirect rules. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html">Hosting Websites on Amazon S3</a>.</p> <p>This PUT action requires the <code>S3:PutBucketWebsite</code> permission. By default, only the bucket owner can configure the website attached to a bucket; however, bucket owners can allow other users to set the website configuration by writing a bucket policy that grants them the <code>S3:PutBucketWebsite</code> permission.</p> <p>To redirect all website requests sent to the bucket's website endpoint, you add a website configuration with the following elements. Because all requests are sent to another website, you don't need to provide index document name for the bucket.</p> <ul> <li> <p> <code>WebsiteConfiguration</code> </p> </li> <li> <p> <code>RedirectAllRequestsTo</code> </p> </li> <li> <p> <code>HostName</code> </p> </li> <li> <p> <code>Protocol</code> </p> </li> </ul> <p>If you want granular control over redirects, you can use the following elements to add routing rules that describe conditions for redirecting requests and information about the redirect destination. In this case, the website configuration must provide an index document for the bucket, because some requests might not be redirected. </p> <ul> <li> <p> <code>WebsiteConfiguration</code> </p> </li> <li> <p> <code>IndexDocument</code> </p> </li> <li> <p> <code>Suffix</code> </p> </li> <li> <p> <code>ErrorDocument</code> </p> </li> <li> <p> <code>Key</code> </p> </li> <li> <p> <code>RoutingRules</code> </p> </li> <li> <p> <code>RoutingRule</code> </p> </li> <li> <p> <code>Condition</code> </p> </li> <li> <p> <code>HttpErrorCodeReturnedEquals</code> </p> </li> <li> <p> <code>KeyPrefixEquals</code> </p> </li> <li> <p> <code>Redirect</code> </p> </li> <li> <p> <code>Protocol</code> </p> </li> <li> <p> <code>HostName</code> </p> </li> <li> <p> <code>ReplaceKeyPrefixWith</code> </p> </li> <li> <p> <code>ReplaceKeyWith</code> </p> </li> <li> <p> <code>HttpRedirectCode</code> </p> </li> </ul> <p>Amazon S3 has a limitation of 50 routing rules per website configuration. If you require more than 50 routing rules, you can use object redirect. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html">Configuring an Object Redirect</a> in the <i>Amazon S3 User Guide</i>.</p>
#
# PUT /{Bucket}#website
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html
# operationId: PutBucketWebsite
export def "api PutBucketWebsite" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --website: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit. For more information, see <a href="http://www.ietf.org/rfc/rfc1864.txt">RFC 1864</a>.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "website" $website "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#website" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Removes the null version (if there is one) of an object and inserts a delete marker, which becomes the latest version of the object. If there isn't a null version, Amazon S3 does not remove any objects but will still respond that the command was successful.</p> <p>To remove a specific version, you must be the bucket owner and you must use the version Id subresource. Using this subresource permanently deletes the version. If the object deleted is a delete marker, Amazon S3 sets the response header, <code>x-amz-delete-marker</code>, to true. </p> <p>If the object you want to delete is in a bucket where the bucket versioning configuration is MFA Delete enabled, you must include the <code>x-amz-mfa</code> request header in the DELETE <code>versionId</code> request. Requests that include <code>x-amz-mfa</code> must use HTTPS. </p> <p> For more information about MFA Delete, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMFADelete.html">Using MFA Delete</a>. To see sample requests that use versioning, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectDELETE.html#ExampleVersionObjectDelete">Sample Request</a>. </p> <p>You can delete objects by explicitly calling DELETE Object or configure its lifecycle (<a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycle.html">PutBucketLifecycle</a>) to enable Amazon S3 to remove them for you. If you want to block users or accounts from removing or deleting objects from your bucket, you must deny them the <code>s3:DeleteObject</code>, <code>s3:DeleteObjectVersion</code>, and <code>s3:PutLifeCycleConfiguration</code> actions. </p> <p>The following action is related to <code>DeleteObject</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html">PutObject</a> </p> </li> </ul>
#
# DELETE /{Bucket}/{Key}
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html
# operationId: DeleteObject
export def "api DeleteObject" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # VersionId used to reference a specific version of the object.
  --x-amz-security-token: string
  --x-amz-mfa: string # The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device. Required to permanently delete a versioned object if versioning is configured with MFA delete enabled.
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-bypass-governance-retention: string@bool-completer # Indicates whether S3 Object Lock should bypass Governance-mode restrictions to process this operation. To use this header, you must have the <code>s3:BypassGovernanceRetention</code> permission.
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-mfa": $x_amz_mfa, "x-amz-request-payer": $x_amz_request_payer, "x-amz-bypass-governance-retention": $x_amz_bypass_governance_retention, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Retrieves objects from Amazon S3. To use <code>GET</code>, you must have <code>READ</code> access to the object. If you grant <code>READ</code> access to the anonymous user, you can return the object without using an authorization header.</p> <p>An Amazon S3 bucket has no directory hierarchy such as you would find in a typical computer file system. You can, however, create a logical hierarchy by using object key names that imply a folder structure. For example, instead of naming an object <code>sample.jpg</code>, you can name it <code>photos/2006/February/sample.jpg</code>.</p> <p>To get an object from such a logical hierarchy, specify the full key name for the object in the <code>GET</code> operation. For a virtual hosted-style request example, if you have the object <code>photos/2006/February/sample.jpg</code>, specify the resource as <code>/photos/2006/February/sample.jpg</code>. For a path-style request example, if you have the object <code>photos/2006/February/sample.jpg</code> in the bucket named <code>examplebucket</code>, specify the resource as <code>/examplebucket/photos/2006/February/sample.jpg</code>. For more information about request types, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/VirtualHosting.html#VirtualHostingSpecifyBucket">HTTP Host Header Bucket Specification</a>.</p> <p>For more information about returning the ACL of an object, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAcl.html">GetObjectAcl</a>.</p> <p>If the object you are retrieving is stored in the S3 Glacier or S3 Glacier Deep Archive storage class, or S3 Intelligent-Tiering Archive or S3 Intelligent-Tiering Deep Archive tiers, before you can retrieve the object you must first restore a copy using <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html">RestoreObject</a>. Otherwise, this action returns an <code>InvalidObjectStateError</code> error. For information about restoring archived objects, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/restoring-objects.html">Restoring Archived Objects</a>.</p> <p>Encryption request headers, like <code>x-amz-server-side-encryption</code>, should not be sent for GET requests if your object uses server-side encryption with KMS keys (SSE-KMS) or server-side encryption with Amazon S3–managed encryption keys (SSE-S3). If your object does use these types of keys, you’ll get an HTTP 400 BadRequest error.</p> <p>If you encrypt an object by using server-side encryption with customer-provided encryption keys (SSE-C) when you store the object in Amazon S3, then when you GET the object, you must use the following headers:</p> <ul> <li> <p>x-amz-server-side-encryption-customer-algorithm</p> </li> <li> <p>x-amz-server-side-encryption-customer-key</p> </li> <li> <p>x-amz-server-side-encryption-customer-key-MD5</p> </li> </ul> <p>For more information about SSE-C, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Server-Side Encryption (Using Customer-Provided Encryption Keys)</a>.</p> <p>Assuming you have the relevant permission to read object tags, the response also returns the <code>x-amz-tagging-count</code> header that provides the count of number of tags associated with the object. You can use <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html">GetObjectTagging</a> to retrieve the tag set associated with an object.</p> <p> <b>Permissions</b> </p> <p>You need the relevant read object (or version) permission for this operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html">Specifying Permissions in a Policy</a>. If the object you request does not exist, the error Amazon S3 returns depends on whether you also have the <code>s3:ListBucket</code> permission.</p> <ul> <li> <p>If you have the <code>s3:ListBucket</code> permission on the bucket, Amazon S3 will return an HTTP status code 404 ("no such key") error.</p> </li> <li> <p>If you don’t have the <code>s3:ListBucket</code> permission, Amazon S3 will return an HTTP status code 403 ("access denied") error.</p> </li> </ul> <p> <b>Versioning</b> </p> <p>By default, the GET action returns the current version of an object. To return a different version, use the <code>versionId</code> subresource.</p> <note> <ul> <li> <p> If you supply a <code>versionId</code>, you need the <code>s3:GetObjectVersion</code> permission to access a specific version of an object. If you request a specific version, you do not need to have the <code>s3:GetObject</code> permission. </p> </li> <li> <p>If the current version of the object is a delete marker, Amazon S3 behaves as if the object was deleted and includes <code>x-amz-delete-marker: true</code> in the response.</p> </li> </ul> </note> <p>For more information about versioning, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketVersioning.html">PutBucketVersioning</a>. </p> <p> <b>Overriding Response Header Values</b> </p> <p>There are times when you want to override certain response header values in a GET response. For example, you might override the <code>Content-Disposition</code> response header value in your GET request.</p> <p>You can override values for a set of response headers using the following query parameters. These response header values are sent only on a successful request, that is, when status code 200 OK is returned. The set of headers you can override using these parameters is a subset of the headers that Amazon S3 accepts when you create an object. The response headers that you can override for the GET response are <code>Content-Type</code>, <code>Content-Language</code>, <code>Expires</code>, <code>Cache-Control</code>, <code>Content-Disposition</code>, and <code>Content-Encoding</code>. To override these header values in the GET response, you use the following request parameters.</p> <note> <p>You must sign the request, either using an Authorization header or a presigned URL, when using these parameters. They cannot be used with an unsigned (anonymous) request.</p> </note> <ul> <li> <p> <code>response-content-type</code> </p> </li> <li> <p> <code>response-content-language</code> </p> </li> <li> <p> <code>response-expires</code> </p> </li> <li> <p> <code>response-cache-control</code> </p> </li> <li> <p> <code>response-content-disposition</code> </p> </li> <li> <p> <code>response-content-encoding</code> </p> </li> </ul> <p> <b>Additional Considerations about Request Headers</b> </p> <p>If both of the <code>If-Match</code> and <code>If-Unmodified-Since</code> headers are present in the request as follows: <code>If-Match</code> condition evaluates to <code>true</code>, and; <code>If-Unmodified-Since</code> condition evaluates to <code>false</code>; then, S3 returns 200 OK and the data requested. </p> <p>If both of the <code>If-None-Match</code> and <code>If-Modified-Since</code> headers are present in the request as follows:<code> If-None-Match</code> condition evaluates to <code>false</code>, and; <code>If-Modified-Since</code> condition evaluates to <code>true</code>; then, S3 returns 304 Not Modified response code.</p> <p>For more information about conditional requests, see <a href="https://tools.ietf.org/html/rfc7232">RFC 7232</a>.</p> <p>The following operations are related to <code>GetObject</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBuckets.html">ListBuckets</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAcl.html">GetObjectAcl</a> </p> </li> </ul>
#
# GET /{Bucket}/{Key}
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGET.html
# operationId: GetObject
export def "api GetObject" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --response-cache-control: string # Sets the <code>Cache-Control</code> header of the response.
  --response-content-disposition: string # Sets the <code>Content-Disposition</code> header of the response
  --response-content-encoding: string # Sets the <code>Content-Encoding</code> header of the response.
  --response-content-language: string # Sets the <code>Content-Language</code> header of the response.
  --response-content-type: string # Sets the <code>Content-Type</code> header of the response.
  --response-expires: string # Sets the <code>Expires</code> header of the response. (format: date-time)
  --versionId: string # VersionId used to reference a specific version of the object.
  --partNumber: int # Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' GET request for the part specified. Useful for downloading just a part of an object.
  --x-amz-security-token: string
  --If-Match: string # Return the object only if its entity tag (ETag) is the same as the one specified; otherwise, return a 412 (precondition failed) error.
  --If-Modified-Since: string # Return the object only if it has been modified since the specified time; otherwise, return a 304 (not modified) error.
  --If-None-Match: string # Return the object only if its entity tag (ETag) is different from the one specified; otherwise, return a 304 (not modified) error.
  --If-Unmodified-Since: string # Return the object only if it has not been modified since the specified time; otherwise, return a 412 (precondition failed) error.
  --Range: string # <p>Downloads the specified range bytes of an object. For more information about the HTTP Range header, see <a href="https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35">https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35</a>.</p> <note> <p>Amazon S3 doesn't support retrieving multiple ranges of data per <code>GET</code> request.</p> </note>
  --x-amz-server-side-encryption-customer-algorithm: string # Specifies the algorithm to use to when decrypting the object (for example, AES256).
  --x-amz-server-side-encryption-customer-key: string # Specifies the customer-provided encryption key for Amazon S3 used to encrypt the data. This value is used to decrypt the object when recovering it and must match the one used when storing the data. The key must be appropriate for use with the algorithm specified in the <code>x-amz-server-side-encryption-customer-algorithm</code> header.
  --x-amz-server-side-encryption-customer-key-MD5: string # Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-checksum-mode: string@x-amz-checksum-mode-completer # To retrieve the checksum, this mode must be enabled.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "response-cache-control" $response_cache_control "scalar") (serialize-qp "response-content-disposition" $response_content_disposition "scalar") (serialize-qp "response-content-encoding" $response_content_encoding "scalar") (serialize-qp "response-content-language" $response_content_language "scalar") (serialize-qp "response-content-type" $response_content_type "scalar") (serialize-qp "response-expires" $response_expires "scalar") (serialize-qp "versionId" $versionId "scalar") (serialize-qp "partNumber" $partNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "If-Match": $If_Match, "If-Modified-Since": $If_Modified_Since, "If-None-Match": $If_None_Match, "If-Unmodified-Since": $If_Unmodified_Since, "Range": $Range, "x-amz-server-side-encryption-customer-algorithm": $x_amz_server_side_encryption_customer_algorithm, "x-amz-server-side-encryption-customer-key": $x_amz_server_side_encryption_customer_key, "x-amz-server-side-encryption-customer-key-MD5": $x_amz_server_side_encryption_customer_key_MD5, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-checksum-mode": $x_amz_checksum_mode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>The HEAD action retrieves metadata from an object without returning the object itself. This action is useful if you're only interested in an object's metadata. To use HEAD, you must have READ access to the object.</p> <p>A <code>HEAD</code> request has the same options as a <code>GET</code> action on an object. The response is identical to the <code>GET</code> response except that there is no response body. Because of this, if the <code>HEAD</code> request generates an error, it returns a generic <code>404 Not Found</code> or <code>403 Forbidden</code> code. It is not possible to retrieve the exact exception beyond these error codes.</p> <p>If you encrypt an object by using server-side encryption with customer-provided encryption keys (SSE-C) when you store the object in Amazon S3, then when you retrieve the metadata from the object, you must use the following headers:</p> <ul> <li> <p>x-amz-server-side-encryption-customer-algorithm</p> </li> <li> <p>x-amz-server-side-encryption-customer-key</p> </li> <li> <p>x-amz-server-side-encryption-customer-key-MD5</p> </li> </ul> <p>For more information about SSE-C, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Server-Side Encryption (Using Customer-Provided Encryption Keys)</a>.</p> <note> <ul> <li> <p>Encryption request headers, like <code>x-amz-server-side-encryption</code>, should not be sent for GET requests if your object uses server-side encryption with KMS keys (SSE-KMS) or server-side encryption with Amazon S3–managed encryption keys (SSE-S3). If your object does use these types of keys, you’ll get an HTTP 400 BadRequest error.</p> </li> <li> <p> The last modified property in this case is the creation date of the object.</p> </li> </ul> </note> <p>Request headers are limited to 8 KB in size. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/RESTCommonRequestHeaders.html">Common Request Headers</a>.</p> <p>Consider the following when using request headers:</p> <ul> <li> <p> Consideration 1 – If both of the <code>If-Match</code> and <code>If-Unmodified-Since</code> headers are present in the request as follows:</p> <ul> <li> <p> <code>If-Match</code> condition evaluates to <code>true</code>, and;</p> </li> <li> <p> <code>If-Unmodified-Since</code> condition evaluates to <code>false</code>;</p> </li> </ul> <p>Then Amazon S3 returns <code>200 OK</code> and the data requested.</p> </li> <li> <p> Consideration 2 – If both of the <code>If-None-Match</code> and <code>If-Modified-Since</code> headers are present in the request as follows:</p> <ul> <li> <p> <code>If-None-Match</code> condition evaluates to <code>false</code>, and;</p> </li> <li> <p> <code>If-Modified-Since</code> condition evaluates to <code>true</code>;</p> </li> </ul> <p>Then Amazon S3 returns the <code>304 Not Modified</code> response code.</p> </li> </ul> <p>For more information about conditional requests, see <a href="https://tools.ietf.org/html/rfc7232">RFC 7232</a>.</p> <p> <b>Permissions</b> </p> <p>You need the relevant read object (or version) permission for this operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html">Specifying Permissions in a Policy</a>. If the object you request does not exist, the error Amazon S3 returns depends on whether you also have the s3:ListBucket permission.</p> <ul> <li> <p>If you have the <code>s3:ListBucket</code> permission on the bucket, Amazon S3 returns an HTTP status code 404 ("no such key") error.</p> </li> <li> <p>If you don’t have the <code>s3:ListBucket</code> permission, Amazon S3 returns an HTTP status code 403 ("access denied") error.</p> </li> </ul> <p>The following actions are related to <code>HeadObject</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html">GetObjectAttributes</a> </p> </li> </ul>
#
# HEAD /{Bucket}/{Key}
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html
# operationId: HeadObject
export def "api HeadObject" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # VersionId used to reference a specific version of the object.
  --partNumber: int # Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
  --x-amz-security-token: string
  --If-Match: string # Return the object only if its entity tag (ETag) is the same as the one specified; otherwise, return a 412 (precondition failed) error.
  --If-Modified-Since: string # Return the object only if it has been modified since the specified time; otherwise, return a 304 (not modified) error.
  --If-None-Match: string # Return the object only if its entity tag (ETag) is different from the one specified; otherwise, return a 304 (not modified) error.
  --If-Unmodified-Since: string # Return the object only if it has not been modified since the specified time; otherwise, return a 412 (precondition failed) error.
  --Range: string # Because <code>HeadObject</code> returns only the metadata for an object, this parameter has no effect.
  --x-amz-server-side-encryption-customer-algorithm: string # Specifies the algorithm to use to when encrypting the object (for example, AES256).
  --x-amz-server-side-encryption-customer-key: string # Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon S3 does not store the encryption key. The key must be appropriate for use with the algorithm specified in the <code>x-amz-server-side-encryption-customer-algorithm</code> header.
  --x-amz-server-side-encryption-customer-key-MD5: string # Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-checksum-mode: string@x-amz-checksum-mode-completer # <p>To retrieve the checksum, this parameter must be enabled.</p> <p>In addition, if you enable <code>ChecksumMode</code> and the object is encrypted with Amazon Web Services Key Management Service (Amazon Web Services KMS), you must have permission to use the <code>kms:Decrypt</code> action for the request to succeed.</p>
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "partNumber" $partNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "If-Match": $If_Match, "If-Modified-Since": $If_Modified_Since, "If-None-Match": $If_None_Match, "If-Unmodified-Since": $If_Unmodified_Since, "Range": $Range, "x-amz-server-side-encryption-customer-algorithm": $x_amz_server_side_encryption_customer_algorithm, "x-amz-server-side-encryption-customer-key": $x_amz_server_side_encryption_customer_key, "x-amz-server-side-encryption-customer-key-MD5": $x_amz_server_side_encryption_customer_key_MD5, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-checksum-mode": $x_amz_checksum_mode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Adds an object to a bucket. You must have WRITE permissions on a bucket to add an object to it.</p> <p>Amazon S3 never adds partial objects; if you receive a success response, Amazon S3 added the entire object to the bucket.</p> <p>Amazon S3 is a distributed system. If it receives multiple write requests for the same object simultaneously, it overwrites all but the last object written. Amazon S3 does not provide object locking; if you need this, make sure to build it into your application layer or use versioning instead.</p> <p>To ensure that data is not corrupted traversing the network, use the <code>Content-MD5</code> header. When you use this header, Amazon S3 checks the object against the provided MD5 value and, if they do not match, returns an error. Additionally, you can calculate the MD5 while putting an object to Amazon S3 and compare the returned ETag to the calculated MD5 value.</p> <note> <ul> <li> <p>To successfully complete the <code>PutObject</code> request, you must have the <code>s3:PutObject</code> in your IAM permissions.</p> </li> <li> <p>To successfully change the objects acl of your <code>PutObject</code> request, you must have the <code>s3:PutObjectAcl</code> in your IAM permissions.</p> </li> <li> <p> The <code>Content-MD5</code> header is required for any request to upload an object with a retention period configured using Amazon S3 Object Lock. For more information about Amazon S3 Object Lock, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock-overview.html">Amazon S3 Object Lock Overview</a> in the <i>Amazon S3 User Guide</i>. </p> </li> </ul> </note> <p> <b>Server-side Encryption</b> </p> <p>You can optionally request server-side encryption. With server-side encryption, Amazon S3 encrypts your data as it writes it to disks in its data centers and decrypts the data when you access it. You have the option to provide your own encryption key or use Amazon Web Services managed encryption keys (SSE-S3 or SSE-KMS). For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingServerSideEncryption.html">Using Server-Side Encryption</a>.</p> <p>If you request server-side encryption using Amazon Web Services Key Management Service (SSE-KMS), you can enable an S3 Bucket Key at the object-level. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-key.html">Amazon S3 Bucket Keys</a> in the <i>Amazon S3 User Guide</i>.</p> <p> <b>Access Control List (ACL)-Specific Request Headers</b> </p> <p>You can use headers to grant ACL- based permissions. By default, all objects are private. Only the owner has full access control. When adding a new object, you can grant permissions to individual Amazon Web Services accounts or to predefined groups defined by Amazon S3. These permissions are then added to the ACL on the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html">Access Control List (ACL) Overview</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-using-rest-api.html">Managing ACLs Using the REST API</a>. </p> <p>If the bucket that you're uploading objects to uses the bucket owner enforced setting for S3 Object Ownership, ACLs are disabled and no longer affect permissions. Buckets that use this setting only accept PUT requests that don't specify an ACL or PUT requests that specify bucket owner full control ACLs, such as the <code>bucket-owner-full-control</code> canned ACL or an equivalent form of this ACL expressed in the XML format. PUT requests that contain other ACLs (for example, custom grants to certain Amazon Web Services accounts) fail and return a <code>400</code> error with the error code <code>AccessControlListNotSupported</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html"> Controlling ownership of objects and disabling ACLs</a> in the <i>Amazon S3 User Guide</i>.</p> <note> <p>If your bucket uses the bucket owner enforced setting for Object Ownership, all objects written to the bucket by any account will be owned by the bucket owner.</p> </note> <p> <b>Storage Class Options</b> </p> <p>By default, Amazon S3 uses the STANDARD Storage Class to store newly created objects. The STANDARD storage class provides high durability and high availability. Depending on performance needs, you can specify a different Storage Class. Amazon S3 on Outposts only uses the OUTPOSTS Storage Class. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html">Storage Classes</a> in the <i>Amazon S3 User Guide</i>.</p> <p> <b>Versioning</b> </p> <p>If you enable versioning for a bucket, Amazon S3 automatically generates a unique version ID for the object being stored. Amazon S3 returns this ID in the response. When you enable versioning for a bucket, if Amazon S3 receives multiple write requests for the same object simultaneously, it stores all of the objects.</p> <p>For more information about versioning, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/AddingObjectstoVersioningEnabledBuckets.html">Adding Objects to Versioning Enabled Buckets</a>. For information about returning the versioning state of a bucket, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketVersioning.html">GetBucketVersioning</a>. </p> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html">CopyObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html">DeleteObject</a> </p> </li> </ul>
#
# PUT /{Bucket}/{Key}
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html
# operationId: PutObject
export def "api PutObject" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-amz-security-token: string
  --x-amz-acl: string@x-amz-acl-completer # <p>The canned ACL to apply to the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL">Canned ACL</a>.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --Cache-Control: string #  Can be used to specify caching behavior along the request/reply chain. For more information, see <a href="http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9">http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9</a>.
  --Content-Disposition: string # Specifies presentational information for the object. For more information, see <a href="http://www.w3.org/Protocols/rfc2616/rfc2616-sec19.html#sec19.5.1">http://www.w3.org/Protocols/rfc2616/rfc2616-sec19.html#sec19.5.1</a>.
  --Content-Encoding: string # Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field. For more information, see <a href="http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.11">http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.11</a>.
  --Content-Language: string # The language the content is in.
  --Content-Length: int # Size of the body in bytes. This parameter is useful when the size of the body cannot be determined automatically. For more information, see <a href="http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.13">http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.13</a>.
  --Content-MD5: string # The base64-encoded 128-bit MD5 digest of the message (without the headers) according to RFC 1864. This header can be used as a message integrity check to verify that the data is the same data that was originally sent. Although it is optional, we recommend using the Content-MD5 mechanism as an end-to-end integrity check. For more information about REST request authentication, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html">REST Authentication</a>.
  --Content-Type: string # A standard MIME type describing the format of the contents. For more information, see <a href="http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.17">http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.17</a>.
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-checksum-crc32: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 32-bit CRC32 checksum of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-checksum-crc32c: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 32-bit CRC32C checksum of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-checksum-sha1: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 160-bit SHA-1 digest of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-checksum-sha256: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 256-bit SHA-256 digest of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --Expires: string # The date and time at which the object is no longer cacheable. For more information, see <a href="http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.21">http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.21</a>.
  --x-amz-grant-full-control: string # <p>Gives the grantee READ, READ_ACP, and WRITE_ACP permissions on the object.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-read: string # <p>Allows grantee to read the object data and its metadata.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-read-acp: string # <p>Allows grantee to read the object ACL.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-write-acp: string # <p>Allows grantee to write the ACL for the applicable object.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-server-side-encryption: string@x-amz-server-side-encryption-completer # The server-side encryption algorithm used when storing this object in Amazon S3 (for example, AES256, aws:kms).
  --x-amz-storage-class: string@x-amz-storage-class-completer # By default, Amazon S3 uses the STANDARD Storage Class to store newly created objects. The STANDARD storage class provides high durability and high availability. Depending on performance needs, you can specify a different Storage Class. Amazon S3 on Outposts only uses the OUTPOSTS Storage Class. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html">Storage Classes</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-website-redirect-location: string # <p>If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata. For information about object metadata, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html">Object Key and Metadata</a>.</p> <p>In the following example, the request header sets the redirect to an object (anotherPage.html) in the same bucket:</p> <p> <code>x-amz-website-redirect-location: /anotherPage.html</code> </p> <p>In the following example, the request header sets the object redirect to another website:</p> <p> <code>x-amz-website-redirect-location: http://www.example.com/</code> </p> <p>For more information about website hosting in Amazon S3, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html">Hosting Websites on Amazon S3</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html">How to Configure Website Page Redirects</a>. </p>
  --x-amz-server-side-encryption-customer-algorithm: string # Specifies the algorithm to use to when encrypting the object (for example, AES256).
  --x-amz-server-side-encryption-customer-key: string # Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon S3 does not store the encryption key. The key must be appropriate for use with the algorithm specified in the <code>x-amz-server-side-encryption-customer-algorithm</code> header.
  --x-amz-server-side-encryption-customer-key-MD5: string # Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
  --x-amz-server-side-encryption-aws-kms-key-id: string # If <code>x-amz-server-side-encryption</code> is present and has the value of <code>aws:kms</code>, this header specifies the ID of the Amazon Web Services Key Management Service (Amazon Web Services KMS) symmetrical customer managed key that was used for the object. If you specify <code>x-amz-server-side-encryption:aws:kms</code>, but do not provide<code> x-amz-server-side-encryption-aws-kms-key-id</code>, Amazon S3 uses the Amazon Web Services managed key to protect the data. If the KMS key does not exist in the same account issuing the command, you must use the full ARN and not just the ID. 
  --x-amz-server-side-encryption-context: string # Specifies the Amazon Web Services KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs.
  --x-amz-server-side-encryption-bucket-key-enabled: string@bool-completer # <p>Specifies whether Amazon S3 should use an S3 Bucket Key for object encryption with server-side encryption using AWS KMS (SSE-KMS). Setting this header to <code>true</code> causes Amazon S3 to use an S3 Bucket Key for object encryption with SSE-KMS.</p> <p>Specifying this header with a PUT action doesn’t affect bucket-level settings for S3 Bucket Key.</p>
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-tagging: string # The tag-set for the object. The tag-set must be encoded as URL Query parameters. (For example, "Key1=Value1")
  --x-amz-object-lock-mode: string@x-amz-object-lock-mode-completer # The Object Lock mode that you want to apply to this object.
  --x-amz-object-lock-retain-until-date: string # The date and time when you want this object's Object Lock to expire. Must be formatted as a timestamp parameter.
  --x-amz-object-lock-legal-hold: string@x-amz-object-lock-legal-hold-completer # Specifies whether a legal hold will be applied to this object. For more information about S3 Object Lock, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html">Object Lock</a>.
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($Bucket)/($Key)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-acl": $x_amz_acl, "Cache-Control": $Cache_Control, "Content-Disposition": $Content_Disposition, "Content-Encoding": $Content_Encoding, "Content-Language": $Content_Language, "Content-Length": $Content_Length, "Content-MD5": $Content_MD5, "Content-Type": $Content_Type, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-checksum-crc32": $x_amz_checksum_crc32, "x-amz-checksum-crc32c": $x_amz_checksum_crc32c, "x-amz-checksum-sha1": $x_amz_checksum_sha1, "x-amz-checksum-sha256": $x_amz_checksum_sha256, "Expires": $Expires, "x-amz-grant-full-control": $x_amz_grant_full_control, "x-amz-grant-read": $x_amz_grant_read, "x-amz-grant-read-acp": $x_amz_grant_read_acp, "x-amz-grant-write-acp": $x_amz_grant_write_acp, "x-amz-server-side-encryption": $x_amz_server_side_encryption, "x-amz-storage-class": $x_amz_storage_class, "x-amz-website-redirect-location": $x_amz_website_redirect_location, "x-amz-server-side-encryption-customer-algorithm": $x_amz_server_side_encryption_customer_algorithm, "x-amz-server-side-encryption-customer-key": $x_amz_server_side_encryption_customer_key, "x-amz-server-side-encryption-customer-key-MD5": $x_amz_server_side_encryption_customer_key_MD5, "x-amz-server-side-encryption-aws-kms-key-id": $x_amz_server_side_encryption_aws_kms_key_id, "x-amz-server-side-encryption-context": $x_amz_server_side_encryption_context, "x-amz-server-side-encryption-bucket-key-enabled": $x_amz_server_side_encryption_bucket_key_enabled, "x-amz-request-payer": $x_amz_request_payer, "x-amz-tagging": $x_amz_tagging, "x-amz-object-lock-mode": $x_amz_object_lock_mode, "x-amz-object-lock-retain-until-date": $x_amz_object_lock_retain_until_date, "x-amz-object-lock-legal-hold": $x_amz_object_lock_legal_hold, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Removes the entire tag set from the specified object. For more information about managing object tags, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-tagging.html"> Object Tagging</a>.</p> <p>To use this operation, you must have permission to perform the <code>s3:DeleteObjectTagging</code> action.</p> <p>To delete tags of a specific object version, add the <code>versionId</code> query parameter in the request. You will need permission for the <code>s3:DeleteObjectVersionTagging</code> action.</p> <p>The following operations are related to <code>DeleteBucketMetricsConfiguration</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectTagging.html">PutObjectTagging</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html">GetObjectTagging</a> </p> </li> </ul>
#
# DELETE /{Bucket}/{Key}#tagging
# operationId: DeleteObjectTagging
export def "api DeleteObjectTagging" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # The versionId of the object that the tag-set will be removed from.
  --tagging: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "tagging" $tagging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#tagging" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns the tag-set of an object. You send the GET request against the tagging subresource associated with the object.</p> <p>To use this operation, you must have permission to perform the <code>s3:GetObjectTagging</code> action. By default, the GET action returns information about current version of an object. For a versioned bucket, you can have multiple versions of an object in your bucket. To retrieve tags of any other version, use the versionId query parameter. You also need permission for the <code>s3:GetObjectVersionTagging</code> action.</p> <p> By default, the bucket owner has this permission and can grant this permission to others.</p> <p> For information about the Amazon S3 object tagging feature, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-tagging.html">Object Tagging</a>.</p> <p>The following actions are related to <code>GetObjectTagging</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjectTagging.html">DeleteObjectTagging</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html">GetObjectAttributes</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectTagging.html">PutObjectTagging</a> </p> </li> </ul>
#
# GET /{Bucket}/{Key}#tagging
# operationId: GetObjectTagging
export def "api GetObjectTagging" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # The versionId of the object for which to get the tagging information.
  --tagging: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-request-payer: string@x-amz-request-payer-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "tagging" $tagging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#tagging" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-request-payer": $x_amz_request_payer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Sets the supplied tag-set to an object that already exists in a bucket.</p> <p>A tag is a key-value pair. You can associate tags with an object by sending a PUT request against the tagging subresource that is associated with the object. You can retrieve tags by sending a GET request. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html">GetObjectTagging</a>.</p> <p>For tagging-related restrictions related to characters and encodings, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">Tag Restrictions</a>. Note that Amazon S3 limits the maximum number of tags to 10 tags per object.</p> <p>To use this operation, you must have permission to perform the <code>s3:PutObjectTagging</code> action. By default, the bucket owner has this permission and can grant this permission to others.</p> <p>To put tags of any other version, use the <code>versionId</code> query parameter. You also need permission for the <code>s3:PutObjectVersionTagging</code> action.</p> <p>For information about the Amazon S3 object tagging feature, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-tagging.html">Object Tagging</a>.</p> <p class="title"> <b>Special Errors</b> </p> <ul> <li> <ul> <li> <p> <i>Code: InvalidTagError </i> </p> </li> <li> <p> <i>Cause: The tag provided was not a valid tag. This error can occur if the tag did not pass input validation. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-tagging.html">Object Tagging</a>.</i> </p> </li> </ul> </li> <li> <ul> <li> <p> <i>Code: MalformedXMLError </i> </p> </li> <li> <p> <i>Cause: The XML provided does not match the schema.</i> </p> </li> </ul> </li> <li> <ul> <li> <p> <i>Code: OperationAbortedError </i> </p> </li> <li> <p> <i>Cause: A conflicting conditional action is currently in progress against this resource. Please try again.</i> </p> </li> </ul> </li> <li> <ul> <li> <p> <i>Code: InternalError</i> </p> </li> <li> <p> <i>Cause: The service was unable to apply the provided tag to the object.</i> </p> </li> </ul> </li> </ul> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html">GetObjectTagging</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjectTagging.html">DeleteObjectTagging</a> </p> </li> </ul>
#
# PUT /{Bucket}/{Key}#tagging
# operationId: PutObjectTagging
export def "api PutObjectTagging" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # The versionId of the object that the tag-set will be added to.
  --tagging: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The MD5 hash for the request body.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "tagging" $tagging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#tagging" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-request-payer": $x_amz_request_payer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>This action enables you to delete multiple objects from a bucket using a single HTTP request. If you know the object keys that you want to delete, then this action provides a suitable alternative to sending individual delete requests, reducing per-request overhead.</p> <p>The request contains a list of up to 1000 keys that you want to delete. In the XML, you provide the object key names, and optionally, version IDs if you want to delete a specific version of the object from a versioning-enabled bucket. For each key, Amazon S3 performs a delete action and returns the result of that delete, success, or failure, in the response. Note that if the object specified in the request is not found, Amazon S3 returns the result as deleted.</p> <p> The action supports two modes for the response: verbose and quiet. By default, the action uses verbose mode in which the response includes the result of deletion of each key in your request. In quiet mode the response includes only keys where the delete action encountered an error. For a successful deletion, the action does not return any information about the delete in the response body.</p> <p>When performing this action on an MFA Delete enabled bucket, that attempts to delete any versioned objects, you must include an MFA token. If you do not provide one, the entire request will fail, even if there are non-versioned objects you are trying to delete. If you provide an invalid token, whether there are versioned keys in the request or not, the entire Multi-Object Delete request will fail. For information about MFA Delete, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html#MultiFactorAuthenticationDelete"> MFA Delete</a>.</p> <p>Finally, the Content-MD5 header is required for all Multi-Object Delete requests. Amazon S3 uses the header value to ensure that your request body has not been altered in transit.</p> <p>The following operations are related to <code>DeleteObjects</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html">CreateMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html">CompleteMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html">ListParts</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html">AbortMultipartUpload</a> </p> </li> </ul>
#
# POST /{Bucket}#delete
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/multiobjectdeleteapi.html
# operationId: DeleteObjects
export def "api DeleteObjects" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-mfa: string # The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device. Required to permanently delete a versioned object if versioning is configured with MFA delete enabled.
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-bypass-governance-retention: string@bool-completer # Specifies whether you want to delete this object even if it has a Governance-type Object Lock in place. To use this header, you must have the <code>s3:BypassGovernanceRetention</code> permission.
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p> <p>This checksum algorithm must be the same for all parts and it match the checksum value supplied in the <code>CreateMultipartUpload</code> request.</p>
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete" $delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#delete" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-mfa": $x_amz_mfa, "x-amz-request-payer": $x_amz_request_payer, "x-amz-bypass-governance-retention": $x_amz_bypass_governance_retention, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Removes the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket. To use this operation, you must have the <code>s3:PutBucketPublicAccessBlock</code> permission. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>The following operations are related to <code>DeletePublicAccessBlock</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html">Using Amazon S3 Block Public Access</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html">GetPublicAccessBlock</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutPublicAccessBlock.html">PutPublicAccessBlock</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicyStatus.html">GetBucketPolicyStatus</a> </p> </li> </ul>
#
# DELETE /{Bucket}#publicAccessBlock
# operationId: DeletePublicAccessBlock
export def "api DeletePublicAccessBlock" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --publicAccessBlock: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "publicAccessBlock" $publicAccessBlock "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#publicAccessBlock" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket. To use this operation, you must have the <code>s3:GetBucketPublicAccessBlock</code> permission. For more information about Amazon S3 permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html">Specifying Permissions in a Policy</a>.</p> <important> <p>When Amazon S3 evaluates the <code>PublicAccessBlock</code> configuration for a bucket or an object, it checks the <code>PublicAccessBlock</code> configuration for both the bucket (or the bucket that contains the object) and the bucket owner's account. If the <code>PublicAccessBlock</code> settings are different between the bucket and the account, Amazon S3 uses the most restrictive combination of the bucket-level and account-level settings.</p> </important> <p>For more information about when Amazon S3 considers a bucket or an object public, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html#access-control-block-public-access-policy-status">The Meaning of "Public"</a>.</p> <p>The following operations are related to <code>GetPublicAccessBlock</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html">Using Amazon S3 Block Public Access</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutPublicAccessBlock.html">PutPublicAccessBlock</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html">GetPublicAccessBlock</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeletePublicAccessBlock.html">DeletePublicAccessBlock</a> </p> </li> </ul>
#
# GET /{Bucket}#publicAccessBlock
# operationId: GetPublicAccessBlock
export def "api GetPublicAccessBlock" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --publicAccessBlock: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "publicAccessBlock" $publicAccessBlock "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#publicAccessBlock" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon S3 bucket. To use this operation, you must have the <code>s3:PutBucketPublicAccessBlock</code> permission. For more information about Amazon S3 permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html">Specifying Permissions in a Policy</a>.</p> <important> <p>When Amazon S3 evaluates the <code>PublicAccessBlock</code> configuration for a bucket or an object, it checks the <code>PublicAccessBlock</code> configuration for both the bucket (or the bucket that contains the object) and the bucket owner's account. If the <code>PublicAccessBlock</code> configurations are different between the bucket and the account, Amazon S3 uses the most restrictive combination of the bucket-level and account-level settings.</p> </important> <p>For more information about when Amazon S3 considers a bucket or an object public, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html#access-control-block-public-access-policy-status">The Meaning of "Public"</a>.</p> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html">GetPublicAccessBlock</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeletePublicAccessBlock.html">DeletePublicAccessBlock</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicyStatus.html">GetBucketPolicyStatus</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html">Using Amazon S3 Block Public Access</a> </p> </li> </ul>
#
# PUT /{Bucket}#publicAccessBlock
# operationId: PutPublicAccessBlock
export def "api PutPublicAccessBlock" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --publicAccessBlock: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The MD5 hash of the <code>PutPublicAccessBlock</code> request body. </p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "publicAccessBlock" $publicAccessBlock "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#publicAccessBlock" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>This implementation of the GET action uses the <code>accelerate</code> subresource to return the Transfer Acceleration state of a bucket, which is either <code>Enabled</code> or <code>Suspended</code>. Amazon S3 Transfer Acceleration is a bucket-level feature that enables you to perform faster data transfers to and from Amazon S3.</p> <p>To use this operation, you must have permission to perform the <code>s3:GetAccelerateConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to your Amazon S3 Resources</a> in the <i>Amazon S3 User Guide</i>.</p> <p>You set the Transfer Acceleration state of an existing bucket to <code>Enabled</code> or <code>Suspended</code> by using the <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketAccelerateConfiguration.html">PutBucketAccelerateConfiguration</a> operation. </p> <p>A GET <code>accelerate</code> request does not return a state value for a bucket that has no transfer acceleration state. A bucket has no Transfer Acceleration state if a state has never been set on the bucket. </p> <p>For more information about transfer acceleration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html">Transfer Acceleration</a> in the Amazon S3 User Guide.</p> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketAccelerateConfiguration.html">PutBucketAccelerateConfiguration</a> </p> </li> </ul>
#
# GET /{Bucket}#accelerate
# operationId: GetBucketAccelerateConfiguration
export def "api GetBucketAccelerateConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accelerate: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accelerate" $accelerate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#accelerate" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Sets the accelerate configuration of an existing bucket. Amazon S3 Transfer Acceleration is a bucket-level feature that enables you to perform faster data transfers to Amazon S3.</p> <p> To use this operation, you must have permission to perform the <code>s3:PutAccelerateConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p> The Transfer Acceleration state of a bucket can be set to one of the following two values:</p> <ul> <li> <p> Enabled – Enables accelerated data transfers to the bucket.</p> </li> <li> <p> Suspended – Disables accelerated data transfers to the bucket.</p> </li> </ul> <p>The <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAccelerateConfiguration.html">GetBucketAccelerateConfiguration</a> action returns the transfer acceleration state of a bucket.</p> <p>After setting the Transfer Acceleration state of a bucket to Enabled, it might take up to thirty minutes before the data transfer rates to the bucket increase.</p> <p> The name of the bucket used for Transfer Acceleration must be DNS-compliant and must not contain periods (".").</p> <p> For more information about transfer acceleration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html">Transfer Acceleration</a>.</p> <p>The following operations are related to <code>PutBucketAccelerateConfiguration</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAccelerateConfiguration.html">GetBucketAccelerateConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> </ul>
#
# PUT /{Bucket}#accelerate
# operationId: PutBucketAccelerateConfiguration
export def "api PutBucketAccelerateConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accelerate: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accelerate" $accelerate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#accelerate" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>This implementation of the <code>GET</code> action uses the <code>acl</code> subresource to return the access control list (ACL) of a bucket. To use <code>GET</code> to return the ACL of the bucket, you must have <code>READ_ACP</code> access to the bucket. If <code>READ_ACP</code> permission is granted to the anonymous user, you can return the ACL of the bucket without using an authorization header.</p> <note> <p>If your bucket uses the bucket owner enforced setting for S3 Object Ownership, requests to read ACLs are still supported and return the <code>bucket-owner-full-control</code> ACL with the owner being the account that created the bucket. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html"> Controlling object ownership and disabling ACLs</a> in the <i>Amazon S3 User Guide</i>.</p> </note> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjects.html">ListObjects</a> </p> </li> </ul>
#
# GET /{Bucket}#acl
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETacl.html
# operationId: GetBucketAcl
export def "api GetBucketAcl" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acl: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acl" $acl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#acl" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Sets the permissions on an existing bucket using access control lists (ACL). For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_ACLs_UsingACLs.html">Using ACLs</a>. To set the ACL of a bucket, you must have <code>WRITE_ACP</code> permission.</p> <p>You can use one of the following two ways to set a bucket's permissions:</p> <ul> <li> <p>Specify the ACL in the request body</p> </li> <li> <p>Specify permissions using request headers</p> </li> </ul> <note> <p>You cannot specify access permission using both the body and the request headers.</p> </note> <p>Depending on your application needs, you may choose to set the ACL on a bucket using either the request body or the headers. For example, if you have an existing application that updates a bucket ACL using the request body, then you can continue to use that approach.</p> <important> <p>If your bucket uses the bucket owner enforced setting for S3 Object Ownership, ACLs are disabled and no longer affect permissions. You must use policies to grant access to your bucket and the objects in it. Requests to set ACLs or update ACLs fail and return the <code>AccessControlListNotSupported</code> error code. Requests to read ACLs are still supported. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html">Controlling object ownership</a> in the <i>Amazon S3 User Guide</i>.</p> </important> <p> <b>Access Permissions</b> </p> <p>You can set access permissions using one of the following methods:</p> <ul> <li> <p>Specify a canned ACL with the <code>x-amz-acl</code> request header. Amazon S3 supports a set of predefined ACLs, known as <i>canned ACLs</i>. Each canned ACL has a predefined set of grantees and permissions. Specify the canned ACL name as the value of <code>x-amz-acl</code>. If you use this header, you cannot use other access control-specific headers in your request. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL">Canned ACL</a>.</p> </li> <li> <p>Specify access permissions explicitly with the <code>x-amz-grant-read</code>, <code>x-amz-grant-read-acp</code>, <code>x-amz-grant-write-acp</code>, and <code>x-amz-grant-full-control</code> headers. When using these headers, you specify explicit access permissions and grantees (Amazon Web Services accounts or Amazon S3 groups) who will receive the permission. If you use these ACL-specific headers, you cannot use the <code>x-amz-acl</code> header to set a canned ACL. These parameters map to the set of permissions that Amazon S3 supports in an ACL. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html">Access Control List (ACL) Overview</a>.</p> <p>You specify each grantee as a type=value pair, where the type is one of the following:</p> <ul> <li> <p> <code>id</code> – if the value specified is the canonical user ID of an Amazon Web Services account</p> </li> <li> <p> <code>uri</code> – if you are granting permissions to a predefined group</p> </li> <li> <p> <code>emailAddress</code> – if the value specified is the email address of an Amazon Web Services account</p> <note> <p>Using email addresses to specify a grantee is only supported in the following Amazon Web Services Regions: </p> <ul> <li> <p>US East (N. Virginia)</p> </li> <li> <p>US West (N. California)</p> </li> <li> <p> US West (Oregon)</p> </li> <li> <p> Asia Pacific (Singapore)</p> </li> <li> <p>Asia Pacific (Sydney)</p> </li> <li> <p>Asia Pacific (Tokyo)</p> </li> <li> <p>Europe (Ireland)</p> </li> <li> <p>South America (São Paulo)</p> </li> </ul> <p>For a list of all the Amazon S3 supported Regions and endpoints, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region">Regions and Endpoints</a> in the Amazon Web Services General Reference.</p> </note> </li> </ul> <p>For example, the following <code>x-amz-grant-write</code> header grants create, overwrite, and delete objects permission to LogDelivery group predefined by Amazon S3 and two Amazon Web Services accounts identified by their email addresses.</p> <p> <code>x-amz-grant-write: uri="http://acs.amazonaws.com/groups/s3/LogDelivery", id="111122223333", id="555566667777" </code> </p> </li> </ul> <p>You can use either a canned ACL or specify access permissions explicitly. You cannot do both.</p> <p> <b>Grantee Values</b> </p> <p>You can specify the person (grantee) to whom you're assigning access rights (using request elements) in the following ways:</p> <ul> <li> <p>By the person's ID:</p> <p> <code>&lt;Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser"&gt;&lt;ID&gt;&lt;&gt;ID&lt;&gt;&lt;/ID&gt;&lt;DisplayName&gt;&lt;&gt;GranteesEmail&lt;&gt;&lt;/DisplayName&gt; &lt;/Grantee&gt;</code> </p> <p>DisplayName is optional and ignored in the request</p> </li> <li> <p>By URI:</p> <p> <code>&lt;Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"&gt;&lt;URI&gt;&lt;&gt;http://acs.amazonaws.com/groups/global/AuthenticatedUsers&lt;&gt;&lt;/URI&gt;&lt;/Grantee&gt;</code> </p> </li> <li> <p>By Email address:</p> <p> <code>&lt;Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="AmazonCustomerByEmail"&gt;&lt;EmailAddress&gt;&lt;&gt;Grantees@email.com&lt;&gt;&lt;/EmailAddress&gt;lt;/Grantee&gt;</code> </p> <p>The grantee is resolved to the CanonicalUser and, in a response to a GET Object acl request, appears as the CanonicalUser. </p> <note> <p>Using email addresses to specify a grantee is only supported in the following Amazon Web Services Regions: </p> <ul> <li> <p>US East (N. Virginia)</p> </li> <li> <p>US West (N. California)</p> </li> <li> <p> US West (Oregon)</p> </li> <li> <p> Asia Pacific (Singapore)</p> </li> <li> <p>Asia Pacific (Sydney)</p> </li> <li> <p>Asia Pacific (Tokyo)</p> </li> <li> <p>Europe (Ireland)</p> </li> <li> <p>South America (São Paulo)</p> </li> </ul> <p>For a list of all the Amazon S3 supported Regions and endpoints, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region">Regions and Endpoints</a> in the Amazon Web Services General Reference.</p> </note> </li> </ul> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html">DeleteBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAcl.html">GetObjectAcl</a> </p> </li> </ul>
#
# PUT /{Bucket}#acl
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTacl.html
# operationId: PutBucketAcl
export def "api PutBucketAcl" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --acl: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-acl: string@x-amz-acl-completer-1 # The canned ACL to apply to the bucket.
  --Content-MD5: string # <p>The base64-encoded 128-bit MD5 digest of the data. This header must be used as a message integrity check to verify that the request body was not corrupted in transit. For more information, go to <a href="http://www.ietf.org/rfc/rfc1864.txt">RFC 1864.</a> </p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-grant-full-control: string # Allows grantee the read, write, read ACP, and write ACP permissions on the bucket.
  --x-amz-grant-read: string # Allows grantee to list the objects in the bucket.
  --x-amz-grant-read-acp: string # Allows grantee to read the bucket ACL.
  --x-amz-grant-write: string # <p>Allows grantee to create new objects in the bucket.</p> <p>For the bucket and object owners of existing objects, also allows deletions and overwrites of those objects.</p>
  --x-amz-grant-write-acp: string # Allows grantee to write the ACL for the applicable bucket.
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acl" $acl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#acl" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-acl": $x_amz_acl, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-grant-full-control": $x_amz_grant_full_control, "x-amz-grant-read": $x_amz_grant_read, "x-amz-grant-read-acp": $x_amz_grant_read_acp, "x-amz-grant-write": $x_amz_grant_write, "x-amz-grant-write-acp": $x_amz_grant_write_acp, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <important> <p>For an updated version of this API, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html">GetBucketLifecycleConfiguration</a>. If you configured a bucket lifecycle using the <code>filter</code> element, you should see the updated version of this topic. This topic is provided for backward compatibility.</p> </important> <p>Returns the lifecycle configuration information set on the bucket. For information about lifecycle configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html">Object Lifecycle Management</a>.</p> <p> To use this operation, you must have permission to perform the <code>s3:GetLifecycleConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p> <code>GetBucketLifecycle</code> has the following special error:</p> <ul> <li> <p>Error code: <code>NoSuchLifecycleConfiguration</code> </p> <ul> <li> <p>Description: The lifecycle configuration does not exist.</p> </li> <li> <p>HTTP Status Code: 404 Not Found</p> </li> <li> <p>SOAP Fault Code Prefix: Client</p> </li> </ul> </li> </ul> <p>The following operations are related to <code>GetBucketLifecycle</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html">GetBucketLifecycleConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycle.html">PutBucketLifecycle</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketLifecycle.html">DeleteBucketLifecycle</a> </p> </li> </ul>
#
# GET /{Bucket}#lifecycle&deprecated!
# DEPRECATED
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlifecycle.html
# operationId: GetBucketLifecycle
@deprecated
export def "api GetBucketLifecycle" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lifecycle: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lifecycle" $lifecycle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#lifecycle&deprecated!" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <important> <p>For an updated version of this API, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html">PutBucketLifecycleConfiguration</a>. This version has been deprecated. Existing lifecycle configurations will work. For new lifecycle configurations, use the updated API. </p> </important> <p>Creates a new lifecycle configuration for the bucket or replaces an existing lifecycle configuration. For information about lifecycle configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html">Object Lifecycle Management</a> in the <i>Amazon S3 User Guide</i>. </p> <p>By default, all Amazon S3 resources, including buckets, objects, and related subresources (for example, lifecycle configuration and website configuration) are private. Only the resource owner, the Amazon Web Services account that created the resource, can access it. The resource owner can optionally grant access permissions to others by writing an access policy. For this operation, users must get the <code>s3:PutLifecycleConfiguration</code> permission.</p> <p>You can also explicitly deny permissions. Explicit denial also supersedes any other permissions. If you want to prevent users or accounts from removing or deleting objects from your bucket, you must deny them permissions for the following actions: </p> <ul> <li> <p> <code>s3:DeleteObject</code> </p> </li> <li> <p> <code>s3:DeleteObjectVersion</code> </p> </li> <li> <p> <code>s3:PutLifecycleConfiguration</code> </p> </li> </ul> <p>For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to your Amazon S3 Resources</a> in the <i>Amazon S3 User Guide</i>.</p> <p>For more examples of transitioning objects to storage classes such as STANDARD_IA or ONEZONE_IA, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#lifecycle-configuration-examples">Examples of Lifecycle Configuration</a>.</p> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycle.html">GetBucketLifecycle</a>(Deprecated)</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html">GetBucketLifecycleConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html">RestoreObject</a> </p> </li> <li> <p>By default, a resource owner—in this case, a bucket owner, which is the Amazon Web Services account that created the bucket—can perform any of the operations. A resource owner can also grant others permission to perform the operation. For more information, see the following topics in the Amazon S3 User Guide: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html">Specifying Permissions in a Policy</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to your Amazon S3 Resources</a> </p> </li> </ul> </li> </ul>
#
# PUT /{Bucket}#lifecycle&deprecated!
# DEPRECATED
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
# operationId: PutBucketLifecycle
@deprecated
export def "api PutBucketLifecycle" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lifecycle: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p/> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lifecycle" $lifecycle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#lifecycle&deprecated!" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Returns the Region the bucket resides in. You set the bucket's Region using the <code>LocationConstraint</code> request parameter in a <code>CreateBucket</code> request. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a>.</p> <p>To use this implementation of the operation, you must be the bucket owner.</p> <p>To use this API against an access point, provide the alias of the access point in place of the bucket name.</p> <p>The following operations are related to <code>GetBucketLocation</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> </ul>
#
# GET /{Bucket}#location
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlocation.html
# operationId: GetBucketLocation
export def "api GetBucketLocation" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#location" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns the logging status of a bucket and the permissions users have to view and modify that status. To use GET, you must be the bucket owner.</p> <p>The following operations are related to <code>GetBucketLogging</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLogging.html">PutBucketLogging</a> </p> </li> </ul>
#
# GET /{Bucket}#logging
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETlogging.html
# operationId: GetBucketLogging
export def "api GetBucketLogging" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --logging: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "logging" $logging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#logging" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Set the logging parameters for a bucket and to specify permissions for who can view and modify the logging parameters. All logs are saved to buckets in the same Amazon Web Services Region as the source bucket. To set the logging status of a bucket, you must be the bucket owner.</p> <p>The bucket owner is automatically granted FULL_CONTROL to all logs. You use the <code>Grantee</code> request element to grant access to other people. The <code>Permissions</code> request element specifies the kind of access the grantee has to the logs.</p> <important> <p>If the target bucket for log delivery uses the bucket owner enforced setting for S3 Object Ownership, you can't use the <code>Grantee</code> request element to grant access to others. Permissions can only be granted using policies. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html#grant-log-delivery-permissions-general">Permissions for server access log delivery</a> in the <i>Amazon S3 User Guide</i>.</p> </important> <p> <b>Grantee Values</b> </p> <p>You can specify the person (grantee) to whom you're assigning access rights (using request elements) in the following ways:</p> <ul> <li> <p>By the person's ID:</p> <p> <code>&lt;Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser"&gt;&lt;ID&gt;&lt;&gt;ID&lt;&gt;&lt;/ID&gt;&lt;DisplayName&gt;&lt;&gt;GranteesEmail&lt;&gt;&lt;/DisplayName&gt; &lt;/Grantee&gt;</code> </p> <p>DisplayName is optional and ignored in the request.</p> </li> <li> <p>By Email address:</p> <p> <code> &lt;Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="AmazonCustomerByEmail"&gt;&lt;EmailAddress&gt;&lt;&gt;Grantees@email.com&lt;&gt;&lt;/EmailAddress&gt;&lt;/Grantee&gt;</code> </p> <p>The grantee is resolved to the CanonicalUser and, in a response to a GET Object acl request, appears as the CanonicalUser.</p> </li> <li> <p>By URI:</p> <p> <code>&lt;Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"&gt;&lt;URI&gt;&lt;&gt;http://acs.amazonaws.com/groups/global/AuthenticatedUsers&lt;&gt;&lt;/URI&gt;&lt;/Grantee&gt;</code> </p> </li> </ul> <p>To enable logging, you use LoggingEnabled and its children request elements. To disable logging, you use an empty BucketLoggingStatus request element:</p> <p> <code>&lt;BucketLoggingStatus xmlns="http://doc.s3.amazonaws.com/2006-03-01" /&gt;</code> </p> <p>For more information about server access logging, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html">Server Access Logging</a> in the <i>Amazon S3 User Guide</i>. </p> <p>For more information about creating a bucket, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a>. For more information about returning the logging status of a bucket, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLogging.html">GetBucketLogging</a>.</p> <p>The following operations are related to <code>PutBucketLogging</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html">PutObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html">DeleteBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLogging.html">GetBucketLogging</a> </p> </li> </ul>
#
# PUT /{Bucket}#logging
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTlogging.html
# operationId: PutBucketLogging
export def "api PutBucketLogging" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --logging: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The MD5 hash of the <code>PutBucketLogging</code> request body.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "logging" $logging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#logging" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Returns the notification configuration of a bucket.</p> <p>If notifications are not enabled on the bucket, the action returns an empty <code>NotificationConfiguration</code> element.</p> <p>By default, you must be the bucket owner to read the notification configuration of a bucket. However, the bucket owner can use a bucket policy to grant permission to other users to read this configuration with the <code>s3:GetBucketNotification</code> permission.</p> <p>For more information about setting and reading the notification configuration on a bucket, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html">Setting Up Notification of Bucket Events</a>. For more information about bucket policies, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html">Using Bucket Policies</a>.</p> <p>The following action is related to <code>GetBucketNotification</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketNotification.html">PutBucketNotification</a> </p> </li> </ul>
#
# GET /{Bucket}#notification
# operationId: GetBucketNotificationConfiguration
export def "api GetBucketNotificationConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notification: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notification" $notification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#notification" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Enables notifications of specified events for a bucket. For more information about event notifications, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html">Configuring Event Notifications</a>.</p> <p>Using this API, you can replace an existing notification configuration. The configuration is an XML file that defines the event types that you want Amazon S3 to publish and the destination where you want Amazon S3 to publish an event notification when it detects an event of the specified type.</p> <p>By default, your bucket has no event notifications configured. That is, the notification configuration will be an empty <code>NotificationConfiguration</code>.</p> <p> <code>&lt;NotificationConfiguration&gt;</code> </p> <p> <code>&lt;/NotificationConfiguration&gt;</code> </p> <p>This action replaces the existing notification configuration with the configuration you include in the request body.</p> <p>After Amazon S3 receives this request, it first verifies that any Amazon Simple Notification Service (Amazon SNS) or Amazon Simple Queue Service (Amazon SQS) destination exists, and that the bucket owner has permission to publish to it by sending a test notification. In the case of Lambda destinations, Amazon S3 verifies that the Lambda function permissions grant Amazon S3 permission to invoke the function from the Amazon S3 bucket. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html">Configuring Notifications for Amazon S3 Events</a>.</p> <p>You can disable notifications by adding the empty NotificationConfiguration element.</p> <p>For more information about the number of event notification configurations that you can create per bucket, see <a href="https://docs.aws.amazon.com/general/latest/gr/s3.html#limits_s3">Amazon S3 service quotas</a> in <i>Amazon Web Services General Reference</i>.</p> <p>By default, only the bucket owner can configure notifications on a bucket. However, bucket owners can use a bucket policy to grant permission to other users to set this configuration with <code>s3:PutBucketNotification</code> permission.</p> <note> <p>The PUT notification is an atomic operation. For example, suppose your notification configuration includes SNS topic, SQS queue, and Lambda function configurations. When you send a PUT request with this configuration, Amazon S3 sends test messages to your SNS topic. If the message fails, the entire PUT action will fail, and Amazon S3 will not add the configuration to your bucket.</p> </note> <p> <b>Responses</b> </p> <p>If the configuration in the request body includes only one <code>TopicConfiguration</code> specifying only the <code>s3:ReducedRedundancyLostObject</code> event type, the response will also include the <code>x-amz-sns-test-message-id</code> header containing the message ID of the test notification sent to the topic.</p> <p>The following action is related to <code>PutBucketNotificationConfiguration</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketNotificationConfiguration.html">GetBucketNotificationConfiguration</a> </p> </li> </ul>
#
# PUT /{Bucket}#notification
# operationId: PutBucketNotificationConfiguration
export def "api PutBucketNotificationConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notification: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-skip-destination-validation: string@bool-completer # Skips validation of Amazon SQS, Amazon SNS, and Lambda destinations. True or false value.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notification" $notification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#notification" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-skip-destination-validation": $x_amz_skip_destination_validation} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

#  No longer used, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketNotificationConfiguration.html">GetBucketNotificationConfiguration</a>.
#
# GET /{Bucket}#notification&deprecated!
# DEPRECATED
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETnotification.html
# operationId: GetBucketNotification
@deprecated
export def "api GetBucketNotification" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notification: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notification" $notification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#notification&deprecated!" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

#  No longer used, see the <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketNotificationConfiguration.html">PutBucketNotificationConfiguration</a> operation.
#
# PUT /{Bucket}#notification&deprecated!
# DEPRECATED
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTnotification.html
# operationId: PutBucketNotification
@deprecated
export def "api PutBucketNotification" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notification: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The MD5 hash of the <code>PutPublicAccessBlock</code> request body.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notification" $notification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#notification&deprecated!" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Retrieves the policy status for an Amazon S3 bucket, indicating whether the bucket is public. In order to use this operation, you must have the <code>s3:GetBucketPolicyStatus</code> permission. For more information about Amazon S3 permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html">Specifying Permissions in a Policy</a>.</p> <p> For more information about when Amazon S3 considers a bucket public, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html#access-control-block-public-access-policy-status">The Meaning of "Public"</a>. </p> <p>The following operations are related to <code>GetBucketPolicyStatus</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html">Using Amazon S3 Block Public Access</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html">GetPublicAccessBlock</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutPublicAccessBlock.html">PutPublicAccessBlock</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeletePublicAccessBlock.html">DeletePublicAccessBlock</a> </p> </li> </ul>
#
# GET /{Bucket}#policyStatus
# operationId: GetBucketPolicyStatus
export def "api GetBucketPolicyStatus" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --policyStatus: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policyStatus" $policyStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#policyStatus" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns the request payment configuration of a bucket. To use this version of the operation, you must be the bucket owner. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html">Requester Pays Buckets</a>.</p> <p>The following operations are related to <code>GetBucketRequestPayment</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjects.html">ListObjects</a> </p> </li> </ul>
#
# GET /{Bucket}#requestPayment
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentGET.html
# operationId: GetBucketRequestPayment
export def "api GetBucketRequestPayment" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requestPayment: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requestPayment" $requestPayment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#requestPayment" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Sets the request payment configuration for a bucket. By default, the bucket owner pays for downloads from the bucket. This configuration parameter enables the bucket owner (only) to specify that the person requesting the download will be charged for the download. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html">Requester Pays Buckets</a>.</p> <p>The following operations are related to <code>PutBucketRequestPayment</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketRequestPayment.html">GetBucketRequestPayment</a> </p> </li> </ul>
#
# PUT /{Bucket}#requestPayment
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTrequestPaymentPUT.html
# operationId: PutBucketRequestPayment
export def "api PutBucketRequestPayment" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requestPayment: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit. For more information, see <a href="http://www.ietf.org/rfc/rfc1864.txt">RFC 1864</a>.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requestPayment" $requestPayment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#requestPayment" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Returns the versioning state of a bucket.</p> <p>To retrieve the versioning state of a bucket, you must be the bucket owner.</p> <p>This implementation also returns the MFA Delete status of the versioning state. If the MFA Delete status is <code>enabled</code>, the bucket owner must use an authentication device to change the versioning state of the bucket.</p> <p>The following operations are related to <code>GetBucketVersioning</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html">PutObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html">DeleteObject</a> </p> </li> </ul>
#
# GET /{Bucket}#versioning
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETversioningStatus.html
# operationId: GetBucketVersioning
export def "api GetBucketVersioning" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versioning: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versioning" $versioning "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#versioning" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Sets the versioning state of an existing bucket.</p> <p>You can set the versioning state with one of the following values:</p> <p> <b>Enabled</b>—Enables versioning for the objects in the bucket. All objects added to the bucket receive a unique version ID.</p> <p> <b>Suspended</b>—Disables versioning for the objects in the bucket. All objects added to the bucket receive the version ID null.</p> <p>If the versioning state has never been set on a bucket, it has no versioning state; a <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketVersioning.html">GetBucketVersioning</a> request does not return a versioning state value.</p> <p>In order to enable MFA Delete, you must be the bucket owner. If you are the bucket owner and want to enable MFA Delete in the bucket versioning configuration, you must include the <code>x-amz-mfa request</code> header and the <code>Status</code> and the <code>MfaDelete</code> request elements in a request to set the versioning state of the bucket.</p> <important> <p>If you have an object expiration lifecycle policy in your non-versioned bucket and you want to maintain the same permanent delete behavior when you enable versioning, you must add a noncurrent expiration policy. The noncurrent expiration lifecycle policy will manage the deletes of the noncurrent object versions in the version-enabled bucket. (A version-enabled bucket maintains one current and zero or more noncurrent object versions.) For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html#lifecycle-and-other-bucket-config">Lifecycle and Versioning</a>.</p> </important> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html">DeleteBucket</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketVersioning.html">GetBucketVersioning</a> </p> </li> </ul>
#
# PUT /{Bucket}#versioning
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTVersioningStatus.html
# operationId: PutBucketVersioning
export def "api PutBucketVersioning" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versioning: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --Content-MD5: string # <p>&gt;The base64-encoded 128-bit MD5 digest of the data. You must use this header as a message integrity check to verify that the request body was not corrupted in transit. For more information, see <a href="http://www.ietf.org/rfc/rfc1864.txt">RFC 1864</a>.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-mfa: string # The concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device.
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versioning" $versioning "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#versioning" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-mfa": $x_amz_mfa, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Returns the access control list (ACL) of an object. To use this operation, you must have <code>s3:GetObjectAcl</code> permissions or <code>READ_ACP</code> access to the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#acl-access-policy-permission-mapping">Mapping of ACL permissions and access policy permissions</a> in the <i>Amazon S3 User Guide</i> </p> <p>This action is not supported by Amazon S3 on Outposts.</p> <p> <b>Versioning</b> </p> <p>By default, GET returns ACL information about the current version of an object. To return ACL information about a different version, use the versionId subresource.</p> <note> <p>If your bucket uses the bucket owner enforced setting for S3 Object Ownership, requests to read ACLs are still supported and return the <code>bucket-owner-full-control</code> ACL with the owner being the account that created the bucket. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html"> Controlling object ownership and disabling ACLs</a> in the <i>Amazon S3 User Guide</i>.</p> </note> <p>The following operations are related to <code>GetObjectAcl</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html">GetObjectAttributes</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html">DeleteObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html">PutObject</a> </p> </li> </ul>
#
# GET /{Bucket}/{Key}#acl
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETacl.html
# operationId: GetObjectAcl
export def "api GetObjectAcl" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # VersionId used to reference a specific version of the object.
  --acl: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "acl" $acl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#acl" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Uses the <code>acl</code> subresource to set the access control list (ACL) permissions for a new or existing object in an S3 bucket. You must have <code>WRITE_ACP</code> permission to set the ACL of an object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#permissions">What permissions can I grant?</a> in the <i>Amazon S3 User Guide</i>.</p> <p>This action is not supported by Amazon S3 on Outposts.</p> <p>Depending on your application needs, you can choose to set the ACL on an object using either the request body or the headers. For example, if you have an existing application that updates a bucket ACL using the request body, you can continue to use that approach. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html">Access Control List (ACL) Overview</a> in the <i>Amazon S3 User Guide</i>.</p> <important> <p>If your bucket uses the bucket owner enforced setting for S3 Object Ownership, ACLs are disabled and no longer affect permissions. You must use policies to grant access to your bucket and the objects in it. Requests to set ACLs or update ACLs fail and return the <code>AccessControlListNotSupported</code> error code. Requests to read ACLs are still supported. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html">Controlling object ownership</a> in the <i>Amazon S3 User Guide</i>.</p> </important> <p> <b>Access Permissions</b> </p> <p>You can set access permissions using one of the following methods:</p> <ul> <li> <p>Specify a canned ACL with the <code>x-amz-acl</code> request header. Amazon S3 supports a set of predefined ACLs, known as canned ACLs. Each canned ACL has a predefined set of grantees and permissions. Specify the canned ACL name as the value of <code>x-amz-ac</code>l. If you use this header, you cannot use other access control-specific headers in your request. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL">Canned ACL</a>.</p> </li> <li> <p>Specify access permissions explicitly with the <code>x-amz-grant-read</code>, <code>x-amz-grant-read-acp</code>, <code>x-amz-grant-write-acp</code>, and <code>x-amz-grant-full-control</code> headers. When using these headers, you specify explicit access permissions and grantees (Amazon Web Services accounts or Amazon S3 groups) who will receive the permission. If you use these ACL-specific headers, you cannot use <code>x-amz-acl</code> header to set a canned ACL. These parameters map to the set of permissions that Amazon S3 supports in an ACL. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html">Access Control List (ACL) Overview</a>.</p> <p>You specify each grantee as a type=value pair, where the type is one of the following:</p> <ul> <li> <p> <code>id</code> – if the value specified is the canonical user ID of an Amazon Web Services account</p> </li> <li> <p> <code>uri</code> – if you are granting permissions to a predefined group</p> </li> <li> <p> <code>emailAddress</code> – if the value specified is the email address of an Amazon Web Services account</p> <note> <p>Using email addresses to specify a grantee is only supported in the following Amazon Web Services Regions: </p> <ul> <li> <p>US East (N. Virginia)</p> </li> <li> <p>US West (N. California)</p> </li> <li> <p> US West (Oregon)</p> </li> <li> <p> Asia Pacific (Singapore)</p> </li> <li> <p>Asia Pacific (Sydney)</p> </li> <li> <p>Asia Pacific (Tokyo)</p> </li> <li> <p>Europe (Ireland)</p> </li> <li> <p>South America (São Paulo)</p> </li> </ul> <p>For a list of all the Amazon S3 supported Regions and endpoints, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region">Regions and Endpoints</a> in the Amazon Web Services General Reference.</p> </note> </li> </ul> <p>For example, the following <code>x-amz-grant-read</code> header grants list objects permission to the two Amazon Web Services accounts identified by their email addresses.</p> <p> <code>x-amz-grant-read: emailAddress="xyz@amazon.com", emailAddress="abc@amazon.com" </code> </p> </li> </ul> <p>You can use either a canned ACL or specify access permissions explicitly. You cannot do both.</p> <p> <b>Grantee Values</b> </p> <p>You can specify the person (grantee) to whom you're assigning access rights (using request elements) in the following ways:</p> <ul> <li> <p>By the person's ID:</p> <p> <code>&lt;Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser"&gt;&lt;ID&gt;&lt;&gt;ID&lt;&gt;&lt;/ID&gt;&lt;DisplayName&gt;&lt;&gt;GranteesEmail&lt;&gt;&lt;/DisplayName&gt; &lt;/Grantee&gt;</code> </p> <p>DisplayName is optional and ignored in the request.</p> </li> <li> <p>By URI:</p> <p> <code>&lt;Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"&gt;&lt;URI&gt;&lt;&gt;http://acs.amazonaws.com/groups/global/AuthenticatedUsers&lt;&gt;&lt;/URI&gt;&lt;/Grantee&gt;</code> </p> </li> <li> <p>By Email address:</p> <p> <code>&lt;Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="AmazonCustomerByEmail"&gt;&lt;EmailAddress&gt;&lt;&gt;Grantees@email.com&lt;&gt;&lt;/EmailAddress&gt;lt;/Grantee&gt;</code> </p> <p>The grantee is resolved to the CanonicalUser and, in a response to a GET Object acl request, appears as the CanonicalUser.</p> <note> <p>Using email addresses to specify a grantee is only supported in the following Amazon Web Services Regions: </p> <ul> <li> <p>US East (N. Virginia)</p> </li> <li> <p>US West (N. California)</p> </li> <li> <p> US West (Oregon)</p> </li> <li> <p> Asia Pacific (Singapore)</p> </li> <li> <p>Asia Pacific (Sydney)</p> </li> <li> <p>Asia Pacific (Tokyo)</p> </li> <li> <p>Europe (Ireland)</p> </li> <li> <p>South America (São Paulo)</p> </li> </ul> <p>For a list of all the Amazon S3 supported Regions and endpoints, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region">Regions and Endpoints</a> in the Amazon Web Services General Reference.</p> </note> </li> </ul> <p> <b>Versioning</b> </p> <p>The ACL of an object is set at the object version level. By default, PUT sets the ACL of the current version of an object. To set the ACL of a different version, use the <code>versionId</code> subresource.</p> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html">CopyObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> </ul>
#
# PUT /{Bucket}/{Key}#acl
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUTacl.html
# operationId: PutObjectAcl
export def "api PutObjectAcl" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # VersionId used to reference a specific version of the object.
  --acl: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-acl: string@x-amz-acl-completer # The canned ACL to apply to the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL">Canned ACL</a>.
  --Content-MD5: string # <p>The base64-encoded 128-bit MD5 digest of the data. This header must be used as a message integrity check to verify that the request body was not corrupted in transit. For more information, go to <a href="http://www.ietf.org/rfc/rfc1864.txt">RFC 1864.&gt;</a> </p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-grant-full-control: string # <p>Allows grantee the read, write, read ACP, and write ACP permissions on the bucket.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-read: string # <p>Allows grantee to list the objects in the bucket.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-read-acp: string # <p>Allows grantee to read the bucket ACL.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-grant-write: string # <p>Allows grantee to create new objects in the bucket.</p> <p>For the bucket and object owners of existing objects, also allows deletions and overwrites of those objects.</p>
  --x-amz-grant-write-acp: string # <p>Allows grantee to write the ACL for the applicable bucket.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "acl" $acl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#acl" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-acl": $x_amz_acl, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-grant-full-control": $x_amz_grant_full_control, "x-amz-grant-read": $x_amz_grant_read, "x-amz-grant-read-acp": $x_amz_grant_read_acp, "x-amz-grant-write": $x_amz_grant_write, "x-amz-grant-write-acp": $x_amz_grant_write_acp, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Retrieves all the metadata from an object without returning the object itself. This action is useful if you're interested only in an object's metadata. To use <code>GetObjectAttributes</code>, you must have READ access to the object.</p> <p> <code>GetObjectAttributes</code> combines the functionality of <code>GetObjectAcl</code>, <code>GetObjectLegalHold</code>, <code>GetObjectLockConfiguration</code>, <code>GetObjectRetention</code>, <code>GetObjectTagging</code>, <code>HeadObject</code>, and <code>ListParts</code>. All of the data returned with each of those individual calls can be returned with a single call to <code>GetObjectAttributes</code>.</p> <p>If you encrypt an object by using server-side encryption with customer-provided encryption keys (SSE-C) when you store the object in Amazon S3, then when you retrieve the metadata from the object, you must use the following headers:</p> <ul> <li> <p> <code>x-amz-server-side-encryption-customer-algorithm</code> </p> </li> <li> <p> <code>x-amz-server-side-encryption-customer-key</code> </p> </li> <li> <p> <code>x-amz-server-side-encryption-customer-key-MD5</code> </p> </li> </ul> <p>For more information about SSE-C, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Server-Side Encryption (Using Customer-Provided Encryption Keys)</a> in the <i>Amazon S3 User Guide</i>.</p> <note> <ul> <li> <p>Encryption request headers, such as <code>x-amz-server-side-encryption</code>, should not be sent for GET requests if your object uses server-side encryption with Amazon Web Services KMS keys stored in Amazon Web Services Key Management Service (SSE-KMS) or server-side encryption with Amazon S3 managed encryption keys (SSE-S3). If your object does use these types of keys, you'll get an HTTP <code>400 Bad Request</code> error.</p> </li> <li> <p> The last modified property in this case is the creation date of the object.</p> </li> </ul> </note> <p>Consider the following when using request headers:</p> <ul> <li> <p> If both of the <code>If-Match</code> and <code>If-Unmodified-Since</code> headers are present in the request as follows, then Amazon S3 returns the HTTP status code <code>200 OK</code> and the data requested:</p> <ul> <li> <p> <code>If-Match</code> condition evaluates to <code>true</code>.</p> </li> <li> <p> <code>If-Unmodified-Since</code> condition evaluates to <code>false</code>.</p> </li> </ul> </li> <li> <p>If both of the <code>If-None-Match</code> and <code>If-Modified-Since</code> headers are present in the request as follows, then Amazon S3 returns the HTTP status code <code>304 Not Modified</code>:</p> <ul> <li> <p> <code>If-None-Match</code> condition evaluates to <code>false</code>.</p> </li> <li> <p> <code>If-Modified-Since</code> condition evaluates to <code>true</code>.</p> </li> </ul> </li> </ul> <p>For more information about conditional requests, see <a href="https://tools.ietf.org/html/rfc7232">RFC 7232</a>.</p> <p> <b>Permissions</b> </p> <p>The permissions that you need to use this operation depend on whether the bucket is versioned. If the bucket is versioned, you need both the <code>s3:GetObjectVersion</code> and <code>s3:GetObjectVersionAttributes</code> permissions for this operation. If the bucket is not versioned, you need the <code>s3:GetObject</code> and <code>s3:GetObjectAttributes</code> permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html">Specifying Permissions in a Policy</a> in the <i>Amazon S3 User Guide</i>. If the object that you request does not exist, the error Amazon S3 returns depends on whether you also have the <code>s3:ListBucket</code> permission.</p> <ul> <li> <p>If you have the <code>s3:ListBucket</code> permission on the bucket, Amazon S3 returns an HTTP status code <code>404 Not Found</code> ("no such key") error.</p> </li> <li> <p>If you don't have the <code>s3:ListBucket</code> permission, Amazon S3 returns an HTTP status code <code>403 Forbidden</code> ("access denied") error.</p> </li> </ul> <p>The following actions are related to <code>GetObjectAttributes</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAcl.html">GetObjectAcl</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectLegalHold.html">GetObjectLegalHold</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectLockConfiguration.html">GetObjectLockConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectRetention.html">GetObjectRetention</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html">GetObjectTagging</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html">HeadObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html">ListParts</a> </p> </li> </ul>
#
# GET /{Bucket}/{Key}#attributes&x-amz-object-attributes
# operationId: GetObjectAttributes
export def "api GetObjectAttributes" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # The version ID used to reference a specific version of the object.
  --attributes: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-max-parts: int # Sets the maximum number of parts to return.
  --x-amz-part-number-marker: int # Specifies the part after which listing should begin. Only parts with higher part numbers will be listed.
  --x-amz-server-side-encryption-customer-algorithm: string # Specifies the algorithm to use when encrypting the object (for example, AES256).
  --x-amz-server-side-encryption-customer-key: string # Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon S3 does not store the encryption key. The key must be appropriate for use with the algorithm specified in the <code>x-amz-server-side-encryption-customer-algorithm</code> header.
  --x-amz-server-side-encryption-customer-key-MD5: string # Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-object-attributes: list # An XML header that specifies the fields at the root level that you want returned in the response. Fields that you do not specify are not returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "attributes" $attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#attributes&x-amz-object-attributes" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-max-parts": $x_amz_max_parts, "x-amz-part-number-marker": $x_amz_part_number_marker, "x-amz-server-side-encryption-customer-algorithm": $x_amz_server_side_encryption_customer_algorithm, "x-amz-server-side-encryption-customer-key": $x_amz_server_side_encryption_customer_key, "x-amz-server-side-encryption-customer-key-MD5": $x_amz_server_side_encryption_customer_key_MD5, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-object-attributes": $x_amz_object_attributes} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Gets an object's current legal hold status. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html">Locking Objects</a>.</p> <p>This action is not supported by Amazon S3 on Outposts.</p> <p>The following action is related to <code>GetObjectLegalHold</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html">GetObjectAttributes</a> </p> </li> </ul>
#
# GET /{Bucket}/{Key}#legal-hold
# operationId: GetObjectLegalHold
export def "api GetObjectLegalHold" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # The version ID of the object whose legal hold status you want to retrieve.
  --legal-hold: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "legal-hold" $legal_hold "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#legal-hold" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Applies a legal hold configuration to the specified object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html">Locking Objects</a>.</p> <p>This action is not supported by Amazon S3 on Outposts.</p>
#
# PUT /{Bucket}/{Key}#legal-hold
# operationId: PutObjectLegalHold
export def "api PutObjectLegalHold" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # The version ID of the object that you want to place a legal hold on.
  --legal-hold: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --Content-MD5: string # <p>The MD5 hash for the request body.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "legal-hold" $legal_hold "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#legal-hold" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Gets the Object Lock configuration for a bucket. The rule specified in the Object Lock configuration will be applied by default to every new object placed in the specified bucket. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html">Locking Objects</a>.</p> <p>The following action is related to <code>GetObjectLockConfiguration</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html">GetObjectAttributes</a> </p> </li> </ul>
#
# GET /{Bucket}#object-lock
# operationId: GetObjectLockConfiguration
export def "api GetObjectLockConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --object-lock: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "object-lock" $object_lock "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#object-lock" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Places an Object Lock configuration on the specified bucket. The rule specified in the Object Lock configuration will be applied by default to every new object placed in the specified bucket. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html">Locking Objects</a>. </p> <note> <ul> <li> <p>The <code>DefaultRetention</code> settings require both a mode and a period.</p> </li> <li> <p>The <code>DefaultRetention</code> period can be either <code>Days</code> or <code>Years</code> but you must select one. You cannot specify <code>Days</code> and <code>Years</code> at the same time.</p> </li> <li> <p>You can only enable Object Lock for new buckets. If you want to turn on Object Lock for an existing bucket, contact Amazon Web Services Support.</p> </li> </ul> </note>
#
# PUT /{Bucket}#object-lock
# operationId: PutObjectLockConfiguration
export def "api PutObjectLockConfiguration" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --object-lock: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-bucket-object-lock-token: string # A token to allow Object Lock to be enabled for an existing bucket.
  --Content-MD5: string # <p>The MD5 hash for the request body.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "object-lock" $object_lock "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#object-lock" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "x-amz-bucket-object-lock-token": $x_amz_bucket_object_lock_token, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Retrieves an object's retention settings. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html">Locking Objects</a>.</p> <p>This action is not supported by Amazon S3 on Outposts.</p> <p>The following action is related to <code>GetObjectRetention</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html">GetObjectAttributes</a> </p> </li> </ul>
#
# GET /{Bucket}/{Key}#retention
# operationId: GetObjectRetention
export def "api GetObjectRetention" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # The version ID for the object whose retention settings you want to retrieve.
  --retention: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "retention" $retention "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#retention" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Places an Object Retention configuration on an object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html">Locking Objects</a>. Users or accounts require the <code>s3:PutObjectRetention</code> permission in order to place an Object Retention configuration on objects. Bypassing a Governance Retention configuration requires the <code>s3:BypassGovernanceRetention</code> permission. </p> <p>This action is not supported by Amazon S3 on Outposts.</p>
#
# PUT /{Bucket}/{Key}#retention
# operationId: PutObjectRetention
export def "api PutObjectRetention" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # The version ID for the object that you want to apply this Object Retention configuration to.
  --retention: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-bypass-governance-retention: string@bool-completer # Indicates whether this action should bypass Governance-mode restrictions.
  --Content-MD5: string # <p>The MD5 hash for the request body.</p> <p>For requests made using the Amazon Web Services Command Line Interface (CLI) or Amazon Web Services SDKs, this field is calculated automatically.</p>
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "retention" $retention "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#retention" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "x-amz-bypass-governance-retention": $x_amz_bypass_governance_retention, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Returns torrent files from a bucket. BitTorrent can save you bandwidth when you're distributing large files. For more information about BitTorrent, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/S3Torrent.html">Using BitTorrent with Amazon S3</a>.</p> <note> <p>You can get torrent only for objects that are less than 5 GB in size, and that are not encrypted using server-side encryption with a customer-provided encryption key.</p> </note> <p>To use GET, you must have READ access to the object.</p> <p>This action is not supported by Amazon S3 on Outposts.</p> <p>The following action is related to <code>GetObjectTorrent</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> </ul>
#
# GET /{Bucket}/{Key}#torrent
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectGETtorrent.html
# operationId: GetObjectTorrent
export def "api GetObjectTorrent" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --torrent: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "torrent" $torrent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#torrent" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Lists the analytics configurations for the bucket. You can have up to 1,000 analytics configurations per bucket.</p> <p>This action supports list pagination and does not return more than 100 configurations at a time. You should always check the <code>IsTruncated</code> element in the response. If there are no more configurations to list, <code>IsTruncated</code> is set to false. If there are more configurations to list, <code>IsTruncated</code> is set to true, and there will be a value in <code>NextContinuationToken</code>. You use the <code>NextContinuationToken</code> value to continue the pagination of the list by passing the value in continuation-token in the request to <code>GET</code> the next page.</p> <p>To use this operation, you must have permissions to perform the <code>s3:GetAnalyticsConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>For information about Amazon S3 analytics feature, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/analytics-storage-class.html">Amazon S3 Analytics – Storage Class Analysis</a>. </p> <p>The following operations are related to <code>ListBucketAnalyticsConfigurations</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAnalyticsConfiguration.html">GetBucketAnalyticsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketAnalyticsConfiguration.html">DeleteBucketAnalyticsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketAnalyticsConfiguration.html">PutBucketAnalyticsConfiguration</a> </p> </li> </ul>
#
# GET /{Bucket}#analytics
# operationId: ListBucketAnalyticsConfigurations
export def "api ListBucketAnalyticsConfigurations" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --continuation-token: string # The ContinuationToken that represents a placeholder from where this request should begin.
  --analytics: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "continuation-token" $continuation_token "scalar") (serialize-qp "analytics" $analytics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#analytics" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Lists the S3 Intelligent-Tiering configuration from the specified bucket.</p> <p>The S3 Intelligent-Tiering storage class is designed to optimize storage costs by automatically moving data to the most cost-effective storage access tier, without performance impact or operational overhead. S3 Intelligent-Tiering delivers automatic cost savings in three low latency and high throughput access tiers. To get the lowest storage cost on data that can be accessed in minutes to hours, you can choose to activate additional archiving capabilities.</p> <p>The S3 Intelligent-Tiering storage class is the ideal storage class for data with unknown, changing, or unpredictable access patterns, independent of object size or retention period. If the size of an object is less than 128 KB, it is not monitored and not eligible for auto-tiering. Smaller objects can be stored, but they are always charged at the Frequent Access tier rates in the S3 Intelligent-Tiering storage class.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-dynamic-data-access">Storage class for automatically optimizing frequently and infrequently accessed objects</a>.</p> <p>Operations related to <code>ListBucketIntelligentTieringConfigurations</code> include: </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketIntelligentTieringConfiguration.html">DeleteBucketIntelligentTieringConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketIntelligentTieringConfiguration.html">PutBucketIntelligentTieringConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketIntelligentTieringConfiguration.html">GetBucketIntelligentTieringConfiguration</a> </p> </li> </ul>
#
# GET /{Bucket}#intelligent-tiering
# operationId: ListBucketIntelligentTieringConfigurations
export def "api ListBucketIntelligentTieringConfigurations" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --continuation-token: string # The <code>ContinuationToken</code> that represents a placeholder from where this request should begin.
  --intelligent-tiering: string@bool-completer # allows empty value
  --x-amz-security-token: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "continuation-token" $continuation_token "scalar") (serialize-qp "intelligent-tiering" $intelligent_tiering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#intelligent-tiering" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns a list of inventory configurations for the bucket. You can have up to 1,000 analytics configurations per bucket.</p> <p>This action supports list pagination and does not return more than 100 configurations at a time. Always check the <code>IsTruncated</code> element in the response. If there are no more configurations to list, <code>IsTruncated</code> is set to false. If there are more configurations to list, <code>IsTruncated</code> is set to true, and there is a value in <code>NextContinuationToken</code>. You use the <code>NextContinuationToken</code> value to continue the pagination of the list by passing the value in continuation-token in the request to <code>GET</code> the next page.</p> <p> To use this operation, you must have permissions to perform the <code>s3:GetInventoryConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>For information about the Amazon S3 inventory feature, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-inventory.html">Amazon S3 Inventory</a> </p> <p>The following operations are related to <code>ListBucketInventoryConfigurations</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketInventoryConfiguration.html">GetBucketInventoryConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketInventoryConfiguration.html">DeleteBucketInventoryConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketInventoryConfiguration.html">PutBucketInventoryConfiguration</a> </p> </li> </ul>
#
# GET /{Bucket}#inventory
# operationId: ListBucketInventoryConfigurations
export def "api ListBucketInventoryConfigurations" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --continuation-token: string # The marker used to continue an inventory configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  --inventory: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "continuation-token" $continuation_token "scalar") (serialize-qp "inventory" $inventory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#inventory" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Lists the metrics configurations for the bucket. The metrics configurations are only for the request metrics of the bucket and do not provide information on daily storage metrics. You can have up to 1,000 configurations per bucket.</p> <p>This action supports list pagination and does not return more than 100 configurations at a time. Always check the <code>IsTruncated</code> element in the response. If there are no more configurations to list, <code>IsTruncated</code> is set to false. If there are more configurations to list, <code>IsTruncated</code> is set to true, and there is a value in <code>NextContinuationToken</code>. You use the <code>NextContinuationToken</code> value to continue the pagination of the list by passing the value in <code>continuation-token</code> in the request to <code>GET</code> the next page.</p> <p>To use this operation, you must have permissions to perform the <code>s3:GetMetricsConfiguration</code> action. The bucket owner has this permission by default. The bucket owner can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <p>For more information about metrics configurations and CloudWatch request metrics, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/cloudwatch-monitoring.html">Monitoring Metrics with Amazon CloudWatch</a>.</p> <p>The following operations are related to <code>ListBucketMetricsConfigurations</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketMetricsConfiguration.html">PutBucketMetricsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketMetricsConfiguration.html">GetBucketMetricsConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketMetricsConfiguration.html">DeleteBucketMetricsConfiguration</a> </p> </li> </ul>
#
# GET /{Bucket}#metrics
# operationId: ListBucketMetricsConfigurations
export def "api ListBucketMetricsConfigurations" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --continuation-token: string # The marker that is used to continue a metrics configuration listing that has been truncated. Use the NextContinuationToken from a previously truncated list response to continue the listing. The continuation token is an opaque value that Amazon S3 understands.
  --metrics: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "continuation-token" $continuation_token "scalar") (serialize-qp "metrics" $metrics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#metrics" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of all buckets owned by the authenticated sender of the request. To use this operation, you must have the <code>s3:ListAllMyBuckets</code> permission.
#
# GET /
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTServiceGET.html
# operationId: ListBuckets
export def "api ListBuckets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-amz-security-token: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let extra_headers = {"x-amz-security-token": $x_amz_security_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>This action lists in-progress multipart uploads. An in-progress multipart upload is a multipart upload that has been initiated using the Initiate Multipart Upload request, but has not yet been completed or aborted.</p> <p>This action returns at most 1,000 multipart uploads in the response. 1,000 multipart uploads is the maximum number of uploads a response can include, which is also the default value. You can further limit the number of uploads in a response by specifying the <code>max-uploads</code> parameter in the response. If additional multipart uploads satisfy the list criteria, the response will contain an <code>IsTruncated</code> element with the value true. To list the additional multipart uploads, use the <code>key-marker</code> and <code>upload-id-marker</code> request parameters.</p> <p>In the response, the uploads are sorted by key. If your application has initiated more than one multipart upload using the same object key, then uploads in the response are first sorted by key. Additionally, uploads are sorted in ascending order within each key by the upload initiation time.</p> <p>For more information on multipart uploads, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/uploadobjusingmpu.html">Uploading Objects Using Multipart Upload</a>.</p> <p>For information on permissions required to use the multipart upload API, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html">Multipart Upload and Permissions</a>.</p> <p>The following operations are related to <code>ListMultipartUploads</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html">CreateMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html">CompleteMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html">ListParts</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html">AbortMultipartUpload</a> </p> </li> </ul>
#
# GET /{Bucket}#uploads
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListMPUpload.html
# operationId: ListMultipartUploads
export def "api ListMultipartUploads" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delimiter: string # <p>Character you use to group keys.</p> <p>All keys that contain the same string between the prefix, if specified, and the first occurrence of the delimiter after the prefix are grouped under a single result element, <code>CommonPrefixes</code>. If you don't specify the prefix parameter, then the substring starts at the beginning of the key. The keys that are grouped under <code>CommonPrefixes</code> result element are not returned elsewhere in the response.</p>
  --encoding-type: string@encoding-type-completer
  --key-marker: string # <p>Together with upload-id-marker, this parameter specifies the multipart upload after which listing should begin.</p> <p>If <code>upload-id-marker</code> is not specified, only the keys lexicographically greater than the specified <code>key-marker</code> will be included in the list.</p> <p>If <code>upload-id-marker</code> is specified, any multipart uploads for a key equal to the <code>key-marker</code> might also be included, provided those multipart uploads have upload IDs lexicographically greater than the specified <code>upload-id-marker</code>.</p>
  --max-uploads: int # Sets the maximum number of multipart uploads, from 1 to 1,000, to return in the response body. 1,000 is the maximum number of uploads that can be returned in a response.
  --prefix: string # Lists in-progress uploads only for those keys that begin with the specified prefix. You can use prefixes to separate a bucket into different grouping of keys. (You can think of using prefix to make groups in the same way you'd use a folder in a file system.)
  --upload-id-marker: string # Together with key-marker, specifies the multipart upload after which listing should begin. If key-marker is not specified, the upload-id-marker parameter is ignored. Otherwise, any multipart uploads for a key equal to the key-marker might be included in the list only if they have an upload ID lexicographically greater than the specified <code>upload-id-marker</code>.
  --MaxUploads: string # Pagination limit
  --KeyMarker: string # Pagination token
  --UploadIdMarker: string # Pagination token
  --uploads: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "encoding-type" $encoding_type "scalar") (serialize-qp "key-marker" $key_marker "scalar") (serialize-qp "max-uploads" $max_uploads "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "upload-id-marker" $upload_id_marker "scalar") (serialize-qp "MaxUploads" $MaxUploads "scalar") (serialize-qp "KeyMarker" $KeyMarker "scalar") (serialize-qp "UploadIdMarker" $UploadIdMarker "scalar") (serialize-qp "uploads" $uploads "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#uploads" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns metadata about all versions of the objects in a bucket. You can also use request parameters as selection criteria to return metadata about a subset of all the object versions.</p> <important> <p> To use this operation, you must have permissions to perform the <code>s3:ListBucketVersions</code> action. Be aware of the name difference. </p> </important> <note> <p> A 200 OK response can contain valid or invalid XML. Make sure to design your application to parse the contents of the response and handle it appropriately.</p> </note> <p>To use this operation, you must have READ access to the bucket.</p> <p>This action is not supported by Amazon S3 on Outposts.</p> <p>The following operations are related to <code>ListObjectVersions</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjectsV2.html">ListObjectsV2</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html">PutObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html">DeleteObject</a> </p> </li> </ul>
#
# GET /{Bucket}#versions
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketGETVersion.html
# operationId: ListObjectVersions
export def "api ListObjectVersions" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delimiter: string # A delimiter is a character that you specify to group keys. All keys that contain the same string between the <code>prefix</code> and the first occurrence of the delimiter are grouped under a single result element in CommonPrefixes. These groups are counted as one result against the max-keys limitation. These keys are not returned elsewhere in the response.
  --encoding-type: string@encoding-type-completer
  --key-marker: string # Specifies the key to start with when listing objects in a bucket.
  --max-keys: int # Sets the maximum number of keys returned in the response. By default the action returns up to 1,000 key names. The response might contain fewer keys but will never contain more. If additional keys satisfy the search criteria, but were not returned because max-keys was exceeded, the response contains &lt;isTruncated&gt;true&lt;/isTruncated&gt;. To return the additional keys, see key-marker and version-id-marker.
  --prefix: string # Use this parameter to select only those keys that begin with the specified prefix. You can use prefixes to separate a bucket into different groupings of keys. (You can think of using prefix to make groups in the same way you'd use a folder in a file system.) You can use prefix with delimiter to roll up numerous objects into a single result under CommonPrefixes. 
  --version-id-marker: string # Specifies the object version you want to start listing from.
  --MaxKeys: string # Pagination limit
  --KeyMarker: string # Pagination token
  --VersionIdMarker: string # Pagination token
  --versions: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "encoding-type" $encoding_type "scalar") (serialize-qp "key-marker" $key_marker "scalar") (serialize-qp "max-keys" $max_keys "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "version-id-marker" $version_id_marker "scalar") (serialize-qp "MaxKeys" $MaxKeys "scalar") (serialize-qp "KeyMarker" $KeyMarker "scalar") (serialize-qp "VersionIdMarker" $VersionIdMarker "scalar") (serialize-qp "versions" $versions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#versions" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Returns some or all (up to 1,000) of the objects in a bucket with each request. You can use the request parameters as selection criteria to return a subset of the objects in a bucket. A <code>200 OK</code> response can contain valid or invalid XML. Make sure to design your application to parse the contents of the response and handle it appropriately. Objects are returned sorted in an ascending order of the respective key names in the list. For more information about listing objects, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/ListingKeysUsingAPIs.html">Listing object keys programmatically</a> </p> <p>To use this operation, you must have READ access to the bucket.</p> <p>To use this action in an Identity and Access Management (IAM) policy, you must have permissions to perform the <code>s3:ListBucket</code> action. The bucket owner has this permission by default and can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a>.</p> <important> <p>This section describes the latest revision of this action. We recommend that you use this revised API for application development. For backward compatibility, Amazon S3 continues to support the prior version of this API, <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjects.html">ListObjects</a>.</p> </important> <p>To get a list of your buckets, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBuckets.html">ListBuckets</a>.</p> <p>The following operations are related to <code>ListObjectsV2</code>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html">PutObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html">CreateBucket</a> </p> </li> </ul>
#
# GET /{Bucket}#list-type=2
# operationId: ListObjectsV2
export def "api ListObjectsV2" [
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delimiter: string # A delimiter is a character you use to group keys.
  --encoding-type: string@encoding-type-completer # Encoding type used by Amazon S3 to encode object keys in the response.
  --max-keys: int # Sets the maximum number of keys returned in the response. By default the action returns up to 1,000 key names. The response might contain fewer keys but will never contain more.
  --prefix: string # Limits the response to keys that begin with the specified prefix.
  --continuation-token: string # ContinuationToken indicates Amazon S3 that the list is being continued on this bucket with a token. ContinuationToken is obfuscated and is not a real key.
  --fetch-owner: string@bool-completer # The owner field is not present in listV2 by default, if you want to return owner field with each key in the result then set the fetch owner field to true.
  --start-after: string # StartAfter is where you want Amazon S3 to start listing from. Amazon S3 starts listing after this specified key. StartAfter can be any key in the bucket.
  --MaxKeys: string # Pagination limit
  --ContinuationToken: string # Pagination token
  --list-type: string@list-type-completer
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer # Confirms that the requester knows that she or he will be charged for the list objects request in V2 style. Bucket owners need not specify this parameter in their requests.
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "encoding-type" $encoding_type "scalar") (serialize-qp "max-keys" $max_keys "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "continuation-token" $continuation_token "scalar") (serialize-qp "fetch-owner" $fetch_owner "scalar") (serialize-qp "start-after" $start_after "scalar") (serialize-qp "MaxKeys" $MaxKeys "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "list-type" $list_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)#list-type=2" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Restores an archived copy of an object back into Amazon S3</p> <p>This action is not supported by Amazon S3 on Outposts.</p> <p>This action performs the following types of requests: </p> <ul> <li> <p> <code>select</code> - Perform a select query on an archived object</p> </li> <li> <p> <code>restore an archive</code> - Restore an archived object</p> </li> </ul> <p>To use this operation, you must have permissions to perform the <code>s3:RestoreObject</code> action. The bucket owner has this permission by default and can grant this permission to others. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources">Permissions Related to Bucket Subresource Operations</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html">Managing Access Permissions to Your Amazon S3 Resources</a> in the <i>Amazon S3 User Guide</i>.</p> <p> <b>Querying Archives with Select Requests</b> </p> <p>You use a select type of request to perform SQL queries on archived objects. The archived objects that are being queried by the select request must be formatted as uncompressed comma-separated values (CSV) files. You can run queries and custom analytics on your archived data without having to restore your data to a hotter Amazon S3 tier. For an overview about select requests, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/querying-glacier-archives.html">Querying Archived Objects</a> in the <i>Amazon S3 User Guide</i>.</p> <p>When making a select request, do the following:</p> <ul> <li> <p>Define an output location for the select query's output. This must be an Amazon S3 bucket in the same Amazon Web Services Region as the bucket that contains the archive object that is being queried. The Amazon Web Services account that initiates the job must have permissions to write to the S3 bucket. You can specify the storage class and encryption for the output objects stored in the bucket. For more information about output, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/querying-glacier-archives.html">Querying Archived Objects</a> in the <i>Amazon S3 User Guide</i>.</p> <p>For more information about the <code>S3</code> structure in the request body, see the following:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html">PutObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_ACLs_UsingACLs.html">Managing Access with ACLs</a> in the <i>Amazon S3 User Guide</i> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html">Protecting Data Using Server-Side Encryption</a> in the <i>Amazon S3 User Guide</i> </p> </li> </ul> </li> <li> <p>Define the SQL expression for the <code>SELECT</code> type of restoration for your query in the request body's <code>SelectParameters</code> structure. You can use expressions like the following examples.</p> <ul> <li> <p>The following expression returns all records from the specified object.</p> <p> <code>SELECT * FROM Object</code> </p> </li> <li> <p>Assuming that you are not using any headers for data stored in the object, you can specify columns with positional headers.</p> <p> <code>SELECT s._1, s._2 FROM Object s WHERE s._3 &gt; 100</code> </p> </li> <li> <p>If you have headers and you set the <code>fileHeaderInfo</code> in the <code>CSV</code> structure in the request body to <code>USE</code>, you can specify headers in the query. (If you set the <code>fileHeaderInfo</code> field to <code>IGNORE</code>, the first row is skipped for the query.) You cannot mix ordinal positions with header column names. </p> <p> <code>SELECT s.Id, s.FirstName, s.SSN FROM S3Object s</code> </p> </li> </ul> </li> </ul> <p>For more information about using SQL with S3 Glacier Select restore, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-glacier-select-sql-reference.html">SQL Reference for Amazon S3 Select and S3 Glacier Select</a> in the <i>Amazon S3 User Guide</i>. </p> <p>When making a select request, you can also do the following:</p> <ul> <li> <p>To expedite your queries, specify the <code>Expedited</code> tier. For more information about tiers, see "Restoring Archives," later in this topic.</p> </li> <li> <p>Specify details about the data serialization format of both the input object that is being queried and the serialization of the CSV-encoded query results.</p> </li> </ul> <p>The following are additional important facts about the select feature:</p> <ul> <li> <p>The output results are new Amazon S3 objects. Unlike archive retrievals, they are stored until explicitly deleted-manually or through a lifecycle policy.</p> </li> <li> <p>You can issue more than one select request on the same Amazon S3 object. Amazon S3 doesn't deduplicate requests, so avoid issuing duplicate requests.</p> </li> <li> <p> Amazon S3 accepts a select request even if the object has already been restored. A select request doesn’t return error response <code>409</code>.</p> </li> </ul> <p> <b>Restoring objects</b> </p> <p>Objects that you archive to the S3 Glacier or S3 Glacier Deep Archive storage class, and S3 Intelligent-Tiering Archive or S3 Intelligent-Tiering Deep Archive tiers are not accessible in real time. For objects in Archive Access or Deep Archive Access tiers you must first initiate a restore request, and then wait until the object is moved into the Frequent Access tier. For objects in S3 Glacier or S3 Glacier Deep Archive storage classes you must first initiate a restore request, and then wait until a temporary copy of the object is available. To access an archived object, you must restore the object for the duration (number of days) that you specify.</p> <p>To restore a specific object version, you can provide a version ID. If you don't provide a version ID, Amazon S3 restores the current version.</p> <p>When restoring an archived object (or using a select request), you can specify one of the following data access tier options in the <code>Tier</code> element of the request body: </p> <ul> <li> <p> <code>Expedited</code> - Expedited retrievals allow you to quickly access your data stored in the S3 Glacier storage class or S3 Intelligent-Tiering Archive tier when occasional urgent requests for a subset of archives are required. For all but the largest archived objects (250 MB+), data accessed using Expedited retrievals is typically made available within 1–5 minutes. Provisioned capacity ensures that retrieval capacity for Expedited retrievals is available when you need it. Expedited retrievals and provisioned capacity are not available for objects stored in the S3 Glacier Deep Archive storage class or S3 Intelligent-Tiering Deep Archive tier.</p> </li> <li> <p> <code>Standard</code> - Standard retrievals allow you to access any of your archived objects within several hours. This is the default option for retrieval requests that do not specify the retrieval option. Standard retrievals typically finish within 3–5 hours for objects stored in the S3 Glacier storage class or S3 Intelligent-Tiering Archive tier. They typically finish within 12 hours for objects stored in the S3 Glacier Deep Archive storage class or S3 Intelligent-Tiering Deep Archive tier. Standard retrievals are free for objects stored in S3 Intelligent-Tiering.</p> </li> <li> <p> <code>Bulk</code> - Bulk retrievals are the lowest-cost retrieval option in S3 Glacier, enabling you to retrieve large amounts, even petabytes, of data inexpensively. Bulk retrievals typically finish within 5–12 hours for objects stored in the S3 Glacier storage class or S3 Intelligent-Tiering Archive tier. They typically finish within 48 hours for objects stored in the S3 Glacier Deep Archive storage class or S3 Intelligent-Tiering Deep Archive tier. Bulk retrievals are free for objects stored in S3 Intelligent-Tiering.</p> </li> </ul> <p>For more information about archive retrieval options and provisioned capacity for <code>Expedited</code> data access, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/restoring-objects.html">Restoring Archived Objects</a> in the <i>Amazon S3 User Guide</i>. </p> <p>You can use Amazon S3 restore speed upgrade to change the restore speed to a faster speed while it is in progress. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/restoring-objects.html#restoring-objects-upgrade-tier.title.html"> Upgrading the speed of an in-progress restore</a> in the <i>Amazon S3 User Guide</i>. </p> <p>To get the status of object restoration, you can send a <code>HEAD</code> request. Operations return the <code>x-amz-restore</code> header, which provides information about the restoration status, in the response. You can use Amazon S3 event notifications to notify you when a restore is initiated or completed. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html">Configuring Amazon S3 Event Notifications</a> in the <i>Amazon S3 User Guide</i>.</p> <p>After restoring an archived object, you can update the restoration period by reissuing the request with a new period. Amazon S3 updates the restoration period relative to the current time and charges only for the request-there are no data transfer charges. You cannot update the restoration period when Amazon S3 is actively processing your current restore request for the object.</p> <p>If your bucket has a lifecycle configuration with a rule that includes an expiration action, the object expiration overrides the life span that you specify in a restore request. For example, if you restore an object copy for 10 days, but the object is scheduled to expire in 3 days, Amazon S3 deletes the object in 3 days. For more information about lifecycle configuration, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html">PutBucketLifecycleConfiguration</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html">Object Lifecycle Management</a> in <i>Amazon S3 User Guide</i>.</p> <p> <b>Responses</b> </p> <p>A successful action returns either the <code>200 OK</code> or <code>202 Accepted</code> status code. </p> <ul> <li> <p>If the object is not previously restored, then Amazon S3 returns <code>202 Accepted</code> in the response. </p> </li> <li> <p>If the object is previously restored, Amazon S3 returns <code>200 OK</code> in the response. </p> </li> </ul> <p class="title"> <b>Special Errors</b> </p> <ul> <li> <ul> <li> <p> <i>Code: RestoreAlreadyInProgress</i> </p> </li> <li> <p> <i>Cause: Object restore is already in progress. (This error does not apply to SELECT type requests.)</i> </p> </li> <li> <p> <i>HTTP Status Code: 409 Conflict</i> </p> </li> <li> <p> <i>SOAP Fault Code Prefix: Client</i> </p> </li> </ul> </li> <li> <ul> <li> <p> <i>Code: GlacierExpeditedRetrievalNotAvailable</i> </p> </li> <li> <p> <i>Cause: expedited retrievals are currently not available. Try again later. (Returned if there is insufficient capacity to process the Expedited request. This error applies only to Expedited retrievals and not to S3 Standard or Bulk retrievals.)</i> </p> </li> <li> <p> <i>HTTP Status Code: 503</i> </p> </li> <li> <p> <i>SOAP Fault Code Prefix: N/A</i> </p> </li> </ul> </li> </ul> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html">PutBucketLifecycleConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketNotificationConfiguration.html">GetBucketNotificationConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-glacier-select-sql-reference.html">SQL Reference for Amazon S3 Select and S3 Glacier Select </a> in the <i>Amazon S3 User Guide</i> </p> </li> </ul>
#
# POST /{Bucket}/{Key}#restore
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectRestore.html
# operationId: RestoreObject
export def "api RestoreObject" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # VersionId used to reference a specific version of the object.
  --restore: string@bool-completer # allows empty value
  --x-amz-security-token: string
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p>
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar") (serialize-qp "restore" $restore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#restore" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-payer": $x_amz_request_payer, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>This action filters the contents of an Amazon S3 object based on a simple structured query language (SQL) statement. In the request, along with the SQL expression, you must also specify a data serialization format (JSON, CSV, or Apache Parquet) of the object. Amazon S3 uses this format to parse object data into records, and returns only records that match the specified SQL expression. You must also specify the data serialization format for the response.</p> <p>This action is not supported by Amazon S3 on Outposts.</p> <p>For more information about Amazon S3 Select, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/selecting-content-from-objects.html">Selecting Content from Objects</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-glacier-select-sql-reference-select.html">SELECT Command</a> in the <i>Amazon S3 User Guide</i>.</p> <p>For more information about using SQL with Amazon S3 Select, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-glacier-select-sql-reference.html"> SQL Reference for Amazon S3 Select and S3 Glacier Select</a> in the <i>Amazon S3 User Guide</i>.</p> <p/> <p> <b>Permissions</b> </p> <p>You must have <code>s3:GetObject</code> permission for this operation. Amazon S3 Select does not support anonymous access. For more information about permissions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html">Specifying Permissions in a Policy</a> in the <i>Amazon S3 User Guide</i>.</p> <p/> <p> <i>Object Data Formats</i> </p> <p>You can use Amazon S3 Select to query objects that have the following format properties:</p> <ul> <li> <p> <i>CSV, JSON, and Parquet</i> - Objects must be in CSV, JSON, or Parquet format.</p> </li> <li> <p> <i>UTF-8</i> - UTF-8 is the only encoding type Amazon S3 Select supports.</p> </li> <li> <p> <i>GZIP or BZIP2</i> - CSV and JSON files can be compressed using GZIP or BZIP2. GZIP and BZIP2 are the only compression formats that Amazon S3 Select supports for CSV and JSON files. Amazon S3 Select supports columnar compression for Parquet using GZIP or Snappy. Amazon S3 Select does not support whole-object compression for Parquet objects.</p> </li> <li> <p> <i>Server-side encryption</i> - Amazon S3 Select supports querying objects that are protected with server-side encryption.</p> <p>For objects that are encrypted with customer-provided encryption keys (SSE-C), you must use HTTPS, and you must use the headers that are documented in the <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a>. For more information about SSE-C, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Server-Side Encryption (Using Customer-Provided Encryption Keys)</a> in the <i>Amazon S3 User Guide</i>.</p> <p>For objects that are encrypted with Amazon S3 managed encryption keys (SSE-S3) and Amazon Web Services KMS keys (SSE-KMS), server-side encryption is handled transparently, so you don't need to specify anything. For more information about server-side encryption, including SSE-S3 and SSE-KMS, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html">Protecting Data Using Server-Side Encryption</a> in the <i>Amazon S3 User Guide</i>.</p> </li> </ul> <p> <b>Working with the Response Body</b> </p> <p>Given the response size is unknown, Amazon S3 Select streams the response as a series of messages and includes a <code>Transfer-Encoding</code> header with <code>chunked</code> as its value in the response. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/RESTSelectObjectAppendix.html">Appendix: SelectObjectContent Response</a>.</p> <p/> <p> <b>GetObject Support</b> </p> <p>The <code>SelectObjectContent</code> action does not support the following <code>GetObject</code> functionality. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a>.</p> <ul> <li> <p> <code>Range</code>: Although you can specify a scan range for an Amazon S3 Select request (see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_SelectObjectContent.html#AmazonS3-SelectObjectContent-request-ScanRange">SelectObjectContentRequest - ScanRange</a> in the request parameters), you cannot specify the range of bytes of an object to return. </p> </li> <li> <p>GLACIER, DEEP_ARCHIVE and REDUCED_REDUNDANCY storage classes: You cannot specify the GLACIER, DEEP_ARCHIVE, or <code>REDUCED_REDUNDANCY</code> storage classes. For more information, about storage classes see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html#storage-class-intro">Storage Classes</a> in the <i>Amazon S3 User Guide</i>.</p> </li> </ul> <p/> <p> <b>Special Errors</b> </p> <p>For a list of special errors for this operation, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#SelectObjectContentErrorCodeList">List of SELECT Object Content Error Codes</a> </p> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html">GetBucketLifecycleConfiguration</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html">PutBucketLifecycleConfiguration</a> </p> </li> </ul>
#
# POST /{Bucket}/{Key}#select&select-type=2
# operationId: SelectObjectContent
export def "api SelectObjectContent" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string@bool-completer # allows empty value
  --select-type: string@select-type-completer
  --x-amz-security-token: string
  --x-amz-server-side-encryption-customer-algorithm: string # The server-side encryption (SSE) algorithm used to encrypt the object. This parameter is needed only when the object was created using a checksum algorithm. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Protecting data using SSE-C keys</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-server-side-encryption-customer-key: string # The server-side encryption (SSE) customer managed key. This parameter is needed only when the object was created using a checksum algorithm. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Protecting data using SSE-C keys</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-server-side-encryption-customer-key-MD5: string # The MD5 server-side encryption (SSE) customer managed key. This parameter is needed only when the object was created using a checksum algorithm. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html">Protecting data using SSE-C keys</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "select-type" $select_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#select&select-type=2" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-server-side-encryption-customer-algorithm": $x_amz_server_side_encryption_customer_algorithm, "x-amz-server-side-encryption-customer-key": $x_amz_server_side_encryption_customer_key, "x-amz-server-side-encryption-customer-key-MD5": $x_amz_server_side_encryption_customer_key_MD5, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Uploads a part in a multipart upload.</p> <note> <p>In this operation, you provide part data in your request. However, you have an option to specify your existing Amazon S3 object as a data source for the part you are uploading. To upload a part from an existing object, you use the <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html">UploadPartCopy</a> operation. </p> </note> <p>You must initiate a multipart upload (see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html">CreateMultipartUpload</a>) before you can upload any part. In response to your initiate request, Amazon S3 returns an upload ID, a unique identifier, that you must include in your upload part request.</p> <p>Part numbers can be any number from 1 to 10,000, inclusive. A part number uniquely identifies a part and also defines its position within the object being created. If you upload a new part using the same part number that was used with a previous part, the previously uploaded part is overwritten.</p> <p>For information about maximum and minimum part sizes and other multipart upload specifications, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html">Multipart upload limits</a> in the <i>Amazon S3 User Guide</i>.</p> <p>To ensure that data is not corrupted when traversing the network, specify the <code>Content-MD5</code> header in the upload part request. Amazon S3 checks the part data against the provided MD5 value. If they do not match, Amazon S3 returns an error. </p> <p>If the upload request is signed with Signature Version 4, then Amazon Web Services S3 uses the <code>x-amz-content-sha256</code> header as a checksum instead of <code>Content-MD5</code>. For more information see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-auth-using-authorization-header.html">Authenticating Requests: Using the Authorization Header (Amazon Web Services Signature Version 4)</a>. </p> <p> <b>Note:</b> After you initiate multipart upload and upload one or more parts, you must either complete or abort multipart upload in order to stop getting charged for storage of the uploaded parts. Only after you either complete or abort multipart upload, Amazon S3 frees up the parts storage and stops charging you for the parts storage.</p> <p>For more information on multipart uploads, go to <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html">Multipart Upload Overview</a> in the <i>Amazon S3 User Guide </i>.</p> <p>For information on the permissions required to use the multipart upload API, go to <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html">Multipart Upload and Permissions</a> in the <i>Amazon S3 User Guide</i>.</p> <p>You can optionally request server-side encryption where Amazon S3 encrypts your data as it writes it to disks in its data centers and decrypts it for you when you access it. You have the option of providing your own encryption key, or you can use the Amazon Web Services managed encryption keys. If you choose to provide your own encryption key, the request headers you provide in the request must match the headers you used in the request to initiate the upload by using <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html">CreateMultipartUpload</a>. For more information, go to <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingServerSideEncryption.html">Using Server-Side Encryption</a> in the <i>Amazon S3 User Guide</i>.</p> <p>Server-side encryption is supported by the S3 Multipart Upload actions. Unless you are using a customer-provided encryption key, you don't need to specify the encryption parameters in each UploadPart request. Instead, you only need to specify the server-side encryption parameters in the initial Initiate Multipart request. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html">CreateMultipartUpload</a>.</p> <p>If you requested server-side encryption using a customer-provided encryption key in your initiate multipart upload request, you must provide identical encryption information in each part upload using the following headers.</p> <ul> <li> <p>x-amz-server-side-encryption-customer-algorithm</p> </li> <li> <p>x-amz-server-side-encryption-customer-key</p> </li> <li> <p>x-amz-server-side-encryption-customer-key-MD5</p> </li> </ul> <p class="title"> <b>Special Errors</b> </p> <ul> <li> <ul> <li> <p> <i>Code: NoSuchUpload</i> </p> </li> <li> <p> <i>Cause: The specified multipart upload does not exist. The upload ID might be invalid, or the multipart upload might have been aborted or completed.</i> </p> </li> <li> <p> <i> HTTP Status Code: 404 Not Found </i> </p> </li> <li> <p> <i>SOAP Fault Code Prefix: Client</i> </p> </li> </ul> </li> </ul> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html">CreateMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html">CompleteMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html">AbortMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html">ListParts</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html">ListMultipartUploads</a> </p> </li> </ul>
#
# PUT /{Bucket}/{Key}#partNumber&uploadId
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPart.html
# operationId: UploadPart
export def "api UploadPart" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --partNumber: int # Part number of part being uploaded. This is a positive integer between 1 and 10,000.
  --uploadId: string # Upload ID identifying the multipart upload whose part is being uploaded.
  --x-amz-security-token: string
  --Content-Length: int # Size of the body in bytes. This parameter is useful when the size of the body cannot be determined automatically.
  --Content-MD5: string # The base64-encoded 128-bit MD5 digest of the part data. This parameter is auto-populated when using the command from the CLI. This parameter is required if object lock parameters are specified.
  --x-amz-sdk-checksum-algorithm: string@x-amz-sdk-checksum-algorithm-completer # <p>Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding <code>x-amz-checksum</code> or <code>x-amz-trailer</code> header sent. Otherwise, Amazon S3 fails the request with the HTTP status code <code>400 Bad Request</code>. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>If you provide an individual checksum, Amazon S3 ignores any provided <code>ChecksumAlgorithm</code> parameter.</p> <p>This checksum algorithm must be the same for all parts and it match the checksum value supplied in the <code>CreateMultipartUpload</code> request.</p>
  --x-amz-checksum-crc32: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 32-bit CRC32 checksum of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-checksum-crc32c: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 32-bit CRC32C checksum of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-checksum-sha1: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 160-bit SHA-1 digest of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-checksum-sha256: string # This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 256-bit SHA-256 digest of the object. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.
  --x-amz-server-side-encryption-customer-algorithm: string # Specifies the algorithm to use to when encrypting the object (for example, AES256).
  --x-amz-server-side-encryption-customer-key: string # Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon S3 does not store the encryption key. The key must be appropriate for use with the algorithm specified in the <code>x-amz-server-side-encryption-customer-algorithm header</code>. This must be the same encryption key specified in the initiate multipart upload request.
  --x-amz-server-side-encryption-customer-key-MD5: string # Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partNumber" $partNumber "scalar") (serialize-qp "uploadId" $uploadId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#partNumber&uploadId" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "Content-Length": $Content_Length, "Content-MD5": $Content_MD5, "x-amz-sdk-checksum-algorithm": $x_amz_sdk_checksum_algorithm, "x-amz-checksum-crc32": $x_amz_checksum_crc32, "x-amz-checksum-crc32c": $x_amz_checksum_crc32c, "x-amz-checksum-sha1": $x_amz_checksum_sha1, "x-amz-checksum-sha256": $x_amz_checksum_sha256, "x-amz-server-side-encryption-customer-algorithm": $x_amz_server_side_encryption_customer_algorithm, "x-amz-server-side-encryption-customer-key": $x_amz_server_side_encryption_customer_key, "x-amz-server-side-encryption-customer-key-MD5": $x_amz_server_side_encryption_customer_key_MD5, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}

# <p>Uploads a part by copying data from an existing object as data source. You specify the data source by adding the request header <code>x-amz-copy-source</code> in your request and a byte range by adding the request header <code>x-amz-copy-source-range</code> in your request. </p> <p>For information about maximum and minimum part sizes and other multipart upload specifications, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html">Multipart upload limits</a> in the <i>Amazon S3 User Guide</i>. </p> <note> <p>Instead of using an existing object as part data, you might use the <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a> action and provide data in your request.</p> </note> <p>You must initiate a multipart upload before you can upload any part. In response to your initiate request. Amazon S3 returns a unique identifier, the upload ID, that you must include in your upload part request.</p> <p>For more information about using the <code>UploadPartCopy</code> operation, see the following:</p> <ul> <li> <p>For conceptual information about multipart uploads, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/uploadobjusingmpu.html">Uploading Objects Using Multipart Upload</a> in the <i>Amazon S3 User Guide</i>.</p> </li> <li> <p>For information about permissions required to use the multipart upload API, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html">Multipart Upload and Permissions</a> in the <i>Amazon S3 User Guide</i>.</p> </li> <li> <p>For information about copying objects using a single atomic action vs. a multipart upload, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectOperations.html">Operations on Objects</a> in the <i>Amazon S3 User Guide</i>.</p> </li> <li> <p>For information about using server-side encryption with customer-provided encryption keys with the <code>UploadPartCopy</code> operation, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html">CopyObject</a> and <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a>.</p> </li> </ul> <p>Note the following additional considerations about the request headers <code>x-amz-copy-source-if-match</code>, <code>x-amz-copy-source-if-none-match</code>, <code>x-amz-copy-source-if-unmodified-since</code>, and <code>x-amz-copy-source-if-modified-since</code>:</p> <p> </p> <ul> <li> <p> <b>Consideration 1</b> - If both of the <code>x-amz-copy-source-if-match</code> and <code>x-amz-copy-source-if-unmodified-since</code> headers are present in the request as follows:</p> <p> <code>x-amz-copy-source-if-match</code> condition evaluates to <code>true</code>, and;</p> <p> <code>x-amz-copy-source-if-unmodified-since</code> condition evaluates to <code>false</code>;</p> <p>Amazon S3 returns <code>200 OK</code> and copies the data. </p> </li> <li> <p> <b>Consideration 2</b> - If both of the <code>x-amz-copy-source-if-none-match</code> and <code>x-amz-copy-source-if-modified-since</code> headers are present in the request as follows:</p> <p> <code>x-amz-copy-source-if-none-match</code> condition evaluates to <code>false</code>, and;</p> <p> <code>x-amz-copy-source-if-modified-since</code> condition evaluates to <code>true</code>;</p> <p>Amazon S3 returns <code>412 Precondition Failed</code> response code. </p> </li> </ul> <p> <b>Versioning</b> </p> <p>If your bucket has versioning enabled, you could have multiple versions of the same object. By default, <code>x-amz-copy-source</code> identifies the current version of the object to copy. If the current version is a delete marker and you don't specify a versionId in the <code>x-amz-copy-source</code>, Amazon S3 returns a 404 error, because the object does not exist. If you specify versionId in the <code>x-amz-copy-source</code> and the versionId is a delete marker, Amazon S3 returns an HTTP 400 error, because you are not allowed to specify a delete marker as a version for the <code>x-amz-copy-source</code>. </p> <p>You can optionally specify a specific version of the source object to copy by adding the <code>versionId</code> subresource as shown in the following example:</p> <p> <code>x-amz-copy-source: /bucket/object?versionId=version id</code> </p> <p class="title"> <b>Special Errors</b> </p> <ul> <li> <ul> <li> <p> <i>Code: NoSuchUpload</i> </p> </li> <li> <p> <i>Cause: The specified multipart upload does not exist. The upload ID might be invalid, or the multipart upload might have been aborted or completed.</i> </p> </li> <li> <p> <i>HTTP Status Code: 404 Not Found</i> </p> </li> </ul> </li> <li> <ul> <li> <p> <i>Code: InvalidRequest</i> </p> </li> <li> <p> <i>Cause: The specified copy source is not supported as a byte-range copy source.</i> </p> </li> <li> <p> <i>HTTP Status Code: 400 Bad Request</i> </p> </li> </ul> </li> </ul> <p class="title"> <b>Related Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html">CreateMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html">UploadPart</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html">CompleteMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html">AbortMultipartUpload</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html">ListParts</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html">ListMultipartUploads</a> </p> </li> </ul>
#
# PUT /{Bucket}/{Key}#x-amz-copy-source&partNumber&uploadId
# Docs: http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadUploadPartCopy.html
# operationId: UploadPartCopy
export def "api UploadPartCopy" [
  Bucket: string
  Key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --partNumber: int # Part number of part being copied. This is a positive integer between 1 and 10,000.
  --uploadId: string # Upload ID identifying the multipart upload whose part is being copied.
  --x-amz-security-token: string
  --x-amz-copy-source: string # <p>Specifies the source object for the copy operation. You specify the value in one of two formats, depending on whether you want to access the source object through an <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html">access point</a>:</p> <ul> <li> <p>For objects not accessed through an access point, specify the name of the source bucket and key of the source object, separated by a slash (/). For example, to copy the object <code>reports/january.pdf</code> from the bucket <code>awsexamplebucket</code>, use <code>awsexamplebucket/reports/january.pdf</code>. The value must be URL-encoded.</p> </li> <li> <p>For objects accessed through access points, specify the Amazon Resource Name (ARN) of the object as accessed through the access point, in the format <code>arn:aws:s3:&lt;Region&gt;:&lt;account-id&gt;:accesspoint/&lt;access-point-name&gt;/object/&lt;key&gt;</code>. For example, to copy the object <code>reports/january.pdf</code> through access point <code>my-access-point</code> owned by account <code>123456789012</code> in Region <code>us-west-2</code>, use the URL encoding of <code>arn:aws:s3:us-west-2:123456789012:accesspoint/my-access-point/object/reports/january.pdf</code>. The value must be URL encoded.</p> <note> <p>Amazon S3 supports copy operations using access points only when the source and destination buckets are in the same Amazon Web Services Region.</p> </note> <p>Alternatively, for objects accessed through Amazon S3 on Outposts, specify the ARN of the object as accessed in the format <code>arn:aws:s3-outposts:&lt;Region&gt;:&lt;account-id&gt;:outpost/&lt;outpost-id&gt;/object/&lt;key&gt;</code>. For example, to copy the object <code>reports/january.pdf</code> through outpost <code>my-outpost</code> owned by account <code>123456789012</code> in Region <code>us-west-2</code>, use the URL encoding of <code>arn:aws:s3-outposts:us-west-2:123456789012:outpost/my-outpost/object/reports/january.pdf</code>. The value must be URL-encoded. </p> </li> </ul> <p>To copy a specific version of an object, append <code>?versionId=&lt;version-id&gt;</code> to the value (for example, <code>awsexamplebucket/reports/january.pdf?versionId=QUpfdndhfd8438MNFDN93jdnJFkdmqnh893</code>). If you don't specify a version ID, Amazon S3 copies the latest version of the source object.</p>
  --x-amz-copy-source-if-match: string # Copies the object if its entity tag (ETag) matches the specified tag.
  --x-amz-copy-source-if-modified-since: string # Copies the object if it has been modified since the specified time.
  --x-amz-copy-source-if-none-match: string # Copies the object if its entity tag (ETag) is different than the specified ETag.
  --x-amz-copy-source-if-unmodified-since: string # Copies the object if it hasn't been modified since the specified time.
  --x-amz-copy-source-range: string # The range of bytes to copy from the source object. The range value must use the form bytes=first-last, where the first and last are the zero-based byte offsets to copy. For example, bytes=0-9 indicates that you want to copy the first 10 bytes of the source. You can copy a range only if the source object is greater than 5 MB.
  --x-amz-server-side-encryption-customer-algorithm: string # Specifies the algorithm to use to when encrypting the object (for example, AES256).
  --x-amz-server-side-encryption-customer-key: string # Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon S3 does not store the encryption key. The key must be appropriate for use with the algorithm specified in the <code>x-amz-server-side-encryption-customer-algorithm</code> header. This must be the same encryption key specified in the initiate multipart upload request.
  --x-amz-server-side-encryption-customer-key-MD5: string # Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
  --x-amz-copy-source-server-side-encryption-customer-algorithm: string # Specifies the algorithm to use when decrypting the source object (for example, AES256).
  --x-amz-copy-source-server-side-encryption-customer-key: string # Specifies the customer-provided encryption key for Amazon S3 to use to decrypt the source object. The encryption key provided in this header must be one that was used when the source object was created.
  --x-amz-copy-source-server-side-encryption-customer-key-MD5: string # Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
  --x-amz-request-payer: string@x-amz-request-payer-completer
  --x-amz-expected-bucket-owner: string # The account ID of the expected destination bucket owner. If the destination bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
  --x-amz-source-expected-bucket-owner: string # The account ID of the expected source bucket owner. If the source bucket is owned by a different account, the request fails with the HTTP status code <code>403 Forbidden</code> (access denied).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partNumber" $partNumber "scalar") (serialize-qp "uploadId" $uploadId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($Bucket)/($Key)#x-amz-copy-source&partNumber&uploadId" $qp)
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-copy-source": $x_amz_copy_source, "x-amz-copy-source-if-match": $x_amz_copy_source_if_match, "x-amz-copy-source-if-modified-since": $x_amz_copy_source_if_modified_since, "x-amz-copy-source-if-none-match": $x_amz_copy_source_if_none_match, "x-amz-copy-source-if-unmodified-since": $x_amz_copy_source_if_unmodified_since, "x-amz-copy-source-range": $x_amz_copy_source_range, "x-amz-server-side-encryption-customer-algorithm": $x_amz_server_side_encryption_customer_algorithm, "x-amz-server-side-encryption-customer-key": $x_amz_server_side_encryption_customer_key, "x-amz-server-side-encryption-customer-key-MD5": $x_amz_server_side_encryption_customer_key_MD5, "x-amz-copy-source-server-side-encryption-customer-algorithm": $x_amz_copy_source_server_side_encryption_customer_algorithm, "x-amz-copy-source-server-side-encryption-customer-key": $x_amz_copy_source_server_side_encryption_customer_key, "x-amz-copy-source-server-side-encryption-customer-key-MD5": $x_amz_copy_source_server_side_encryption_customer_key_MD5, "x-amz-request-payer": $x_amz_request_payer, "x-amz-expected-bucket-owner": $x_amz_expected_bucket_owner, "x-amz-source-expected-bucket-owner": $x_amz_source_expected_bucket_owner} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <p>Passes transformed objects to a <code>GetObject</code> operation when using Object Lambda access points. For information about Object Lambda access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/transforming-objects.html">Transforming objects with Object Lambda access points</a> in the <i>Amazon S3 User Guide</i>.</p> <p>This operation supports metadata that can be returned by <a href="https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html">GetObject</a>, in addition to <code>RequestRoute</code>, <code>RequestToken</code>, <code>StatusCode</code>, <code>ErrorCode</code>, and <code>ErrorMessage</code>. The <code>GetObject</code> response metadata is supported so that the <code>WriteGetObjectResponse</code> caller, typically an Lambda function, can provide the same metadata when it internally invokes <code>GetObject</code>. When <code>WriteGetObjectResponse</code> is called by a customer-owned Lambda function, the metadata returned to the end user <code>GetObject</code> call might differ from what Amazon S3 would normally return.</p> <p>You can include any number of metadata headers. When including a metadata header, it should be prefaced with <code>x-amz-meta</code>. For example, <code>x-amz-meta-my-custom-header: MyCustomValue</code>. The primary use case for this is to forward <code>GetObject</code> metadata.</p> <p>Amazon Web Services provides some prebuilt Lambda functions that you can use with S3 Object Lambda to detect and redact personally identifiable information (PII) and decompress S3 objects. These Lambda functions are available in the Amazon Web Services Serverless Application Repository, and can be selected through the Amazon Web Services Management Console when you create your Object Lambda access point.</p> <p>Example 1: PII Access Control - This Lambda function uses Amazon Comprehend, a natural language processing (NLP) service using machine learning to find insights and relationships in text. It automatically detects personally identifiable information (PII) such as names, addresses, dates, credit card numbers, and social security numbers from documents in your Amazon S3 bucket. </p> <p>Example 2: PII Redaction - This Lambda function uses Amazon Comprehend, a natural language processing (NLP) service using machine learning to find insights and relationships in text. It automatically redacts personally identifiable information (PII) such as names, addresses, dates, credit card numbers, and social security numbers from documents in your Amazon S3 bucket. </p> <p>Example 3: Decompression - The Lambda function S3ObjectLambdaDecompression, is equipped to decompress objects stored in S3 in one of six compressed file formats including bzip2, gzip, snappy, zlib, zstandard and ZIP. </p> <p>For information on how to view and use these functions, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/olap-examples.html">Using Amazon Web Services built Lambda functions</a> in the <i>Amazon S3 User Guide</i>.</p>
#
# POST /WriteGetObjectResponse#x-amz-request-route&x-amz-request-token
# operationId: WriteGetObjectResponse
export def "write-get-object-responsex-amz-request-routex-amz-request-token WriteGetObjectResponse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-amz-security-token: string
  --x-amz-request-route: string # Route prefix to the HTTP URL generated.
  --x-amz-request-token: string # A single use encrypted token that maps <code>WriteGetObjectResponse</code> to the end user <code>GetObject</code> request.
  --x-amz-fwd-status: int # <p>The integer status code for an HTTP response of a corresponding <code>GetObject</code> request.</p> <p class="title"> <b>Status Codes</b> </p> <ul> <li> <p> <code>200 - OK</code> </p> </li> <li> <p> <code>206 - Partial Content</code> </p> </li> <li> <p> <code>304 - Not Modified</code> </p> </li> <li> <p> <code>400 - Bad Request</code> </p> </li> <li> <p> <code>401 - Unauthorized</code> </p> </li> <li> <p> <code>403 - Forbidden</code> </p> </li> <li> <p> <code>404 - Not Found</code> </p> </li> <li> <p> <code>405 - Method Not Allowed</code> </p> </li> <li> <p> <code>409 - Conflict</code> </p> </li> <li> <p> <code>411 - Length Required</code> </p> </li> <li> <p> <code>412 - Precondition Failed</code> </p> </li> <li> <p> <code>416 - Range Not Satisfiable</code> </p> </li> <li> <p> <code>500 - Internal Server Error</code> </p> </li> <li> <p> <code>503 - Service Unavailable</code> </p> </li> </ul>
  --x-amz-fwd-error-code: string # A string that uniquely identifies an error condition. Returned in the &lt;Code&gt; tag of the error XML response for a corresponding <code>GetObject</code> call. Cannot be used with a successful <code>StatusCode</code> header or when the transformed object is provided in the body. All error codes from S3 are sentence-cased. The regular expression (regex) value is <code>"^[A-Z][a-zA-Z]+$"</code>.
  --x-amz-fwd-error-message: string # Contains a generic description of the error condition. Returned in the &lt;Message&gt; tag of the error XML response for a corresponding <code>GetObject</code> call. Cannot be used with a successful <code>StatusCode</code> header or when the transformed object is provided in body.
  --x-amz-fwd-header-accept-ranges: string # Indicates that a range of bytes was specified.
  --x-amz-fwd-header-Cache-Control: string # Specifies caching behavior along the request/reply chain.
  --x-amz-fwd-header-Content-Disposition: string # Specifies presentational information for the object.
  --x-amz-fwd-header-Content-Encoding: string # Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field.
  --x-amz-fwd-header-Content-Language: string # The language the content is in.
  --Content-Length: int # The size of the content body in bytes.
  --x-amz-fwd-header-Content-Range: string # The portion of the object returned in the response.
  --x-amz-fwd-header-Content-Type: string # A standard MIME type describing the format of the object data.
  --x-amz-fwd-header-x-amz-checksum-crc32: string # <p>This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This specifies the base64-encoded, 32-bit CRC32 checksum of the object returned by the Object Lambda function. This may not match the checksum for the object stored in Amazon S3. Amazon S3 will perform validation of the checksum values only when the original <code>GetObject</code> request required checksum validation. For more information about checksums, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>Only one checksum header can be specified at a time. If you supply multiple checksum headers, this request will fail.</p> <p/>
  --x-amz-fwd-header-x-amz-checksum-crc32c: string # <p>This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This specifies the base64-encoded, 32-bit CRC32C checksum of the object returned by the Object Lambda function. This may not match the checksum for the object stored in Amazon S3. Amazon S3 will perform validation of the checksum values only when the original <code>GetObject</code> request required checksum validation. For more information about checksums, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>Only one checksum header can be specified at a time. If you supply multiple checksum headers, this request will fail.</p>
  --x-amz-fwd-header-x-amz-checksum-sha1: string # <p>This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This specifies the base64-encoded, 160-bit SHA-1 digest of the object returned by the Object Lambda function. This may not match the checksum for the object stored in Amazon S3. Amazon S3 will perform validation of the checksum values only when the original <code>GetObject</code> request required checksum validation. For more information about checksums, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>Only one checksum header can be specified at a time. If you supply multiple checksum headers, this request will fail.</p>
  --x-amz-fwd-header-x-amz-checksum-sha256: string # <p>This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This specifies the base64-encoded, 256-bit SHA-256 digest of the object returned by the Object Lambda function. This may not match the checksum for the object stored in Amazon S3. Amazon S3 will perform validation of the checksum values only when the original <code>GetObject</code> request required checksum validation. For more information about checksums, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html">Checking object integrity</a> in the <i>Amazon S3 User Guide</i>.</p> <p>Only one checksum header can be specified at a time. If you supply multiple checksum headers, this request will fail.</p>
  --x-amz-fwd-header-x-amz-delete-marker: string@bool-completer # Specifies whether an object stored in Amazon S3 is (<code>true</code>) or is not (<code>false</code>) a delete marker. 
  --x-amz-fwd-header-ETag: string # An opaque identifier assigned by a web server to a specific version of a resource found at a URL. 
  --x-amz-fwd-header-Expires: string # The date and time at which the object is no longer cacheable.
  --x-amz-fwd-header-x-amz-expiration: string # If the object expiration is configured (see PUT Bucket lifecycle), the response includes this header. It includes the <code>expiry-date</code> and <code>rule-id</code> key-value pairs that provide the object expiration information. The value of the <code>rule-id</code> is URL-encoded. 
  --x-amz-fwd-header-Last-Modified: string # The date and time that the object was last modified.
  --x-amz-fwd-header-x-amz-missing-meta: int # Set to the number of metadata entries not returned in <code>x-amz-meta</code> headers. This can happen if you create metadata using an API like SOAP that supports more flexible metadata than the REST API. For example, using SOAP, you can create metadata whose values are not legal HTTP headers.
  --x-amz-fwd-header-x-amz-object-lock-mode: string@x-amz-fwd-header-x-amz-object-lock-mode-completer # Indicates whether an object stored in Amazon S3 has Object Lock enabled. For more information about S3 Object Lock, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html">Object Lock</a>.
  --x-amz-fwd-header-x-amz-object-lock-legal-hold: string@x-amz-fwd-header-x-amz-object-lock-legal-hold-completer # Indicates whether an object stored in Amazon S3 has an active legal hold.
  --x-amz-fwd-header-x-amz-object-lock-retain-until-date: string # The date and time when Object Lock is configured to expire.
  --x-amz-fwd-header-x-amz-mp-parts-count: int # The count of parts this object has.
  --x-amz-fwd-header-x-amz-replication-status: string@x-amz-fwd-header-x-amz-replication-status-completer # Indicates if request involves bucket that is either a source or destination in a Replication rule. For more information about S3 Replication, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html">Replication</a>.
  --x-amz-fwd-header-x-amz-request-charged: string@x-amz-fwd-header-x-amz-request-charged-completer
  --x-amz-fwd-header-x-amz-restore: string # Provides information about object restoration operation and expiration time of the restored object copy.
  --x-amz-fwd-header-x-amz-server-side-encryption: string@x-amz-fwd-header-x-amz-server-side-encryption-completer #  The server-side encryption algorithm used when storing requested object in Amazon S3 (for example, AES256, aws:kms).
  --x-amz-fwd-header-x-amz-server-side-encryption-customer-algorithm: string # Encryption algorithm used if server-side encryption with a customer-provided encryption key was specified for object stored in Amazon S3.
  --x-amz-fwd-header-x-amz-server-side-encryption-aws-kms-key-id: string #  If present, specifies the ID of the Amazon Web Services Key Management Service (Amazon Web Services KMS) symmetric customer managed key that was used for stored in Amazon S3 object. 
  --x-amz-fwd-header-x-amz-server-side-encryption-customer-key-MD5: string #  128-bit MD5 digest of customer-provided encryption key used in Amazon S3 to encrypt data stored in S3. For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerSideEncryptionCustomerKeys.html">Protecting data using server-side encryption with customer-provided encryption keys (SSE-C)</a>.
  --x-amz-fwd-header-x-amz-storage-class: string@x-amz-fwd-header-x-amz-storage-class-completer # <p>Provides storage class information of the object. Amazon S3 returns this header for all objects except for S3 Standard storage class objects.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html">Storage Classes</a>.</p>
  --x-amz-fwd-header-x-amz-tagging-count: int # The number of tags, if any, on the object.
  --x-amz-fwd-header-x-amz-version-id: string # An ID used to reference a specific version of the object.
  --x-amz-fwd-header-x-amz-server-side-encryption-bucket-key-enabled: string@bool-completer #  Indicates whether the object stored in Amazon S3 uses an S3 bucket key for server-side encryption with Amazon Web Services KMS (SSE-KMS).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/WriteGetObjectResponse#x-amz-request-route&x-amz-request-token")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-amz-security-token": $x_amz_security_token, "x-amz-request-route": $x_amz_request_route, "x-amz-request-token": $x_amz_request_token, "x-amz-fwd-status": $x_amz_fwd_status, "x-amz-fwd-error-code": $x_amz_fwd_error_code, "x-amz-fwd-error-message": $x_amz_fwd_error_message, "x-amz-fwd-header-accept-ranges": $x_amz_fwd_header_accept_ranges, "x-amz-fwd-header-Cache-Control": $x_amz_fwd_header_Cache_Control, "x-amz-fwd-header-Content-Disposition": $x_amz_fwd_header_Content_Disposition, "x-amz-fwd-header-Content-Encoding": $x_amz_fwd_header_Content_Encoding, "x-amz-fwd-header-Content-Language": $x_amz_fwd_header_Content_Language, "Content-Length": $Content_Length, "x-amz-fwd-header-Content-Range": $x_amz_fwd_header_Content_Range, "x-amz-fwd-header-Content-Type": $x_amz_fwd_header_Content_Type, "x-amz-fwd-header-x-amz-checksum-crc32": $x_amz_fwd_header_x_amz_checksum_crc32, "x-amz-fwd-header-x-amz-checksum-crc32c": $x_amz_fwd_header_x_amz_checksum_crc32c, "x-amz-fwd-header-x-amz-checksum-sha1": $x_amz_fwd_header_x_amz_checksum_sha1, "x-amz-fwd-header-x-amz-checksum-sha256": $x_amz_fwd_header_x_amz_checksum_sha256, "x-amz-fwd-header-x-amz-delete-marker": $x_amz_fwd_header_x_amz_delete_marker, "x-amz-fwd-header-ETag": $x_amz_fwd_header_ETag, "x-amz-fwd-header-Expires": $x_amz_fwd_header_Expires, "x-amz-fwd-header-x-amz-expiration": $x_amz_fwd_header_x_amz_expiration, "x-amz-fwd-header-Last-Modified": $x_amz_fwd_header_Last_Modified, "x-amz-fwd-header-x-amz-missing-meta": $x_amz_fwd_header_x_amz_missing_meta, "x-amz-fwd-header-x-amz-object-lock-mode": $x_amz_fwd_header_x_amz_object_lock_mode, "x-amz-fwd-header-x-amz-object-lock-legal-hold": $x_amz_fwd_header_x_amz_object_lock_legal_hold, "x-amz-fwd-header-x-amz-object-lock-retain-until-date": $x_amz_fwd_header_x_amz_object_lock_retain_until_date, "x-amz-fwd-header-x-amz-mp-parts-count": $x_amz_fwd_header_x_amz_mp_parts_count, "x-amz-fwd-header-x-amz-replication-status": $x_amz_fwd_header_x_amz_replication_status, "x-amz-fwd-header-x-amz-request-charged": $x_amz_fwd_header_x_amz_request_charged, "x-amz-fwd-header-x-amz-restore": $x_amz_fwd_header_x_amz_restore, "x-amz-fwd-header-x-amz-server-side-encryption": $x_amz_fwd_header_x_amz_server_side_encryption, "x-amz-fwd-header-x-amz-server-side-encryption-customer-algorithm": $x_amz_fwd_header_x_amz_server_side_encryption_customer_algorithm, "x-amz-fwd-header-x-amz-server-side-encryption-aws-kms-key-id": $x_amz_fwd_header_x_amz_server_side_encryption_aws_kms_key_id, "x-amz-fwd-header-x-amz-server-side-encryption-customer-key-MD5": $x_amz_fwd_header_x_amz_server_side_encryption_customer_key_MD5, "x-amz-fwd-header-x-amz-storage-class": $x_amz_fwd_header_x_amz_storage_class, "x-amz-fwd-header-x-amz-tagging-count": $x_amz_fwd_header_x_amz_tagging_count, "x-amz-fwd-header-x-amz-version-id": $x_amz_fwd_header_x_amz_version_id, "x-amz-fwd-header-x-amz-server-side-encryption-bucket-key-enabled": $x_amz_fwd_header_x_amz_server_side_encryption_bucket_key_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/xml" $body
}
