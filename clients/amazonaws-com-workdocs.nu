# Auto-generated client for Amazon WorkDocs v2016-05-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/workdocs/2016-05-01/openapi.json
# Auth: --token flag or $env.AMAZON_WORKDOCS_TOKEN

const BASE_URL = "http://workdocs.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_WORKDOCS_TOKEN | default "" }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "documents-versions abort-upload" } } | get name | first)
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

# Aborts the upload of the specified document version that was previously initiated by InitiateDocumentVersionUpload. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
#
# DELETE /api/v1/documents/{DocumentId}/versions/{VersionId}
# operationId: AbortDocumentVersionUpload
export def "documents-versions abort-upload" [
  document_id: string
  version_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'VersionId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), version_id: (encode-path-segment $version_id)} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'VersionId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "includeCustomMetadata" $include_custom_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), version_id: (encode-path-segment $version_id)} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "includeCustomMetadata": $include_custom_metadata} | compact), body: null}
}

# Changes the status of the document version to ACTIVE. Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by InitiateDocumentVersionUpload.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'VersionId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), version_id: (encode-path-segment $version_id)} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}"))
  let req_body = {"VersionStatus": $version_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Activates the specified user. Only active users can access Amazon WorkDocs.
#
# POST /api/v1/users/{UserId}/activation
# operationId: ActivateUser
export def "users-activation create-activate" [
  user_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> record<User: record<Id: record, Username: record, EmailAddress: record, GivenName: record, Surname: record, OrganizationId: record, RootFolderId: record, RecycleBinFolderId: record, Status: record, Type: record, CreatedTimestamp: record, ModifiedTimestamp: record, TimeZoneId: record, Locale: record, Storage: record<StorageUtilizedInBytes: record, StorageRule: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/api/v1/users/{user_id}/activation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
#
# DELETE /api/v1/users/{UserId}/activation
# operationId: DeactivateUser
export def "users-activation delete-deactivate" [
  user_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/api/v1/users/{user_id}/activation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'ResourceId' must be non-empty" } }
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/api/v1/resources/{resource_id}/permissions"))
  let req_body = {"Principals": $principals, "NotificationOptions": $notification_options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --principal-id: string # The ID of the principal to filter permissions by.
  --limit: int # The maximum number of items to return with this call.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call)
  --limit-2: string # Pagination limit (disambiguated-2)
  --marker-2: string # Pagination token (disambiguated-2)
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
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'ResourceId' must be non-empty" } }
  let qp = [(serialize-qp "principalId" $principal_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "Limit" $limit_2 "scalar") (serialize-qp "Marker" $marker_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/api/v1/resources/{resource_id}/permissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"principalId": $principal_id, "limit": $limit, "marker": $marker, "Limit": $limit_2, "Marker": $marker_2} | compact), body: null}
}

# Removes all the permissions from the specified resource.
#
# DELETE /api/v1/resources/{ResourceId}/permissions
# operationId: RemoveAllResourcePermissions
export def "resources-permissions delete-list" [
  resource_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'ResourceId' must be non-empty" } }
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/api/v1/resources/{resource_id}/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'VersionId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), version_id: (encode-path-segment $version_id)} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}/comment"))
  let req_body = {"ParentId": $parent_id, "ThreadId": $thread_id, "Text": $text, "Visibility": $visibility, "NotifyCollaborators": $notify_collaborators} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'ResourceId' must be non-empty" } }
  let qp = [(serialize-qp "versionid" $versionid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/api/v1/resources/{resource_id}/customMetadata") $qp)
  let req_body = {"CustomMetadata": $custom_metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"versionid": $versionid} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'ResourceId' must be non-empty" } }
  let qp = [(serialize-qp "versionId" $version_id "scalar") (serialize-qp "keys" $keys "multi") (serialize-qp "deleteAll" $delete_all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/api/v1/resources/{resource_id}/customMetadata") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"versionId": $version_id, "keys": $keys, "deleteAll": $delete_all} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"Name": $name, "ParentFolderId": $parent_folder_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
  labels: list<string> # List of labels to add to the resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'ResourceId' must be non-empty" } }
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/api/v1/resources/{resource_id}/labels"))
  let req_body = {"Labels": $labels} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'ResourceId' must be non-empty" } }
  let qp = [(serialize-qp "labels" $labels "multi") (serialize-qp "deleteAll" $delete_all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/api/v1/resources/{resource_id}/labels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"labels": $labels, "deleteAll": $delete_all} | compact), body: null}
}

# Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription. For more information, see Setting up notifications for an IAM user or role (https://docs.aws.amazon.com/workdocs/latest/developerguide/manage-notifications.html) in the Amazon WorkDocs Developer Guide.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  endpoint: string # The endpoint to receive the notifications. If the protocol is HTTPS, the endpoint is a URL that begins with https.
  protocol: string@protocol-completer # The protocol to use. The supported value is https, which delivers JSON-encoded messages using HTTPS POST.
  subscription_type: string@subscription-type-completer # The notification type.
]: any -> record<Subscription: record<SubscriptionId: record, EndPoint: record, Protocol: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_id | is-empty) { error make --unspanned { msg: "path parameter 'OrganizationId' must be non-empty" } }
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/subscriptions"))
  let req_body = {"Endpoint": $endpoint, "Protocol": $protocol, "SubscriptionType": $subscription_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the specified notification subscriptions.
#
# GET /api/v1/organizations/{OrganizationId}/subscriptions
# operationId: DescribeNotificationSubscriptions
export def "organizations-subscriptions get-notification" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of items to return with this call.
  --limit-2: string # Pagination limit (disambiguated-2)
  --marker-2: string # Pagination token (disambiguated-2)
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
  if ($organization_id | is-empty) { error make --unspanned { msg: "path parameter 'OrganizationId' must be non-empty" } }
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "Limit" $limit_2 "scalar") (serialize-qp "Marker" $marker_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/api/v1/organizations/{organization_id}/subscriptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"marker": $marker, "limit": $limit, "Limit": $limit_2, "Marker": $marker_2} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"OrganizationId": $organization_id, "Username": $username, "EmailAddress": $email_address, "GivenName": $given_name, "Surname": $surname, "Password": $password, "TimeZoneId": $time_zone_id, "StorageRule": $storage_rule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Describes the specified users. You can describe all users or filter the results (for example, by status or organization). By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # The ID of the organization.
  --user-ids: string # The IDs of the users.
  --query: string # A query to filter users by user name. Remember the following about the Userids and Query parameters: If you don't use either parameter, the API returns a paginated list of all users on the site. If you use both parameters, the API ignores the Query parameter. The Userid parameter only returns user names that match a corresponding user ID. The Query parameter runs a "prefix" search for users by the GivenName, SurName, or UserName fields included in a CreateUser (https://docs.aws.amazon.com/workdocs/latest/APIReference/API_CreateUser.html) API call. For example, querying on Ma returns Márcia Oliveira, María García, and Mateo Jackson. If you use multiple characters, the API only returns data that matches all characters. For example, querying on Ma J only returns Mateo Jackson. (format: password)
  --include: string@include-completer # The state of the users. Specify "ALL" to include inactive users.
  --order: string@order-completer # The order for the results.
  --qp-sort: string@sort-completer # The sorting criteria.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of items to return.
  --fields: string # A comma-separated list of values. Specify "STORAGE_METADATA" to include the user storage quota and utilization information.
  --limit-2: string # Pagination limit (disambiguated-2)
  --marker-2: string # Pagination token (disambiguated-2)
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
  let qp = [(serialize-qp "organizationId" $organization_id "scalar") (serialize-qp "userIds" $user_ids "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "Limit" $limit_2 "scalar") (serialize-qp "Marker" $marker_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"organizationId": $organization_id, "userIds": $user_ids, "query": $query, "include": $include, "order": $order, "sort": $qp_sort, "marker": $marker, "limit": $limit, "fields": $fields, "Limit": $limit_2, "Marker": $marker_2} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'VersionId' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'CommentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), version_id: (encode-path-segment $version_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}/comment/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/api/v1/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-custom-metadata: oneof<nothing, bool> # Set this to TRUE to include custom metadata in the response.
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
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  let qp = [(serialize-qp "includeCustomMetadata" $include_custom_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/api/v1/documents/{document_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeCustomMetadata": $include_custom_metadata} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/api/v1/documents/{document_id}"))
  let req_body = {"Name": $name, "ParentFolderId": $parent_folder_id, "ResourceState": $resource_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a specific version of a document.
#
# DELETE /api/v1/documentVersions/{DocumentId}/versions/{VersionId}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'VersionId' must be non-empty" } }
  let qp = [(serialize-qp "deletePriorVersions" $delete_prior_versions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), version_id: (encode-path-segment $version_id)} | format pattern "/api/v1/documentVersions/{document_id}/versions/{version_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"deletePriorVersions": $delete_prior_versions} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'FolderId' must be non-empty" } }
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/api/v1/folders/{folder_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'FolderId' must be non-empty" } }
  let qp = [(serialize-qp "includeCustomMetadata" $include_custom_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/api/v1/folders/{folder_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeCustomMetadata": $include_custom_metadata} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'FolderId' must be non-empty" } }
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/api/v1/folders/{folder_id}"))
  let req_body = {"Name": $name, "ParentFolderId": $parent_folder_id, "ResourceState": $resource_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'FolderId' must be non-empty" } }
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/api/v1/folders/{folder_id}/contents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes the contents of the specified folder, including its documents and subfolders. By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string@sort-completer-1 # The sorting criteria.
  --order: string@order-completer # The order for the contents of the folder.
  --limit: int # The maximum number of items to return with this call.
  --marker: string # The marker for the next set of results. This marker was received from a previous call.
  --type: string@type-completer # The type of items.
  --include: string # The contents to include. Specify "INITIALIZED" to include initialized documents.
  --limit-2: string # Pagination limit (disambiguated-2)
  --marker-2: string # Pagination token (disambiguated-2)
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
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'FolderId' must be non-empty" } }
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "Limit" $limit_2 "scalar") (serialize-qp "Marker" $marker_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/api/v1/folders/{folder_id}/contents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "order": $order, "limit": $limit, "marker": $marker, "type": $type, "include": $include, "Limit": $limit_2, "Marker": $marker_2} | compact), body: null}
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
  if ($organization_id | is-empty) { error make --unspanned { msg: "path parameter 'OrganizationId' must be non-empty" } }
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'SubscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), subscription_id: (encode-path-segment $subscription_id)} | format pattern "/api/v1/organizations/{organization_id}/subscriptions/{subscription_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes the specified user from a Simple AD or Microsoft AD directory. Deleting a user immediately and permanently deletes all content in that user's folder structure. Site retention policies do NOT apply to this type of deletion.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/api/v1/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/api/v1/users/{user_id}"))
  let req_body = {"GivenName": $given_name, "Surname": $surname, "Type": $type, "StorageRule": $storage_rule, "TimeZoneId": $time_zone_id, "Locale": $locale, "GrantPoweruserPrivileges": $grant_poweruser_privileges} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --limit-2: string # Pagination limit (disambiguated-2)
  --marker-2: string # Pagination token (disambiguated-2)
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
  let qp = [(serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "organizationId" $organization_id "scalar") (serialize-qp "activityTypes" $activity_types "scalar") (serialize-qp "resourceId" $resource_id "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "includeIndirectActivities" $include_indirect_activities "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "Limit" $limit_2 "scalar") (serialize-qp "Marker" $marker_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startTime": $start_time, "endTime": $end_time, "organizationId": $organization_id, "activityTypes": $activity_types, "resourceId": $resource_id, "userId": $user_id, "includeIndirectActivities": $include_indirect_activities, "limit": $limit, "marker": $marker, "Limit": $limit_2, "Marker": $marker_2} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return.
  --marker: string # The marker for the next set of results. This marker was received from a previous call.
  --limit-2: string # Pagination limit (disambiguated-2)
  --marker-2: string # Pagination token (disambiguated-2)
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
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'VersionId' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "Limit" $limit_2 "scalar") (serialize-qp "Marker" $marker_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), version_id: (encode-path-segment $version_id)} | format pattern "/api/v1/documents/{document_id}/versions/{version_id}/comments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "marker": $marker, "Limit": $limit_2, "Marker": $marker_2} | compact), body: null}
}

# Retrieves the document versions for the specified document. By default, only active versions are returned.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of versions to return with this call.
  --include: string # A comma-separated list of values. Specify "INITIALIZED" to include incomplete versions.
  --fields: string # Specify "SOURCE" to include initialized versions and a URL for the source document.
  --limit-2: string # Pagination limit (disambiguated-2)
  --marker-2: string # Pagination token (disambiguated-2)
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
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "Limit" $limit_2 "scalar") (serialize-qp "Marker" $marker_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/api/v1/documents/{document_id}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"marker": $marker, "limit": $limit, "include": $include, "fields": $fields, "Limit": $limit_2, "Marker": $marker_2} | compact), body: null}
}

# Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
#
# GET /api/v1/groups
# operationId: DescribeGroups
export def "groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-query: string # A query to describe groups by group name. (format: password)
  --organization-id: string # The ID of the organization.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit: int # The maximum number of items to return with this call.
  --limit-2: string # Pagination limit (disambiguated-2)
  --marker-2: string # Pagination token (disambiguated-2)
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
  let qp = [(serialize-qp "searchQuery" $search_query "scalar") (serialize-qp "organizationId" $organization_id "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "Limit" $limit_2 "scalar") (serialize-qp "Marker" $marker_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"searchQuery": $search_query, "organizationId": $organization_id, "marker": $marker, "limit": $limit, "Limit": $limit_2, "Marker": $marker_2} | compact), body: null}
}

# Describes the current user's special folders; the RootFolder and the RecycleBin. RootFolder is the root of user's files and folders and RecycleBin is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients. This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see Authentication and Access Control for User Applications (https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html) in the Amazon WorkDocs Developer Guide.
#
# GET /api/v1/me/root
# operationId: DescribeRootFolders
export def "me-root get-folders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return.
  --marker: string # The marker for the next set of results. (You received this marker from a previous call.)
  --limit-2: string # Pagination limit (disambiguated-2)
  --marker-2: string # Pagination token (disambiguated-2)
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
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marker" $marker "scalar") (serialize-qp "Limit" $limit_2 "scalar") (serialize-qp "Marker" $marker_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/me/root" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "marker": $marker, "Limit": $limit_2, "Marker": $marker_2} | compact), body: null}
}

# Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients. This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see Authentication and Access Control for User Applications (https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html) in the Amazon WorkDocs Developer Guide.
#
# GET /api/v1/me
# operationId: GetCurrentUser
export def "me get-user" [
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
  --authentication: string # Amazon WorkDocs authentication token.
]: nothing -> record<User: record<Id: record, Username: record, EmailAddress: record, GivenName: record, Surname: record, OrganizationId: record, RootFolderId: record, RecycleBinFolderId: record, Status: record, Type: record, CreatedTimestamp: record, ModifiedTimestamp: record, TimeZoneId: record, Locale: record, Storage: record<StorageUtilizedInBytes: record, StorageRule: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves the path information (the hierarchy from the root folder) for the requested document. By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of levels in the hierarchy to return.
  --fields: string # A comma-separated list of values. Specify NAME to include the names of the parent folders.
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
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/api/v1/documents/{document_id}/path") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "fields": $fields, "marker": $marker} | compact), body: null}
}

# Retrieves the path information (the hierarchy from the root folder) for the specified folder. By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'FolderId' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/api/v1/folders/{folder_id}/path") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "fields": $fields, "marker": $marker} | compact), body: null}
}

# Retrieves a collection of resources, including folders and documents. The only CollectionType supported is SHARED_WITH_ME.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"userId": $user_id, "collectionType": $collection_type, "limit": $limit, "marker": $marker} | compact), body: null}
}

# Creates a new document object and version object. The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call UpdateDocumentVersion. To cancel the document upload, call AbortDocumentVersionUpload.
#
# POST /api/v1/documents
# operationId: InitiateDocumentVersionUpload
export def "documents version-initiate-upload" [
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
  let req_body = {"Id": $id, "Name": $name, "ContentCreatedTimestamp": $content_created_timestamp, "ContentModifiedTimestamp": $content_modified_timestamp, "ContentType": $content_type, "DocumentSizeInBytes": $document_size_in_bytes, "ParentFolderId": $parent_folder_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'ResourceId' must be non-empty" } }
  if ($principal_id | is-empty) { error make --unspanned { msg: "path parameter 'PrincipalId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id), principal_id: (encode-path-segment $principal_id)} | format pattern "/api/v1/resources/{resource_id}/permissions/{principal_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type} | compact), body: null}
}

# Recovers a deleted version of an Amazon WorkDocs document.
#
# POST /api/v1/documentVersions/restore/{DocumentId}
# operationId: RestoreDocumentVersions
export def "document-versions-restore create" [
  document_id: string
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
  --authentication: string # Amazon WorkDocs authentication token. Not required when using Amazon Web Services administrator credentials to access the API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'DocumentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/api/v1/documentVersions/restore/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --query-scopes: list<string> # Filter based on the text field type. A Folder has only a name and no content. A Comment has only content and no name. A Document or Document Version has a name and content
  --organization-id: string # Filters based on the resource owner OrgId. This is a mandatory parameter when using Admin SigV4 credentials.
  --additional-response-fields: list<string> # A list of attributes to include in the response. Used to request fields that are not normally returned in a standard response.
  --filters: record # Filters results based on entity metadata. — shape: {TextLocales?: any, ContentCategories?: any, ResourceTypes?: any, Labels?: any, Principals?: any, AncestorIds?: any, SearchCollectionTypes?: any, SizeRange?: any, CreatedRange?: any, ModifiedRange?: any}
  --order-by: list # Order by results in one or more categories. — item shape: {Field?: any, Order?: any}
  --limit-body: int # Max results count per page. (body field)
  --marker-body: string # The marker for the next set of results. (body field)
]: any -> record<Items: record, Marker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "Marker" $marker "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search" $qp)
  let req_body = {"QueryText": $query_text, "QueryScopes": $query_scopes, "OrganizationId": $organization_id, "AdditionalResponseFields": $additional_response_fields, "Filters": $filters, "OrderBy": $order_by, "Limit": $limit_body, "Marker": $marker_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "Authentication": $authentication} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"Limit": $limit, "Marker": $marker} | compact), body: $req_body}
}
