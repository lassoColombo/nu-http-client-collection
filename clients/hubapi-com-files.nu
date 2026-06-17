# Auto-generated client for Files vv3
# Source: https://api.apis.guru/v2/specs/hubapi.com/files/v3/openapi.json
# Auth: --token flag or $env.FILES_TOKEN

const BASE_URL = "https://api.hubapi.com"
const DEFAULT_AUTH = "query-hapikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FILES_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-hapikey" => { {headers: {}, query: $"hapikey=($token_val)"} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "private-app-legacy" => { {headers: {private-app-legacy: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.hubapi.com"] }
def auth-scheme-completer [] { ["query-hapikey" "bearer" "private-app-legacy"] }

# Completers for enum parameters
def access-completer [] { ["HIDDEN_INDEXABLE" "HIDDEN_NOT_INDEXABLE" "HIDDEN_PRIVATE" "PRIVATE" "PUBLIC_INDEXABLE" "PUBLIC_NOT_INDEXABLE"] }
def duplicate-validation-scope-completer [] { ["ENTIRE_PORTAL" "EXACT_FOLDER"] }
def duplicate-validation-strategy-completer [] { ["NONE" "REJECT" "RETURN_EXISTING"] }
def size-completer [] { ["icon" "medium" "preview" "thumb"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "files-files upload" } } | get name | first)
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

# Upload file
#
# POST /files/v3/files
# operationId: post-/files/v3/files_upload
export def "files-files upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --charset-hunch: string # Character set of the uploaded file.
  --file: string # File to be uploaded. (format: binary)
  --file-name: string # Desired name for the uploaded file.
  --folder-id: string # Either 'folderId' or 'folderPath' is required. folderId is the ID of the folder the file will be uploaded to.
  --folder-path: string # Either 'folderPath' or 'folderId' is required. This field represents the destination folder path for the uploaded file. If a path doesn't exist, the system will try to create one.
  --options: string # JSON string representing FileUploadOptions.
]: any -> record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files/v3/files")
  let body = {"charsetHunch": $charset_hunch, "file": $file, "fileName": $file_name, "folderId": $folder_id, "folderPath": $folder_path, "options": $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Import a file from a URL into the file manager.
#
# POST /files/v3/files/import-from-url/async
# operationId: post-/files/v3/files/import-from-url/async_importFromUrl
export def "files-files-import-from-url-async import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access: string@access-completer # PUBLIC_INDEXABLE: File is publicly accessible by anyone who has the URL. Search engines can index the file. PUBLIC_NOT_INDEXABLE: File is publicly accessible by anyone who has the URL. Search engines *can't* index the file. PRIVATE: File is NOT publicly accessible. Requires a signed URL to see content. Search engines *can't* index the file.
  duplicate_validation_scope: string@duplicate-validation-scope-completer # ENTIRE_PORTAL: Look for a duplicate file in the entire account. EXACT_FOLDER: Look for a duplicate file in the provided folder.
  duplicate_validation_strategy: string@duplicate-validation-strategy-completer # NONE: Do not run any duplicate validation. REJECT: Reject the upload if a duplicate is found. RETURN_EXISTING: If a duplicate file is found, do not upload a new file and return the found duplicate instead.
  --folder-id: string # One of folderId or folderPath is required. Destination folder ID for the uploaded file.
  --folder-path: string # One of folderPath or folderId is required. Destination folder path for the uploaded file. If the folder path does not exist, there will be an attempt to create the folder path.
  --name: string # Name to give the resulting file in the file manager.
  --overwrite: oneof<nothing, bool> # If true, it will overwrite existing files if a file with the same name exists in the given folder.
  --ttl: string # Time to live. If specified the file will be deleted after the given time frame.
  --body-url: string # URL to download the new file from.
]: any -> record<id: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files/v3/files/import-from-url/async")
  let body = {"access": $access, "duplicateValidationScope": $duplicate_validation_scope, "duplicateValidationStrategy": $duplicate_validation_strategy, "folderId": $folder_id, "folderPath": $folder_path, "name": $name, "overwrite": $overwrite, "ttl": $ttl, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check import status.
#
# GET /files/v3/files/import-from-url/async/tasks/{taskId}/status
# operationId: get-/files/v3/files/import-from-url/async/tasks/{taskId}/status_checkImport
export def "files-files-import-from-url-async-tasks-status check" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, result: record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>, startedAt: string, status: string, taskId: string> {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/files/v3/files/import-from-url/async/tasks/{task_id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search files
#
# GET /files/v3/files/search
# operationId: get-/files/v3/files/search_doSearch
export def "files-files-search doSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: list # Desired file properties in the return object.
  --after: string # The maximum offset of items for a given search is 10000. Narrow your search down if you are reaching this limit.
  --before: string
  --limit: int # Number of items to return. Maximum limit is 100. (format: int32)
  --qp-sort: list # Sort files by a given field.
  --id: string # Search files by given ID.
  --created-at: string # Search files by time of creation. (format: date-time)
  --created-at-lte: string # format: date-time
  --created-at-gte: string # format: date-time
  --updated-at: string # Search files by time of latest updated. (format: date-time)
  --updated-at-lte: string # format: date-time
  --updated-at-gte: string # format: date-time
  --name: string # Search for files containing the given name.
  --path: string # Search files by path.
  --parent-folder-id: int # Search files within given folder ID. (format: int64)
  --size: int # Query by file size. (format: int64)
  --height: int # Search files by height of image or video. (format: int32)
  --width: int # Search files by width of image or video. (format: int32)
  --encoding: string # Search files with specified encoding.
  --type: string # Filter by provided file type.
  --extension: string # Search files by given extension.
  --qp-url: string # Search for given URL
  --is-usable-in-content: oneof<nothing, bool> # If true shows files that have been marked to be used in new content. It false shows files that should not be used in new content.
  --allows-anonymous-access: oneof<nothing, bool> # If 'true' will show private files; if 'false' will show public files
]: nothing -> record<paging: record<next: record<after: string, link: string>, prev: record<before: string, link: string>>, results: table<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "properties" $properties "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "id" $id "scalar") (serialize-qp "createdAt" $created_at "scalar") (serialize-qp "createdAtLte" $created_at_lte "scalar") (serialize-qp "createdAtGte" $created_at_gte "scalar") (serialize-qp "updatedAt" $updated_at "scalar") (serialize-qp "updatedAtLte" $updated_at_lte "scalar") (serialize-qp "updatedAtGte" $updated_at_gte "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "parentFolderId" $parent_folder_id "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "encoding" $encoding "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "extension" $extension "scalar") (serialize-qp "url" $qp_url "scalar") (serialize-qp "isUsableInContent" $is_usable_in_content "scalar") (serialize-qp "allowsAnonymousAccess" $allows_anonymous_access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files/v3/files/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete file
#
# DELETE /files/v3/files/{fileId}
# operationId: delete-/files/v3/files/{fileId}_archive
export def "files-files archive" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/v3/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file.
#
# GET /files/v3/files/{fileId}
# operationId: get-/files/v3/files/{fileId}_getById
export def "files-files get-by" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: list
]: nothing -> record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "properties" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/v3/files/{file_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# update file properties
#
# PATCH /files/v3/files/{fileId}
# operationId: patch-/files/v3/files/{fileId}_updateProperties
export def "files-files update-properties" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: string@access-completer # NONE: Do not run any duplicate validation. REJECT: Reject the upload if a duplicate is found. RETURN_EXISTING: If a duplicate file is found, do not upload a new file and return the found duplicate instead.
  --is-usable-in-content: oneof<nothing, bool> # Mark weather the file should be used in new content or not.
  --name: string # New name for the file.
  --parent-folder-id: string # Folder ID where the file should be moved to.  folderId and folderPath cannot be set at the same time.
  --parent-folder-path: string # Folder path where the file should be moved to. folderId and folderPath cannot be set at the same time.
]: any -> record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/v3/files/{file_id}"))
  let body = {"access": $access, "isUsableInContent": $is_usable_in_content, "name": $name, "parentFolderId": $parent_folder_id, "parentFolderPath": $parent_folder_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace file.
#
# PUT /files/v3/files/{fileId}
# operationId: put-/files/v3/files/{fileId}_replace
export def "files-files replace" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --charset-hunch: string # Character set of given file data.
  --file: string # File data that will replace existing file in the file manager. (format: binary)
  --options: string # JSON String representing FileReplaceOptions
]: any -> record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/v3/files/{file_id}"))
  let body = {"charsetHunch": $charset_hunch, "file": $file, "options": $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# GDPR delete
#
# DELETE /files/v3/files/{fileId}/gdpr-delete
# operationId: delete-/files/v3/files/{fileId}/gdpr-delete_archiveGDPR
export def "files-files-gdpr-delete archive" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/v3/files/{file_id}/gdpr-delete"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get signed URL to access private file.
#
# GET /files/v3/files/{fileId}/signed-url
# operationId: get-/files/v3/files/{fileId}/signed-url_getSignedUrl
export def "files-files-signed-url get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --size: string@size-completer # For image files. This will resize the image to the desired size before sharing. Does not affect the original file, just the file served by this signed URL.
  --expiration-seconds: int # How long in seconds the link will provide access to the file. (format: int64)
  --upscale: oneof<nothing, bool> # If size is provided, this will upscale the image to fit the size dimensions.
]: nothing -> record<expiresAt: string, extension: string, height: int, name: string, size: int, type: string, url: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "expirationSeconds" $expiration_seconds "scalar") (serialize-qp "upscale" $upscale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/files/v3/files/{file_id}/signed-url") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create folder.
#
# POST /files/v3/folders
# operationId: post-/files/v3/folders_create
export def "files-folders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Desired name for the folder.
  --parent-folder-id: string # Folder ID of the parent of the created folder. If not specified, the folder will be created at the root level. parentFolderId and parentFolderPath cannot be set at the same time.
  --parent-path: string # Path of the parent of the created folder. If not specified the folder will be created at the root level. parentFolderPath and parentFolderId cannot be set at the same time.
]: any -> record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files/v3/folders")
  let body = {"name": $name, "parentFolderId": $parent_folder_id, "parentPath": $parent_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search folders
#
# GET /files/v3/folders/search
# operationId: get-/files/v3/folders/search_doSearch
export def "files-folders-search doSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: list # Properties that should be included in the returned folders.
  --after: string # The maximum offset of items for a given search is 10000. Narrow your search down if you are reaching this limit.
  --before: string
  --limit: int # Limit of results to return. Max limit is 100. (format: int32)
  --qp-sort: list # Sort results by given property. For example -name sorts by name field descending, name sorts by name field ascending.
  --id: string # Search folder by given ID.
  --created-at: string # Search for folders with the given creation timestamp. (format: date-time)
  --created-at-lte: string # format: date-time
  --created-at-gte: string # format: date-time
  --updated-at: string # Search for folder at given update timestamp. (format: date-time)
  --updated-at-lte: string # format: date-time
  --updated-at-gte: string # format: date-time
  --name: string # Search for folders containing the specified name.
  --path: string # Search for folders by path.
  --parent-folder-id: int # Search for folders with the given parent folder ID. (format: int64)
]: nothing -> record<paging: record<next: record<after: string, link: string>, prev: record<before: string, link: string>>, results: table<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "properties" $properties "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "id" $id "scalar") (serialize-qp "createdAt" $created_at "scalar") (serialize-qp "createdAtLte" $created_at_lte "scalar") (serialize-qp "createdAtGte" $created_at_gte "scalar") (serialize-qp "updatedAt" $updated_at "scalar") (serialize-qp "updatedAtLte" $updated_at_lte "scalar") (serialize-qp "updatedAtGte" $updated_at_gte "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "parentFolderId" $parent_folder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files/v3/folders/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update folder properties
#
# POST /files/v3/folders/update/async
# operationId: post-/files/v3/folders/update/async_updateProperties
export def "files-folders-update-async update-properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Id of the folder to change.
  --name: string # New name. If specified the folder's name and fullPath will change. All children of the folder will be updated accordingly.
  --parent-folder-id: int # New parent folder ID. If changed, the folder and all it's children will be moved into the specified folder. parentFolderId and parentFolderPath cannot be specified at the same time. (format: int64)
]: any -> record<id: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files/v3/folders/update/async")
  let body = {"id": $id, "name": $name, "parentFolderId": $parent_folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check folder update status.
#
# GET /files/v3/folders/update/async/tasks/{taskId}/status
# operationId: get-/files/v3/folders/update/async/tasks/{taskId}/status_checkUpdateStatus
export def "files-folders-update-async-tasks-status check" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, result: record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>, startedAt: string, status: string, taskId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: $task_id} | format pattern "/files/v3/folders/update/async/tasks/{task_id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete folder.
#
# DELETE /files/v3/folders/{folderId}
# operationId: delete-/files/v3/folders/{folderId}_archive
export def "files-folders archive" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/files/v3/folders/{folder_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get folder
#
# GET /files/v3/folders/{folderId}
# operationId: get-/files/v3/folders/{folderId}_getById
export def "files-folders get-by" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: list # Properties to set on returned folder.
]: nothing -> record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "properties" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/files/v3/folders/{folder_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete folder.
#
# DELETE /files/v3/folders/{folderPath}
# operationId: delete-/files/v3/folders/{folderPath}_archiveByPath
export def "files-folders archive-by-path" [
  folder_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_path: $folder_path} | format pattern "/files/v3/folders/{folder_path}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get folder.
#
# GET /files/v3/folders/{folderPath}
# operationId: get-/files/v3/folders/{folderPath}_getByPath
export def "files-folders get-by-path" [
  folder_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: list # Properties to set on returned folder.
]: nothing -> record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "private-app-legacy"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "properties" $properties "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_path: $folder_path} | format pattern "/files/v3/folders/{folder_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
