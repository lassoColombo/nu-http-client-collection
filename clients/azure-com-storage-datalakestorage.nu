# Auto-generated client for Azure Data Lake Storage v2019-10-31
# Source: https://api.apis.guru/v2/specs/azure.com/storage-DataLakeStorage/2019-10-31/swagger.json
# Auth: --token flag or $env.AZURE_DATA_LAKE_STORAGE_TOKEN

const BASE_URL = "https://azure.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AZURE_DATA_LAKE_STORAGE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-completer [] { ["account"] }
def resource-completer-1 [] { ["filesystem"] }
def accept-completer [] { ["application/json" "application/octet-stream" "text/plain"] }
def action-completer [] { ["checkAccess" "getAccessControl" "getStatus"] }
def action-completer-1 [] { ["append" "flush" "setAccessControl" "setProperties"] }
def x-ms-lease-action-completer [] { ["acquire" "break" "change" "release" "renew"] }
def resource-completer-2 [] { ["directory" "file"] }
def mode-completer [] { ["legacy" "posix"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-operations list-filesystem" } } | get name | first)
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

# List Filesystems
#
# GET /
# operationId: Filesystem_List
export def "account-operations list-filesystem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer # The value must be "account" for all account operations.
  --prefix: string # Filters results to filesystems within the specified prefix.
  --continuation: string # The number of filesystems returned with each invocation is limited. If the number of filesystems to be returned exceeds this limit, a continuation token is returned in the response header x-ms-continuation. When a continuation token is returned in the response, it must be specified in a subsequent invocation of the list operation to continue listing the filesystems.
  --max-results: int # An optional value that specifies the maximum number of items to return. If omitted or greater than 5,000, the response will include up to 5,000 items. (format: int32)
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
]: nothing -> record<filesystems: table<eTag: string, lastModified: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "continuation" $continuation "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Filesystem
#
# DELETE /{filesystem}
# operationId: Filesystem_Delete
export def "filesystem-operations delete" [
  filesystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer-1 # The value must be "filesystem" for all filesystem operations.
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filesystem: (encode-path-segment $filesystem)} | format pattern "/{filesystem}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Paths
#
# GET /{filesystem}
# operationId: Path_List
export def "filesystem-operations list-path" [
  filesystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer-1 # The value must be "filesystem" for all filesystem operations.
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --directory: string # Filters results to paths within the specified directory. An error occurs if the directory does not exist.
  --recursive: oneof<nothing, bool> # If "true", all paths are listed; otherwise, only paths at the root of the filesystem are listed. If "directory" is specified, the list will only include paths that share the same root.
  --continuation: string # The number of paths returned with each invocation is limited. If the number of paths to be returned exceeds this limit, a continuation token is returned in the response header x-ms-continuation. When a continuation token is returned in the response, it must be specified in a subsequent invocation of the list operation to continue listing the paths.
  --max-results: int # An optional value that specifies the maximum number of items to return. If omitted or greater than 5,000, the response will include up to 5,000 items. (format: int32)
  --upn: oneof<nothing, bool> # Optional. Valid only when Hierarchical Namespace is enabled for the account. If "true", the user identity values returned in the owner and group fields of each list entry will be transformed from Azure Active Directory Object IDs to User Principal Names. If "false", the values will be returned as Azure Active Directory Object IDs. The default value is false. Note that group and application Object IDs are not translated because they do not have unique friendly names.
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
]: nothing -> record<paths: table<contentLength: int, eTag: string, group: string, isDirectory: bool, lastModified: string, name: string, owner: string, permissions: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "directory" $directory "scalar") (serialize-qp "recursive" $recursive "scalar") (serialize-qp "continuation" $continuation "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "upn" $upn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filesystem: (encode-path-segment $filesystem)} | format pattern "/{filesystem}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Filesystem Properties.
#
# HEAD /{filesystem}
# operationId: Filesystem_GetProperties
export def "filesystem-operations get-properties" [
  filesystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer-1 # The value must be "filesystem" for all filesystem operations.
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filesystem: (encode-path-segment $filesystem)} | format pattern "/{filesystem}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set Filesystem Properties
#
# PATCH /{filesystem}
# operationId: Filesystem_SetProperties
export def "filesystem-operations update-properties" [
  filesystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer-1 # The value must be "filesystem" for all filesystem operations.
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --x-ms-properties: string # Optional. User-defined properties to be stored with the filesystem, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set. If the filesystem exists, any properties not included in the list will be removed. All properties are removed if the header is omitted. To merge new and existing properties, first get all existing properties and the current E-Tag, then make a conditional request with the E-Tag and include values for all properties.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filesystem: (encode-path-segment $filesystem)} | format pattern "/{filesystem}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version, "x-ms-properties": $x_ms_properties, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Filesystem
#
# PUT /{filesystem}
# operationId: Filesystem_Create
export def "filesystem-operations create" [
  filesystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer-1 # The value must be "filesystem" for all filesystem operations.
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --x-ms-properties: string # User-defined properties to be stored with the filesystem, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filesystem: (encode-path-segment $filesystem)} | format pattern "/{filesystem}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version, "x-ms-properties": $x_ms_properties} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete File | Delete Directory
#
# DELETE /{filesystem}/{path}
# operationId: Path_Delete
export def "file-and-directory-operations delete" [
  filesystem: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --recursive: oneof<nothing, bool> # Required and valid only when the resource is a directory. If "true", all paths beneath the directory will be deleted. If "false" and the directory is non-empty, an error occurs.
  --continuation: string # Optional. When deleting a directory, the number of paths that are deleted with each invocation is limited. If the number of paths to be deleted exceeds this limit, a continuation token is returned in this response header. When a continuation token is returned in the response, it must be specified in a subsequent invocation of the delete operation to continue deleting the directory.
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --x-ms-lease-id: string # The lease ID must be specified if there is an active lease.
  --if-match: string # Optional. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "recursive" $recursive "scalar") (serialize-qp "continuation" $continuation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filesystem: (encode-path-segment $filesystem), path: (encode-path-segment $path)} | format pattern "/{filesystem}/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version, "x-ms-lease-id": $x_ms_lease_id, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Read File
#
# GET /{filesystem}/{path}
# operationId: Path_Read
export def "file-and-directory-operations get" [
  filesystem: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --range: string # The HTTP Range request header specifies one or more byte ranges of the resource to be retrieved.
  --x-ms-lease-id: string # Optional. If this header is specified, the operation will be performed only if both of the following conditions are met: i) the path's lease is currently active and ii) the lease ID specified in the request matches that of the path.
  --x-ms-range-get-content-md5: oneof<nothing, bool> # Optional. When this header is set to "true" and specified together with the Range header, the service returns the MD5 hash for the range, as long as the range is less than or equal to 4MB in size. If this header is specified without the Range header, the service returns status code 400 (Bad Request). If this header is set to true when the range exceeds 4 MB in size, the service returns status code 400 (Bad Request).
  --if-match: string # Optional. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filesystem: (encode-path-segment $filesystem), path: (encode-path-segment $path)} | format pattern "/{filesystem}/{path}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version, "Range": $range, "x-ms-lease-id": $x_ms_lease_id, "x-ms-range-get-content-md5": $x_ms_range_get_content_md5, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Properties | Get Status | Get Access Control List | Check Access
#
# HEAD /{filesystem}/{path}
# operationId: Path_GetProperties
export def "file-and-directory-operations get-properties" [
  filesystem: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --action: string@action-completer # Optional. If the value is "getStatus" only the system defined properties for the path are returned. If the value is "getAccessControl" the access control list is returned in the response headers (Hierarchical Namespace must be enabled for the account), otherwise the properties are returned.
  --upn: oneof<nothing, bool> # Optional. Valid only when Hierarchical Namespace is enabled for the account. If "true", the user identity values returned in the x-ms-owner, x-ms-group, and x-ms-acl response headers will be transformed from Azure Active Directory Object IDs to User Principal Names. If "false", the values will be returned as Azure Active Directory Object IDs. The default value is false. Note that group and application Object IDs are not translated because they do not have unique friendly names.
  --fs-action: string # Required only for check access action. Valid only when Hierarchical Namespace is enabled for the account. File system operation read/write/execute in string form, matching regex pattern '[rwx-]{3}'
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --x-ms-lease-id: string # Optional. If this header is specified, the operation will be performed only if both of the following conditions are met: i) the path's lease is currently active and ii) the lease ID specified in the request matches that of the path.
  --if-match: string # Optional. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "upn" $upn "scalar") (serialize-qp "fsAction" $fs_action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filesystem: (encode-path-segment $filesystem), path: (encode-path-segment $path)} | format pattern "/{filesystem}/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version, "x-ms-lease-id": $x_ms_lease_id, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Append Data | Flush Data | Set Properties | Set Access Control
#
# PATCH /{filesystem}/{path}
# operationId: Path_Update
export def "file-and-directory-operations update" [
  filesystem: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --action: string@action-completer-1 # The action must be "append" to upload data to be appended to a file, "flush" to flush previously uploaded data to a file, "setProperties" to set the properties of a file or directory, or "setAccessControl" to set the owner, group, permissions, or access control list for a file or directory. Note that Hierarchical Namespace must be enabled for the account in order to use access control. Also note that the Access Control List (ACL) includes permissions for the owner, owning group, and others, so the x-ms-permissions and x-ms-acl request headers are mutually exclusive.
  --position: int # This parameter allows the caller to upload data in parallel and control the order in which it is appended to the file. It is required when uploading data to be appended to the file and when flushing previously uploaded data to the file. The value must be the position where the data is to be appended. Uploaded data is not immediately flushed, or written, to the file. To flush, the previously uploaded data must be contiguous, the position parameter must be specified and equal to the length of the file after all data has been written, and there must not be a request entity body included with the request. (format: int64)
  --retain-uncommitted-data: oneof<nothing, bool> # Valid only for flush operations. If "true", uncommitted data is retained after the flush operation completes; otherwise, the uncommitted data is deleted after the flush operation. The default is false. Data at offsets less than the specified position are written to the file when flush succeeds, but this optional parameter allows data after the flush position to be retained for a future flush operation.
  --close: oneof<nothing, bool> # Azure Storage Events allow applications to receive notifications when files change. When Azure Storage Events are enabled, a file changed event is raised. This event has a property indicating whether this is the final change to distinguish the difference between an intermediate flush to a file stream and the final close of a file stream. The close query parameter is valid only when the action is "flush" and change notifications are enabled. If the value of close is "true" and the flush operation completes successfully, the service raises a file change notification with a property indicating that this is the final update (the file stream has been closed). If "false" a change notification is raised indicating the file has changed. The default is false. This query parameter is set to true by the Hadoop ABFS driver to indicate that the file stream has been closed."
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --content-length: int # Required for "Append Data" and "Flush Data". Must be 0 for "Flush Data". Must be the length of the request content in bytes for "Append Data".
  --content-md5: string # Optional. An MD5 hash of the request content. This header is valid on "Append" and "Flush" operations. This hash is used to verify the integrity of the request content during transport. When this header is specified, the storage service compares the hash of the content that has arrived with this header value. If the two hashes do not match, the operation will fail with error code 400 (Bad Request). Note that this MD5 hash is not stored with the file. This header is associated with the request content, and not with the stored content of the file itself.
  --x-ms-lease-id: string # The lease ID must be specified if there is an active lease.
  --x-ms-cache-control: string # Optional and only valid for flush and set properties operations. The service stores this value and includes it in the "Cache-Control" response header for "Read File" operations.
  --x-ms-content-type: string # Optional and only valid for flush and set properties operations. The service stores this value and includes it in the "Content-Type" response header for "Read File" operations.
  --x-ms-content-disposition: string # Optional and only valid for flush and set properties operations. The service stores this value and includes it in the "Content-Disposition" response header for "Read File" operations.
  --x-ms-content-encoding: string # Optional and only valid for flush and set properties operations. The service stores this value and includes it in the "Content-Encoding" response header for "Read File" operations.
  --x-ms-content-language: string # Optional and only valid for flush and set properties operations. The service stores this value and includes it in the "Content-Language" response header for "Read File" operations.
  --x-ms-content-md5: string # Optional and only valid for "Flush & Set Properties" operations. The service stores this value and includes it in the "Content-Md5" response header for "Read & Get Properties" operations. If this property is not specified on the request, then the property will be cleared for the file. Subsequent calls to "Read & Get Properties" will not return this property unless it is explicitly set on that file again.
  --x-ms-properties: string # Optional. User-defined properties to be stored with the file or directory, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set. Valid only for the setProperties operation. If the file or directory exists, any properties not included in the list will be removed. All properties are removed if the header is omitted. To merge new and existing properties, first get all existing properties and the current E-Tag, then make a conditional request with the E-Tag and include values for all properties.
  --x-ms-owner: string # Optional and valid only for the setAccessControl operation. Sets the owner of the file or directory.
  --x-ms-group: string # Optional and valid only for the setAccessControl operation. Sets the owning group of the file or directory.
  --x-ms-permissions: string # Optional and only valid if Hierarchical Namespace is enabled for the account. Sets POSIX access permissions for the file owner, the file owning group, and others. Each class may be granted read, write, or execute permission. The sticky bit is also supported. Both symbolic (rwxrw-rw-) and 4-digit octal notation (e.g. 0766) are supported. Invalid in conjunction with x-ms-acl.
  --x-ms-acl: string # Optional and valid only for the setAccessControl operation. Sets POSIX access control rights on files and directories. The value is a comma-separated list of access control entries that fully replaces the existing access control list (ACL). Each access control entry (ACE) consists of a scope, a type, a user or group identifier, and permissions in the format "[scope:][type]:[id]:[permissions]". The scope must be "default" to indicate the ACE belongs to the default ACL for a directory; otherwise scope is implicit and the ACE belongs to the access ACL. There are four ACE types: "user" grants rights to the owner or a named user, "group" grants rights to the owning group or a named group, "mask" restricts rights granted to named users and the members of groups, and "other" grants rights to all users not found in any of the other entries. The user or group identifier is omitted for entries of type "mask" and "other". The user or group identifier is also omitted for the owner and owning group. The permission field is a 3-character sequence where the first character is 'r' to grant read access, the second character is 'w' to grant write access, and the third character is 'x' to grant execute permission. If access is not granted, the '-' character is used to denote that the permission is denied. For example, the following ACL grants read, write, and execute rights to the file owner and john.doe@contoso, the read right to the owning group, and nothing to everyone else: "user::rwx,user:john.doe@contoso:rwx,group::r--,other::---,mask=rwx". Invalid in conjunction with x-ms-permissions.
  --if-match: string # Optional for Flush Data and Set Properties, but invalid for Append Data. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional for Flush Data and Set Properties, but invalid for Append Data. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional for Flush Data and Set Properties, but invalid for Append Data. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional for Flush Data and Set Properties, but invalid for Append Data. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "retainUncommittedData" $retain_uncommitted_data "scalar") (serialize-qp "close" $close "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filesystem: (encode-path-segment $filesystem), path: (encode-path-segment $path)} | format pattern "/{filesystem}/{path}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version, "Content-Length": $content_length, "Content-MD5": $content_md5, "x-ms-lease-id": $x_ms_lease_id, "x-ms-cache-control": $x_ms_cache_control, "x-ms-content-type": $x_ms_content_type, "x-ms-content-disposition": $x_ms_content_disposition, "x-ms-content-encoding": $x_ms_content_encoding, "x-ms-content-language": $x_ms_content_language, "x-ms-content-md5": $x_ms_content_md5, "x-ms-properties": $x_ms_properties, "x-ms-owner": $x_ms_owner, "x-ms-group": $x_ms_group, "x-ms-permissions": $x_ms_permissions, "x-ms-acl": $x_ms_acl, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lease Path
#
# POST /{filesystem}/{path}
# operationId: Path_Lease
export def "file-and-directory-operations create-lease" [
  filesystem: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --x-ms-lease-action: string@x-ms-lease-action-completer # There are five lease actions: "acquire", "break", "change", "renew", and "release". Use "acquire" and specify the "x-ms-proposed-lease-id" and "x-ms-lease-duration" to acquire a new lease. Use "break" to break an existing lease. When a lease is broken, the lease break period is allowed to elapse, during which time no lease operation except break and release can be performed on the file. When a lease is successfully broken, the response indicates the interval in seconds until a new lease can be acquired. Use "change" and specify the current lease ID in "x-ms-lease-id" and the new lease ID in "x-ms-proposed-lease-id" to change the lease ID of an active lease. Use "renew" and specify the "x-ms-lease-id" to renew an existing lease. Use "release" and specify the "x-ms-lease-id" to release a lease.
  --x-ms-lease-duration: int # The lease duration is required to acquire a lease, and specifies the duration of the lease in seconds. The lease duration must be between 15 and 60 seconds or -1 for infinite lease.
  --x-ms-lease-break-period: int # The lease break period duration is optional to break a lease, and specifies the break period of the lease in seconds. The lease break duration must be between 0 and 60 seconds.
  --x-ms-lease-id: string # Required when "x-ms-lease-action" is "renew", "change" or "release". For the renew and release actions, this must match the current lease ID.
  --x-ms-proposed-lease-id: string # Required when "x-ms-lease-action" is "acquire" or "change". A lease will be acquired with this lease ID if the operation is successful.
  --if-match: string # Optional. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filesystem: (encode-path-segment $filesystem), path: (encode-path-segment $path)} | format pattern "/{filesystem}/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version, "x-ms-lease-action": $x_ms_lease_action, "x-ms-lease-duration": $x_ms_lease_duration, "x-ms-lease-break-period": $x_ms_lease_break_period, "x-ms-lease-id": $x_ms_lease_id, "x-ms-proposed-lease-id": $x_ms_proposed_lease_id, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create File | Create Directory | Rename File | Rename Directory
#
# PUT /{filesystem}/{path}
# operationId: Path_Create
export def "file-and-directory-operations create" [
  filesystem: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --resource: string@resource-completer-2 # Required only for Create File and Create Directory. The value must be "file" or "directory".
  --continuation: string # Optional. When renaming a directory, the number of paths that are renamed with each invocation is limited. If the number of paths to be renamed exceeds this limit, a continuation token is returned in this response header. When a continuation token is returned in the response, it must be specified in a subsequent invocation of the rename operation to continue renaming the directory.
  --mode: string@mode-completer # Optional. Valid only when namespace is enabled. This parameter determines the behavior of the rename operation. The value must be "legacy" or "posix", and the default value will be "posix".
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --cache-control: string # Optional. The service stores this value and includes it in the "Cache-Control" response header for "Read File" operations for "Read File" operations.
  --content-encoding: string # Optional. Specifies which content encodings have been applied to the file. This value is returned to the client when the "Read File" operation is performed.
  --content-language: string # Optional. Specifies the natural language used by the intended audience for the file.
  --content-disposition: string # Optional. The service stores this value and includes it in the "Content-Disposition" response header for "Read File" operations.
  --x-ms-cache-control: string # Optional. The service stores this value and includes it in the "Cache-Control" response header for "Read File" operations.
  --x-ms-content-type: string # Optional. The service stores this value and includes it in the "Content-Type" response header for "Read File" operations.
  --x-ms-content-encoding: string # Optional. The service stores this value and includes it in the "Content-Encoding" response header for "Read File" operations.
  --x-ms-content-language: string # Optional. The service stores this value and includes it in the "Content-Language" response header for "Read File" operations.
  --x-ms-content-disposition: string # Optional. The service stores this value and includes it in the "Content-Disposition" response header for "Read File" operations.
  --x-ms-rename-source: string # An optional file or directory to be renamed. The value must have the following format: "/{filesystem}/{path}". If "x-ms-properties" is specified, the properties will overwrite the existing properties; otherwise, the existing properties will be preserved. This value must be a URL percent-encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set.
  --x-ms-lease-id: string # Optional. A lease ID for the path specified in the URI. The path to be overwritten must have an active lease and the lease ID must match.
  --x-ms-source-lease-id: string # Optional for rename operations. A lease ID for the source path. The source path must have an active lease and the lease ID must match.
  --x-ms-properties: string # Optional. User-defined properties to be stored with the file or directory, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set.
  --x-ms-permissions: string # Optional and only valid if Hierarchical Namespace is enabled for the account. Sets POSIX access permissions for the file owner, the file owning group, and others. Each class may be granted read, write, or execute permission. The sticky bit is also supported. Both symbolic (rwxrw-rw-) and 4-digit octal notation (e.g. 0766) are supported.
  --x-ms-umask: string # Optional and only valid if Hierarchical Namespace is enabled for the account. When creating a file or directory and the parent folder does not have a default ACL, the umask restricts the permissions of the file or directory to be created. The resulting permission is given by p & ^u, where p is the permission and u is the umask. For example, if p is 0777 and u is 0057, then the resulting permission is 0720. The default permission is 0777 for a directory and 0666 for a file. The default umask is 0027. The umask must be specified in 4-digit octal notation (e.g. 0766).
  --if-match: string # Optional. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
  --x-ms-source-if-match: string # Optional. An ETag value. Specify this header to perform the rename operation only if the source's ETag matches the value specified. The ETag must be specified in quotes.
  --x-ms-source-if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the rename operation only if the source's ETag does not match the value specified. The ETag must be specified in quotes.
  --x-ms-source-if-modified-since: string # Optional. A date and time value. Specify this header to perform the rename operation only if the source has been modified since the specified date and time.
  --x-ms-source-if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the rename operation only if the source has not been modified since the specified date and time.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "resource" $resource "scalar") (serialize-qp "continuation" $continuation "scalar") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filesystem: (encode-path-segment $filesystem), path: (encode-path-segment $path)} | format pattern "/{filesystem}/{path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-date": $x_ms_date, "x-ms-version": $x_ms_version, "Cache-Control": $cache_control, "Content-Encoding": $content_encoding, "Content-Language": $content_language, "Content-Disposition": $content_disposition, "x-ms-cache-control": $x_ms_cache_control, "x-ms-content-type": $x_ms_content_type, "x-ms-content-encoding": $x_ms_content_encoding, "x-ms-content-language": $x_ms_content_language, "x-ms-content-disposition": $x_ms_content_disposition, "x-ms-rename-source": $x_ms_rename_source, "x-ms-lease-id": $x_ms_lease_id, "x-ms-source-lease-id": $x_ms_source_lease_id, "x-ms-properties": $x_ms_properties, "x-ms-permissions": $x_ms_permissions, "x-ms-umask": $x_ms_umask, "If-Match": $if_match, "If-None-Match": $if_none_match, "If-Modified-Since": $if_modified_since, "If-Unmodified-Since": $if_unmodified_since, "x-ms-source-if-match": $x_ms_source_if_match, "x-ms-source-if-none-match": $x_ms_source_if_none_match, "x-ms-source-if-modified-since": $x_ms_source_if_modified_since, "x-ms-source-if-unmodified-since": $x_ms_source_if_unmodified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
