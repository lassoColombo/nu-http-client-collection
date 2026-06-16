# Auto-generated client for Asana v1.0
# Source: https://api.apis.guru/v2/specs/asana.com/1.0/openapi.json
# Auth: --token flag or $env.ASANA_TOKEN

const BASE_URL = "https://app.asana.com/api/1.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ASANA_TOKEN | default "" }
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

def base-url-completer [] { ["https://app.asana.com/api/1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-subtype-completer [] { ["asana" "box" "dropbox" "external" "gdrive" "onedrive" "vimeo"] }
def resource-type-completer [] { ["portfolio" "project" "project_template" "tag" "task" "user"] }
def actor-type-completer [] { ["anonymous" "asana" "asana_support" "external_administrator" "user"] }
def resource-subtype-completer-1 [] { ["default_task" "milestone"] }
def sort-by-completer [] { ["completed_at" "created_at" "due_date" "likes" "modified_at"] }
def resource-type-completer-1 [] { ["custom_field" "portfolio" "project" "project_template" "tag" "task" "user"] }
def type-completer [] { ["custom_field" "portfolio" "project" "tag" "task" "user"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "attachments list" } } | get name | first)
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

# Get attachments from an object
#
# GET /attachments
# operationId: getAttachmentsForObject
export def "attachments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --parent: string # Globally unique identifier for object to fetch statuses from. Must be a GID for a `project`, `project_brief`, or `task`. (e.g. 159874)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload an attachment
#
# POST /attachments
# operationId: createAttachmentForObject
export def "attachments createAttachmentForObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --connect-to-app: oneof<nothing, bool> # *Optional*. Only relevant for external attachments with a parent task. A boolean indicating whether the current app should be connected with the attachment for the purposes of showing an app components widget. Requires the app to have been added to a project the parent task is in.
  --file: string # Required for `asana` attachments.  (format: binary)
  --name: string # The name of the external resource being attached. Required for attachments of type `external`.
  --parent: string # Required identifier of the parent task, project, or project_brief, as a string.
  --resource-subtype: string@resource-subtype-completer # The type of the attachment. Must be one of the given values. If not specified, a file attachment of type `asana` will be assumed. Note that if the value of `resource_subtype` is `external`, a `parent`, `name`, and `url` must also be provided.  (e.g. external)
  --body-url: string # The URL of the external resource being attached. Required for attachments of type `external`.
]: any -> record<data: record<connected_to_app: bool, created_at: string, download_url: string, host: string, parent: record<resource_subtype: string>, permanent_url: string, size: int, view_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/attachments" $qp)
  let body = {connect_to_app: $connect_to_app, file: $file, name: $name, parent: $parent, resource_subtype: $resource_subtype, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete an attachment
#
# DELETE /attachments/{attachment_gid}
# operationId: deleteAttachment
export def "attachments delete" [
  attachment_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/attachments/($attachment_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an attachment
#
# GET /attachments/{attachment_gid}
# operationId: getAttachment
export def "attachments get" [
  attachment_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<connected_to_app: bool, created_at: string, download_url: string, host: string, parent: record<resource_subtype: string>, permanent_url: string, size: int, view_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/attachments/($attachment_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit parallel requests
#
# POST /batch
# operationId: createBatchRequest
# --data shape: {actions?: list}
export def "batch createBatchRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A request object for use in a batch request. — shape: {actions?: list}
]: any -> record<data: table<body: record, headers: record, status_code: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/batch" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a custom field
#
# POST /custom_fields
# operationId: createCustomField
export def "custom-fields createCustomField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: any
]: any -> record<data: record<created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_fields" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a custom field
#
# DELETE /custom_fields/{custom_field_gid}
# operationId: deleteCustomField
export def "custom-fields delete" [
  custom_field_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_fields/($custom_field_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a custom field
#
# GET /custom_fields/{custom_field_gid}
# operationId: getCustomField
export def "custom-fields get" [
  custom_field_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_fields/($custom_field_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a custom field
#
# PUT /custom_fields/{custom_field_gid}
# operationId: updateCustomField
export def "custom-fields updateCustomField" [
  custom_field_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_fields/($custom_field_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an enum option
#
# POST /custom_fields/{custom_field_gid}/enum_options
# operationId: createEnumOptionForCustomField
export def "custom-fields-enum-options createEnumOptionForCustomField" [
  custom_field_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_fields/($custom_field_gid)/enum_options" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reorder a custom field's enum
#
# POST /custom_fields/{custom_field_gid}/enum_options/insert
# operationId: insertEnumOptionForCustomField
# --data shape: {after_enum_option?: string, before_enum_option?: string, enum_option: string}
export def "custom-fields-enum-options-insert insertEnumOptionForCustomField" [
  custom_field_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {after_enum_option?: string, before_enum_option?: string, enum_option: string}
]: any -> record<data: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_fields/($custom_field_gid)/enum_options/insert" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an enum option
#
# PUT /enum_options/{enum_option_gid}
# operationId: updateEnumOption
export def "enum-options updateEnumOption" [
  enum_option_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/enum_options/($enum_option_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get events on a resource
#
# GET /events
# operationId: getEvents
export def "events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string # A resource ID to subscribe to. The resource can be a task or project. (e.g. 12345)
  --sync: string # A sync token received from the last request, or none on first sync. Events will be returned from the point in time that the sync token was generated. *Note: On your first request, omit the sync token. The response will be the same as for an expired sync token, and will include a new valid sync token.If the sync token is too old (which may happen from time to time) the API will return a `412 Precondition Failed` error, and include a fresh sync token in the response.* (e.g. de4774f6915eae04714ca93bb2f5ee81)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: table<action: string, change: record, created_at: string, parent: record, resource: record, type: string, user: record>, has_more: bool, sync: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "sync" $sync "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get goal relationships
#
# GET /goal_relationships
# operationId: getGoalRelationships
export def "goal-relationships list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --supported-goal: string # Globally unique identifier for the supported goal in the goal relationship. (e.g. 12345)
  --resource-subtype: string # If provided, filter to goal relationships with a given resource_subtype. (e.g. subgoal)
]: nothing -> record<data: table<gid: string, resource_type: string, contribution_weight: float, resource_subtype: string, supporting_resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "supported_goal" $supported_goal "scalar") (serialize-qp "resource_subtype" $resource_subtype "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/goal_relationships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a goal relationship
#
# GET /goal_relationships/{goal_relationship_gid}
# operationId: getGoalRelationship
export def "goal-relationships get" [
  goal_relationship_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goal_relationships/($goal_relationship_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a goal relationship
#
# PUT /goal_relationships/{goal_relationship_gid}
# operationId: updateGoalRelationship
export def "goal-relationships updateGoalRelationship" [
  goal_relationship_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goal_relationships/($goal_relationship_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get goals
#
# GET /goals
# operationId: getGoals
export def "goals list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --portfolio: string # Globally unique identifier for supporting portfolio. (e.g. 159874)
  --project: string # Globally unique identifier for supporting project. (e.g. 512241)
  --is-workspace-level: oneof<nothing, bool> # Filter to goals with is_workspace_level set to query value. Must be used with the workspace parameter. (e.g. false)
  --team: string # Globally unique identifier for the team. (e.g. 31326)
  --workspace: string # Globally unique identifier for the workspace. (e.g. 31326)
  --time-periods: list # Globally unique identifiers for the time periods. (e.g. 221693,506165)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, owner: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "portfolio" $portfolio "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "is_workspace_level" $is_workspace_level "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "time_periods" $time_periods "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/goals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a goal
#
# POST /goals
# operationId: createGoal
export def "goals createGoal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: any
]: any -> record<data: record<current_status_update: record, followers: list<record>, likes: list<record>, metric: record<can_manage: bool>, num_likes: int, owner: record, team: record, time_period: record, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/goals" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a goal
#
# DELETE /goals/{goal_gid}
# operationId: deleteGoal
export def "goals delete" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a goal
#
# GET /goals/{goal_gid}
# operationId: getGoal
export def "goals get" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<current_status_update: record, followers: list<record>, likes: list<record>, metric: record<can_manage: bool>, num_likes: int, owner: record, team: record, time_period: record, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a goal
#
# PUT /goals/{goal_gid}
# operationId: updateGoal
export def "goals updateGoal" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<current_status_update: record, followers: list<record>, likes: list<record>, metric: record<can_manage: bool>, num_likes: int, owner: record, team: record, time_period: record, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a collaborator to a goal
#
# POST /goals/{goal_gid}/addFollowers
# operationId: addFollowers
# --data shape: {followers: list}
export def "goals-add-followers addFollowers" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: list}
]: any -> record<data: record<current_status_update: record, followers: list<record>, likes: list<record>, metric: record<can_manage: bool>, num_likes: int, owner: record, team: record, time_period: record, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/addFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a supporting goal relationship
#
# POST /goals/{goal_gid}/addSupportingRelationship
# operationId: addSupportingRelationship
# --data shape: {contribution_weight?: float, insert_after?: string, insert_before?: string, supporting_resource: string}
export def "goals-add-supporting-relationship addSupportingRelationship" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {contribution_weight?: float, insert_after?: string, insert_before?: string, supporting_resource: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/addSupportingRelationship" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get parent goals from a goal
#
# GET /goals/{goal_gid}/parentGoals
# operationId: getParentGoalsForGoal
export def "goals-parent-goals get" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, owner: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/parentGoals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a collaborator from a goal
#
# POST /goals/{goal_gid}/removeFollowers
# operationId: removeFollowers
# --data shape: {followers: list}
export def "goals-remove-followers removeFollowers" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: list}
]: any -> record<data: record<current_status_update: record, followers: list<record>, likes: list<record>, metric: record<can_manage: bool>, num_likes: int, owner: record, team: record, time_period: record, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/removeFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a supporting goal relationship
#
# POST /goals/{goal_gid}/removeSupportingRelationship
# operationId: removeSupportingRelationship
# --data shape: {supporting_resource: string}
export def "goals-remove-supporting-relationship removeSupportingRelationship" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {supporting_resource: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/removeSupportingRelationship" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a goal metric
#
# POST /goals/{goal_gid}/setMetric
# operationId: createGoalMetric
export def "goals-set-metric createGoalMetric" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<current_status_update: record, followers: list<record>, likes: list<record>, metric: record<can_manage: bool>, num_likes: int, owner: record, team: record, time_period: record, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/setMetric" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a goal metric
#
# POST /goals/{goal_gid}/setMetricCurrentValue
# operationId: updateGoalMetric
export def "goals-set-metric-current-value updateGoalMetric" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<current_status_update: record, followers: list<record>, likes: list<record>, metric: record<can_manage: bool>, num_likes: int, owner: record, team: record, time_period: record, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/setMetricCurrentValue" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a job by id
#
# GET /jobs/{job_gid}
# operationId: getJob
export def "jobs get" [
  job_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($job_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an organization export request
#
# POST /organization_exports
# operationId: createOrganizationExport
# --data shape: {organization?: string}
export def "organization-exports createOrganizationExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: record # An *organization_export* request starts a job to export the complete data of the given Organization. — shape: {organization?: string}
]: any -> record<data: record<gid: string, resource_type: string, created_at: string, download_url: string, organization: record<gid: string, resource_type: string, name: string>, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization_exports" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get details on an org export request
#
# GET /organization_exports/{organization_export_gid}
# operationId: getOrganizationExport
export def "organization-exports get" [
  organization_export_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<gid: string, resource_type: string, created_at: string, download_url: string, organization: record<gid: string, resource_type: string, name: string>, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization_exports/($organization_export_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple portfolio memberships
#
# GET /portfolio_memberships
# operationId: getPortfolioMemberships
export def "portfolio-memberships list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --portfolio: string # The portfolio to filter results on. (e.g. 12345)
  --workspace: string # The workspace to filter results on. (e.g. 12345)
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, portfolio: record, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "portfolio" $portfolio "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/portfolio_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a portfolio membership
#
# GET /portfolio_memberships/{portfolio_membership_gid}
# operationId: getPortfolioMembership
export def "portfolio-memberships get" [
  portfolio_membership_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<gid: string, resource_type: string, portfolio: record<gid: string, resource_type: string, name: string>, user: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolio_memberships/($portfolio_membership_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple portfolios
#
# GET /portfolios
# operationId: getPortfolios
export def "portfolios list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace or organization to filter portfolios on. (e.g. 1331)
  --owner: string # The user who owns the portfolio. Currently, API users can only get a list of portfolios that they themselves own. (e.g. 14916)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/portfolios" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a portfolio
#
# POST /portfolios
# operationId: createPortfolio
export def "portfolios createPortfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/portfolios" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a portfolio
#
# DELETE /portfolios/{portfolio_gid}
# operationId: deletePortfolio
export def "portfolios delete" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a portfolio
#
# GET /portfolios/{portfolio_gid}
# operationId: getPortfolio
export def "portfolios get" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a portfolio
#
# PUT /portfolios/{portfolio_gid}
# operationId: updatePortfolio
export def "portfolios updatePortfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a custom field to a portfolio
#
# POST /portfolios/{portfolio_gid}/addCustomFieldSetting
# operationId: addCustomFieldSettingForPortfolio
# --data shape: {custom_field: string, insert_after?: string, insert_before?: string, is_important?: bool}
export def "portfolios-add-custom-field-setting addCustomFieldSettingForPortfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {custom_field: string, insert_after?: string, insert_before?: string, is_important?: bool}
]: any -> record<data: record<custom_field: record, is_important: bool, parent: record, project: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/addCustomFieldSetting" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a portfolio item
#
# POST /portfolios/{portfolio_gid}/addItem
# operationId: addItemForPortfolio
# --data shape: {insert_after?: string, insert_before?: string, item: string}
export def "portfolios-add-item addItemForPortfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, item: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/addItem" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add users to a portfolio
#
# POST /portfolios/{portfolio_gid}/addMembers
# operationId: addMembersForPortfolio
# --data shape: {members: string}
export def "portfolios-add-members addMembersForPortfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {members: string}
]: any -> record<data: record<created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/addMembers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a portfolio's custom fields
#
# GET /portfolios/{portfolio_gid}/custom_field_settings
# operationId: getCustomFieldSettingsForPortfolio
export def "portfolios-custom-field-settings get" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<custom_field: record, is_important: bool, parent: record, project: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/custom_field_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get portfolio items
#
# GET /portfolios/{portfolio_gid}/items
# operationId: getItemsForPortfolio
export def "portfolios-items get" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get memberships from a portfolio
#
# GET /portfolios/{portfolio_gid}/portfolio_memberships
# operationId: getPortfolioMembershipsForPortfolio
export def "portfolios-portfolio-memberships get" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, portfolio: record, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/portfolio_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a custom field from a portfolio
#
# POST /portfolios/{portfolio_gid}/removeCustomFieldSetting
# operationId: removeCustomFieldSettingForPortfolio
# --data shape: {custom_field: string}
export def "portfolios-remove-custom-field-setting removeCustomFieldSettingForPortfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {custom_field: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/removeCustomFieldSetting" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a portfolio item
#
# POST /portfolios/{portfolio_gid}/removeItem
# operationId: removeItemForPortfolio
# --data shape: {item: string}
export def "portfolios-remove-item removeItemForPortfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {item: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/removeItem" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove users from a portfolio
#
# POST /portfolios/{portfolio_gid}/removeMembers
# operationId: removeMembersForPortfolio
# --data shape: {members: string}
export def "portfolios-remove-members removeMembersForPortfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {members: string}
]: any -> record<data: record<created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/removeMembers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a project brief
#
# DELETE /project_briefs/{project_brief_gid}
# operationId: deleteProjectBrief
export def "project-briefs delete" [
  project_brief_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_briefs/($project_brief_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project brief
#
# GET /project_briefs/{project_brief_gid}
# operationId: getProjectBrief
export def "project-briefs get" [
  project_brief_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<permalink_url: string, project: record, text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_briefs/($project_brief_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a project brief
#
# PUT /project_briefs/{project_brief_gid}
# operationId: updateProjectBrief
export def "project-briefs updateProjectBrief" [
  project_brief_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<permalink_url: string, project: record, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_briefs/($project_brief_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a project membership
#
# GET /project_memberships/{project_membership_gid}
# operationId: getProjectMembership
export def "project-memberships get" [
  project_membership_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<project: record<gid: string, resource_type: string, name: string>, write_access: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_memberships/($project_membership_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a project status
#
# DELETE /project_statuses/{project_status_gid}
# operationId: deleteProjectStatus
export def "project-statuses delete" [
  project_status_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_statuses/($project_status_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project status
#
# GET /project_statuses/{project_status_gid}
# operationId: getProjectStatus
export def "project-statuses get" [
  project_status_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, modified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_statuses/($project_status_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple project templates
#
# GET /project_templates
# operationId: getProjectTemplates
export def "project-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: string # The workspace to filter results on. (e.g. 12345)
  --team: string # The team to filter projects on. (e.g. 14916)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspace" $workspace "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/project_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project template
#
# GET /project_templates/{project_template_gid}
# operationId: getProjectTemplate
export def "project-templates get" [
  project_template_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_templates/($project_template_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Instantiate a project from a project template
#
# POST /project_templates/{project_template_gid}/instantiateProject
# operationId: instantiateProject
# --data shape: {is_strict?: bool, name: string, public: bool, requested_dates?: list, team?: string, workspace?: string}
export def "project-templates-instantiate-project instantiateProject" [
  project_template_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {is_strict?: bool, name: string, public: bool, requested_dates?: list, team?: string, workspace?: string}
]: any -> record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_templates/($project_template_gid)/instantiateProject" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get multiple projects
#
# GET /projects
# operationId: getProjects
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace or organization to filter projects on. (e.g. 1331)
  --team: string # The team to filter projects on. (e.g. 14916)
  --archived: oneof<nothing, bool> # Only return projects whose `archived` field takes on the value of this parameter. (e.g. false)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a project
#
# POST /projects
# operationId: createProject
export def "projects createProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record, custom_fields: list<record>, followers: list<record>, icon: string, owner: record, permalink_url: string, project_brief: record, team: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a project
#
# DELETE /projects/{project_gid}
# operationId: deleteProject
export def "projects delete" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project
#
# GET /projects/{project_gid}
# operationId: getProject
export def "projects get" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record, custom_fields: list<record>, followers: list<record>, icon: string, owner: record, permalink_url: string, project_brief: record, team: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a project
#
# PUT /projects/{project_gid}
# operationId: updateProject
export def "projects updateProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record, custom_fields: list<record>, followers: list<record>, icon: string, owner: record, permalink_url: string, project_brief: record, team: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a custom field to a project
#
# POST /projects/{project_gid}/addCustomFieldSetting
# operationId: addCustomFieldSettingForProject
# --data shape: {custom_field: string, insert_after?: string, insert_before?: string, is_important?: bool}
export def "projects-add-custom-field-setting addCustomFieldSettingForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {custom_field: string, insert_after?: string, insert_before?: string, is_important?: bool}
]: any -> record<data: record<custom_field: record, is_important: bool, parent: record, project: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/addCustomFieldSetting" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add followers to a project
#
# POST /projects/{project_gid}/addFollowers
# operationId: addFollowersForProject
# --data shape: {followers: string}
export def "projects-add-followers addFollowersForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: string}
]: any -> record<data: record<completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record, custom_fields: list<record>, followers: list<record>, icon: string, owner: record, permalink_url: string, project_brief: record, team: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/addFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add users to a project
#
# POST /projects/{project_gid}/addMembers
# operationId: addMembersForProject
# --data shape: {members: string}
export def "projects-add-members addMembersForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {members: string}
]: any -> record<data: record<completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record, custom_fields: list<record>, followers: list<record>, icon: string, owner: record, permalink_url: string, project_brief: record, team: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/addMembers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a project's custom fields
#
# GET /projects/{project_gid}/custom_field_settings
# operationId: getCustomFieldSettingsForProject
export def "projects-custom-field-settings get" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<custom_field: record, is_important: bool, parent: record, project: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/custom_field_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Duplicate a project
#
# POST /projects/{project_gid}/duplicate
# operationId: duplicateProject
# --data shape: {include?: "members"|"notes"|"forms"|"task_notes"|"task_assignee"|"task_subtasks"|"task_attachments"|"task_dates"|"task_dependencies"|"task_followers"|"task_tags"|"task_projects", name: string, schedule_dates?: record, team?: string}
export def "projects-duplicate duplicateProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {include?: "members"|"notes"|"forms"|"task_notes"|"task_assignee"|"task_subtasks"|"task_attachments"|"task_dates"|"task_dependencies"|"task_followers"|"task_tags"|"task_projects", name: string, schedule_dates?: record, team?: string}
]: any -> record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/duplicate" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a project brief
#
# POST /projects/{project_gid}/project_briefs
# operationId: createProjectBrief
export def "projects-project-briefs createProjectBrief" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<permalink_url: string, project: record, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/project_briefs" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get memberships from a project
#
# GET /projects/{project_gid}/project_memberships
# operationId: getProjectMembershipsForProject
export def "projects-project-memberships get" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/project_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get statuses from a project
#
# GET /projects/{project_gid}/project_statuses
# operationId: getProjectStatusesForProject
export def "projects-project-statuses get" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/project_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a project status
#
# POST /projects/{project_gid}/project_statuses
# operationId: createProjectStatusForProject
export def "projects-project-statuses createProjectStatusForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, modified_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/project_statuses" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a custom field from a project
#
# POST /projects/{project_gid}/removeCustomFieldSetting
# operationId: removeCustomFieldSettingForProject
# --data shape: {custom_field: string}
export def "projects-remove-custom-field-setting removeCustomFieldSettingForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {custom_field: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/removeCustomFieldSetting" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove followers from a project
#
# POST /projects/{project_gid}/removeFollowers
# operationId: removeFollowersForProject
# --data shape: {followers: string}
export def "projects-remove-followers removeFollowersForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: string}
]: any -> record<data: record<completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record, custom_fields: list<record>, followers: list<record>, icon: string, owner: record, permalink_url: string, project_brief: record, team: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/removeFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove users from a project
#
# POST /projects/{project_gid}/removeMembers
# operationId: removeMembersForProject
# --data shape: {members: string}
export def "projects-remove-members removeMembersForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {members: string}
]: any -> record<data: record<completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record, custom_fields: list<record>, followers: list<record>, icon: string, owner: record, permalink_url: string, project_brief: record, team: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/removeMembers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a project template from a project
#
# POST /projects/{project_gid}/saveAsTemplate
# operationId: projectSaveAsTemplate
# --data shape: {name: string, public: bool, team?: string, workspace?: string}
export def "projects-save-as-template projectSaveAsTemplate" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {name: string, public: bool, team?: string, workspace?: string}
]: any -> record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/saveAsTemplate" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get sections in a project
#
# GET /projects/{project_gid}/sections
# operationId: getSectionsForProject
export def "projects-sections get" [
  project_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/sections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a section in a project
#
# POST /projects/{project_gid}/sections
# operationId: createSectionForProject
# --data shape: {insert_after?: string, insert_before?: string, name: string}
export def "projects-sections createSectionForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, name: string}
]: any -> record<data: record<created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/sections" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Move or Insert sections
#
# POST /projects/{project_gid}/sections/insert
# operationId: insertSectionForProject
# --data shape: {after_section?: string, before_section?: string, project: string, section: string}
export def "projects-sections-insert insertSectionForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {after_section?: string, before_section?: string, project: string, section: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/sections/insert" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get task count of a project
#
# GET /projects/{project_gid}/task_counts
# operationId: getTaskCountsForProject
export def "projects-task-counts get" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: record<num_completed_milestones: int, num_completed_tasks: int, num_incomplete_milestones: int, num_incomplete_tasks: int, num_milestones: int, num_tasks: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/task_counts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tasks from a project
#
# GET /projects/{project_gid}/tasks
# operationId: getTasksForProject
export def "projects-tasks get" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --completed-since: string # Only return tasks that are either incomplete or that have been completed since this time. Accepts a date-time string or the keyword *now*.  (e.g. 2012-02-22T02:06:58.158Z)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "completed_since" $completed_since "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a section
#
# DELETE /sections/{section_gid}
# operationId: deleteSection
export def "sections delete" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/sections/($section_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a section
#
# GET /sections/{section_gid}
# operationId: getSection
export def "sections get" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/sections/($section_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a section
#
# PUT /sections/{section_gid}
# operationId: updateSection
# --data shape: {insert_after?: string, insert_before?: string, name: string}
export def "sections updateSection" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, name: string}
]: any -> record<data: record<created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/sections/($section_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add task to section
#
# POST /sections/{section_gid}/addTask
# operationId: addTaskForSection
# --data shape: {insert_after?: string, insert_before?: string, task: string}
export def "sections-add-task addTaskForSection" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, task: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/sections/($section_gid)/addTask" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tasks from a section
#
# GET /sections/{section_gid}/tasks
# operationId: getTasksForSection
export def "sections-tasks get" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sections/($section_gid)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get status updates from an object
#
# GET /status_updates
# operationId: getStatusesForObject
export def "status-updates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --parent: string # Globally unique identifier for object to fetch statuses from. Must be a GID for a project, portfolio, or goal. (e.g. 159874)
  --created-since: string # Only return statuses that have been created since the given time. (format: date-time, e.g. 2012-02-22T02:06:58.158Z)
]: nothing -> record<data: table<gid: string, resource_type: string, resource_subtype: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "created_since" $created_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/status_updates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a status update
#
# POST /status_updates
# operationId: createStatusForObject
export def "status-updates createStatusForObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: any
]: any -> record<data: record<author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, liked: bool, likes: list<record>, modified_at: string, num_hearts: int, num_likes: int, parent: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/status_updates" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a status update
#
# DELETE /status_updates/{status_gid}
# operationId: deleteStatus
export def "status-updates delete" [
  status_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_updates/($status_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a status update
#
# GET /status_updates/{status_gid}
# operationId: getStatus
export def "status-updates get" [
  status_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, liked: bool, likes: list<record>, modified_at: string, num_hearts: int, num_likes: int, parent: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_updates/($status_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a story
#
# DELETE /stories/{story_gid}
# operationId: deleteStory
export def "stories delete" [
  story_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/stories/($story_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a story
#
# GET /stories/{story_gid}
# operationId: getStory
export def "stories get" [
  story_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: record<assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string>, follower: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, is_editable: bool, is_edited: bool, liked: bool, likes: list<record>, new_approval_status: string, new_date_value: record<due_at: string, due_on: string, start_on: string>, new_dates: record<due_at: string, due_on: string, start_on: string>, new_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, new_multi_enum_values: list<record>, new_name: string, new_number_value: int, new_people_value: list<record>, new_resource_subtype: string, new_section: record<gid: string, resource_type: string, name: string>, new_text_value: string, num_hearts: int, num_likes: int, old_approval_status: string, old_date_value: record<due_at: string, due_on: string, start_on: string>, old_dates: record<due_at: string, due_on: string, start_on: string>, old_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, old_multi_enum_values: list<record>, old_name: string, old_number_value: int, old_people_value: list<record>, old_resource_subtype: string, old_section: record<gid: string, resource_type: string, name: string>, old_text_value: string, previews: list<record>, project: record<gid: string, resource_type: string, name: string>, source: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, tag: record<gid: string, resource_type: string, name: string>, target: record, task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stories/($story_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a story
#
# PUT /stories/{story_gid}
# operationId: updateStory
export def "stories updateStory" [
  story_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string>, follower: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, is_editable: bool, is_edited: bool, liked: bool, likes: list<record>, new_approval_status: string, new_date_value: record<due_at: string, due_on: string, start_on: string>, new_dates: record<due_at: string, due_on: string, start_on: string>, new_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, new_multi_enum_values: list<record>, new_name: string, new_number_value: int, new_people_value: list<record>, new_resource_subtype: string, new_section: record<gid: string, resource_type: string, name: string>, new_text_value: string, num_hearts: int, num_likes: int, old_approval_status: string, old_date_value: record<due_at: string, due_on: string, start_on: string>, old_dates: record<due_at: string, due_on: string, start_on: string>, old_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, old_multi_enum_values: list<record>, old_name: string, old_number_value: int, old_people_value: list<record>, old_resource_subtype: string, old_section: record<gid: string, resource_type: string, name: string>, old_text_value: string, previews: list<record>, project: record<gid: string, resource_type: string, name: string>, source: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, tag: record<gid: string, resource_type: string, name: string>, target: record, task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/stories/($story_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get multiple tags
#
# GET /tags
# operationId: getTags
export def "tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace to filter tags on. (e.g. 1331)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "workspace" $workspace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a tag
#
# POST /tags
# operationId: createTag
export def "tags createTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a tag
#
# DELETE /tags/{tag_gid}
# operationId: deleteTag
export def "tags delete" [
  tag_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tag_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a tag
#
# GET /tags/{tag_gid}
# operationId: getTag
export def "tags get" [
  tag_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: record<created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tag_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a tag
#
# PUT /tags/{tag_gid}
# operationId: updateTag
export def "tags updateTag" [
  tag_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: record<created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tag_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tasks from a tag
#
# GET /tags/{tag_gid}/tasks
# operationId: getTasksForTag
export def "tags-tasks get" [
  tag_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tag_gid)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple tasks
#
# GET /tasks
# operationId: getTasks
export def "tasks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --assignee: string # The assignee to filter tasks on. If searching for unassigned tasks, assignee.any = null can be specified. *Note: If you specify `assignee`, you must also specify the `workspace` to filter on.* (e.g. 14641)
  --project: string # The project to filter tasks on. (e.g. 321654)
  --section: string # The section to filter tasks on. *Note: Currently, this is only supported in board views.* (e.g. 321654)
  --workspace: string # The workspace to filter tasks on. *Note: If you specify `workspace`, you must also specify the `assignee` to filter on.* (e.g. 321654)
  --completed-since: string # Only return tasks that are either incomplete or that have been completed since this time. (format: date-time, e.g. 2012-02-22T02:06:58.158Z)
  --modified-since: string # Only return tasks that have been modified since the given time.  *Note: A task is considered “modified” if any of its properties change, or associations between it and other objects are modified (e.g.  a task being added to a project). A task is not considered modified just because another object it is associated with (e.g. a subtask) is modified. Actions that count as modifying the task include assigning, renaming, completing, and adding stories.* (format: date-time, e.g. 2012-02-22T02:06:58.158Z)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "assignee" $assignee "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "section" $section "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "completed_since" $completed_since "scalar") (serialize-qp "modified_since" $modified_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a task
#
# POST /tasks
# operationId: createTask
export def "tasks createTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<assignee: record, assignee_section: record, custom_fields: list<record>, followers: list<record>, parent: record, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a task
#
# DELETE /tasks/{task_gid}
# operationId: deleteTask
export def "tasks delete" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a task
#
# GET /tasks/{task_gid}
# operationId: getTask
export def "tasks get" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<assignee: record, assignee_section: record, custom_fields: list<record>, followers: list<record>, parent: record, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a task
#
# PUT /tasks/{task_gid}
# operationId: updateTask
export def "tasks updateTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<assignee: record, assignee_section: record, custom_fields: list<record>, followers: list<record>, parent: record, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set dependencies for a task
#
# POST /tasks/{task_gid}/addDependencies
# operationId: addDependenciesForTask
# --data shape: {dependencies?: list}
export def "tasks-add-dependencies addDependenciesForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # e.g. {dependencies: [133713, 184253]} — shape: {dependencies?: list}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/addDependencies" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set dependents for a task
#
# POST /tasks/{task_gid}/addDependents
# operationId: addDependentsForTask
# --data shape: {dependents?: list}
export def "tasks-add-dependents addDependentsForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A set of dependent tasks. (e.g. {dependents: [133713, 184253]}) — shape: {dependents?: list}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/addDependents" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add followers to a task
#
# POST /tasks/{task_gid}/addFollowers
# operationId: addFollowersForTask
# --data shape: {followers: list}
export def "tasks-add-followers addFollowersForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: list}
]: any -> record<data: record<assignee: record, assignee_section: record, custom_fields: list<record>, followers: list<record>, parent: record, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/addFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a project to a task
#
# POST /tasks/{task_gid}/addProject
# operationId: addProjectForTask
# --data shape: {insert_after?: string, insert_before?: string, project: string, section?: string}
export def "tasks-add-project addProjectForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, project: string, section?: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/addProject" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a tag to a task
#
# POST /tasks/{task_gid}/addTag
# operationId: addTagForTask
# --data shape: {tag: string}
export def "tasks-add-tag addTagForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {tag: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/addTag" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get dependencies from a task
#
# GET /tasks/{task_gid}/dependencies
# operationId: getDependenciesForTask
export def "tasks-dependencies get" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/dependencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get dependents from a task
#
# GET /tasks/{task_gid}/dependents
# operationId: getDependentsForTask
export def "tasks-dependents get" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/dependents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Duplicate a task
#
# POST /tasks/{task_gid}/duplicate
# operationId: duplicateTask
# --data shape: {include?: "notes"|"assignee"|"subtasks"|"attachments"|"tags"|"followers"|"projects"|"dates"|"dependencies"|"parent", name?: string}
export def "tasks-duplicate duplicateTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {include?: "notes"|"assignee"|"subtasks"|"attachments"|"tags"|"followers"|"projects"|"dates"|"dependencies"|"parent", name?: string}
]: any -> record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/duplicate" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get projects a task is in
#
# GET /tasks/{task_gid}/projects
# operationId: getProjectsForTask
export def "tasks-projects get" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unlink dependencies from a task
#
# POST /tasks/{task_gid}/removeDependencies
# operationId: removeDependenciesForTask
# --data shape: {dependencies?: list}
export def "tasks-remove-dependencies removeDependenciesForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # e.g. {dependencies: [133713, 184253]} — shape: {dependencies?: list}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/removeDependencies" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unlink dependents from a task
#
# POST /tasks/{task_gid}/removeDependents
# operationId: removeDependentsForTask
# --data shape: {dependents?: list}
export def "tasks-remove-dependents removeDependentsForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A set of dependent tasks. (e.g. {dependents: [133713, 184253]}) — shape: {dependents?: list}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/removeDependents" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove followers from a task
#
# POST /tasks/{task_gid}/removeFollowers
# operationId: removeFollowerForTask
# --data shape: {followers: list}
export def "tasks-remove-followers removeFollowerForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: list}
]: any -> record<data: record<assignee: record, assignee_section: record, custom_fields: list<record>, followers: list<record>, parent: record, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/removeFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a project from a task
#
# POST /tasks/{task_gid}/removeProject
# operationId: removeProjectForTask
# --data shape: {project: string}
export def "tasks-remove-project removeProjectForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {project: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/removeProject" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a tag from a task
#
# POST /tasks/{task_gid}/removeTag
# operationId: removeTagForTask
# --data shape: {tag: string}
export def "tasks-remove-tag removeTagForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {tag: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/removeTag" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set the parent of a task
#
# POST /tasks/{task_gid}/setParent
# operationId: setParentForTask
# --data shape: {insert_after?: string, insert_before?: string, parent: string}
export def "tasks-set-parent setParentForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, parent: string}
]: any -> record<data: record<assignee: record, assignee_section: record, custom_fields: list<record>, followers: list<record>, parent: record, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/setParent" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get stories from a task
#
# GET /tasks/{task_gid}/stories
# operationId: getStoriesForTask
export def "tasks-stories get" [
  task_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: list<record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/stories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a story on a task
#
# POST /tasks/{task_gid}/stories
# operationId: createStoryForTask
export def "tasks-stories createStoryForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string>, follower: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, is_editable: bool, is_edited: bool, liked: bool, likes: list<record>, new_approval_status: string, new_date_value: record<due_at: string, due_on: string, start_on: string>, new_dates: record<due_at: string, due_on: string, start_on: string>, new_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, new_multi_enum_values: list<record>, new_name: string, new_number_value: int, new_people_value: list<record>, new_resource_subtype: string, new_section: record<gid: string, resource_type: string, name: string>, new_text_value: string, num_hearts: int, num_likes: int, old_approval_status: string, old_date_value: record<due_at: string, due_on: string, start_on: string>, old_dates: record<due_at: string, due_on: string, start_on: string>, old_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, old_multi_enum_values: list<record>, old_name: string, old_number_value: int, old_people_value: list<record>, old_resource_subtype: string, old_section: record<gid: string, resource_type: string, name: string>, old_text_value: string, previews: list<record>, project: record<gid: string, resource_type: string, name: string>, source: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, tag: record<gid: string, resource_type: string, name: string>, target: record, task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/stories" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get subtasks from a task
#
# GET /tasks/{task_gid}/subtasks
# operationId: getSubtasksForTask
export def "tasks-subtasks get" [
  task_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/subtasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a subtask
#
# POST /tasks/{task_gid}/subtasks
# operationId: createSubtaskForTask
export def "tasks-subtasks createSubtaskForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<assignee: record, assignee_section: record, custom_fields: list<record>, followers: list<record>, parent: record, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/subtasks" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a task's tags
#
# GET /tasks/{task_gid}/tags
# operationId: getTagsForTask
export def "tasks-tags get" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get team memberships
#
# GET /team_memberships
# operationId: getTeamMemberships
export def "team-memberships list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --team: string # Globally unique identifier for the team. (e.g. 159874)
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. This parameter must be used with the workspace parameter. (e.g. 512241)
  --workspace: string # Globally unique identifier for the workspace. This parameter must be used with the user parameter. (e.g. 31326)
]: nothing -> record<data: table<gid: string, resource_type: string, is_guest: bool, team: record, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "workspace" $workspace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a team membership
#
# GET /team_memberships/{team_membership_gid}
# operationId: getTeamMembership
export def "team-memberships get" [
  team_membership_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<gid: string, resource_type: string, is_guest: bool, team: record<gid: string, resource_type: string, name: string>, user: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/team_memberships/($team_membership_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a team
#
# POST /teams
# operationId: createTeam
export def "teams createTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: any
]: any -> record<data: record<description: string, html_description: string, organization: record, permalink_url: string, visibility: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a team
#
# PUT /teams
# operationId: updateTeam
export def "teams updateTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: any
]: any -> record<data: record<description: string, html_description: string, organization: record, permalink_url: string, visibility: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a team
#
# GET /teams/{team_gid}
# operationId: getTeam
export def "teams get" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: record<description: string, html_description: string, organization: record, permalink_url: string, visibility: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a user to a team
#
# POST /teams/{team_gid}/addUser
# operationId: addUserForTeam
# --data shape: {user?: string}
export def "teams-add-user addUserForTeam" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> record<data: record<gid: string, resource_type: string, is_guest: bool, team: record<gid: string, resource_type: string, name: string>, user: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/addUser" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a team's project templates
#
# GET /teams/{team_gid}/project_templates
# operationId: getProjectTemplatesForTeam
export def "teams-project-templates get" [
  team_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/project_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a team's projects
#
# GET /teams/{team_gid}/projects
# operationId: getProjectsForTeam
export def "teams-projects get" [
  team_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --archived: oneof<nothing, bool> # Only return projects whose `archived` field takes on the value of this parameter. (e.g. false)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a project in a team
#
# POST /teams/{team_gid}/projects
# operationId: createProjectForTeam
export def "teams-projects createProjectForTeam" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record, custom_fields: list<record>, followers: list<record>, icon: string, owner: record, permalink_url: string, project_brief: record, team: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/projects" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a user from a team
#
# POST /teams/{team_gid}/removeUser
# operationId: removeUserForTeam
# --data shape: {user?: string}
export def "teams-remove-user removeUserForTeam" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/removeUser" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get memberships from a team
#
# GET /teams/{team_gid}/team_memberships
# operationId: getTeamMembershipsForTeam
export def "teams-team-memberships get" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, is_guest: bool, team: record, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/team_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users in a team
#
# GET /teams/{team_gid}/users
# operationId: getUsersForTeam
export def "teams-users get" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get time periods
#
# GET /time_periods
# operationId: getTimePeriods
export def "time-periods list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --start-on: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --end-on: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --workspace: string # Globally unique identifier for the workspace. (e.g. 31326)
]: nothing -> record<data: table<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "start_on" $start_on "scalar") (serialize-qp "end_on" $end_on "scalar") (serialize-qp "workspace" $workspace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/time_periods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a time period
#
# GET /time_periods/{time_period_gid}
# operationId: getTimePeriod
export def "time-periods get" [
  time_period_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/time_periods/($time_period_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user task list
#
# GET /user_task_lists/{user_task_list_gid}
# operationId: getUserTaskList
export def "user-task-lists get" [
  user_task_list_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<gid: string, resource_type: string, name: string, owner: record, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_task_lists/($user_task_list_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tasks from a user task list
#
# GET /user_task_lists/{user_task_list_gid}/tasks
# operationId: getTasksForUserTaskList
export def "user-task-lists-tasks get" [
  user_task_list_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --completed-since: string # Only return tasks that are either incomplete or that have been completed since this time. Accepts a date-time string or the keyword *now*.  (e.g. 2012-02-22T02:06:58.158Z)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "completed_since" $completed_since "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_task_lists/($user_task_list_gid)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple users
#
# GET /users
# operationId: getUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: string # The workspace or organization ID to filter users on. (e.g. 1331)
  --team: string # The team ID to filter users on. (e.g. 15627)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspace" $workspace "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /users/{user_gid}
# operationId: getUser
export def "users get" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<workspaces: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user's favorites
#
# GET /users/{user_gid}/favorites
# operationId: getFavoritesForUser
export def "users-favorites get" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --resource-type: string@resource-type-completer # The resource type of favorites to be returned. (default: project)
  --workspace: string # The workspace in which to get favorites. (e.g. 1234)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "resource_type" $resource_type "scalar") (serialize-qp "workspace" $workspace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)/favorites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get memberships from a user
#
# GET /users/{user_gid}/team_memberships
# operationId: getTeamMembershipsForUser
export def "users-team-memberships get" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # Globally unique identifier for the workspace. (e.g. 31326)
]: nothing -> record<data: table<gid: string, resource_type: string, is_guest: bool, team: record, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "workspace" $workspace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)/team_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get teams for a user
#
# GET /users/{user_gid}/teams
# operationId: getTeamsForUser
export def "users-teams get" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --organization: string # The workspace or organization to filter teams on. (e.g. 1331)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "organization" $organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user's task list
#
# GET /users/{user_gid}/user_task_list
# operationId: getUserTaskListForUser
export def "users-user-task-list get" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --workspace: string # The workspace in which to get the user task list. (e.g. 1234)
]: nothing -> record<data: record<gid: string, resource_type: string, name: string, owner: record, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "workspace" $workspace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)/user_task_list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get workspace memberships for a user
#
# GET /users/{user_gid}/workspace_memberships
# operationId: getWorkspaceMembershipsForUser
export def "users-workspace-memberships get" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, user: record, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)/workspace_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple webhooks
#
# GET /webhooks
# operationId: getWebhooks
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace to query for webhooks in. (e.g. 1331)
  --resource: string # Only return webhooks for the given resource. (e.g. 51648)
]: nothing -> record<data: table<created_at: string, filters: list, last_failure_at: string, last_failure_content: string, last_success_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "resource" $resource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Establish a webhook
#
# POST /webhooks
# operationId: createWebhook
# --data shape: {filters?: list, resource: string, target: string}
export def "webhooks createWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {filters?: list, resource: string, target: string}
]: any -> record<data: record<created_at: string, filters: list<record>, last_failure_at: string, last_failure_content: string, last_success_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /webhooks/{webhook_gid}
# operationId: deleteWebhook
export def "webhooks delete" [
  webhook_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a webhook
#
# GET /webhooks/{webhook_gid}
# operationId: getWebhook
export def "webhooks get" [
  webhook_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<created_at: string, filters: list<record>, last_failure_at: string, last_failure_content: string, last_success_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PUT /webhooks/{webhook_gid}
# operationId: updateWebhook
# --data shape: {filters?: list}
export def "webhooks updateWebhook" [
  webhook_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {filters?: list}
]: any -> record<data: record<created_at: string, filters: list<record>, last_failure_at: string, last_failure_content: string, last_success_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a workspace membership
#
# GET /workspace_memberships/{workspace_membership_gid}
# operationId: getWorkspaceMembership
export def "workspace-memberships get" [
  workspace_membership_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<is_active: bool, is_admin: bool, is_guest: bool, user_task_list: record<gid: string, resource_type: string, name: string, owner: record, workspace: record>, vacation_dates: record<end_on: string, start_on: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspace_memberships/($workspace_membership_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get multiple workspaces
#
# GET /workspaces
# operationId: getWorkspaces
export def "workspaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a workspace
#
# GET /workspaces/{workspace_gid}
# operationId: getWorkspace
export def "workspaces get" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: record<email_domains: list<string>, is_organization: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a workspace
#
# PUT /workspaces/{workspace_gid}
# operationId: updateWorkspace
export def "workspaces updateWorkspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<email_domains: list<string>, is_organization: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a user to a workspace or organization
#
# POST /workspaces/{workspace_gid}/addUser
# operationId: addUserForWorkspace
# --data shape: {user?: string}
export def "workspaces-add-user addUserForWorkspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> record<data: record<email: string, photo: record<image_1024x1024: string, image_128x128: string, image_21x21: string, image_27x27: string, image_36x36: string, image_60x60: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/addUser" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get audit log events
#
# GET /workspaces/{workspace_gid}/audit_log_events
# operationId: getAuditLogEvents
export def "workspaces-audit-log-events get" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Filter to events created after this time (inclusive). (format: date-time)
  --end-at: string # Filter to events created before this time (exclusive). (format: date-time)
  --event-type: string # Filter to events of this type. Refer to the [Supported AuditLogEvents](/docs/supported-auditlogevents) for a full list of values.
  --actor-type: string@actor-type-completer # Filter to events with an actor of this type. This only needs to be included if querying for actor types without an ID. If `actor_gid` is included, this should be excluded.
  --actor-gid: string # Filter to events triggered by the actor with this ID.
  --resource-gid: string # Filter to events with this resource ID.
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<actor: record, context: record, created_at: string, details: record, event_category: string, event_type: string, gid: string, resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "event_type" $event_type "scalar") (serialize-qp "actor_type" $actor_type "scalar") (serialize-qp "actor_gid" $actor_gid "scalar") (serialize-qp "resource_gid" $resource_gid "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/audit_log_events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a workspace's custom fields
#
# GET /workspaces/{workspace_gid}/custom_fields
# operationId: getCustomFieldsForWorkspace
export def "workspaces-custom-fields get" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<created_by: record, people_value: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/custom_fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all projects in a workspace
#
# GET /workspaces/{workspace_gid}/projects
# operationId: getProjectsForWorkspace
export def "workspaces-projects get" [
  workspace_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --archived: oneof<nothing, bool> # Only return projects whose `archived` field takes on the value of this parameter. (e.g. false)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a project in a workspace
#
# POST /workspaces/{workspace_gid}/projects
# operationId: createProjectForWorkspace
export def "workspaces-projects createProjectForWorkspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record, custom_fields: list<record>, followers: list<record>, icon: string, owner: record, permalink_url: string, project_brief: record, team: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/projects" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a user from a workspace or organization
#
# POST /workspaces/{workspace_gid}/removeUser
# operationId: removeUserForWorkspace
# --data shape: {user?: string}
export def "workspaces-remove-user removeUserForWorkspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/removeUser" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tags in a workspace
#
# GET /workspaces/{workspace_gid}/tags
# operationId: getTagsForWorkspace
export def "workspaces-tags get" [
  workspace_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a tag in a workspace
#
# POST /workspaces/{workspace_gid}/tags
# operationId: createTagForWorkspace
export def "workspaces-tags createTagForWorkspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: any
]: any -> record<data: record<created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/tags" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search tasks in a workspace
#
# GET /workspaces/{workspace_gid}/tasks/search
# operationId: searchTasksForWorkspace
export def "workspaces-tasks-search searchTasksForWorkspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --text: string # Performs full-text search on both task name and description (e.g. Bug)
  --resource-subtype: string@resource-subtype-completer-1 # Filters results by the task's resource_subtype (default: milestone)
  --assigneeany: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --assigneenot: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --portfoliosany: string # Comma-separated list of portfolio IDs (e.g. 12345,23456,34567)
  --projectsany: string # Comma-separated list of project IDs (e.g. 12345,23456,34567)
  --projectsnot: string # Comma-separated list of project IDs (e.g. 12345,23456,34567)
  --projectsall: string # Comma-separated list of project IDs (e.g. 12345,23456,34567)
  --sectionsany: string # Comma-separated list of section or column IDs (e.g. 12345,23456,34567)
  --sectionsnot: string # Comma-separated list of section or column IDs (e.g. 12345,23456,34567)
  --sectionsall: string # Comma-separated list of section or column IDs (e.g. 12345,23456,34567)
  --tagsany: string # Comma-separated list of tag IDs (e.g. 12345,23456,34567)
  --tagsnot: string # Comma-separated list of tag IDs (e.g. 12345,23456,34567)
  --tagsall: string # Comma-separated list of tag IDs (e.g. 12345,23456,34567)
  --teamsany: string # Comma-separated list of team IDs (e.g. 12345,23456,34567)
  --followersnot: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --created-byany: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --created-bynot: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --assigned-byany: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --assigned-bynot: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --liked-bynot: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --commented-on-bynot: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --due-onbefore: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --due-onafter: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --due-on: string # ISO 8601 date string or `null` (nullable, format: date, e.g. 2019-09-15)
  --due-atbefore: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --due-atafter: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --start-onbefore: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --start-onafter: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --start-on: string # ISO 8601 date string or `null` (nullable, format: date, e.g. 2019-09-15)
  --created-onbefore: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --created-onafter: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --created-on: string # ISO 8601 date string or `null` (nullable, format: date, e.g. 2019-09-15)
  --created-atbefore: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --created-atafter: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --completed-onbefore: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --completed-onafter: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --completed-on: string # ISO 8601 date string or `null` (nullable, format: date, e.g. 2019-09-15)
  --completed-atbefore: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --completed-atafter: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --modified-onbefore: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --modified-onafter: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --modified-on: string # ISO 8601 date string or `null` (nullable, format: date, e.g. 2019-09-15)
  --modified-atbefore: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --modified-atafter: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --is-blocking: oneof<nothing, bool> # Filter to incomplete tasks with dependents (e.g. false)
  --is-blocked: oneof<nothing, bool> # Filter to tasks with incomplete dependencies (e.g. false)
  --has-attachment: oneof<nothing, bool> # Filter to tasks with attachments (e.g. false)
  --completed: oneof<nothing, bool> # Filter to completed tasks (e.g. false)
  --is-subtask: oneof<nothing, bool> # Filter to subtasks (e.g. false)
  --sort-by: string@sort-by-completer # One of `due_date`, `created_at`, `completed_at`, `likes`, or `modified_at`, defaults to `modified_at` (default: modified_at, e.g. likes)
  --sort-ascending: oneof<nothing, bool> # Default `false` (default: false, e.g. true)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "text" $text "scalar") (serialize-qp "resource_subtype" $resource_subtype "scalar") (serialize-qp "assignee.any" $assigneeany "scalar") (serialize-qp "assignee.not" $assigneenot "scalar") (serialize-qp "portfolios.any" $portfoliosany "scalar") (serialize-qp "projects.any" $projectsany "scalar") (serialize-qp "projects.not" $projectsnot "scalar") (serialize-qp "projects.all" $projectsall "scalar") (serialize-qp "sections.any" $sectionsany "scalar") (serialize-qp "sections.not" $sectionsnot "scalar") (serialize-qp "sections.all" $sectionsall "scalar") (serialize-qp "tags.any" $tagsany "scalar") (serialize-qp "tags.not" $tagsnot "scalar") (serialize-qp "tags.all" $tagsall "scalar") (serialize-qp "teams.any" $teamsany "scalar") (serialize-qp "followers.not" $followersnot "scalar") (serialize-qp "created_by.any" $created_byany "scalar") (serialize-qp "created_by.not" $created_bynot "scalar") (serialize-qp "assigned_by.any" $assigned_byany "scalar") (serialize-qp "assigned_by.not" $assigned_bynot "scalar") (serialize-qp "liked_by.not" $liked_bynot "scalar") (serialize-qp "commented_on_by.not" $commented_on_bynot "scalar") (serialize-qp "due_on.before" $due_onbefore "scalar") (serialize-qp "due_on.after" $due_onafter "scalar") (serialize-qp "due_on" $due_on "scalar") (serialize-qp "due_at.before" $due_atbefore "scalar") (serialize-qp "due_at.after" $due_atafter "scalar") (serialize-qp "start_on.before" $start_onbefore "scalar") (serialize-qp "start_on.after" $start_onafter "scalar") (serialize-qp "start_on" $start_on "scalar") (serialize-qp "created_on.before" $created_onbefore "scalar") (serialize-qp "created_on.after" $created_onafter "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "completed_on.before" $completed_onbefore "scalar") (serialize-qp "completed_on.after" $completed_onafter "scalar") (serialize-qp "completed_on" $completed_on "scalar") (serialize-qp "completed_at.before" $completed_atbefore "scalar") (serialize-qp "completed_at.after" $completed_atafter "scalar") (serialize-qp "modified_on.before" $modified_onbefore "scalar") (serialize-qp "modified_on.after" $modified_onafter "scalar") (serialize-qp "modified_on" $modified_on "scalar") (serialize-qp "modified_at.before" $modified_atbefore "scalar") (serialize-qp "modified_at.after" $modified_atafter "scalar") (serialize-qp "is_blocking" $is_blocking "scalar") (serialize-qp "is_blocked" $is_blocked "scalar") (serialize-qp "has_attachment" $has_attachment "scalar") (serialize-qp "completed" $completed "scalar") (serialize-qp "is_subtask" $is_subtask "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_ascending" $sort_ascending "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/tasks/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get teams in a workspace
#
# GET /workspaces/{workspace_gid}/teams
# operationId: getTeamsForWorkspace
export def "workspaces-teams get" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get objects via typeahead
#
# GET /workspaces/{workspace_gid}/typeahead
# operationId: typeaheadForWorkspace
export def "workspaces-typeahead typeaheadForWorkspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string@resource-type-completer-1 # The type of values the typeahead should return. You can choose from one of the following: `custom_field`, `project`, `project_template`, `portfolio`, `tag`, `task`, and `user`. Note that unlike in the names of endpoints, the types listed here are in singular form (e.g. `task`). Using multiple types is not yet supported. (default: user)
  --type: string@type-completer # *Deprecated: new integrations should prefer the resource_type field.* (default: user)
  --query: string # The string that will be used to search for relevant objects. If an empty string is passed in, the API will return results. (e.g. Greg)
  --count: int # The number of results to return. The default is 20 if this parameter is omitted, with a minimum of 1 and a maximum of 100. If there are fewer results found than requested, all will be returned. (e.g. 20)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource_type" $resource_type "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/typeahead" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users in a workspace or organization
#
# GET /workspaces/{workspace_gid}/users
# operationId: getUsersForWorkspace
export def "workspaces-users get" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the workspace memberships for a workspace
#
# GET /workspaces/{workspace_gid}/workspace_memberships
# operationId: getWorkspaceMembershipsForWorkspace
export def "workspaces-workspace-memberships get" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, resource_type: string, user: record, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/workspace_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
