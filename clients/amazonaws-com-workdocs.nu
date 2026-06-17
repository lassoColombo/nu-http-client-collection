# Auto-generated client for Amazon WorkDocs v2016-05-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/workdocs/2016-05-01/openapi.json
# Auth: --token flag or $env.AMAZON_WORKDOCS_TOKEN

const BASE_URL = "http://workdocs.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_WORKDOCS_TOKEN | default "" }
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

def base-url-completer [] { ["http://workdocs.us-east-1.amazonaws.com" "http://workdocs.us-east-2.amazonaws.com" "http://workdocs.us-west-1.amazonaws.com" "http://workdocs.us-west-2.amazonaws.com" "http://workdocs.us-gov-west-1.amazonaws.com" "http://workdocs.us-gov-east-1.amazonaws.com" "http://workdocs.ca-central-1.amazonaws.com" "http://workdocs.eu-north-1.amazonaws.com" "http://workdocs.eu-west-1.amazonaws.com" "http://workdocs.eu-west-2.amazonaws.com" "http://workdocs.eu-west-3.amazonaws.com" "http://workdocs.eu-central-1.amazonaws.com" "http://workdocs.eu-south-1.amazonaws.com" "http://workdocs.af-south-1.amazonaws.com" "http://workdocs.ap-northeast-1.amazonaws.com" "http://workdocs.ap-northeast-2.amazonaws.com" "http://workdocs.ap-northeast-3.amazonaws.com" "http://workdocs.ap-southeast-1.amazonaws.com" "http://workdocs.ap-southeast-2.amazonaws.com" "http://workdocs.ap-east-1.amazonaws.com" "http://workdocs.ap-south-1.amazonaws.com" "http://workdocs.sa-east-1.amazonaws.com" "http://workdocs.me-south-1.amazonaws.com" "https://workdocs.us-east-1.amazonaws.com" "https://workdocs.us-east-2.amazonaws.com" "https://workdocs.us-west-1.amazonaws.com" "https://workdocs.us-west-2.amazonaws.com" "https://workdocs.us-gov-west-1.amazonaws.com" "https://workdocs.us-gov-east-1.amazonaws.com" "https://workdocs.ca-central-1.amazonaws.com" "https://workdocs.eu-north-1.amazonaws.com" "https://workdocs.eu-west-1.amazonaws.com" "https://workdocs.eu-west-2.amazonaws.com" "https://workdocs.eu-west-3.amazonaws.com" "https://workdocs.eu-central-1.amazonaws.com" "https://workdocs.eu-south-1.amazonaws.com" "https://workdocs.af-south-1.amazonaws.com" "https://workdocs.ap-northeast-1.amazonaws.com" "https://workdocs.ap-northeast-2.amazonaws.com" "https://workdocs.ap-northeast-3.amazonaws.com" "https://workdocs.ap-southeast-1.amazonaws.com" "https://workdocs.ap-southeast-2.amazonaws.com" "https://workdocs.ap-east-1.amazonaws.com" "https://workdocs.ap-south-1.amazonaws.com" "https://workdocs.sa-east-1.amazonaws.com" "https://workdocs.me-south-1.amazonaws.com" "http://workdocs.cn-north-1.amazonaws.com.cn" "http://workdocs.cn-northwest-1.amazonaws.com.cn" "https://workdocs.cn-north-1.amazonaws.com.cn" "https://workdocs.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def version-status-completer [] { ["ACTIVE"] }
def visibility-completer [] { ["PRIVATE" "PUBLIC"] }
def protocol-completer [] { ["HTTPS" "SQS"] }
def subscription-type-completer [] { ["ALL"] }
def include-completer [] { ["ACTIVE_PENDING" "ALL"] }
def order-completer [] { ["ASCENDING" "DESCENDING"] }
def sort-completer [] { ["FULL_NAME" "STORAGE_LIMIT" "STORAGE_USED" "USER_NAME" "USER_STATUS"] }
def resource-state-completer [] { ["ACTIVE" "RECYCLED" "RECYCLING" "RESTORING"] }
def sort-completer-1 [] { ["DATE" "NAME"] }
def type-completer [] { ["ALL" "DOCUMENT" "FOLDER"] }
def type-completer-1 [] { ["ADMIN" "MINIMALUSER" "POWERUSER" "USER" "WORKSPACESUSER"] }
def locale-completer [] { ["de" "default" "en" "es" "fr" "ja" "ko" "pt_BR" "ru" "zh_CN" "zh_TW"] }
def grant-poweruser-privileges-completer [] { ["FALSE" "TRUE"] }
def collection-type-completer [] { ["SHARED_WITH_ME"] }
def type-completer-2 [] { ["ANONYMOUS" "GROUP" "INVITE" "ORGANIZATION" "USER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "documents-versions abort-document-version-upload" } } | get name | first)
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

# Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
#
# DELETE /api/v1/documents/{DocumentId}/versions/{VersionId}
# operationId: AbortDocumentVersionUpload
export def "documents-versions abort-document-version-upload" [
  document_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({document_id: $document_id, version_id: $version_id} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves version metadata for the specified document.
#
# GET /api/v1/documents/{DocumentId}/versions/{VersionId}
# operationId: GetDocumentVersion
export def "documents-versions get" [
  document_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  --include-custom-metadata: oneof<nothing, bool> # Set this to TRUE to include custom metadata in the response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<Metadata: record<Id: record, Name: record, ContentType: record, Size: record, Signature: record, Status: record, CreatedTimestamp: record, ModifiedTimestamp: record, ContentCreatedTimestamp: record, ContentModifiedTimestamp: record, CreatorId: record, Thumbnail: record, Source: record>, CustomMetadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "includeCustomMetadata" $include_custom_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: $document_id, version_id: $version_id} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
#
# PATCH /api/v1/documents/{DocumentId}/versions/{VersionId}
# operationId: UpdateDocumentVersion
export def "documents-versions update" [
  document_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  --version-status: string@version-status-completer # The status of the version.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({document_id: $document_id, version_id: $version_id} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}"))
  let body = {"VersionStatus": $version_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Activates the specified user. Only active users can access Amazon WorkDocs.
#
# POST /api/v1/users/{UserId}/activation
# operationId: ActivateUser
export def "users-activation post" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<User: record<Id: record, Username: record, EmailAddress: record, GivenName: record, Surname: record, OrganizationId: record, RootFolderId: record, RecycleBinFolderId: record, Status: record, Type: record, CreatedTimestamp: record, ModifiedTimestamp: record, TimeZoneId: record, Locale: record, Storage: record<StorageUtilizedInBytes: record, StorageRule: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/api/v1/users/{user_id}/activation"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
#
# DELETE /api/v1/users/{UserId}/activation
# operationId: DeactivateUser
export def "users-activation delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/api/v1/users/{user_id}/activation"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
#
# POST /api/v1/resources/{ResourceId}/permissions
# operationId: AddResourcePermissions
# --Principals item shape: {Id: any, Type: any, Role: any}
# --NotificationOptions shape: {SendEmail?: any, EmailMessage?: any}
export def "resources-permissions create" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  principals: list # The users, groups, or organization being granted permission. — item shape: {Id: any, Type: any, Role: any}
  --notification-options: record # Set of options which defines notification preferences of given action. — shape: {SendEmail?: any, EmailMessage?: any}
]: any -> record<ShareResults: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_id: $resource_id} | format pattern "/api/v1/resources/{resource_id}/permissions"))
  let body = {"Principals": $principals, "NotificationOptions": $notification_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the permissions of a specified resource.
#
# GET /api/v1/resources/{ResourceId}/permissions
# operationId: DescribeResourcePermissions
export def "resources-permissions get" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --principal-id: string # The ID of the principal to filter permissions by.
  --limit: int # The maximum number of items to return with this call.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call)
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<Principals: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "principalId" $principal_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: $resource_id} | format pattern "/api/v1/resources/{resource_id}/permissions") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes all the permissions from the specified resource.
#
# DELETE /api/v1/resources/{ResourceId}/permissions
# operationId: RemoveAllResourcePermissions
export def "resources-permissions delete-all" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_id: $resource_id} | format pattern "/api/v1/resources/{resource_id}/permissions"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a new comment to the specified document version.
#
# POST /api/v1/documents/{DocumentId}/versions/{VersionId}/comment
# operationId: CreateComment
export def "documents-versions-comment create" [
  document_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  --parent-id: string # The ID of the parent comment.
  --thread-id: string # The ID of the root comment in the thread.
  text: string # The text of the comment. (format: password)
  --visibility: string@visibility-completer # The visibility of the comment. Options are either PRIVATE, where the comment is visible only to the comment author and document owner and co-owners, or PUBLIC, where the comment is visible to document owners, co-owners, and contributors.
  --notify-collaborators: oneof<nothing, bool> # Set this parameter to TRUE to send an email out to the document collaborators after the comment is created.
]: any -> record<Comment: record<CommentId: record, ParentId: record, ThreadId: record, Text: record, Contributor: record<Id: record, Username: record, EmailAddress: record, GivenName: record, Surname: record, OrganizationId: record, RootFolderId: record, RecycleBinFolderId: record, Status: record, Type: record, CreatedTimestamp: record, ModifiedTimestamp: record, TimeZoneId: record, Locale: record, Storage: record>, CreatedTimestamp: record, Status: record, Visibility: record, RecipientId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({document_id: $document_id, version_id: $version_id} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}/comment"))
  let body = {"ParentId": $parent_id, "ThreadId": $thread_id, "Text": $text, "Visibility": $visibility, "NotifyCollaborators": $notify_collaborators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds one or more custom properties to the specified resource (a folder, document, or version).
#
# PUT /api/v1/resources/{ResourceId}/customMetadata
# operationId: CreateCustomMetadata
export def "resources-custom-metadata create" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --versionid: string # The ID of the version, if the custom metadata is being added to a document version.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  custom_metadata: record # Custom metadata in the form of name-value pairs.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionid" $versionid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: $resource_id} | format pattern "/api/v1/resources/{resource_id}/customMetadata") $qp)
  let body = {"CustomMetadata": $custom_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes custom metadata from the specified resource.
#
# DELETE /api/v1/resources/{ResourceId}/customMetadata
# operationId: DeleteCustomMetadata
export def "resources-custom-metadata delete" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-id: string # The ID of the version, if the custom metadata is being deleted from a document version.
  --keys: list # List of properties to remove.
  --delete-all: oneof<nothing, bool> # Flag to indicate removal of all custom metadata properties from the specified resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $version_id "scalar") (serialize-qp "keys" $keys "multi") (serialize-qp "deleteAll" $delete_all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: $resource_id} | format pattern "/api/v1/resources/{resource_id}/customMetadata") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a folder with the specified name and parent folder.
#
# POST /api/v1/folders
# operationId: CreateFolder
export def "folders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  --name: string # The name of the new folder. (format: password)
  parent_folder_id: string # The ID of the parent folder.
]: any -> record<Metadata: record<Id: record, Name: record, CreatorId: record, ParentFolderId: record, CreatedTimestamp: record, ModifiedTimestamp: record, ResourceState: record, Signature: record, Labels: record, Size: record, LatestVersionSize: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/folders")
  let body = {"Name": $name, "ParentFolderId": $parent_folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds the specified list of labels to the given resource (a document or folder)
#
# PUT /api/v1/resources/{ResourceId}/labels
# operationId: CreateLabels
export def "resources-labels create" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  labels: list # List of labels to add to the resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_id: $resource_id} | format pattern "/api/v1/resources/{resource_id}/labels"))
  let body = {"Labels": $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the specified list of labels from a resource.
#
# DELETE /api/v1/resources/{ResourceId}/labels
# operationId: DeleteLabels
export def "resources-labels delete" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: list # List of labels to delete from the resource.
  --delete-all: oneof<nothing, bool> # Flag to request removal of all labels from the specified resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "labels" $labels "multi") (serialize-qp "deleteAll" $delete_all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: $resource_id} | format pattern "/api/v1/resources/{resource_id}/labels") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/manage-notifications.html">Setting up notifications for an IAM user or role</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
#
# POST /api/v1/organizations/{OrganizationId}/subscriptions
# operationId: CreateNotificationSubscription
export def "organizations-subscriptions create-notification" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  endpoint: string # The endpoint to receive the notifications. If the protocol is HTTPS, the endpoint is a URL that begins with <code>https</code>.
  protocol: string@protocol-completer # The protocol to use. The supported value is https, which delivers JSON-encoded messages using HTTPS POST.
  subscription_type: string@subscription-type-completer # The notification type.
]: any -> record<Subscription: record<SubscriptionId: record, EndPoint: record, Protocol: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: $organization_id} | format pattern "/api/v1/organizations/{organization_id}/subscriptions"))
  let body = {"Endpoint": $endpoint, "Protocol": $protocol, "SubscriptionType": $subscription_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the specified notification subscriptions.
#
# GET /api/v1/organizations/{OrganizationId}/subscriptions
# operationId: DescribeNotificationSubscriptions
export def "organizations-subscriptions get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of items to return with this call.
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Subscriptions: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: $organization_id} | format pattern "/api/v1/organizations/{organization_id}/subscriptions") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
#
# POST /api/v1/users
# operationId: CreateUser
# --StorageRule shape: {StorageAllocatedInBytes?: any, StorageType?: any}
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  --organization-id: string # The ID of the organization.
  username: string # The login name of the user. (format: password)
  --email-address: string # The email address of the user. (format: password)
  given_name: string # The given name of the user. (format: password)
  surname: string # The surname of the user. (format: password)
  password: string # The password of the user. (format: password)
  --time-zone-id: string # The time zone ID of the user.
  --storage-rule: record # Describes the storage for a user. — shape: {StorageAllocatedInBytes?: any, StorageType?: any}
]: any -> record<User: record<Id: record, Username: record, EmailAddress: record, GivenName: record, Surname: record, OrganizationId: record, RootFolderId: record, RecycleBinFolderId: record, Status: record, Type: record, CreatedTimestamp: record, ModifiedTimestamp: record, TimeZoneId: record, Locale: record, Storage: record<StorageUtilizedInBytes: record, StorageRule: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users")
  let body = {"OrganizationId": $organization_id, "Username": $username, "EmailAddress": $email_address, "GivenName": $given_name, "Surname": $surname, "Password": $password, "TimeZoneId": $time_zone_id, "StorageRule": $storage_rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
#
# GET /api/v1/users
# operationId: DescribeUsers
export def "users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # The ID of the organization.
  --user-ids: string # The IDs of the users.
  --query: string # <p>A query to filter users by user name. Remember the following about the <code>Userids</code> and <code>Query</code> parameters:</p> <ul> <li> <p>If you don't use either parameter, the API returns a paginated list of all users on the site.</p> </li> <li> <p>If you use both parameters, the API ignores the <code>Query</code> parameter.</p> </li> <li> <p>The <code>Userid</code> parameter only returns user names that match a corresponding user ID.</p> </li> <li> <p>The <code>Query</code> parameter runs a "prefix" search for users by the <code>GivenName</code>, <code>SurName</code>, or <code>UserName</code> fields included in a <a href="https://docs.aws.amazon.com/workdocs/latest/APIReference/API_CreateUser.html">CreateUser</a> API call. For example, querying on <code>Ma</code> returns Márcia Oliveira, María García, and Mateo Jackson. If you use multiple characters, the API only returns data that matches all characters. For example, querying on <code>Ma J</code> only returns Mateo Jackson.</p> </li> </ul> (format: password)
  --include: string@include-completer # The state of the users. Specify "ALL" to include inactive users.
  --order: string@order-completer # The order for the results.
  --qp-sort: string@sort-completer # The sorting criteria.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of items to return.
  --fields: string # A comma-separated list of values. Specify "STORAGE_METADATA" to include the user storage quota and utilization information.
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<Users: record, TotalNumberOfUsers: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationId" $organization_id "scalar") (serialize-qp "userIds" $user_ids "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified comment from the document version.
#
# DELETE /api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}
# operationId: DeleteComment
export def "documents-versions-comment delete" [
  document_id: string
  version_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({document_id: $document_id, version_id: $version_id, comment_id: $comment_id} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}/comment/{comment_id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permanently deletes the specified document and its associated metadata.
#
# DELETE /api/v1/documents/{DocumentId}
# operationId: DeleteDocument
export def "documents delete" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/api/v1/documents/{document_id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves details of a document.
#
# GET /api/v1/documents/{DocumentId}
# operationId: GetDocument
export def "documents get" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-custom-metadata: oneof<nothing, bool> # Set this to <code>TRUE</code> to include custom metadata in the response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<Metadata: record<Id: record, CreatorId: record, ParentFolderId: record, CreatedTimestamp: record, ModifiedTimestamp: record, LatestVersionMetadata: record<Id: record, Name: record, ContentType: record, Size: record, Signature: record, Status: record, CreatedTimestamp: record, ModifiedTimestamp: record, ContentCreatedTimestamp: record, ContentModifiedTimestamp: record, CreatorId: record, Thumbnail: record, Source: record>, ResourceState: record, Labels: record>, CustomMetadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeCustomMetadata" $include_custom_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/api/v1/documents/{document_id}") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
#
# PATCH /api/v1/documents/{DocumentId}
# operationId: UpdateDocument
export def "documents update" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  --name: string # The name of the document. (format: password)
  --parent-folder-id: string # The ID of the parent folder.
  --resource-state: string@resource-state-completer # The resource state of the document. Only ACTIVE and RECYCLED are supported.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/api/v1/documents/{document_id}"))
  let body = {"Name": $name, "ParentFolderId": $parent_folder_id, "ResourceState": $resource_state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a specific version of a document.
#
# DELETE /api/v1/documentVersions/{DocumentId}/versions/{VersionId}#deletePriorVersions
# operationId: DeleteDocumentVersion
export def "document-versions-versions delete" [
  document_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-prior-versions: oneof<nothing, bool> # Deletes all versions of a document prior to the current version.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deletePriorVersions" $delete_prior_versions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: $document_id, version_id: $version_id} | format pattern "/api/v1/documentVersions/{document_id}/versions/{version_id}#deletePriorVersions") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permanently deletes the specified folder and its contents.
#
# DELETE /api/v1/folders/{FolderId}
# operationId: DeleteFolder
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/api/v1/folders/{folder_id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the metadata of the specified folder.
#
# GET /api/v1/folders/{FolderId}
# operationId: GetFolder
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
  --include-custom-metadata: oneof<nothing, bool> # Set to TRUE to include custom metadata in the response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<Metadata: record<Id: record, Name: record, CreatorId: record, ParentFolderId: record, CreatedTimestamp: record, ModifiedTimestamp: record, ResourceState: record, Signature: record, Labels: record, Size: record, LatestVersionSize: record>, CustomMetadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeCustomMetadata" $include_custom_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/api/v1/folders/{folder_id}") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
#
# PATCH /api/v1/folders/{FolderId}
# operationId: UpdateFolder
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  --name: string # The name of the folder. (format: password)
  --parent-folder-id: string # The ID of the parent folder.
  --resource-state: string@resource-state-completer # The resource state of the folder. Only ACTIVE and RECYCLED are accepted values from the API.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/api/v1/folders/{folder_id}"))
  let body = {"Name": $name, "ParentFolderId": $parent_folder_id, "ResourceState": $resource_state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the contents of the specified folder.
#
# DELETE /api/v1/folders/{FolderId}/contents
# operationId: DeleteFolderContents
export def "folders-contents delete" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/api/v1/folders/{folder_id}/contents"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
#
# GET /api/v1/folders/{FolderId}/contents
# operationId: DescribeFolderContents
export def "folders-contents get" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string@sort-completer-1 # The sorting criteria.
  --order: string@order-completer # The order for the contents of the folder.
  --limit: int # The maximum number of items to return with this call.
  --marker: string # The marker for the next set of results. This marker was received from a previous call.
  --type: string@type-completer # The type of items.
  --include: string # The contents to include. Specify "INITIALIZED" to include initialized documents.
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<Folders: record, Documents: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/api/v1/folders/{folder_id}/contents") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified subscription from the specified organization.
#
# DELETE /api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}
# operationId: DeleteNotificationSubscription
export def "organizations-subscriptions delete-notification" [
  organization_id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({organization_id: $organization_id, subscription_id: $subscription_id} | format pattern "/api/v1/organizations/{organization_id}/subscriptions/{subscription_id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Deletes the specified user from a Simple AD or Microsoft AD directory.</p> <important> <p>Deleting a user immediately and permanently deletes all content in that user's folder structure. Site retention policies do NOT apply to this type of deletion.</p> </important>
#
# DELETE /api/v1/users/{UserId}
# operationId: DeleteUser
export def "users delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using Amazon Web Services credentials.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/api/v1/users/{user_id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
#
# PATCH /api/v1/users/{UserId}
# operationId: UpdateUser
# --StorageRule shape: {StorageAllocatedInBytes?: any, StorageType?: any}
export def "users update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  --given-name: string # The given name of the user. (format: password)
  --surname: string # The surname of the user. (format: password)
  --type: string@type-completer-1 # The type of the user.
  --storage-rule: record # Describes the storage for a user. — shape: {StorageAllocatedInBytes?: any, StorageType?: any}
  --time-zone-id: string # The time zone ID of the user.
  --locale: string@locale-completer # The locale of the user.
  --grant-poweruser-privileges: string@grant-poweruser-privileges-completer # Boolean value to determine whether the user is granted Power user privileges.
]: any -> record<User: record<Id: record, Username: record, EmailAddress: record, GivenName: record, Surname: record, OrganizationId: record, RootFolderId: record, RecycleBinFolderId: record, Status: record, Type: record, CreatedTimestamp: record, ModifiedTimestamp: record, TimeZoneId: record, Locale: record, Storage: record<StorageUtilizedInBytes: record, StorageRule: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/api/v1/users/{user_id}"))
  let body = {"GivenName": $given_name, "Surname": $surname, "Type": $type, "StorageRule": $storage_rule, "TimeZoneId": $time_zone_id, "Locale": $locale, "GrantPoweruserPrivileges": $grant_poweruser_privileges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the user activities in a specified time period.
#
# GET /api/v1/activities
# operationId: DescribeActivities
export def "activities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: string # The timestamp that determines the starting time of the activities. The response includes the activities performed after the specified timestamp. (format: date-time)
  --end-time: string # The timestamp that determines the end time of the activities. The response includes the activities performed before the specified timestamp. (format: date-time)
  --organization-id: string # The ID of the organization. This is a mandatory parameter when using administrative API (SigV4) requests.
  --activity-types: string # Specifies which activity types to include in the response. If this field is left empty, all activity types are returned.
  --resource-id: string # The document or folder ID for which to describe activity types.
  --user-id: string # The ID of the user who performed the action. The response includes activities pertaining to this user. This is an optional parameter and is only applicable for administrative API (SigV4) requests.
  --include-indirect-activities: oneof<nothing, bool> # Includes indirect activities. An indirect activity results from a direct activity performed on a parent resource. For example, sharing a parent folder (the direct activity) shares all of the subfolders and documents within the parent folder (the indirect activity).
  --limit: int # The maximum number of items to return.
  --marker: string # The marker for the next set of results.
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<UserActivities: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "organizationId" $organization_id "scalar") (serialize-qp "activityTypes" $activity_types "scalar") (serialize-qp "resourceId" $resource_id "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "includeIndirectActivities" $include_indirect_activities "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/activities" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the comments for the specified document version.
#
# GET /api/v1/documents/{DocumentId}/versions/{VersionId}/comments
# operationId: DescribeComments
export def "documents-versions-comments get" [
  document_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return.
  --marker: string # The marker for the next set of results. This marker was received from a previous call.
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<Comments: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: $document_id, version_id: $version_id} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}/comments") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
#
# GET /api/v1/documents/{DocumentId}/versions
# operationId: DescribeDocumentVersions
export def "documents-versions list" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of versions to return with this call.
  --include: string # A comma-separated list of values. Specify "INITIALIZED" to include incomplete versions.
  --fields: string # Specify "SOURCE" to include initialized versions and a URL for the source document.
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<DocumentVersions: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/api/v1/documents/{document_id}/versions") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
#
# GET /api/v1/groups#searchQuery
# operationId: DescribeGroups
export def "groupssearch-query get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-query: string # A query to describe groups by group name. (format: password)
  --organization-id: string # The ID of the organization.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of items to return with this call.
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<Groups: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchQuery" $search_query "scalar") (serialize-qp "organizationId" $organization_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/groups#searchQuery" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
#
# GET /api/v1/me/root#Authentication
# operationId: DescribeRootFolders
export def "me-root-authentication get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token.
]: nothing -> record<Folders: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/me/root#Authentication" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
#
# GET /api/v1/me#Authentication
# operationId: GetCurrentUser
export def "me-authentication get-current-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token.
]: nothing -> record<User: record<Id: record, Username: record, EmailAddress: record, GivenName: record, Surname: record, OrganizationId: record, RootFolderId: record, RecycleBinFolderId: record, Status: record, Type: record, CreatedTimestamp: record, ModifiedTimestamp: record, TimeZoneId: record, Locale: record, Storage: record<StorageUtilizedInBytes: record, StorageRule: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/me#Authentication")
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
#
# GET /api/v1/documents/{DocumentId}/path
# operationId: GetDocumentPath
export def "documents-path get" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of levels in the hierarchy to return.
  --fields: string # A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  --marker: string # This value is not supported.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<Path: record<Components: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/api/v1/documents/{document_id}/path") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
#
# GET /api/v1/folders/{FolderId}/path
# operationId: GetFolderPath
export def "folders-path get" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of levels in the hierarchy to return.
  --fields: string # A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  --marker: string # This value is not supported.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<Path: record<Components: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/api/v1/folders/{folder_id}/path") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
#
# GET /api/v1/resources
# operationId: GetResources
export def "resources get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The user ID for the resource collection. This is a required field for accessing the API operation using IAM credentials.
  --collection-type: string@collection-type-completer # The collection type.
  --limit: int # The maximum number of resources to return.
  --marker: string # The marker for the next set of results. This marker was received from a previous call.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # The Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<Folders: record, Documents: record, Marker: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar") (serialize-qp "collectionType" $collection_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/resources" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
#
# POST /api/v1/documents
# operationId: InitiateDocumentVersionUpload
export def "documents upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  --id: string # The ID of the document.
  --name: string # The name of the document. (format: password)
  --content-created-timestamp: string # The timestamp when the content of the document was originally created. (format: date-time)
  --content-modified-timestamp: string # The timestamp when the content of the document was modified. (format: date-time)
  --content-type: string # The content type of the document.
  --document-size-in-bytes: int # The size of the document, in bytes.
  --parent-folder-id: string # The ID of the parent folder.
]: any -> record<Metadata: record<Id: record, CreatorId: record, ParentFolderId: record, CreatedTimestamp: record, ModifiedTimestamp: record, LatestVersionMetadata: record<Id: record, Name: record, ContentType: record, Size: record, Signature: record, Status: record, CreatedTimestamp: record, ModifiedTimestamp: record, ContentCreatedTimestamp: record, ContentModifiedTimestamp: record, CreatorId: record, Thumbnail: record, Source: record>, ResourceState: record, Labels: record>, UploadMetadata: record<UploadUrl: record, SignedHeaders: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/documents")
  let body = {"Id": $id, "Name": $name, "ContentCreatedTimestamp": $content_created_timestamp, "ContentModifiedTimestamp": $content_modified_timestamp, "ContentType": $content_type, "DocumentSizeInBytes": $document_size_in_bytes, "ParentFolderId": $parent_folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes the permission for the specified principal from the specified resource.
#
# DELETE /api/v1/resources/{ResourceId}/permissions/{PrincipalId}
# operationId: RemoveResourcePermission
export def "resources-permissions delete" [
  resource_id: string
  principal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-2 # The principal type of the resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: $resource_id, principal_id: $principal_id} | format pattern "/api/v1/resources/{resource_id}/permissions/{principal_id}") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recovers a deleted version of an Amazon WorkDocs document.
#
# POST /api/v1/documentVersions/restore/{DocumentId}
# operationId: RestoreDocumentVersions
export def "document-versions-restore post" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/api/v1/documentVersions/restore/{document_id}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches metadata and the content of folders, documents, document versions, and comments.
#
# POST /api/v1/search
# operationId: SearchResources
# --Filters shape: {TextLocales?: any, ContentCategories?: any, ResourceTypes?: any, Labels?: any, Principals?: any, AncestorIds?: any, SearchCollectionTypes?: any, SizeRange?: any, CreatedRange?: any, ModifiedRange?: any}
# --OrderBy item shape: {Field?: any, Order?: any}
export def "search list-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  --query-text: string # The String to search for. Searches across different text fields based on request parameters. Use double quotes around the query string for exact phrase matches. (format: password)
  --query-scopes: list # Filter based on the text field type. A Folder has only a name and no content. A Comment has only content and no name. A Document or Document Version has a name and content
  --organization-id: string # Filters based on the resource owner OrgId. This is a mandatory parameter when using Admin SigV4 credentials.
  --additional-response-fields: list # A list of attributes to include in the response. Used to request fields that are not normally returned in a standard response.
  --filters: record # Filters results based on entity metadata. — shape: {TextLocales?: any, ContentCategories?: any, ResourceTypes?: any, Labels?: any, Principals?: any, AncestorIds?: any, SearchCollectionTypes?: any, SizeRange?: any, CreatedRange?: any, ModifiedRange?: any}
  --order-by: list # Order by results in one or more categories. — item shape: {Field?: any, Order?: any}
  --limit: int # Max results count per page.
  --marker: string # The marker for the next set of results.
]: any -> record<Items: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search" $qp)
  let body = {"QueryText": $query_text, "QueryScopes": $query_scopes, "OrganizationId": $organization_id, "AdditionalResponseFields": $additional_response_fields, "Filters": $filters, "OrderBy": $order_by, "Limit": $limit, "Marker": $marker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
