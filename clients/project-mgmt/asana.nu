# Auto-generated client for Asana v1.0
# Source: https://raw.githubusercontent.com/Asana/openapi/master/defs/asana_oas.yaml
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
def base-url-completer [] { ["https://app.asana.com/api/1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-subtype-completer [] { ["asana" "external"] }
def actor-type-completer [] { ["anonymous" "asana" "asana_support" "external_administrator" "user"] }
def resource-subtype-completer-1 [] { ["project_membership"] }
def sort-by-completer [] { ["completed_at" "created_at" "due_date" "modified_at" "relevance"] }
def resource-subtype-completer-2 [] { ["approval" "custom" "default_task" "milestone"] }
def sort-by-completer-1 [] { ["completed_at" "created_at" "due_date" "likes" "modified_at" "relevance"] }
def resource-type-completer [] { ["actor" "agent" "custom_field" "goal" "portfolio" "project" "project_template" "tag" "task" "team" "user"] }
def type-completer [] { ["custom_field" "portfolio" "project" "tag" "task" "user"] }
def resource-type-completer-1 [] { ["portfolio" "project" "project_template" "tag" "task" "user"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "access-requests get" } } | get name | first)
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

# Get access requests
#
# GET /access_requests
# operationId: getAccessRequests
export def "access-requests get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --target: string # Globally unique identifier for the target object. (e.g. 1331)
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [approval_status, message, requester, requester.name, target])
]: nothing -> record<data: table<gid: string, resource_type: string, message: string, approval_status: string, requester: record, target: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target" $target "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/access_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an access request
#
# POST /access_requests
# operationId: createAccessRequest
# --data shape: {target: string, message?: string}
export def "access-requests createAccessRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # A request to create shareable access for a user. — shape: {target: string, message?: string}
]: any -> record<data: record<gid: string, resource_type: string, message: string, approval_status: string, requester: record<gid: string, resource_type: string, name: string>, target: record<gid: string, resource_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/access_requests")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Approve an access request
#
# POST /access_requests/{access_request_gid}/approve
# operationId: approveAccessRequest
export def "access-requests-approve approveAccessRequest" [
  access_request_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access_requests/($access_request_gid)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reject an access request
#
# POST /access_requests/{access_request_gid}/reject
# operationId: rejectAccessRequest
export def "access-requests-reject rejectAccessRequest" [
  access_request_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access_requests/($access_request_gid)/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of agents in a workspace
#
# GET /workspaces/{workspace_gid}/agents
# operationId: getAgentsForWorkspace
export def "workspaces-agents get" [
  workspace_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [behavior_guidance, description, name, offset, path, photo, photo.image_1024x1024, photo.image_128x128, photo.image_21x21, photo.image_27x27, photo.image_36x36, photo.image_60x60, resource_subtype, uri, workspace])
]: nothing -> record<data: table<gid: string, resource_type: string, resource_subtype: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/agents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an agent
#
# GET /agents/{agent_gid}
# operationId: getAgent
export def "agents get" [
  agent_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [behavior_guidance, description, name, photo, photo.image_1024x1024, photo.image_128x128, photo.image_21x21, photo.image_27x27, photo.image_36x36, photo.image_60x60, resource_subtype, workspace])
]: nothing -> record<data: record<gid: string, resource_type: string, resource_subtype: string, name: string, description: string, behavior_guidance: string, workspace: record<gid: string, resource_type: string, name: string>, photo: record<image_21x21: string, image_27x27: string, image_36x36: string, image_60x60: string, image_128x128: string, image_1024x1024: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/agents/($agent_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an allocation
#
# GET /allocations/{allocation_gid}
# operationId: getAllocation
export def "allocations get" [
  allocation_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [assignee, assignee.name, created_by, created_by.name, effort, effort.type, effort.value, end_date, parent, parent.name, resource_subtype, start_date])
]: nothing -> record<data: record<gid: string, resource_type: string, start_date: string, end_date: string, effort: record<type: string, value: float>, assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, parent: record<gid: string, resource_type: string, name: string>, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/allocations/($allocation_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an allocation
#
# PUT /allocations/{allocation_gid}
# operationId: updateAllocation
export def "allocations updateAllocation" [
  allocation_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [assignee, assignee.name, created_by, created_by.name, effort, effort.type, effort.value, end_date, parent, parent.name, resource_subtype, start_date])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, start_date: string, end_date: string, effort: record<type: string, value: float>, assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, parent: record<gid: string, resource_type: string, name: string>, resource_subtype: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/allocations/($allocation_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an allocation
#
# DELETE /allocations/{allocation_gid}
# operationId: deleteAllocation
export def "allocations delete" [
  allocation_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/allocations/($allocation_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get multiple allocations
#
# GET /allocations
# operationId: getAllocations
export def "allocations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent: string # Globally unique identifier for the project to filter allocations by. (e.g. 77688)
  --assignee: string # Globally unique identifier for the user or placeholder the allocation is assigned to. (e.g. 12345)
  --workspace: string # Globally unique identifier for the workspace. (e.g. 98765)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [assignee, assignee.name, created_by, created_by.name, effort, effort.type, effort.value, end_date, offset, parent, parent.name, path, resource_subtype, start_date, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, start_date: string, end_date: string, effort: record, assignee: record, created_by: record, parent: record, resource_subtype: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar") (serialize-qp "assignee" $assignee "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/allocations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an allocation
#
# POST /allocations
# operationId: createAllocation
export def "allocations createAllocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [assignee, assignee.name, created_by, created_by.name, effort, effort.type, effort.value, end_date, parent, parent.name, resource_subtype, start_date])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, start_date: string, end_date: string, effort: record<type: string, value: float>, assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, parent: record<gid: string, resource_type: string, name: string>, resource_subtype: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/allocations" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [connected_to_app, created_at, download_url, host, name, parent, parent.created_by, parent.name, parent.resource_subtype, permanent_url, resource_subtype, size, view_url])
]: nothing -> record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_at: string, download_url: string, permanent_url: string, host: string, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, size: int, view_url: string, connected_to_app: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/attachments/($attachment_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/attachments/($attachment_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --parent: string # Globally unique identifier for object to fetch statuses from. Must be a GID for a `project`, `project_brief`, or `task`. (e.g. 159874)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [connected_to_app, created_at, download_url, host, name, offset, parent, parent.created_by, parent.name, parent.resource_subtype, path, permanent_url, resource_subtype, size, uri, view_url])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [connected_to_app, created_at, download_url, host, name, parent, parent.created_by, parent.name, parent.resource_subtype, permanent_url, resource_subtype, size, view_url])
  --resource-subtype: string@resource-subtype-completer # The type of the attachment. Must be one of the given values. If not specified, a file attachment of type `asana` will be assumed. Note that if the value of `resource_subtype` is `external`, a `parent`, `name`, and `url` must also be provided.  (e.g. external)
  --file: string # Required for `asana` attachments.  (format: binary)
  parent: string # Required identifier of the parent task, project, or project_brief, as a string.
  --body-url: string # The URL of the external resource being attached. Required for attachments of type `external`.
  --name: string # The name of the external resource being attached. Required for attachments of type `external`.
  --connect-to-app: string@bool-completer # *Optional*. Only relevant for external attachments with a parent task. A boolean indicating whether the current app should be connected with the attachment for the purposes of showing an app components widget. Requires the app to have been added to a project the parent task is in. This property can only be set if an OAuth token is used to authenticate the request.  Criteria for displaying app widget: 1. An OAuth token must be used to authenticate the request 2. The app needs to have its `widget_metadata_url` configured in the developer console 3. The task the attachment is being attached to must be in a project with the app installed
]: any -> record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_at: string, download_url: string, permanent_url: string, host: string, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, size: int, view_url: string, connected_to_app: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/attachments" $qp)
  let body = {resource_subtype: $resource_subtype, file: $file, parent: $parent, url: $body_url, name: $name, connect_to_app: $connect_to_app} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
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
  --start-at: string # Filter to events created after this time (inclusive). (format: date-time)
  --end-at: string # Filter to events created before this time (exclusive). (format: date-time)
  --event-type: string # Filter to events of this type. Refer to the [supported audit log events](/docs/audit-log-events#supported-audit-log-events) for a full list of values.
  --actor-type: string@actor-type-completer # Filter to events with an actor of this type. This only needs to be included if querying for actor types without an ID. If `actor_gid` is included, this should be excluded.
  --actor-gid: string # Filter to events triggered by the actor with this ID.
  --resource-gid: string # Filter to events with this resource ID.
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> record<data: table<gid: string, created_at: string, event_type: string, event_category: string, actor: record, resource: record, details: record, context: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "event_type" $event_type "scalar") (serialize-qp "actor_type" $actor_type "scalar") (serialize-qp "actor_gid" $actor_gid "scalar") (serialize-qp "resource_gid" $resource_gid "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/audit_log_events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [body, headers, status_code])
  --data: record # A request object for use in a batch request. — shape: {actions?: list}
]: any -> record<data: table<status_code: int, headers: record, body: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/batch" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all budgets
#
# GET /budgets
# operationId: getBudgets
export def "budgets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --parent: string # Globally unique identifier for the budget's parent object. This currently can only be a `project`. (e.g. 1331)
]: nothing -> record<data: table<gid: string, resource_type: string, budget_type: string, estimate: record, actual: record, total: record, parent: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/budgets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a budget
#
# POST /budgets
# operationId: createBudget
export def "budgets createBudget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, budget_type: string, estimate: record, actual: record, total: record, parent: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/budgets" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a budget
#
# GET /budgets/{budget_gid}
# operationId: getBudget
export def "budgets get" [
  budget_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual, actual.billable_status_filter, actual.units, actual.value, budget_type, estimate, estimate.billable_status_filter, estimate.enabled, estimate.source, estimate.units, estimate.value, parent, parent.name, total, total.enabled, total.units, total.value])
]: nothing -> record<data: record<gid: string, resource_type: string, budget_type: string, estimate: record, actual: record, total: record, parent: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/budgets/($budget_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a budget
#
# PUT /budgets/{budget_gid}
# operationId: updateBudget
export def "budgets updateBudget" [
  budget_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual, actual.billable_status_filter, actual.units, actual.value, budget_type, estimate, estimate.billable_status_filter, estimate.enabled, estimate.source, estimate.units, estimate.value, parent, parent.name, total, total.enabled, total.units, total.value])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, budget_type: string, estimate: record, actual: record, total: record, parent: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/budgets/($budget_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a budget
#
# DELETE /budgets/{budget_gid}
# operationId: deleteBudget
export def "budgets delete" [
  budget_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/budgets/($budget_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_field, custom_field.asana_created_field, custom_field.created_by, custom_field.created_by.name, custom_field.currency_code, custom_field.custom_label, custom_field.custom_label_position, custom_field.date_value, custom_field.date_value.date, custom_field.date_value.date_time, custom_field.default_access_level, custom_field.description, custom_field.display_value, custom_field.enabled, custom_field.enum_options, custom_field.enum_options.color, custom_field.enum_options.enabled, custom_field.enum_options.name, custom_field.enum_value, custom_field.enum_value.color, custom_field.enum_value.enabled, custom_field.enum_value.name, custom_field.format, custom_field.has_notifications_enabled, custom_field.html_text_value, custom_field.id_prefix, custom_field.input_restrictions, custom_field.is_formula_field, custom_field.is_global_to_workspace, custom_field.is_value_read_only, custom_field.multi_enum_values, custom_field.multi_enum_values.color, custom_field.multi_enum_values.enabled, custom_field.multi_enum_values.name, custom_field.name, custom_field.number_value, custom_field.people_value, custom_field.people_value.name, custom_field.precision, custom_field.privacy_setting, custom_field.reference_value, custom_field.reference_value.name, custom_field.representation_type, custom_field.resource_subtype, custom_field.text_value, custom_field.type, is_important, offset, parent, parent.name, path, project, project.name, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, project: record, is_important: bool, parent: record, custom_field: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/custom_field_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_field, custom_field.asana_created_field, custom_field.created_by, custom_field.created_by.name, custom_field.currency_code, custom_field.custom_label, custom_field.custom_label_position, custom_field.date_value, custom_field.date_value.date, custom_field.date_value.date_time, custom_field.default_access_level, custom_field.description, custom_field.display_value, custom_field.enabled, custom_field.enum_options, custom_field.enum_options.color, custom_field.enum_options.enabled, custom_field.enum_options.name, custom_field.enum_value, custom_field.enum_value.color, custom_field.enum_value.enabled, custom_field.enum_value.name, custom_field.format, custom_field.has_notifications_enabled, custom_field.html_text_value, custom_field.id_prefix, custom_field.input_restrictions, custom_field.is_formula_field, custom_field.is_global_to_workspace, custom_field.is_value_read_only, custom_field.multi_enum_values, custom_field.multi_enum_values.color, custom_field.multi_enum_values.enabled, custom_field.multi_enum_values.name, custom_field.name, custom_field.number_value, custom_field.people_value, custom_field.people_value.name, custom_field.precision, custom_field.privacy_setting, custom_field.reference_value, custom_field.reference_value.name, custom_field.representation_type, custom_field.resource_subtype, custom_field.text_value, custom_field.type, is_important, offset, parent, parent.name, path, project, project.name, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, project: record, is_important: bool, parent: record, custom_field: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/custom_field_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a goal's custom fields
#
# GET /goals/{goal_gid}/custom_field_settings
# operationId: getCustomFieldSettingsForGoal
export def "goals-custom-field-settings get" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_field, custom_field.asana_created_field, custom_field.created_by, custom_field.created_by.name, custom_field.currency_code, custom_field.custom_label, custom_field.custom_label_position, custom_field.date_value, custom_field.date_value.date, custom_field.date_value.date_time, custom_field.default_access_level, custom_field.description, custom_field.display_value, custom_field.enabled, custom_field.enum_options, custom_field.enum_options.color, custom_field.enum_options.enabled, custom_field.enum_options.name, custom_field.enum_value, custom_field.enum_value.color, custom_field.enum_value.enabled, custom_field.enum_value.name, custom_field.format, custom_field.has_notifications_enabled, custom_field.html_text_value, custom_field.id_prefix, custom_field.input_restrictions, custom_field.is_formula_field, custom_field.is_global_to_workspace, custom_field.is_value_read_only, custom_field.multi_enum_values, custom_field.multi_enum_values.color, custom_field.multi_enum_values.enabled, custom_field.multi_enum_values.name, custom_field.name, custom_field.number_value, custom_field.people_value, custom_field.people_value.name, custom_field.precision, custom_field.privacy_setting, custom_field.reference_value, custom_field.reference_value.name, custom_field.representation_type, custom_field.resource_subtype, custom_field.text_value, custom_field.type, is_important, offset, parent, parent.name, path, project, project.name, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, project: record, is_important: bool, parent: record, custom_field: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/custom_field_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a team's custom fields
#
# GET /teams/{team_gid}/custom_field_settings
# operationId: getCustomFieldSettingsForTeam
export def "teams-custom-field-settings get" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_field, custom_field.asana_created_field, custom_field.created_by, custom_field.created_by.name, custom_field.currency_code, custom_field.custom_label, custom_field.custom_label_position, custom_field.date_value, custom_field.date_value.date, custom_field.date_value.date_time, custom_field.default_access_level, custom_field.description, custom_field.display_value, custom_field.enabled, custom_field.enum_options, custom_field.enum_options.color, custom_field.enum_options.enabled, custom_field.enum_options.name, custom_field.enum_value, custom_field.enum_value.color, custom_field.enum_value.enabled, custom_field.enum_value.name, custom_field.format, custom_field.has_notifications_enabled, custom_field.html_text_value, custom_field.id_prefix, custom_field.input_restrictions, custom_field.is_formula_field, custom_field.is_global_to_workspace, custom_field.is_value_read_only, custom_field.multi_enum_values, custom_field.multi_enum_values.color, custom_field.multi_enum_values.enabled, custom_field.multi_enum_values.name, custom_field.name, custom_field.number_value, custom_field.people_value, custom_field.people_value.name, custom_field.precision, custom_field.privacy_setting, custom_field.reference_value, custom_field.reference_value.name, custom_field.representation_type, custom_field.resource_subtype, custom_field.text_value, custom_field.type, is_important, parent, parent.name, project, project.name])
]: nothing -> record<data: table<gid: string, resource_type: string, project: record, is_important: bool, parent: record, custom_field: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/custom_field_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [asana_created_field, created_by, created_by.name, currency_code, custom_label, custom_label_position, date_value, date_value.date, date_value.date_time, default_access_level, description, display_value, enabled, enum_options, enum_options.color, enum_options.enabled, enum_options.name, enum_value, enum_value.color, enum_value.enabled, enum_value.name, format, has_notifications_enabled, html_text_value, id_prefix, input_restrictions, is_formula_field, is_global_to_workspace, is_value_read_only, multi_enum_values, multi_enum_values.color, multi_enum_values.enabled, multi_enum_values.name, name, number_value, people_value, people_value.name, precision, privacy_setting, reference_value, reference_value.name, representation_type, resource_subtype, text_value, type])
  --data: any
]: any -> record<data: record<representation_type: string, id_prefix: string, input_restrictions: list<string>, is_formula_field: bool, is_value_read_only: bool, created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>, reference_value: list<record>, html_text_value: string, privacy_setting: string, default_access_level: string, resource_subtype: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_fields" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [asana_created_field, created_by, created_by.name, currency_code, custom_label, custom_label_position, date_value, date_value.date, date_value.date_time, default_access_level, description, display_value, enabled, enum_options, enum_options.color, enum_options.enabled, enum_options.name, enum_value, enum_value.color, enum_value.enabled, enum_value.name, format, has_notifications_enabled, html_text_value, id_prefix, input_restrictions, is_formula_field, is_global_to_workspace, is_value_read_only, multi_enum_values, multi_enum_values.color, multi_enum_values.enabled, multi_enum_values.name, name, number_value, people_value, people_value.name, precision, privacy_setting, reference_value, reference_value.name, representation_type, resource_subtype, text_value, type])
]: nothing -> record<data: record<representation_type: string, id_prefix: string, input_restrictions: list<string>, is_formula_field: bool, is_value_read_only: bool, created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>, reference_value: list<record>, html_text_value: string, privacy_setting: string, default_access_level: string, resource_subtype: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_fields/($custom_field_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [asana_created_field, created_by, created_by.name, currency_code, custom_label, custom_label_position, date_value, date_value.date, date_value.date_time, default_access_level, description, display_value, enabled, enum_options, enum_options.color, enum_options.enabled, enum_options.name, enum_value, enum_value.color, enum_value.enabled, enum_value.name, format, has_notifications_enabled, html_text_value, id_prefix, input_restrictions, is_formula_field, is_global_to_workspace, is_value_read_only, multi_enum_values, multi_enum_values.color, multi_enum_values.enabled, multi_enum_values.name, name, number_value, people_value, people_value.name, precision, privacy_setting, reference_value, reference_value.name, representation_type, resource_subtype, text_value, type])
  --data: any
]: any -> record<data: record<representation_type: string, id_prefix: string, input_restrictions: list<string>, is_formula_field: bool, is_value_read_only: bool, created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>, reference_value: list<record>, html_text_value: string, privacy_setting: string, default_access_level: string, resource_subtype: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_fields/($custom_field_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_fields/($custom_field_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [asana_created_field, created_by, created_by.name, currency_code, custom_label, custom_label_position, date_value, date_value.date, date_value.date_time, default_access_level, description, display_value, enabled, enum_options, enum_options.color, enum_options.enabled, enum_options.name, enum_value, enum_value.color, enum_value.enabled, enum_value.name, format, has_notifications_enabled, html_text_value, id_prefix, input_restrictions, is_formula_field, is_global_to_workspace, is_value_read_only, multi_enum_values, multi_enum_values.color, multi_enum_values.enabled, multi_enum_values.name, name, number_value, offset, path, people_value, people_value.name, precision, privacy_setting, reference_value, reference_value.name, representation_type, resource_subtype, text_value, type, uri])
]: nothing -> record<data: table<representation_type: string, id_prefix: string, input_restrictions: list, is_formula_field: bool, is_value_read_only: bool, created_by: record, people_value: list, reference_value: list, html_text_value: string, privacy_setting: string, default_access_level: string, resource_subtype: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/custom_fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, enabled, name])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, name: string, enabled: bool, color: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_fields/($custom_field_gid)/enum_options" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reorder a custom field's enum
#
# POST /custom_fields/{custom_field_gid}/enum_options/insert
# operationId: insertEnumOptionForCustomField
# --data shape: {enum_option: string, before_enum_option?: string, after_enum_option?: string}
export def "custom-fields-enum-options-insert insertEnumOptionForCustomField" [
  custom_field_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, enabled, name])
  --data: record # shape: {enum_option: string, before_enum_option?: string, after_enum_option?: string}
]: any -> record<data: record<gid: string, resource_type: string, name: string, enabled: bool, color: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_fields/($custom_field_gid)/enum_options/insert" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an enum option
#
# PUT /enum_options/{enum_option_gid}
# operationId: updateEnumOption
# --data shape: {name?: string, enabled?: bool, color?: string}
export def "enum-options updateEnumOption" [
  enum_option_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, enabled, name])
  --data: record # Enum options are the possible values which an enum custom field can adopt. An enum custom field must contain at least 1 enum option but no more than 500.  You can add enum options to a custom field by using the `POST /custom_fields/custom_field_gid/enum_options` endpoint.  **It is not possible to remove or delete an enum option**. Instead, enum options can be disabled by updating the `enabled` field to false with the `PUT /enum_options/enum_option_gid` endpoint. Other attributes can be updated similarly.  On creation of an enum option, `enabled` is always set to `true`, meaning the enum option is a selectable value for the custom field. Setting `enabled=false` is equivalent to “trashing” the enum option in the Asana web app within the “Edit Fields” dialog. The enum option will no longer be selectable but, if the enum option value was previously set within a task, the task will retain the value.  Enum options are an ordered list and by default new enum options are inserted at the end. Ordering in relation to existing enum options can be specified on creation by using `insert_before` or `insert_after` to reference an existing enum option. Only one of `insert_before` and `insert_after` can be provided when creating a new enum option.  An enum options list can be reordered with the `POST /custom_fields/custom_field_gid/enum_options/insert` endpoint. — shape: {name?: string, enabled?: bool, color?: string}
]: any -> record<data: record<gid: string, resource_type: string, name: string, enabled: bool, color: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/enum_options/($enum_option_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all custom types associated with an object
#
# GET /custom_types
# operationId: getCustomTypes
export def "custom-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: string # Globally unique identifier for the project, which is used as a filter when retrieving all custom types. (e.g. 1331)
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [name, offset, path, status_options, status_options.color, status_options.completion_state, status_options.enabled, status_options.name, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, status_options: list>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a custom type
#
# GET /custom_types/{custom_type_gid}
# operationId: getCustomType
export def "custom-types get" [
  custom_type_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [name, status_options, status_options.color, status_options.completion_state, status_options.enabled, status_options.name])
]: nothing -> record<data: record<gid: string, resource_type: string, name: string, status_options: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/custom_types/($custom_type_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --resource: string # A resource ID to subscribe to. The resource can be a task, project, or goal. (e.g. 12345)
  --sync: string # A sync token received from the last request, or none on first sync. Events will be returned from the point in time that the sync token was generated. *Note: On your first request, omit the sync token. The response will be the same as for an expired sync token, and will include a new valid sync token.If the sync token is too old (which may happen from time to time) the API will return a `412 Precondition Failed` error, and include a fresh sync token in the response.* (e.g. de4774f6915eae04714ca93bb2f5ee81)
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [action, change, change.action, change.added_value, change.field, change.new_value, change.removed_value, created_at, parent, parent.name, resource, resource.name, type, user, user.name])
]: nothing -> record<data: table<user: record, resource: record, type: string, action: string, parent: record, created_at: string, change: record>, sync: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "sync" $sync "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate a graph export
#
# POST /exports/graph
# operationId: createGraphExport
# --data shape: {parent?: string}
export def "exports-graph createGraphExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # A *graph_export* request starts a job to export data starting from a parent object. — shape: {parent?: string}
]: any -> record<data: record<gid: string, resource_type: string, resource_subtype: string, status: string, new_graph_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/exports/graph")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Initiate a resource export
#
# POST /exports/resource
# operationId: createResourceExport
# --data shape: {workspace?: string, export_request_parameters?: list}
export def "exports-resource createResourceExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # A *resource_export* request starts a job to bulk export objects for one or more resources. — shape: {workspace?: string, export_request_parameters?: list}
]: any -> record<data: record<gid: string, resource_type: string, resource_subtype: string, status: string, new_resource_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/exports/resource")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [contribution_weight, resource_subtype, supported_goal, supported_goal.name, supported_goal.owner, supported_goal.owner.name, supporting_resource, supporting_resource.name])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goal_relationships/($goal_relationship_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [contribution_weight, resource_subtype, supported_goal, supported_goal.name, supported_goal.owner, supported_goal.owner.name, supporting_resource, supporting_resource.name])
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
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --supported-goal: string # Globally unique identifier for the supported goal in the goal relationship. (e.g. 12345)
  --resource-subtype: string # If provided, filter to goal relationships with a given resource_subtype. (e.g. subgoal)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [contribution_weight, offset, path, resource_subtype, supported_goal, supported_goal.name, supported_goal.owner, supported_goal.owner.name, supporting_resource, supporting_resource.name, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, resource_subtype: string, supporting_resource: record, contribution_weight: float>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "supported_goal" $supported_goal "scalar") (serialize-qp "resource_subtype" $resource_subtype "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/goal_relationships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a supporting goal relationship
#
# POST /goals/{goal_gid}/addSupportingRelationship
# operationId: addSupportingRelationship
# --data shape: {supporting_resource: string, insert_before?: string, insert_after?: string, contribution_weight?: float}
export def "goals-add-supporting-relationship addSupportingRelationship" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [contribution_weight, resource_subtype, supported_goal, supported_goal.name, supported_goal.owner, supported_goal.owner.name, supporting_resource, supporting_resource.name])
  --data: record # shape: {supporting_resource: string, insert_before?: string, insert_after?: string, contribution_weight?: float}
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
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {supporting_resource: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/removeSupportingRelationship" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, followers, followers.name, html_notes, is_workspace_level, liked, likes, likes.user, likes.user.name, metric, metric.can_manage, metric.currency_code, metric.current_display_value, metric.current_number_value, metric.initial_number_value, metric.is_custom_weight, metric.precision, metric.progress_source, metric.resource_subtype, metric.target_number_value, metric.unit, name, notes, num_likes, owner, owner.name, privacy_setting, start_on, status, team, team.name, time_period, time_period.display_name, time_period.end_on, time_period.period, time_period.start_on, workspace, workspace.name])
]: nothing -> record<data: record<gid: string, resource_type: string, name: string, html_notes: string, notes: string, due_on: string, start_on: string, is_workspace_level: bool, liked: bool, likes: list<record>, num_likes: int, team: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, followers: list<record>, time_period: record<gid: string, resource_type: string, end_on: string, start_on: string, period: string, display_name: string>, metric: record<gid: string, resource_type: string, resource_subtype: string, precision: int, unit: string, currency_code: string, initial_number_value: float, target_number_value: float, current_number_value: float, current_display_value: string, progress_source: string, is_custom_weight: bool, can_manage: bool>, owner: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, status: string, privacy_setting: string, default_access_level: string, custom_fields: list<record>, custom_field_settings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, followers, followers.name, html_notes, is_workspace_level, liked, likes, likes.user, likes.user.name, metric, metric.can_manage, metric.currency_code, metric.current_display_value, metric.current_number_value, metric.initial_number_value, metric.is_custom_weight, metric.precision, metric.progress_source, metric.resource_subtype, metric.target_number_value, metric.unit, name, notes, num_likes, owner, owner.name, privacy_setting, start_on, status, team, team.name, time_period, time_period.display_name, time_period.end_on, time_period.period, time_period.start_on, workspace, workspace.name])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, name: string, html_notes: string, notes: string, due_on: string, start_on: string, is_workspace_level: bool, liked: bool, likes: list<record>, num_likes: int, team: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, followers: list<record>, time_period: record<gid: string, resource_type: string, end_on: string, start_on: string, period: string, display_name: string>, metric: record<gid: string, resource_type: string, resource_subtype: string, precision: int, unit: string, currency_code: string, initial_number_value: float, target_number_value: float, current_number_value: float, current_display_value: string, progress_source: string, is_custom_weight: bool, can_manage: bool>, owner: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, status: string, privacy_setting: string, default_access_level: string, custom_fields: list<record>, custom_field_settings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --portfolio: string # Globally unique identifier for supporting portfolio. (e.g. 159874)
  --project: string # Globally unique identifier for supporting project. (e.g. 512241)
  --task: string # Globally unique identifier for supporting task. (e.g. 78424)
  --is-workspace-level: string@bool-completer # Filter to goals with is_workspace_level set to query value. Must be used with the workspace parameter. (e.g. false)
  --team: string # Globally unique identifier for the team. (e.g. 31326)
  --workspace: string # Globally unique identifier for the workspace. (e.g. 31326)
  --time-periods: list # Globally unique identifiers for the time periods. (e.g. 221693,506165)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, followers, followers.name, html_notes, is_workspace_level, liked, likes, likes.user, likes.user.name, metric, metric.can_manage, metric.currency_code, metric.current_display_value, metric.current_number_value, metric.initial_number_value, metric.is_custom_weight, metric.precision, metric.progress_source, metric.resource_subtype, metric.target_number_value, metric.unit, name, notes, num_likes, offset, owner, owner.name, path, privacy_setting, start_on, status, team, team.name, time_period, time_period.display_name, time_period.end_on, time_period.period, time_period.start_on, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, owner: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "portfolio" $portfolio "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "task" $task "scalar") (serialize-qp "is_workspace_level" $is_workspace_level "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "time_periods" $time_periods "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/goals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, followers, followers.name, html_notes, is_workspace_level, liked, likes, likes.user, likes.user.name, metric, metric.can_manage, metric.currency_code, metric.current_display_value, metric.current_number_value, metric.initial_number_value, metric.is_custom_weight, metric.precision, metric.progress_source, metric.resource_subtype, metric.target_number_value, metric.unit, name, notes, num_likes, owner, owner.name, privacy_setting, start_on, status, team, team.name, time_period, time_period.display_name, time_period.end_on, time_period.period, time_period.start_on, workspace, workspace.name])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, name: string, html_notes: string, notes: string, due_on: string, start_on: string, is_workspace_level: bool, liked: bool, likes: list<record>, num_likes: int, team: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, followers: list<record>, time_period: record<gid: string, resource_type: string, end_on: string, start_on: string, period: string, display_name: string>, metric: record<gid: string, resource_type: string, resource_subtype: string, precision: int, unit: string, currency_code: string, initial_number_value: float, target_number_value: float, current_number_value: float, current_display_value: string, progress_source: string, is_custom_weight: bool, can_manage: bool>, owner: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, status: string, privacy_setting: string, default_access_level: string, custom_fields: list<record>, custom_field_settings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/goals" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a goal metric
#
# POST /goals/{goal_gid}/setMetric
# operationId: createGoalMetric
# --data shape: {precision?: int, unit?: "none"|"currency"|"percentage", currency_code?: string, initial_number_value?: float, target_number_value?: float, current_number_value?: float, progress_source?: "manual"|"subgoal_progress"|"project_task_completion"|"project_milestone_completion"|"task_completion"|"external", is_custom_weight?: bool}
export def "goals-set-metric createGoalMetric" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, followers, followers.name, html_notes, is_workspace_level, liked, likes, likes.user, likes.user.name, metric, metric.can_manage, metric.currency_code, metric.current_display_value, metric.current_number_value, metric.initial_number_value, metric.is_custom_weight, metric.precision, metric.progress_source, metric.resource_subtype, metric.target_number_value, metric.unit, name, notes, num_likes, owner, owner.name, privacy_setting, start_on, status, team, team.name, time_period, time_period.display_name, time_period.end_on, time_period.period, time_period.start_on, workspace, workspace.name])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {precision?: int, unit?: "none"|"currency"|"percentage", currency_code?: string, initial_number_value?: float, target_number_value?: float, current_number_value?: float, progress_source?: "manual"|"subgoal_progress"|"project_task_completion"|"project_milestone_completion"|"task_completion"|"external", is_custom_weight?: bool}
]: any -> record<data: record<gid: string, resource_type: string, name: string, html_notes: string, notes: string, due_on: string, start_on: string, is_workspace_level: bool, liked: bool, likes: list<record>, num_likes: int, team: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, followers: list<record>, time_period: record<gid: string, resource_type: string, end_on: string, start_on: string, period: string, display_name: string>, metric: record<gid: string, resource_type: string, resource_subtype: string, precision: int, unit: string, currency_code: string, initial_number_value: float, target_number_value: float, current_number_value: float, current_display_value: string, progress_source: string, is_custom_weight: bool, can_manage: bool>, owner: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, status: string, privacy_setting: string, default_access_level: string, custom_fields: list<record>, custom_field_settings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/setMetric" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a goal metric
#
# POST /goals/{goal_gid}/setMetricCurrentValue
# operationId: updateGoalMetric
# --data shape: {current_number_value?: float}
export def "goals-set-metric-current-value updateGoalMetric" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, followers, followers.name, html_notes, is_workspace_level, liked, likes, likes.user, likes.user.name, metric, metric.can_manage, metric.currency_code, metric.current_display_value, metric.current_number_value, metric.initial_number_value, metric.is_custom_weight, metric.precision, metric.progress_source, metric.resource_subtype, metric.target_number_value, metric.unit, name, notes, num_likes, owner, owner.name, privacy_setting, start_on, status, team, team.name, time_period, time_period.display_name, time_period.end_on, time_period.period, time_period.start_on, workspace, workspace.name])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {current_number_value?: float}
]: any -> record<data: record<gid: string, resource_type: string, name: string, html_notes: string, notes: string, due_on: string, start_on: string, is_workspace_level: bool, liked: bool, likes: list<record>, num_likes: int, team: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, followers: list<record>, time_period: record<gid: string, resource_type: string, end_on: string, start_on: string, period: string, display_name: string>, metric: record<gid: string, resource_type: string, resource_subtype: string, precision: int, unit: string, currency_code: string, initial_number_value: float, target_number_value: float, current_number_value: float, current_display_value: string, progress_source: string, is_custom_weight: bool, can_manage: bool>, owner: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, status: string, privacy_setting: string, default_access_level: string, custom_fields: list<record>, custom_field_settings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/setMetricCurrentValue" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, followers, followers.name, html_notes, is_workspace_level, liked, likes, likes.user, likes.user.name, metric, metric.can_manage, metric.currency_code, metric.current_display_value, metric.current_number_value, metric.initial_number_value, metric.is_custom_weight, metric.precision, metric.progress_source, metric.resource_subtype, metric.target_number_value, metric.unit, name, notes, num_likes, owner, owner.name, privacy_setting, start_on, status, team, team.name, time_period, time_period.display_name, time_period.end_on, time_period.period, time_period.start_on, workspace, workspace.name])
  --data: record # shape: {followers: list}
]: any -> record<data: record<gid: string, resource_type: string, name: string, html_notes: string, notes: string, due_on: string, start_on: string, is_workspace_level: bool, liked: bool, likes: list<record>, num_likes: int, team: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, followers: list<record>, time_period: record<gid: string, resource_type: string, end_on: string, start_on: string, period: string, display_name: string>, metric: record<gid: string, resource_type: string, resource_subtype: string, precision: int, unit: string, currency_code: string, initial_number_value: float, target_number_value: float, current_number_value: float, current_display_value: string, progress_source: string, is_custom_weight: bool, can_manage: bool>, owner: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, status: string, privacy_setting: string, default_access_level: string, custom_fields: list<record>, custom_field_settings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/addFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, followers, followers.name, html_notes, is_workspace_level, liked, likes, likes.user, likes.user.name, metric, metric.can_manage, metric.currency_code, metric.current_display_value, metric.current_number_value, metric.initial_number_value, metric.is_custom_weight, metric.precision, metric.progress_source, metric.resource_subtype, metric.target_number_value, metric.unit, name, notes, num_likes, owner, owner.name, privacy_setting, start_on, status, team, team.name, time_period, time_period.display_name, time_period.end_on, time_period.period, time_period.start_on, workspace, workspace.name])
  --data: record # shape: {followers: list}
]: any -> record<data: record<gid: string, resource_type: string, name: string, html_notes: string, notes: string, due_on: string, start_on: string, is_workspace_level: bool, liked: bool, likes: list<record>, num_likes: int, team: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, followers: list<record>, time_period: record<gid: string, resource_type: string, end_on: string, start_on: string, period: string, display_name: string>, metric: record<gid: string, resource_type: string, resource_subtype: string, precision: int, unit: string, currency_code: string, initial_number_value: float, target_number_value: float, current_number_value: float, current_display_value: string, progress_source: string, is_custom_weight: bool, can_manage: bool>, owner: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, status: string, privacy_setting: string, default_access_level: string, custom_fields: list<record>, custom_field_settings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/removeFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, followers, followers.name, html_notes, is_workspace_level, liked, likes, likes.user, likes.user.name, metric, metric.can_manage, metric.currency_code, metric.current_display_value, metric.current_number_value, metric.initial_number_value, metric.is_custom_weight, metric.precision, metric.progress_source, metric.resource_subtype, metric.target_number_value, metric.unit, name, notes, num_likes, owner, owner.name, privacy_setting, start_on, status, team, team.name, time_period, time_period.display_name, time_period.end_on, time_period.period, time_period.start_on, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, owner: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/parentGoals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a custom field to a goal
#
# POST /goals/{goal_gid}/addCustomFieldSetting
# operationId: addCustomFieldSettingForGoal
# --data shape: {custom_field: any, is_important?: bool, insert_before?: string, insert_after?: string}
export def "goals-add-custom-field-setting addCustomFieldSettingForGoal" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {custom_field: any, is_important?: bool, insert_before?: string, insert_after?: string}
]: any -> record<data: record<gid: string, resource_type: string, project: record<gid: string, resource_type: string, name: string>, is_important: bool, parent: record<gid: string, resource_type: string, name: string>, custom_field: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/addCustomFieldSetting" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a custom field from a goal
#
# POST /goals/{goal_gid}/removeCustomFieldSetting
# operationId: removeCustomFieldSettingForGoal
# --data shape: {custom_field: string}
export def "goals-remove-custom-field-setting removeCustomFieldSettingForGoal" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {custom_field: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/removeCustomFieldSetting" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [new_graph_export, new_graph_export.completed_at, new_graph_export.created_at, new_graph_export.download_url, new_portfolio, new_portfolio.name, new_project, new_project.name, new_project_template, new_project_template.name, new_resource_export, new_resource_export.completed_at, new_resource_export.created_at, new_resource_export.download_url, new_task, new_task.created_by, new_task.name, new_task.resource_subtype, resource_subtype, status])
]: nothing -> record<data: record<gid: string, resource_type: string, resource_subtype: string, status: string, new_portfolio: record<gid: string, resource_type: string, name: string>, new_project: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, new_project_template: record<gid: string, resource_type: string, name: string>, new_graph_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>, new_resource_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/jobs/($job_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get multiple memberships
#
# GET /memberships
# operationId: getMemberships
export def "memberships list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent: string # Globally unique identifier for `goal`, `project`, `portfolio`, `custom_type`, or `custom_field`. This parameter is optional when `resource_subtype` is provided along with `member` of type `team`. (e.g. 159874)
  --member: string # Globally unique identifier for `team` or `user`. When used with `resource_subtype` and without `parent`, `member` must be of type `team`. For user-type memberships `parent` parameter is required to disambiguate the workspace from which memberships should be retrieved. (e.g. 1061493)
  --resource-subtype: string@resource-subtype-completer-1 # The type of membership to return. Required when `parent` is absent. Currently supported value is `project_membership` (when `member` is a team GID, returns all project memberships for that team). (e.g. project_membership)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [offset, path, uri])
]: nothing -> record<data: list<any>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar") (serialize-qp "member" $member "scalar") (serialize-qp "resource_subtype" $resource_subtype "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a membership
#
# POST /memberships
# operationId: createMembership
export def "memberships createMembership" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: any
]: any -> record<data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/memberships" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a membership
#
# GET /memberships/{membership_gid}
# operationId: getMembership
export def "memberships get" [
  membership_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/memberships/($membership_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a membership
#
# PUT /memberships/{membership_gid}
# operationId: updateMembership
# --data shape: {access_level?: string}
export def "memberships updateMembership" [
  membership_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {access_level?: string}
]: any -> record<data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/memberships/($membership_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a membership
#
# DELETE /memberships/{membership_gid}
# operationId: deleteMembership
export def "memberships delete" [
  membership_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/memberships/($membership_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an OOO entry
#
# GET /ooo_entries/{ooo_entry_gid}
# operationId: getOooEntry
export def "ooo-entries get" [
  ooo_entry_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_by, created_by.name, end_date, start_date, user, user.name])
]: nothing -> record<data: record<gid: string, resource_type: string, start_date: string, end_date: string, user: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ooo_entries/($ooo_entry_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an OOO entry
#
# PUT /ooo_entries/{ooo_entry_gid}
# operationId: updateOooEntry
# --data shape: {start_date?: string, end_date?: string}
export def "ooo-entries updateOooEntry" [
  ooo_entry_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_by, created_by.name, end_date, start_date, user, user.name])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {start_date?: string, end_date?: string}
]: any -> record<data: record<gid: string, resource_type: string, start_date: string, end_date: string, user: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/ooo_entries/($ooo_entry_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an OOO entry
#
# DELETE /ooo_entries/{ooo_entry_gid}
# operationId: deleteOooEntry
export def "ooo-entries delete" [
  ooo_entry_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ooo_entries/($ooo_entry_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get OOO entries for a user
#
# GET /ooo_entries
# operationId: getOooEntries
export def "ooo-entries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user: string # Globally unique identifier for the user to filter OOO entries by. (e.g. 12345)
  --workspace: string # Globally unique identifier for the workspace. (e.g. 98765)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --start-date: string # An ISO 8601 date string. Filters to OOO entries that overlap with or end after this date. (format: date, e.g. 2025-01-01)
  --end-date: string # An ISO 8601 date string. Filters to OOO entries that overlap with or start before this date. (format: date, e.g. 2025-12-31)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_by, created_by.name, end_date, offset, path, start_date, uri, user, user.name])
]: nothing -> record<data: table<gid: string, resource_type: string, start_date: string, end_date: string, user: record, created_by: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/ooo_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an OOO entry
#
# POST /ooo_entries
# operationId: createOooEntry
export def "ooo-entries createOooEntry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_by, created_by.name, end_date, start_date, user, user.name])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, start_date: string, end_date: string, user: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/ooo_entries" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, download_url, organization, organization.name, state])
  --data: record # An *organization_export* request starts a job to export the complete data of the given Organization. — shape: {organization?: string}
]: any -> record<data: record<gid: string, resource_type: string, created_at: string, download_url: string, state: string, organization: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/organization_exports" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, download_url, organization, organization.name, state])
]: nothing -> record<data: record<gid: string, resource_type: string, created_at: string, download_url: string, state: string, organization: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization_exports/($organization_export_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --portfolio: string # The portfolio to filter results on. (e.g. 12345)
  --workspace: string # The workspace to filter results on. (e.g. 12345)
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [access_level, offset, path, portfolio, portfolio.name, uri, user, user.name])
]: nothing -> record<data: table<gid: string, resource_type: string, portfolio: record, user: record, access_level: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "portfolio" $portfolio "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/portfolio_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [access_level, portfolio, portfolio.name, user, user.name])
]: nothing -> record<data: record<gid: string, resource_type: string, portfolio: record<gid: string, resource_type: string, name: string>, user: record<gid: string, resource_type: string, name: string>, access_level: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolio_memberships/($portfolio_membership_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [access_level, offset, path, portfolio, portfolio.name, uri, user, user.name])
]: nothing -> record<data: table<gid: string, resource_type: string, portfolio: record, user: record, access_level: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/portfolio_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace or organization to filter portfolios on. (e.g. 1331)
  --owner: string # The user who owns the portfolio. Currently, API users can only get a list of portfolios that they themselves own, unless the request is made from a Service Account. In the case of a Service Account, if this parameter is specified, then all portfolios owned by this parameter are returned. Otherwise, all portfolios across the workspace are returned. (e.g. 14916)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, created_at, created_by, created_by.name, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, members, members.name, name, offset, owner, owner.name, path, permalink_url, privacy_setting, project_templates, project_templates.name, public, start_on, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/portfolios" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, created_at, created_by, created_by.name, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, members, members.name, name, owner, owner.name, permalink_url, privacy_setting, project_templates, project_templates.name, public, start_on, workspace, workspace.name])
  --data: any
]: any -> record<data: record<created_at: string, created_by: record<gid: string, resource_type: string, name: string>, custom_field_settings: list<record>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, custom_fields: list<record>, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, privacy_setting: string, project_templates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/portfolios" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, created_at, created_by, created_by.name, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, members, members.name, name, owner, owner.name, permalink_url, privacy_setting, project_templates, project_templates.name, public, start_on, workspace, workspace.name])
]: nothing -> record<data: record<created_at: string, created_by: record<gid: string, resource_type: string, name: string>, custom_field_settings: list<record>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, custom_fields: list<record>, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, privacy_setting: string, project_templates: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, created_at, created_by, created_by.name, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, members, members.name, name, owner, owner.name, permalink_url, privacy_setting, project_templates, project_templates.name, public, start_on, workspace, workspace.name])
  --data: any
]: any -> record<data: record<created_at: string, created_by: record<gid: string, resource_type: string, name: string>, custom_field_settings: list<record>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, custom_fields: list<record>, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, privacy_setting: string, project_templates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, offset, owner, path, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a portfolio item
#
# POST /portfolios/{portfolio_gid}/addItem
# operationId: addItemForPortfolio
# --data shape: {item: string, insert_before?: string, insert_after?: string}
export def "portfolios-add-item addItemForPortfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {item: string, insert_before?: string, insert_after?: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/addItem" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {item: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/removeItem" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a custom field to a portfolio
#
# POST /portfolios/{portfolio_gid}/addCustomFieldSetting
# operationId: addCustomFieldSettingForPortfolio
# --data shape: {custom_field: any, is_important?: bool, insert_before?: string, insert_after?: string}
export def "portfolios-add-custom-field-setting addCustomFieldSettingForPortfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {custom_field: any, is_important?: bool, insert_before?: string, insert_after?: string}
]: any -> record<data: record<gid: string, resource_type: string, project: record<gid: string, resource_type: string, name: string>, is_important: bool, parent: record<gid: string, resource_type: string, name: string>, custom_field: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/addCustomFieldSetting" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
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
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, created_at, created_by, created_by.name, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, members, members.name, name, owner, owner.name, permalink_url, privacy_setting, project_templates, project_templates.name, public, start_on, workspace, workspace.name])
  --data: record # shape: {members: string}
]: any -> record<data: record<created_at: string, created_by: record<gid: string, resource_type: string, name: string>, custom_field_settings: list<record>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, custom_fields: list<record>, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, privacy_setting: string, project_templates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/addMembers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, created_at, created_by, created_by.name, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, due_on, members, members.name, name, owner, owner.name, permalink_url, privacy_setting, project_templates, project_templates.name, public, start_on, workspace, workspace.name])
  --data: record # shape: {members: string}
]: any -> record<data: record<created_at: string, created_by: record<gid: string, resource_type: string, name: string>, custom_field_settings: list<record>, current_status_update: record<gid: string, resource_type: string, title: string, resource_subtype: string>, custom_fields: list<record>, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, privacy_setting: string, project_templates: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/removeMembers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Duplicate a portfolio
#
# POST /portfolios/{portfolio_gid}/duplicate
# operationId: duplicatePortfolio
# --data shape: {name: string, include?: string}
export def "portfolios-duplicate duplicatePortfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [new_graph_export, new_graph_export.completed_at, new_graph_export.created_at, new_graph_export.download_url, new_portfolio, new_portfolio.name, new_project, new_project.name, new_project_template, new_project_template.name, new_resource_export, new_resource_export.completed_at, new_resource_export.created_at, new_resource_export.download_url, new_task, new_task.created_by, new_task.name, new_task.resource_subtype, resource_subtype, status])
  --data: record # shape: {name: string, include?: string}
]: any -> record<data: record<gid: string, resource_type: string, resource_subtype: string, status: string, new_portfolio: record<gid: string, resource_type: string, name: string>, new_project: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, new_project_template: record<gid: string, resource_type: string, name: string>, new_graph_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>, new_resource_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/duplicate" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [html_text, permalink_url, project, project.name, text, title])
]: nothing -> record<data: record<text: string, permalink_url: string, project: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_briefs/($project_brief_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [html_text, permalink_url, project, project.name, text, title])
  --data: any
]: any -> record<data: record<text: string, permalink_url: string, project: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_briefs/($project_brief_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_briefs/($project_brief_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [html_text, permalink_url, project, project.name, text, title])
  --data: any
]: any -> record<data: record<text: string, permalink_url: string, project: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/project_briefs" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [access_level, member, member.name, parent, parent.name, project, project.name, user, user.name, write_access])
]: nothing -> record<data: record<gid: string, resource_type: string, parent: record<gid: string, resource_type: string, name: string>, member: record<gid: string, resource_type: string, name: string>, access_level: string, user: record<gid: string, resource_type: string, name: string>, project: record<gid: string, resource_type: string, name: string>, write_access: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_memberships/($project_membership_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [access_level, member, member.name, offset, parent, parent.name, path, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, parent: record, member: record, access_level: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/project_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a project portfolio setting
#
# GET /project_portfolio_settings/{project_portfolio_setting_gid}
# operationId: getProjectPortfolioSetting
export def "project-portfolio-settings get" [
  project_portfolio_setting_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, is_access_control_inherited, portfolio, project])
]: nothing -> record<data: record<gid: string, resource_type: string, project: record<gid: string, resource_type: string, name: string>, portfolio: record<gid: string, resource_type: string, name: string>, is_access_control_inherited: bool, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_portfolio_settings/($project_portfolio_setting_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a project portfolio setting
#
# PUT /project_portfolio_settings/{project_portfolio_setting_gid}
# operationId: updateProjectPortfolioSetting
# --data shape: {is_access_control_inherited?: bool}
export def "project-portfolio-settings updateProjectPortfolioSetting" [
  project_portfolio_setting_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, is_access_control_inherited, portfolio, project])
  --data: record # shape: {is_access_control_inherited?: bool}
]: any -> record<data: record<gid: string, resource_type: string, project: record<gid: string, resource_type: string, name: string>, portfolio: record<gid: string, resource_type: string, name: string>, is_access_control_inherited: bool, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_portfolio_settings/($project_portfolio_setting_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get project portfolio settings for a project
#
# GET /projects/{project_gid}/project_portfolio_settings
# operationId: getProjectPortfolioSettingsForProject
export def "projects-project-portfolio-settings get" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, is_access_control_inherited, offset, path, portfolio, project, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, project: record, portfolio: record, is_access_control_inherited: bool>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/project_portfolio_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project portfolio settings for a portfolio
#
# GET /portfolios/{portfolio_gid}/project_portfolio_settings
# operationId: getProjectPortfolioSettingsForPortfolio
export def "portfolios-project-portfolio-settings get" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, is_access_control_inherited, offset, path, portfolio, project, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, project: record, portfolio: record, is_access_control_inherited: bool>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/portfolios/($portfolio_gid)/project_portfolio_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [author, author.name, color, created_at, created_by, created_by.name, html_text, modified_at, text, title])
]: nothing -> record<data: record<author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, modified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_statuses/($project_status_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_statuses/($project_status_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [author, author.name, color, created_at, created_by, created_by.name, html_text, modified_at, offset, path, text, title, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, title: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/project_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [author, author.name, color, created_at, created_by, created_by.name, html_text, modified_at, text, title])
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
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, description, html_description, name, owner, public, requested_dates, requested_dates.description, requested_dates.name, requested_roles, requested_roles.name, team, team.name])
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_templates/($project_template_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a project template
#
# DELETE /project_templates/{project_template_gid}
# operationId: deleteProjectTemplate
export def "project-templates delete" [
  project_template_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_templates/($project_template_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --workspace: string # The workspace to filter results on. (e.g. 12345)
  --team: string # The team to filter projects on. (e.g. 14916)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, description, html_description, name, offset, owner, path, public, requested_dates, requested_dates.description, requested_dates.name, requested_roles, requested_roles.name, team, team.name, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspace" $workspace "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/project_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, description, html_description, name, offset, owner, path, public, requested_dates, requested_dates.description, requested_dates.name, requested_roles, requested_roles.name, team, team.name, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/project_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Instantiate a project from a project template
#
# POST /project_templates/{project_template_gid}/instantiateProject
# operationId: instantiateProject
# --data shape: {name: string, team?: string, public?: bool, privacy_setting?: "public_to_workspace"|"private_to_team"|"private", is_strict?: bool, requested_dates?: list, requested_roles?: list}
export def "project-templates-instantiate-project instantiateProject" [
  project_template_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [new_graph_export, new_graph_export.completed_at, new_graph_export.created_at, new_graph_export.download_url, new_portfolio, new_portfolio.name, new_project, new_project.name, new_project_template, new_project_template.name, new_resource_export, new_resource_export.completed_at, new_resource_export.created_at, new_resource_export.download_url, new_task, new_task.created_by, new_task.name, new_task.resource_subtype, resource_subtype, status])
  --data: record # shape: {name: string, team?: string, public?: bool, privacy_setting?: "public_to_workspace"|"private_to_team"|"private", is_strict?: bool, requested_dates?: list, requested_roles?: list}
]: any -> record<data: record<gid: string, resource_type: string, resource_subtype: string, status: string, new_portfolio: record<gid: string, resource_type: string, name: string>, new_project: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, new_project_template: record<gid: string, resource_type: string, name: string>, new_graph_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>, new_resource_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/project_templates/($project_template_gid)/instantiateProject" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get multiple projects
#
# GET /projects
# operationId: getProjects
@deprecated --flag team
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace or organization to filter projects on. (e.g. 1331)
  --team: string # **Deprecated.** The team to filter projects on. Please use `GET /memberships` with `{ member: team, resource_subtype: project_membership }` instead. (DEPRECATED, e.g. 14916)
  --archived: string@bool-completer # Only return projects whose `archived` field takes on the value of this parameter. (e.g. false)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, offset, owner, path, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, owner, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, workspace, workspace.name])
  --data: any
]: any -> record<data: record<custom_fields: list<record>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, followers: list<record>, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, created_from_template: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, owner, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, workspace, workspace.name])
]: nothing -> record<data: record<custom_fields: list<record>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, followers: list<record>, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, created_from_template: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, owner, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, workspace, workspace.name])
  --data: any
]: any -> record<data: record<custom_fields: list<record>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, followers: list<record>, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, created_from_template: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Duplicate a project
#
# POST /projects/{project_gid}/duplicate
# operationId: duplicateProject
# --data shape: {name: string, include?: string, schedule_dates?: record}
export def "projects-duplicate duplicateProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [new_graph_export, new_graph_export.completed_at, new_graph_export.created_at, new_graph_export.download_url, new_portfolio, new_portfolio.name, new_project, new_project.name, new_project_template, new_project_template.name, new_resource_export, new_resource_export.completed_at, new_resource_export.created_at, new_resource_export.download_url, new_task, new_task.created_by, new_task.name, new_task.resource_subtype, resource_subtype, status])
  --data: record # shape: {name: string, include?: string, schedule_dates?: record}
]: any -> record<data: record<gid: string, resource_type: string, resource_subtype: string, status: string, new_portfolio: record<gid: string, resource_type: string, name: string>, new_project: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, new_project_template: record<gid: string, resource_type: string, name: string>, new_graph_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>, new_resource_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/duplicate" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, offset, owner, path, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --archived: string@bool-completer # Only return projects whose `archived` field takes on the value of this parameter. (e.g. false)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, offset, owner, path, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, owner, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, workspace, workspace.name])
  --data: any
]: any -> record<data: record<custom_fields: list<record>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, followers: list<record>, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, created_from_template: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/projects" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --archived: string@bool-completer # Only return projects whose `archived` field takes on the value of this parameter. (e.g. false)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, offset, owner, path, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, owner, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, workspace, workspace.name])
  --data: any
]: any -> record<data: record<custom_fields: list<record>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, followers: list<record>, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, created_from_template: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/projects" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search projects in a workspace
#
# GET /workspaces/{workspace_gid}/projects/search
# operationId: searchProjectsForWorkspace
export def "workspaces-projects-search searchProjectsForWorkspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --text: string # Performs full-text search on the project name. (e.g. Bugs)
  --sort-by: string@sort-by-completer # One of `due_date`, `created_at`, `completed_at`, `relevance`, or `modified_at`, defaults to `modified_at`. (default: modified_at, e.g. modified_at)
  --sort-ascending: string@bool-completer # Default `false`. (default: false, e.g. false)
  --completed: string@bool-completer # Filter on project completion status. (e.g. false)
  --teamsany: string # Comma-separated list of team IDs. (e.g. 12345,67890)
  --ownerany: string # Comma-separated list of user identifiers to filter on as project owners. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,67890)
  --membersany: string # Comma-separated list of user identifiers to filter on as members. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,67890)
  --membersnot: string # Comma-separated list of user identifiers to exclude as members. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,67890)
  --portfoliosany: string # Comma-separated list of portfolio IDs to filter on. (e.g. 12345,67890)
  --completed-on: string # ISO 8601 date string or `null`. (nullable, format: date, e.g. 2019-09-15)
  --completed-onbefore: string # ISO 8601 date string. (format: date, e.g. 2019-09-15)
  --completed-onafter: string # ISO 8601 date string. (format: date, e.g. 2019-09-15)
  --completed-atbefore: string # ISO 8601 datetime string. (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --completed-atafter: string # ISO 8601 datetime string. (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --created-on: string # ISO 8601 date string or `null`. (nullable, format: date, e.g. 2019-09-15)
  --created-onbefore: string # ISO 8601 date string. (format: date, e.g. 2019-09-15)
  --created-onafter: string # ISO 8601 date string. (format: date, e.g. 2019-09-15)
  --created-atbefore: string # ISO 8601 datetime string. (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --created-atafter: string # ISO 8601 datetime string. (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --due-on: string # ISO 8601 date string or `null`. (nullable, format: date, e.g. 2019-09-15)
  --due-onbefore: string # ISO 8601 date string. (format: date, e.g. 2019-09-15)
  --due-onafter: string # ISO 8601 date string. (format: date, e.g. 2019-09-15)
  --due-atbefore: string # ISO 8601 datetime string. (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --due-atafter: string # ISO 8601 datetime string. (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --start-on: string # ISO 8601 date string or `null`. (nullable, format: date, e.g. 2019-09-15)
  --start-onbefore: string # ISO 8601 date string. (format: date, e.g. 2019-09-15)
  --start-onafter: string # ISO 8601 date string. (format: date, e.g. 2019-09-15)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, owner, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_ascending" $sort_ascending "scalar") (serialize-qp "completed" $completed "scalar") (serialize-qp "teams.any" $teamsany "scalar") (serialize-qp "owner.any" $ownerany "scalar") (serialize-qp "members.any" $membersany "scalar") (serialize-qp "members.not" $membersnot "scalar") (serialize-qp "portfolios.any" $portfoliosany "scalar") (serialize-qp "completed_on" $completed_on "scalar") (serialize-qp "completed_on.before" $completed_onbefore "scalar") (serialize-qp "completed_on.after" $completed_onafter "scalar") (serialize-qp "completed_at.before" $completed_atbefore "scalar") (serialize-qp "completed_at.after" $completed_atafter "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "created_on.before" $created_onbefore "scalar") (serialize-qp "created_on.after" $created_onafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "due_on" $due_on "scalar") (serialize-qp "due_on.before" $due_onbefore "scalar") (serialize-qp "due_on.after" $due_onafter "scalar") (serialize-qp "due_at.before" $due_atbefore "scalar") (serialize-qp "due_at.after" $due_atafter "scalar") (serialize-qp "start_on" $start_on "scalar") (serialize-qp "start_on.before" $start_onbefore "scalar") (serialize-qp "start_on.after" $start_onafter "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/projects/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a custom field to a project
#
# POST /projects/{project_gid}/addCustomFieldSetting
# operationId: addCustomFieldSettingForProject
# --data shape: {custom_field: any, is_important?: bool, insert_before?: string, insert_after?: string}
export def "projects-add-custom-field-setting addCustomFieldSettingForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_field, custom_field.asana_created_field, custom_field.created_by, custom_field.created_by.name, custom_field.currency_code, custom_field.custom_label, custom_field.custom_label_position, custom_field.date_value, custom_field.date_value.date, custom_field.date_value.date_time, custom_field.default_access_level, custom_field.description, custom_field.display_value, custom_field.enabled, custom_field.enum_options, custom_field.enum_options.color, custom_field.enum_options.enabled, custom_field.enum_options.name, custom_field.enum_value, custom_field.enum_value.color, custom_field.enum_value.enabled, custom_field.enum_value.name, custom_field.format, custom_field.has_notifications_enabled, custom_field.html_text_value, custom_field.id_prefix, custom_field.input_restrictions, custom_field.is_formula_field, custom_field.is_global_to_workspace, custom_field.is_value_read_only, custom_field.multi_enum_values, custom_field.multi_enum_values.color, custom_field.multi_enum_values.enabled, custom_field.multi_enum_values.name, custom_field.name, custom_field.number_value, custom_field.people_value, custom_field.people_value.name, custom_field.precision, custom_field.privacy_setting, custom_field.reference_value, custom_field.reference_value.name, custom_field.representation_type, custom_field.resource_subtype, custom_field.text_value, custom_field.type, is_important, parent, parent.name, project, project.name])
  --data: record # shape: {custom_field: any, is_important?: bool, insert_before?: string, insert_after?: string}
]: any -> record<data: record<gid: string, resource_type: string, project: record<gid: string, resource_type: string, name: string>, is_important: bool, parent: record<gid: string, resource_type: string, name: string>, custom_field: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/addCustomFieldSetting" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
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
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [num_completed_milestones, num_completed_tasks, num_incomplete_milestones, num_incomplete_tasks, num_milestones, num_tasks])
]: nothing -> record<data: record<num_tasks: int, num_incomplete_tasks: int, num_completed_tasks: int, num_milestones: int, num_incomplete_milestones: int, num_completed_milestones: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/task_counts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, owner, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, workspace, workspace.name])
  --data: record # shape: {members: string}
]: any -> record<data: record<custom_fields: list<record>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, followers: list<record>, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, created_from_template: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/addMembers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, owner, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, workspace, workspace.name])
  --data: record # shape: {members: string}
]: any -> record<data: record<custom_fields: list<record>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, followers: list<record>, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, created_from_template: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/removeMembers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, owner, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, workspace, workspace.name])
  --data: record # shape: {followers: string}
]: any -> record<data: record<custom_fields: list<record>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, followers: list<record>, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, created_from_template: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/addFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [archived, color, completed, completed_at, completed_by, completed_by.name, created_at, created_from_template, created_from_template.name, current_status, current_status.author, current_status.author.name, current_status.color, current_status.created_at, current_status.created_by, current_status.created_by.name, current_status.html_text, current_status.modified_at, current_status.text, current_status.title, current_status_update, current_status_update.resource_subtype, current_status_update.title, custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, default_access_level, default_view, due_date, due_on, followers, followers.name, html_notes, icon, members, members.name, minimum_access_level_for_customization, minimum_access_level_for_sharing, modified_at, name, notes, owner, permalink_url, privacy_setting, project_brief, public, start_on, team, team.name, workspace, workspace.name])
  --data: record # shape: {followers: string}
]: any -> record<data: record<custom_fields: list<record>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, followers: list<record>, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, created_from_template: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/removeFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a project template from a project
#
# POST /projects/{project_gid}/saveAsTemplate
# operationId: projectSaveAsTemplate
# --data shape: {name: string, team?: string, workspace?: string, public: bool}
export def "projects-save-as-template projectSaveAsTemplate" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [new_graph_export, new_graph_export.completed_at, new_graph_export.created_at, new_graph_export.download_url, new_portfolio, new_portfolio.name, new_project, new_project.name, new_project_template, new_project_template.name, new_resource_export, new_resource_export.completed_at, new_resource_export.created_at, new_resource_export.download_url, new_task, new_task.created_by, new_task.name, new_task.resource_subtype, resource_subtype, status])
  --data: record # shape: {name: string, team?: string, workspace?: string, public: bool}
]: any -> record<data: record<gid: string, resource_type: string, resource_subtype: string, status: string, new_portfolio: record<gid: string, resource_type: string, name: string>, new_project: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, new_project_template: record<gid: string, resource_type: string, name: string>, new_graph_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>, new_resource_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/saveAsTemplate" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get multiple rates
#
# GET /rates
# operationId: getRates
export def "rates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent: string # Globally unique identifier for `project`. (e.g. 159874)
  --resource: string # Globally unique identifier for `user` or `placeholder`. (e.g. 1061493)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [offset, path, uri])
]: nothing -> record<data: list<any>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar") (serialize-qp "resource" $resource "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/rates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a rate
#
# POST /rates
# operationId: createRate
# --data shape: {parent: string, resource: string, rate: float}
export def "rates createRate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_by, created_by.name, currency_code, parent, parent.name, rate, resource, resource.name])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {parent: string, resource: string, rate: float}
]: any -> record<data: record<gid: string, resource_type: string, parent: record<gid: string, resource_type: string, name: string>, resource: record<gid: string, resource_type: string, name: string>, rate: float, currency_code: string, created_by: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/rates" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a rate
#
# GET /rates/{rate_gid}
# operationId: getRate
export def "rates get" [
  rate_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_by, created_by.name, currency_code, parent, parent.name, rate, resource, resource.name])
]: nothing -> record<data: record<gid: string, resource_type: string, parent: record<gid: string, resource_type: string, name: string>, resource: record<gid: string, resource_type: string, name: string>, rate: float, currency_code: string, created_by: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/rates/($rate_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a rate
#
# PUT /rates/{rate_gid}
# operationId: updateRate
# --data shape: {rate?: float}
export def "rates updateRate" [
  rate_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_by, created_by.name, currency_code, parent, parent.name, rate, resource, resource.name])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {rate?: float}
]: any -> record<data: record<gid: string, resource_type: string, parent: record<gid: string, resource_type: string, name: string>, resource: record<gid: string, resource_type: string, name: string>, rate: float, currency_code: string, created_by: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/rates/($rate_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a rate
#
# DELETE /rates/{rate_gid}
# operationId: deleteRate
export def "rates delete" [
  rate_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rates/($rate_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get reactions with an emoji base on an object.
#
# GET /reactions
# operationId: getReactionsOnObject
export def "reactions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --target: string # Globally unique identifier for object to fetch reactions from. Must be a GID for a status update or story. (e.g. 159874)
  --emoji-base: string # Only return reactions with this emoji base character. (e.g. 👍)
]: nothing -> record<data: table<gid: string, emoji: string, user: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "emoji_base" $emoji_base "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get multiple roles
#
# GET /roles
# operationId: getRoles
export def "roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace or organization to filter roles on. (e.g. 1331)
  --archived: string@bool-completer # Only return projects whose `archived` field takes on the value of this parameter. (e.g. false)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [base_role_type, creation_time, description, is_standard_role, modified_at, name, offset, path, permissions, permissions.allowed_guest_invites, permissions.assign_roles, permissions.create_and_edit_ai_automations, permissions.create_and_edit_ai_teammates, permissions.create_app_authorization, permissions.create_global_custom_fields, permissions.create_goal, permissions.create_pat_authorization, permissions.create_portfolio, permissions.create_project, permissions.create_read_only_link, permissions.create_team, permissions.download_mobile_attachments, permissions.export_project_data, permissions.import_data, permissions.manage_roles, permissions.proactive_ai, permissions.share_goal_with_domain, permissions.share_portfolios_with_org, permissions.share_teams_with_org, permissions.standard_ai, permissions.task_deletion_policy, permissions.upload_attachments, permissions.view_public_teams, permissions.view_shared_with_org_portfolios, permissions.view_shared_with_org_projects, permissions.view_shared_with_org_tasks, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, description: string, is_standard_role: bool>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a role
#
# POST /roles
# operationId: createRole
export def "roles createRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [base_role_type, creation_time, description, is_standard_role, modified_at, name, permissions, permissions.allowed_guest_invites, permissions.assign_roles, permissions.create_and_edit_ai_automations, permissions.create_and_edit_ai_teammates, permissions.create_app_authorization, permissions.create_global_custom_fields, permissions.create_goal, permissions.create_pat_authorization, permissions.create_portfolio, permissions.create_project, permissions.create_read_only_link, permissions.create_team, permissions.download_mobile_attachments, permissions.export_project_data, permissions.import_data, permissions.manage_roles, permissions.proactive_ai, permissions.share_goal_with_domain, permissions.share_portfolios_with_org, permissions.share_teams_with_org, permissions.standard_ai, permissions.task_deletion_policy, permissions.upload_attachments, permissions.view_public_teams, permissions.view_shared_with_org_portfolios, permissions.view_shared_with_org_projects, permissions.view_shared_with_org_tasks, workspace, workspace.name])
  --data: any
]: any -> record<data: record<workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/roles" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a role
#
# GET /roles/{role_gid}
# operationId: getRole
export def "roles get" [
  role_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [base_role_type, creation_time, description, is_standard_role, modified_at, name, permissions, permissions.allowed_guest_invites, permissions.assign_roles, permissions.create_and_edit_ai_automations, permissions.create_and_edit_ai_teammates, permissions.create_app_authorization, permissions.create_global_custom_fields, permissions.create_goal, permissions.create_pat_authorization, permissions.create_portfolio, permissions.create_project, permissions.create_read_only_link, permissions.create_team, permissions.download_mobile_attachments, permissions.export_project_data, permissions.import_data, permissions.manage_roles, permissions.proactive_ai, permissions.share_goal_with_domain, permissions.share_portfolios_with_org, permissions.share_teams_with_org, permissions.standard_ai, permissions.task_deletion_policy, permissions.upload_attachments, permissions.view_public_teams, permissions.view_shared_with_org_portfolios, permissions.view_shared_with_org_projects, permissions.view_shared_with_org_tasks, workspace, workspace.name])
]: nothing -> record<data: record<workspace: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/roles/($role_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a role
#
# PUT /roles/{role_gid}
# operationId: updateRole
export def "roles updateRole" [
  role_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [base_role_type, creation_time, description, is_standard_role, modified_at, name, permissions, permissions.allowed_guest_invites, permissions.assign_roles, permissions.create_and_edit_ai_automations, permissions.create_and_edit_ai_teammates, permissions.create_app_authorization, permissions.create_global_custom_fields, permissions.create_goal, permissions.create_pat_authorization, permissions.create_portfolio, permissions.create_project, permissions.create_read_only_link, permissions.create_team, permissions.download_mobile_attachments, permissions.export_project_data, permissions.import_data, permissions.manage_roles, permissions.proactive_ai, permissions.share_goal_with_domain, permissions.share_portfolios_with_org, permissions.share_teams_with_org, permissions.standard_ai, permissions.task_deletion_policy, permissions.upload_attachments, permissions.view_public_teams, permissions.view_shared_with_org_portfolios, permissions.view_shared_with_org_projects, permissions.view_shared_with_org_tasks, workspace, workspace.name])
  --data: any
]: any -> record<data: record<workspace: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/roles/($role_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a role
#
# DELETE /roles/{role_gid}
# operationId: deleteRole
export def "roles delete" [
  role_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/roles/($role_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a rule
#
# POST /rule_triggers/{rule_trigger_gid}/run
# operationId: triggerRule
# --data shape: {resource: string, action_data: record}
export def "rule-triggers-run triggerRule" [
  rule_trigger_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # shape: {resource: string, action_data: record}
]: any -> record<data: record<message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rule_triggers/($rule_trigger_gid)/run")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, name, project, project.name, projects, projects.name])
]: nothing -> record<data: record<gid: string, resource_type: string, name: string, created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/sections/($section_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a section
#
# PUT /sections/{section_gid}
# operationId: updateSection
# --data shape: {name: string, insert_before?: string, insert_after?: string}
export def "sections updateSection" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, name, project, project.name, projects, projects.name])
  --data: record # shape: {name: string, insert_before?: string, insert_after?: string}
]: any -> record<data: record<gid: string, resource_type: string, name: string, created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/sections/($section_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sections/($section_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, name, offset, path, project, project.name, projects, projects.name, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/sections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a section in a project
#
# POST /projects/{project_gid}/sections
# operationId: createSectionForProject
# --data shape: {name: string, insert_before?: string, insert_after?: string}
export def "projects-sections createSectionForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, name, project, project.name, projects, projects.name])
  --data: record # shape: {name: string, insert_before?: string, insert_after?: string}
]: any -> record<data: record<gid: string, resource_type: string, name: string, created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/sections" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add task to section
#
# POST /sections/{section_gid}/addTask
# operationId: addTaskForSection
# --data shape: {task: string, insert_before?: string, insert_after?: string}
export def "sections-add-task addTaskForSection" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {task: string, insert_before?: string, insert_after?: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sections/($section_gid)/addTask" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move or Insert sections
#
# POST /projects/{project_gid}/sections/insert
# operationId: insertSectionForProject
# --data shape: {section: string, before_section?: string, after_section?: string}
export def "projects-sections-insert insertSectionForProject" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {section: string, before_section?: string, after_section?: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/sections/insert" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a status update
#
# GET /status_updates/{status_update_gid}
# operationId: getStatus
export def "status-updates get" [
  status_update_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [author, author.name, created_at, created_by, created_by.name, hearted, hearts, hearts.user, hearts.user.name, html_text, liked, likes, likes.user, likes.user.name, modified_at, num_hearts, num_likes, parent, parent.name, reaction_summary, reaction_summary.count, reaction_summary.emoji_base, reaction_summary.reacted, reaction_summary.variant, resource_subtype, status_type, text, title])
]: nothing -> record<data: record<author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, liked: bool, likes: list<record>, reaction_summary: list<record>, modified_at: string, num_hearts: int, num_likes: int, parent: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_updates/($status_update_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a status update
#
# DELETE /status_updates/{status_update_gid}
# operationId: deleteStatus
export def "status-updates delete" [
  status_update_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/status_updates/($status_update_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --parent: string # Globally unique identifier for object to fetch statuses from. Must be a GID for a project, portfolio, or goal. (e.g. 159874)
  --created-since: string # Only return statuses that have been created since the given time. (format: date-time, e.g. 2012-02-22T02:06:58.158Z)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [author, author.name, created_at, created_by, created_by.name, hearted, hearts, hearts.user, hearts.user.name, html_text, liked, likes, likes.user, likes.user.name, modified_at, num_hearts, num_likes, offset, parent, parent.name, path, reaction_summary, reaction_summary.count, reaction_summary.emoji_base, reaction_summary.reacted, reaction_summary.variant, resource_subtype, status_type, text, title, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, title: string, resource_subtype: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "created_since" $created_since "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/status_updates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [author, author.name, created_at, created_by, created_by.name, hearted, hearts, hearts.user, hearts.user.name, html_text, liked, likes, likes.user, likes.user.name, modified_at, num_hearts, num_likes, parent, parent.name, reaction_summary, reaction_summary.count, reaction_summary.emoji_base, reaction_summary.reacted, reaction_summary.variant, resource_subtype, status_type, text, title])
  --data: any
]: any -> record<data: record<author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, liked: bool, likes: list<record>, reaction_summary: list<record>, modified_at: string, num_hearts: int, num_likes: int, parent: record<gid: string, resource_type: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/status_updates" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a story
#
# GET /stories/{story_gid}
# operationId: getStory
export def "stories get" [
  story_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [assignee, assignee.name, created_at, created_by, created_by.name, custom_field, custom_field.date_value, custom_field.date_value.date, custom_field.date_value.date_time, custom_field.display_value, custom_field.enabled, custom_field.enum_options, custom_field.enum_options.color, custom_field.enum_options.enabled, custom_field.enum_options.name, custom_field.enum_value, custom_field.enum_value.color, custom_field.enum_value.enabled, custom_field.enum_value.name, custom_field.id_prefix, custom_field.input_restrictions, custom_field.is_formula_field, custom_field.multi_enum_values, custom_field.multi_enum_values.color, custom_field.multi_enum_values.enabled, custom_field.multi_enum_values.name, custom_field.name, custom_field.number_value, custom_field.representation_type, custom_field.text_value, custom_field.type, dependency, dependency.created_by, dependency.name, dependency.resource_subtype, duplicate_of, duplicate_of.created_by, duplicate_of.name, duplicate_of.resource_subtype, duplicated_from, duplicated_from.created_by, duplicated_from.name, duplicated_from.resource_subtype, follower, follower.name, hearted, hearts, hearts.user, hearts.user.name, html_text, is_editable, is_edited, is_pinned, liked, likes, likes.user, likes.user.name, new_approval_status, new_date_value, new_dates, new_dates.due_at, new_dates.due_on, new_dates.start_on, new_enum_value, new_enum_value.color, new_enum_value.enabled, new_enum_value.name, new_multi_enum_values, new_multi_enum_values.color, new_multi_enum_values.enabled, new_multi_enum_values.name, new_name, new_number_value, new_people_value, new_people_value.name, new_resource_subtype, new_section, new_section.name, new_text_value, num_hearts, num_likes, old_approval_status, old_date_value, old_dates, old_dates.due_at, old_dates.due_on, old_dates.start_on, old_enum_value, old_enum_value.color, old_enum_value.enabled, old_enum_value.name, old_multi_enum_values, old_multi_enum_values.color, old_multi_enum_values.enabled, old_multi_enum_values.name, old_name, old_number_value, old_people_value, old_people_value.name, old_resource_subtype, old_section, old_section.name, old_text_value, previews, previews.fallback, previews.footer, previews.header, previews.header_link, previews.html_text, previews.text, previews.title, previews.title_link, project, project.name, reaction_summary, reaction_summary.count, reaction_summary.emoji_base, reaction_summary.reacted, reaction_summary.variant, resource_subtype, source, sticker_name, story, story.created_at, story.created_by, story.created_by.name, story.resource_subtype, story.text, tag, tag.name, target, target.created_by, target.name, target.resource_subtype, task, task.created_by, task.name, task.resource_subtype, text, type])
]: nothing -> record<data: record<gid: string, resource_type: string, created_at: string, resource_subtype: string, text: string, html_text: string, is_pinned: bool, sticker_name: string, created_by: record<gid: string, resource_type: string, name: string>, type: string, is_editable: bool, is_edited: bool, hearted: bool, hearts: list<record>, num_hearts: int, liked: bool, likes: list<record>, num_likes: int, reaction_summary: list<record>, previews: list<record>, old_name: string, new_name: string, old_dates: record<start_on: string, due_at: string, due_on: string>, new_dates: record<start_on: string, due_at: string, due_on: string>, old_resource_subtype: string, new_resource_subtype: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, assignee: record<gid: string, resource_type: string, name: string>, follower: record<gid: string, resource_type: string, name: string>, old_section: record<gid: string, resource_type: string, name: string>, new_section: record<gid: string, resource_type: string, name: string>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, project: record<gid: string, resource_type: string, name: string>, tag: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, name: string, type: string, enum_options: list, enabled: bool, representation_type: string, id_prefix: string, input_restrictions: list, is_formula_field: bool, date_value: record, enum_value: record, multi_enum_values: list, number_value: float, text_value: string, display_value: string>, old_text_value: string, new_text_value: string, old_number_value: int, new_number_value: int, old_enum_value: record<gid: string, resource_type: string, name: string, enabled: bool, color: string>, new_enum_value: record<gid: string, resource_type: string, name: string, enabled: bool, color: string>, old_date_value: record<start_on: string, due_at: string, due_on: string>, new_date_value: record<start_on: string, due_at: string, due_on: string>, old_people_value: list<record>, new_people_value: list<record>, old_multi_enum_values: list<record>, new_multi_enum_values: list<record>, new_approval_status: string, old_approval_status: string, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, source: string, target: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/stories/($story_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a story
#
# PUT /stories/{story_gid}
# operationId: updateStory
# --data shape: {text?: string, html_text?: string, is_pinned?: bool, sticker_name?: "green_checkmark"|"people_dancing"|"dancing_unicorn"|"heart"|"party_popper"|"people_waving_flags"|"splashing_narwhal"|"trophy"|"yeti_riding_unicorn"|"celebrating_people"|"determined_climbers"|"phoenix_spreading_love"}
export def "stories updateStory" [
  story_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [assignee, assignee.name, created_at, created_by, created_by.name, custom_field, custom_field.date_value, custom_field.date_value.date, custom_field.date_value.date_time, custom_field.display_value, custom_field.enabled, custom_field.enum_options, custom_field.enum_options.color, custom_field.enum_options.enabled, custom_field.enum_options.name, custom_field.enum_value, custom_field.enum_value.color, custom_field.enum_value.enabled, custom_field.enum_value.name, custom_field.id_prefix, custom_field.input_restrictions, custom_field.is_formula_field, custom_field.multi_enum_values, custom_field.multi_enum_values.color, custom_field.multi_enum_values.enabled, custom_field.multi_enum_values.name, custom_field.name, custom_field.number_value, custom_field.representation_type, custom_field.text_value, custom_field.type, dependency, dependency.created_by, dependency.name, dependency.resource_subtype, duplicate_of, duplicate_of.created_by, duplicate_of.name, duplicate_of.resource_subtype, duplicated_from, duplicated_from.created_by, duplicated_from.name, duplicated_from.resource_subtype, follower, follower.name, hearted, hearts, hearts.user, hearts.user.name, html_text, is_editable, is_edited, is_pinned, liked, likes, likes.user, likes.user.name, new_approval_status, new_date_value, new_dates, new_dates.due_at, new_dates.due_on, new_dates.start_on, new_enum_value, new_enum_value.color, new_enum_value.enabled, new_enum_value.name, new_multi_enum_values, new_multi_enum_values.color, new_multi_enum_values.enabled, new_multi_enum_values.name, new_name, new_number_value, new_people_value, new_people_value.name, new_resource_subtype, new_section, new_section.name, new_text_value, num_hearts, num_likes, old_approval_status, old_date_value, old_dates, old_dates.due_at, old_dates.due_on, old_dates.start_on, old_enum_value, old_enum_value.color, old_enum_value.enabled, old_enum_value.name, old_multi_enum_values, old_multi_enum_values.color, old_multi_enum_values.enabled, old_multi_enum_values.name, old_name, old_number_value, old_people_value, old_people_value.name, old_resource_subtype, old_section, old_section.name, old_text_value, previews, previews.fallback, previews.footer, previews.header, previews.header_link, previews.html_text, previews.text, previews.title, previews.title_link, project, project.name, reaction_summary, reaction_summary.count, reaction_summary.emoji_base, reaction_summary.reacted, reaction_summary.variant, resource_subtype, source, sticker_name, story, story.created_at, story.created_by, story.created_by.name, story.resource_subtype, story.text, tag, tag.name, target, target.created_by, target.name, target.resource_subtype, task, task.created_by, task.name, task.resource_subtype, text, type])
  --data: record # A story represents an activity associated with an object in the Asana system. — shape: {text?: string, html_text?: string, is_pinned?: bool, sticker_name?: "green_checkmark"|"people_dancing"|"dancing_unicorn"|"heart"|"party_popper"|"people_waving_flags"|"splashing_narwhal"|"trophy"|"yeti_riding_unicorn"|"celebrating_people"|"determined_climbers"|"phoenix_spreading_love"}
]: any -> record<data: record<gid: string, resource_type: string, created_at: string, resource_subtype: string, text: string, html_text: string, is_pinned: bool, sticker_name: string, created_by: record<gid: string, resource_type: string, name: string>, type: string, is_editable: bool, is_edited: bool, hearted: bool, hearts: list<record>, num_hearts: int, liked: bool, likes: list<record>, num_likes: int, reaction_summary: list<record>, previews: list<record>, old_name: string, new_name: string, old_dates: record<start_on: string, due_at: string, due_on: string>, new_dates: record<start_on: string, due_at: string, due_on: string>, old_resource_subtype: string, new_resource_subtype: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, assignee: record<gid: string, resource_type: string, name: string>, follower: record<gid: string, resource_type: string, name: string>, old_section: record<gid: string, resource_type: string, name: string>, new_section: record<gid: string, resource_type: string, name: string>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, project: record<gid: string, resource_type: string, name: string>, tag: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, name: string, type: string, enum_options: list, enabled: bool, representation_type: string, id_prefix: string, input_restrictions: list, is_formula_field: bool, date_value: record, enum_value: record, multi_enum_values: list, number_value: float, text_value: string, display_value: string>, old_text_value: string, new_text_value: string, old_number_value: int, new_number_value: int, old_enum_value: record<gid: string, resource_type: string, name: string, enabled: bool, color: string>, new_enum_value: record<gid: string, resource_type: string, name: string, enabled: bool, color: string>, old_date_value: record<start_on: string, due_at: string, due_on: string>, new_date_value: record<start_on: string, due_at: string, due_on: string>, old_people_value: list<record>, new_people_value: list<record>, old_multi_enum_values: list<record>, new_multi_enum_values: list<record>, new_approval_status: string, old_approval_status: string, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, source: string, target: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/stories/($story_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stories/($story_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [assignee, assignee.name, created_at, created_by, created_by.name, custom_field, custom_field.date_value, custom_field.date_value.date, custom_field.date_value.date_time, custom_field.display_value, custom_field.enabled, custom_field.enum_options, custom_field.enum_options.color, custom_field.enum_options.enabled, custom_field.enum_options.name, custom_field.enum_value, custom_field.enum_value.color, custom_field.enum_value.enabled, custom_field.enum_value.name, custom_field.id_prefix, custom_field.input_restrictions, custom_field.is_formula_field, custom_field.multi_enum_values, custom_field.multi_enum_values.color, custom_field.multi_enum_values.enabled, custom_field.multi_enum_values.name, custom_field.name, custom_field.number_value, custom_field.representation_type, custom_field.text_value, custom_field.type, dependency, dependency.created_by, dependency.name, dependency.resource_subtype, duplicate_of, duplicate_of.created_by, duplicate_of.name, duplicate_of.resource_subtype, duplicated_from, duplicated_from.created_by, duplicated_from.name, duplicated_from.resource_subtype, follower, follower.name, hearted, hearts, hearts.user, hearts.user.name, html_text, is_editable, is_edited, is_pinned, liked, likes, likes.user, likes.user.name, new_approval_status, new_date_value, new_dates, new_dates.due_at, new_dates.due_on, new_dates.start_on, new_enum_value, new_enum_value.color, new_enum_value.enabled, new_enum_value.name, new_multi_enum_values, new_multi_enum_values.color, new_multi_enum_values.enabled, new_multi_enum_values.name, new_name, new_number_value, new_people_value, new_people_value.name, new_resource_subtype, new_section, new_section.name, new_text_value, num_hearts, num_likes, offset, old_approval_status, old_date_value, old_dates, old_dates.due_at, old_dates.due_on, old_dates.start_on, old_enum_value, old_enum_value.color, old_enum_value.enabled, old_enum_value.name, old_multi_enum_values, old_multi_enum_values.color, old_multi_enum_values.enabled, old_multi_enum_values.name, old_name, old_number_value, old_people_value, old_people_value.name, old_resource_subtype, old_section, old_section.name, old_text_value, path, previews, previews.fallback, previews.footer, previews.header, previews.header_link, previews.html_text, previews.text, previews.title, previews.title_link, project, project.name, reaction_summary, reaction_summary.count, reaction_summary.emoji_base, reaction_summary.reacted, reaction_summary.variant, resource_subtype, source, sticker_name, story, story.created_at, story.created_by, story.created_by.name, story.resource_subtype, story.text, tag, tag.name, target, target.created_by, target.name, target.resource_subtype, task, task.created_by, task.name, task.resource_subtype, text, type, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/stories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a story on a task
#
# POST /tasks/{task_gid}/stories
# operationId: createStoryForTask
# --data shape: {text?: string, html_text?: string, is_pinned?: bool, sticker_name?: "green_checkmark"|"people_dancing"|"dancing_unicorn"|"heart"|"party_popper"|"people_waving_flags"|"splashing_narwhal"|"trophy"|"yeti_riding_unicorn"|"celebrating_people"|"determined_climbers"|"phoenix_spreading_love"}
export def "tasks-stories createStoryForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [assignee, assignee.name, created_at, created_by, created_by.name, custom_field, custom_field.date_value, custom_field.date_value.date, custom_field.date_value.date_time, custom_field.display_value, custom_field.enabled, custom_field.enum_options, custom_field.enum_options.color, custom_field.enum_options.enabled, custom_field.enum_options.name, custom_field.enum_value, custom_field.enum_value.color, custom_field.enum_value.enabled, custom_field.enum_value.name, custom_field.id_prefix, custom_field.input_restrictions, custom_field.is_formula_field, custom_field.multi_enum_values, custom_field.multi_enum_values.color, custom_field.multi_enum_values.enabled, custom_field.multi_enum_values.name, custom_field.name, custom_field.number_value, custom_field.representation_type, custom_field.text_value, custom_field.type, dependency, dependency.created_by, dependency.name, dependency.resource_subtype, duplicate_of, duplicate_of.created_by, duplicate_of.name, duplicate_of.resource_subtype, duplicated_from, duplicated_from.created_by, duplicated_from.name, duplicated_from.resource_subtype, follower, follower.name, hearted, hearts, hearts.user, hearts.user.name, html_text, is_editable, is_edited, is_pinned, liked, likes, likes.user, likes.user.name, new_approval_status, new_date_value, new_dates, new_dates.due_at, new_dates.due_on, new_dates.start_on, new_enum_value, new_enum_value.color, new_enum_value.enabled, new_enum_value.name, new_multi_enum_values, new_multi_enum_values.color, new_multi_enum_values.enabled, new_multi_enum_values.name, new_name, new_number_value, new_people_value, new_people_value.name, new_resource_subtype, new_section, new_section.name, new_text_value, num_hearts, num_likes, old_approval_status, old_date_value, old_dates, old_dates.due_at, old_dates.due_on, old_dates.start_on, old_enum_value, old_enum_value.color, old_enum_value.enabled, old_enum_value.name, old_multi_enum_values, old_multi_enum_values.color, old_multi_enum_values.enabled, old_multi_enum_values.name, old_name, old_number_value, old_people_value, old_people_value.name, old_resource_subtype, old_section, old_section.name, old_text_value, previews, previews.fallback, previews.footer, previews.header, previews.header_link, previews.html_text, previews.text, previews.title, previews.title_link, project, project.name, reaction_summary, reaction_summary.count, reaction_summary.emoji_base, reaction_summary.reacted, reaction_summary.variant, resource_subtype, source, sticker_name, story, story.created_at, story.created_by, story.created_by.name, story.resource_subtype, story.text, tag, tag.name, target, target.created_by, target.name, target.resource_subtype, task, task.created_by, task.name, task.resource_subtype, text, type])
  --data: record # A story represents an activity associated with an object in the Asana system. — shape: {text?: string, html_text?: string, is_pinned?: bool, sticker_name?: "green_checkmark"|"people_dancing"|"dancing_unicorn"|"heart"|"party_popper"|"people_waving_flags"|"splashing_narwhal"|"trophy"|"yeti_riding_unicorn"|"celebrating_people"|"determined_climbers"|"phoenix_spreading_love"}
]: any -> record<data: record<gid: string, resource_type: string, created_at: string, resource_subtype: string, text: string, html_text: string, is_pinned: bool, sticker_name: string, created_by: record<gid: string, resource_type: string, name: string>, type: string, is_editable: bool, is_edited: bool, hearted: bool, hearts: list<record>, num_hearts: int, liked: bool, likes: list<record>, num_likes: int, reaction_summary: list<record>, previews: list<record>, old_name: string, new_name: string, old_dates: record<start_on: string, due_at: string, due_on: string>, new_dates: record<start_on: string, due_at: string, due_on: string>, old_resource_subtype: string, new_resource_subtype: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, assignee: record<gid: string, resource_type: string, name: string>, follower: record<gid: string, resource_type: string, name: string>, old_section: record<gid: string, resource_type: string, name: string>, new_section: record<gid: string, resource_type: string, name: string>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, project: record<gid: string, resource_type: string, name: string>, tag: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, name: string, type: string, enum_options: list, enabled: bool, representation_type: string, id_prefix: string, input_restrictions: list, is_formula_field: bool, date_value: record, enum_value: record, multi_enum_values: list, number_value: float, text_value: string, display_value: string>, old_text_value: string, new_text_value: string, old_number_value: int, new_number_value: int, old_enum_value: record<gid: string, resource_type: string, name: string, enabled: bool, color: string>, new_enum_value: record<gid: string, resource_type: string, name: string, enabled: bool, color: string>, old_date_value: record<start_on: string, due_at: string, due_on: string>, new_date_value: record<start_on: string, due_at: string, due_on: string>, old_people_value: list<record>, new_people_value: list<record>, old_multi_enum_values: list<record>, new_multi_enum_values: list<record>, new_approval_status: string, old_approval_status: string, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, source: string, target: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/stories" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get stories from a goal
#
# GET /goals/{goal_gid}/stories
# operationId: getStoriesForGoal
export def "goals-stories get" [
  goal_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [assignee, assignee.name, created_at, created_by, created_by.name, custom_field, custom_field.date_value, custom_field.date_value.date, custom_field.date_value.date_time, custom_field.display_value, custom_field.enabled, custom_field.enum_options, custom_field.enum_options.color, custom_field.enum_options.enabled, custom_field.enum_options.name, custom_field.enum_value, custom_field.enum_value.color, custom_field.enum_value.enabled, custom_field.enum_value.name, custom_field.id_prefix, custom_field.input_restrictions, custom_field.is_formula_field, custom_field.multi_enum_values, custom_field.multi_enum_values.color, custom_field.multi_enum_values.enabled, custom_field.multi_enum_values.name, custom_field.name, custom_field.number_value, custom_field.representation_type, custom_field.text_value, custom_field.type, dependency, dependency.created_by, dependency.name, dependency.resource_subtype, duplicate_of, duplicate_of.created_by, duplicate_of.name, duplicate_of.resource_subtype, duplicated_from, duplicated_from.created_by, duplicated_from.name, duplicated_from.resource_subtype, follower, follower.name, hearted, hearts, hearts.user, hearts.user.name, html_text, is_editable, is_edited, is_pinned, liked, likes, likes.user, likes.user.name, new_approval_status, new_date_value, new_dates, new_dates.due_at, new_dates.due_on, new_dates.start_on, new_enum_value, new_enum_value.color, new_enum_value.enabled, new_enum_value.name, new_multi_enum_values, new_multi_enum_values.color, new_multi_enum_values.enabled, new_multi_enum_values.name, new_name, new_number_value, new_people_value, new_people_value.name, new_resource_subtype, new_section, new_section.name, new_text_value, num_hearts, num_likes, offset, old_approval_status, old_date_value, old_dates, old_dates.due_at, old_dates.due_on, old_dates.start_on, old_enum_value, old_enum_value.color, old_enum_value.enabled, old_enum_value.name, old_multi_enum_values, old_multi_enum_values.color, old_multi_enum_values.enabled, old_multi_enum_values.name, old_name, old_number_value, old_people_value, old_people_value.name, old_resource_subtype, old_section, old_section.name, old_text_value, path, previews, previews.fallback, previews.footer, previews.header, previews.header_link, previews.html_text, previews.text, previews.title, previews.title_link, project, project.name, reaction_summary, reaction_summary.count, reaction_summary.emoji_base, reaction_summary.reacted, reaction_summary.variant, resource_subtype, source, sticker_name, story, story.created_at, story.created_by, story.created_by.name, story.resource_subtype, story.text, tag, tag.name, target, target.created_by, target.name, target.resource_subtype, task, task.created_by, task.name, task.resource_subtype, text, type, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/stories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a story on a goal
#
# POST /goals/{goal_gid}/stories
# operationId: createStoryForGoal
# --data shape: {text?: string, html_text?: string, is_pinned?: bool, sticker_name?: "green_checkmark"|"people_dancing"|"dancing_unicorn"|"heart"|"party_popper"|"people_waving_flags"|"splashing_narwhal"|"trophy"|"yeti_riding_unicorn"|"celebrating_people"|"determined_climbers"|"phoenix_spreading_love"}
export def "goals-stories createStoryForGoal" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [assignee, assignee.name, created_at, created_by, created_by.name, custom_field, custom_field.date_value, custom_field.date_value.date, custom_field.date_value.date_time, custom_field.display_value, custom_field.enabled, custom_field.enum_options, custom_field.enum_options.color, custom_field.enum_options.enabled, custom_field.enum_options.name, custom_field.enum_value, custom_field.enum_value.color, custom_field.enum_value.enabled, custom_field.enum_value.name, custom_field.id_prefix, custom_field.input_restrictions, custom_field.is_formula_field, custom_field.multi_enum_values, custom_field.multi_enum_values.color, custom_field.multi_enum_values.enabled, custom_field.multi_enum_values.name, custom_field.name, custom_field.number_value, custom_field.representation_type, custom_field.text_value, custom_field.type, dependency, dependency.created_by, dependency.name, dependency.resource_subtype, duplicate_of, duplicate_of.created_by, duplicate_of.name, duplicate_of.resource_subtype, duplicated_from, duplicated_from.created_by, duplicated_from.name, duplicated_from.resource_subtype, follower, follower.name, hearted, hearts, hearts.user, hearts.user.name, html_text, is_editable, is_edited, is_pinned, liked, likes, likes.user, likes.user.name, new_approval_status, new_date_value, new_dates, new_dates.due_at, new_dates.due_on, new_dates.start_on, new_enum_value, new_enum_value.color, new_enum_value.enabled, new_enum_value.name, new_multi_enum_values, new_multi_enum_values.color, new_multi_enum_values.enabled, new_multi_enum_values.name, new_name, new_number_value, new_people_value, new_people_value.name, new_resource_subtype, new_section, new_section.name, new_text_value, num_hearts, num_likes, old_approval_status, old_date_value, old_dates, old_dates.due_at, old_dates.due_on, old_dates.start_on, old_enum_value, old_enum_value.color, old_enum_value.enabled, old_enum_value.name, old_multi_enum_values, old_multi_enum_values.color, old_multi_enum_values.enabled, old_multi_enum_values.name, old_name, old_number_value, old_people_value, old_people_value.name, old_resource_subtype, old_section, old_section.name, old_text_value, previews, previews.fallback, previews.footer, previews.header, previews.header_link, previews.html_text, previews.text, previews.title, previews.title_link, project, project.name, reaction_summary, reaction_summary.count, reaction_summary.emoji_base, reaction_summary.reacted, reaction_summary.variant, resource_subtype, source, sticker_name, story, story.created_at, story.created_by, story.created_by.name, story.resource_subtype, story.text, tag, tag.name, target, target.created_by, target.name, target.resource_subtype, task, task.created_by, task.name, task.resource_subtype, text, type])
  --data: record # A story represents an activity associated with an object in the Asana system. — shape: {text?: string, html_text?: string, is_pinned?: bool, sticker_name?: "green_checkmark"|"people_dancing"|"dancing_unicorn"|"heart"|"party_popper"|"people_waving_flags"|"splashing_narwhal"|"trophy"|"yeti_riding_unicorn"|"celebrating_people"|"determined_climbers"|"phoenix_spreading_love"}
]: any -> record<data: record<gid: string, resource_type: string, created_at: string, resource_subtype: string, text: string, html_text: string, is_pinned: bool, sticker_name: string, created_by: record<gid: string, resource_type: string, name: string>, type: string, is_editable: bool, is_edited: bool, hearted: bool, hearts: list<record>, num_hearts: int, liked: bool, likes: list<record>, num_likes: int, reaction_summary: list<record>, previews: list<record>, old_name: string, new_name: string, old_dates: record<start_on: string, due_at: string, due_on: string>, new_dates: record<start_on: string, due_at: string, due_on: string>, old_resource_subtype: string, new_resource_subtype: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, assignee: record<gid: string, resource_type: string, name: string>, follower: record<gid: string, resource_type: string, name: string>, old_section: record<gid: string, resource_type: string, name: string>, new_section: record<gid: string, resource_type: string, name: string>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, project: record<gid: string, resource_type: string, name: string>, tag: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, name: string, type: string, enum_options: list, enabled: bool, representation_type: string, id_prefix: string, input_restrictions: list, is_formula_field: bool, date_value: record, enum_value: record, multi_enum_values: list, number_value: float, text_value: string, display_value: string>, old_text_value: string, new_text_value: string, old_number_value: int, new_number_value: int, old_enum_value: record<gid: string, resource_type: string, name: string, enabled: bool, color: string>, new_enum_value: record<gid: string, resource_type: string, name: string, enabled: bool, color: string>, old_date_value: record<start_on: string, due_at: string, due_on: string>, new_date_value: record<start_on: string, due_at: string, due_on: string>, old_people_value: list<record>, new_people_value: list<record>, old_multi_enum_values: list<record>, new_multi_enum_values: list<record>, new_approval_status: string, old_approval_status: string, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, source: string, target: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/goals/($goal_gid)/stories" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace to filter tags on. (e.g. 1331)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, created_at, followers, followers.name, name, notes, offset, path, permalink_url, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, created_at, followers, followers.name, name, notes, permalink_url, workspace, workspace.name])
  --data: any
]: any -> record<data: record<created_at: string, followers: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, created_at, followers, followers.name, name, notes, permalink_url, workspace, workspace.name])
]: nothing -> record<data: record<created_at: string, followers: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tag_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, created_at, followers, followers.name, name, notes, permalink_url, workspace, workspace.name])
  --data: any
]: any -> record<data: record<created_at: string, followers: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tag_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tag_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, created_at, followers, followers.name, name, notes, offset, path, permalink_url, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, created_at, followers, followers.name, name, notes, offset, path, permalink_url, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, created_at, followers, followers.name, name, notes, permalink_url, workspace, workspace.name])
  --data: any
]: any -> record<data: record<created_at: string, followers: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/tags" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get multiple task templates
#
# GET /task_templates
# operationId: getTaskTemplates
export def "task-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --project: string # The project to filter task templates on. (e.g. 321654)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, created_by, name, project, template])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/task_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a task template
#
# GET /task_templates/{task_template_gid}
# operationId: getTaskTemplate
export def "task-templates get" [
  task_template_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, created_by, name, project, template])
]: nothing -> record<data: record<name: string, project: record<gid: string, resource_type: string, name: string>, template: record, created_by: record<gid: string, resource_type: string, name: string>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/task_templates/($task_template_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a task template
#
# DELETE /task_templates/{task_template_gid}
# operationId: deleteTaskTemplate
export def "task-templates delete" [
  task_template_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/task_templates/($task_template_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Instantiate a task from a task template
#
# POST /task_templates/{task_template_gid}/instantiateTask
# operationId: instantiateTask
# --data shape: {name?: string}
export def "task-templates-instantiate-task instantiateTask" [
  task_template_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [new_graph_export, new_graph_export.completed_at, new_graph_export.created_at, new_graph_export.download_url, new_portfolio, new_portfolio.name, new_project, new_project.name, new_project_template, new_project_template.name, new_resource_export, new_resource_export.completed_at, new_resource_export.created_at, new_resource_export.download_url, new_task, new_task.created_by, new_task.name, new_task.resource_subtype, resource_subtype, status])
  --data: record # shape: {name?: string}
]: any -> record<data: record<gid: string, resource_type: string, resource_subtype: string, status: string, new_portfolio: record<gid: string, resource_type: string, name: string>, new_project: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, new_project_template: record<gid: string, resource_type: string, name: string>, new_graph_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>, new_resource_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/task_templates/($task_template_gid)/instantiateTask" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --assignee: string # The assignee to filter tasks on. If searching for unassigned tasks, assignee.any = null can be specified. *Note: If you specify `assignee`, you must also specify the `workspace` to filter on.* (e.g. 14641)
  --project: string # The project to filter tasks on. (e.g. 321654)
  --section: string # The section to filter tasks on. (e.g. 321654)
  --workspace: string # The workspace to filter tasks on. *Note: If you specify `workspace`, you must also specify the `assignee` to filter on.* (e.g. 321654)
  --completed-since: string # Only return tasks that are either incomplete or that have been completed since this time. (format: date-time, e.g. 2012-02-22T02:06:58.158Z)
  --modified-since: string # Only return tasks that have been modified since the given time.  *Note: A task is considered “modified” if any of its properties change, or associations between it and other objects are modified (e.g.  a task being added to a project). A task is not considered modified just because another object it is associated with (e.g. a subtask) is modified. Actions that count as modifying the task include assigning, renaming, completing, and adding stories.* (format: date-time, e.g. 2012-02-22T02:06:58.158Z)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, offset, parent, parent.created_by, parent.name, parent.resource_subtype, path, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "assignee" $assignee "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "section" $section "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "completed_since" $completed_since "scalar") (serialize-qp "modified_since" $modified_since "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, parent, parent.created_by, parent.name, parent.resource_subtype, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, workspace, workspace.name])
  --data: any
]: any -> record<data: record<assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, custom_type: record<gid: string, resource_type: string, name: string>, custom_type_status_option: record<gid: string, resource_type: string, name: string>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, parent, parent.created_by, parent.name, parent.resource_subtype, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, workspace, workspace.name])
]: nothing -> record<data: record<assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, custom_type: record<gid: string, resource_type: string, name: string>, custom_type_status_option: record<gid: string, resource_type: string, name: string>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, parent, parent.created_by, parent.name, parent.resource_subtype, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, workspace, workspace.name])
  --data: any
]: any -> record<data: record<assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, custom_type: record<gid: string, resource_type: string, name: string>, custom_type_status_option: record<gid: string, resource_type: string, name: string>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Duplicate a task
#
# POST /tasks/{task_gid}/duplicate
# operationId: duplicateTask
# --data shape: {name?: string, include?: string}
export def "tasks-duplicate duplicateTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [new_graph_export, new_graph_export.completed_at, new_graph_export.created_at, new_graph_export.download_url, new_portfolio, new_portfolio.name, new_project, new_project.name, new_project_template, new_project_template.name, new_resource_export, new_resource_export.completed_at, new_resource_export.created_at, new_resource_export.download_url, new_task, new_task.created_by, new_task.name, new_task.resource_subtype, resource_subtype, status])
  --data: record # shape: {name?: string, include?: string}
]: any -> record<data: record<gid: string, resource_type: string, resource_subtype: string, status: string, new_portfolio: record<gid: string, resource_type: string, name: string>, new_project: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, new_project_template: record<gid: string, resource_type: string, name: string>, new_graph_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>, new_resource_export: record<gid: string, resource_type: string, created_at: string, download_url: string, completed_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/duplicate" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --completed-since: string # Only return tasks that are either incomplete or that have been completed since this time. Accepts a date-time string or the keyword *now*.  (e.g. 2012-02-22T02:06:58.158Z)
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, offset, parent, parent.created_by, parent.name, parent.resource_subtype, path, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "completed_since" $completed_since "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_gid)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --completed-since: string # Only return tasks that are either incomplete or that have been completed since this time. Accepts a date-time string or the keyword *now*.  (e.g. 2012-02-22T02:06:58.158Z)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, offset, parent, parent.created_by, parent.name, parent.resource_subtype, path, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "completed_since" $completed_since "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/sections/($section_gid)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, offset, parent, parent.created_by, parent.name, parent.resource_subtype, path, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tag_gid)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --completed-since: string # Only return tasks that are either incomplete or that have been completed since this time. Accepts a date-time string or the keyword *now*.  (e.g. 2012-02-22T02:06:58.158Z)
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, offset, parent, parent.created_by, parent.name, parent.resource_subtype, path, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "completed_since" $completed_since "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_task_lists/($user_task_list_gid)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, offset, parent, parent.created_by, parent.name, parent.resource_subtype, path, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/subtasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, parent, parent.created_by, parent.name, parent.resource_subtype, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, workspace, workspace.name])
  --data: any
]: any -> record<data: record<assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, custom_type: record<gid: string, resource_type: string, name: string>, custom_type_status_option: record<gid: string, resource_type: string, name: string>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/subtasks" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set the parent of a task
#
# POST /tasks/{task_gid}/setParent
# operationId: setParentForTask
# --data shape: {parent: string, insert_after?: string, insert_before?: string}
export def "tasks-set-parent setParentForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, parent, parent.created_by, parent.name, parent.resource_subtype, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, workspace, workspace.name])
  --data: record # shape: {parent: string, insert_after?: string, insert_before?: string}
]: any -> record<data: record<assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, custom_type: record<gid: string, resource_type: string, name: string>, custom_type_status_option: record<gid: string, resource_type: string, name: string>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/setParent" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, offset, parent, parent.created_by, parent.name, parent.resource_subtype, path, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/dependencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # e.g. {dependencies: [133713, 184253]} — shape: {dependencies?: list}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/addDependencies" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # e.g. {dependencies: [133713, 184253]} — shape: {dependencies?: list}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/removeDependencies" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, offset, parent, parent.created_by, parent.name, parent.resource_subtype, path, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, uri, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/dependents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # A set of dependent tasks. (e.g. {dependents: [133713, 184253]}) — shape: {dependents?: list}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/addDependents" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # A set of dependent tasks. (e.g. {dependents: [133713, 184253]}) — shape: {dependents?: list}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/removeDependents" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a project to a task
#
# POST /tasks/{task_gid}/addProject
# operationId: addProjectForTask
# --data shape: {project: string, insert_after?: string, insert_before?: string, section?: string}
export def "tasks-add-project addProjectForTask" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {project: string, insert_after?: string, insert_before?: string, section?: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/addProject" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {project: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/removeProject" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {tag: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/addTag" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {tag: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/removeTag" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, parent, parent.created_by, parent.name, parent.resource_subtype, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, workspace, workspace.name])
  --data: record # shape: {followers: list}
]: any -> record<data: record<assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, custom_type: record<gid: string, resource_type: string, name: string>, custom_type_status_option: record<gid: string, resource_type: string, name: string>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/addFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, parent, parent.created_by, parent.name, parent.resource_subtype, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, workspace, workspace.name])
  --data: record # shape: {followers: list}
]: any -> record<data: record<assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, custom_type: record<gid: string, resource_type: string, name: string>, custom_type_status_option: record<gid: string, resource_type: string, name: string>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/removeFollowers" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a task for a given custom ID
#
# GET /workspaces/{workspace_gid}/tasks/custom_id/{custom_id}
# operationId: getTaskForCustomID
export def "workspaces-tasks-custom-id get" [
  workspace_gid: string
  custom_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, custom_type: record<gid: string, resource_type: string, name: string>, custom_type_status_option: record<gid: string, resource_type: string, name: string>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>, permalink_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/tasks/custom_id/($custom_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --text: string # Performs full-text search on both task name and description (e.g. Bug)
  --resource-subtype: string@resource-subtype-completer-2 # Filters results by the task's resource_subtype (default: milestone)
  --assigneeany: string # Comma-separated list of user identifiers. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,23456,34567)
  --assigneenot: string # Comma-separated list of user identifiers. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,23456,34567)
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
  --followersany: string # Comma-separated list of user identifiers. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,23456,34567)
  --followersnot: string # Comma-separated list of user identifiers. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,23456,34567)
  --created-byany: string # Comma-separated list of user identifiers. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,23456,34567)
  --created-bynot: string # Comma-separated list of user identifiers. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,23456,34567)
  --assigned-byany: string # Comma-separated list of user identifiers. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,23456,34567)
  --assigned-bynot: string # Comma-separated list of user identifiers. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,23456,34567)
  --liked-bynot: string # Comma-separated list of user identifiers. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,23456,34567)
  --commented-on-bynot: string # Comma-separated list of user identifiers. This can either be the string "me", an email, or the gid of a user. (e.g. 12345,23456,34567)
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
  --is-blocking: string@bool-completer # Filter to incomplete tasks with dependents (e.g. false)
  --is-blocked: string@bool-completer # Filter to tasks with incomplete dependencies (e.g. false)
  --has-attachment: string@bool-completer # Filter to tasks with attachments (e.g. false)
  --completed: string@bool-completer # Filter to completed tasks (e.g. false)
  --is-subtask: string@bool-completer # Filter to subtasks (e.g. false)
  --sort-by: string@sort-by-completer-1 # One of `due_date`, `created_at`, `completed_at`, `likes`, `relevance`, or `modified_at`, defaults to `modified_at` (default: modified_at, e.g. likes)
  --sort-ascending: string@bool-completer # Default `false` (default: false, e.g. true)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [actual_time_minutes, approval_status, assigned_by, assigned_by.name, assignee, assignee.name, assignee_section, assignee_section.name, assignee_status, completed, completed_at, completed_by, completed_by.name, created_at, created_by, custom_fields, custom_fields.asana_created_field, custom_fields.created_by, custom_fields.created_by.name, custom_fields.currency_code, custom_fields.custom_label, custom_fields.custom_label_position, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.default_access_level, custom_fields.description, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.format, custom_fields.has_notifications_enabled, custom_fields.html_text_value, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.is_global_to_workspace, custom_fields.is_value_read_only, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.people_value, custom_fields.people_value.name, custom_fields.precision, custom_fields.privacy_setting, custom_fields.reference_value, custom_fields.reference_value.name, custom_fields.representation_type, custom_fields.resource_subtype, custom_fields.text_value, custom_fields.type, custom_type, custom_type.name, custom_type_status_option, custom_type_status_option.name, dependencies, dependents, due_at, due_on, external, external.data, followers, followers.name, hearted, hearts, hearts.user, hearts.user.name, html_notes, is_rendered_as_separator, liked, likes, likes.user, likes.user.name, memberships, memberships.project, memberships.project.name, memberships.section, memberships.section.name, modified_at, name, notes, num_hearts, num_likes, num_subtasks, parent, parent.created_by, parent.name, parent.resource_subtype, permalink_url, projects, projects.name, resource_subtype, start_at, start_on, tags, tags.name, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "resource_subtype" $resource_subtype "scalar") (serialize-qp "assignee.any" $assigneeany "scalar") (serialize-qp "assignee.not" $assigneenot "scalar") (serialize-qp "portfolios.any" $portfoliosany "scalar") (serialize-qp "projects.any" $projectsany "scalar") (serialize-qp "projects.not" $projectsnot "scalar") (serialize-qp "projects.all" $projectsall "scalar") (serialize-qp "sections.any" $sectionsany "scalar") (serialize-qp "sections.not" $sectionsnot "scalar") (serialize-qp "sections.all" $sectionsall "scalar") (serialize-qp "tags.any" $tagsany "scalar") (serialize-qp "tags.not" $tagsnot "scalar") (serialize-qp "tags.all" $tagsall "scalar") (serialize-qp "teams.any" $teamsany "scalar") (serialize-qp "followers.any" $followersany "scalar") (serialize-qp "followers.not" $followersnot "scalar") (serialize-qp "created_by.any" $created_byany "scalar") (serialize-qp "created_by.not" $created_bynot "scalar") (serialize-qp "assigned_by.any" $assigned_byany "scalar") (serialize-qp "assigned_by.not" $assigned_bynot "scalar") (serialize-qp "liked_by.not" $liked_bynot "scalar") (serialize-qp "commented_on_by.not" $commented_on_bynot "scalar") (serialize-qp "due_on.before" $due_onbefore "scalar") (serialize-qp "due_on.after" $due_onafter "scalar") (serialize-qp "due_on" $due_on "scalar") (serialize-qp "due_at.before" $due_atbefore "scalar") (serialize-qp "due_at.after" $due_atafter "scalar") (serialize-qp "start_on.before" $start_onbefore "scalar") (serialize-qp "start_on.after" $start_onafter "scalar") (serialize-qp "start_on" $start_on "scalar") (serialize-qp "created_on.before" $created_onbefore "scalar") (serialize-qp "created_on.after" $created_onafter "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "completed_on.before" $completed_onbefore "scalar") (serialize-qp "completed_on.after" $completed_onafter "scalar") (serialize-qp "completed_on" $completed_on "scalar") (serialize-qp "completed_at.before" $completed_atbefore "scalar") (serialize-qp "completed_at.after" $completed_atafter "scalar") (serialize-qp "modified_on.before" $modified_onbefore "scalar") (serialize-qp "modified_on.after" $modified_onafter "scalar") (serialize-qp "modified_on" $modified_on "scalar") (serialize-qp "modified_at.before" $modified_atbefore "scalar") (serialize-qp "modified_at.after" $modified_atafter "scalar") (serialize-qp "is_blocking" $is_blocking "scalar") (serialize-qp "is_blocked" $is_blocked "scalar") (serialize-qp "has_attachment" $has_attachment "scalar") (serialize-qp "completed" $completed "scalar") (serialize-qp "is_subtask" $is_subtask "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_ascending" $sort_ascending "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/tasks/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [is_admin, is_guest, is_limited_access, team, team.name, user, user.name])
]: nothing -> record<data: record<gid: string, resource_type: string, user: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, is_guest: bool, is_limited_access: bool, is_admin: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/team_memberships/($team_membership_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --team: string # Globally unique identifier for the team. (e.g. 159874)
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. This parameter must be used with the workspace parameter. (e.g. 512241)
  --workspace: string # Globally unique identifier for the workspace. This parameter must be used with the user parameter. (e.g. 31326)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [is_admin, is_guest, is_limited_access, offset, path, team, team.name, uri, user, user.name])
]: nothing -> record<data: table<gid: string, resource_type: string, user: record, team: record, is_guest: bool, is_limited_access: bool, is_admin: bool>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/team_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [is_admin, is_guest, is_limited_access, offset, path, team, team.name, uri, user, user.name])
]: nothing -> record<data: table<gid: string, resource_type: string, user: record, team: record, is_guest: bool, is_limited_access: bool, is_admin: bool>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/team_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # Globally unique identifier for the workspace. (e.g. 31326)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [is_admin, is_guest, is_limited_access, offset, path, team, team.name, uri, user, user.name])
]: nothing -> record<data: table<gid: string, resource_type: string, user: record, team: record, is_guest: bool, is_limited_access: bool, is_admin: bool>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)/team_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, description, edit_team_name_or_description_access_level, edit_team_visibility_or_trash_team_access_level, endorsed, guest_invite_management_access_level, html_description, join_request_management_access_level, member_invite_management_access_level, name, organization, organization.name, permalink_url, team_content_management_access_level, team_member_removal_access_level, visibility])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, name: string, description: string, html_description: string, organization: record<gid: string, resource_type: string, name: string>, permalink_url: string, visibility: string, edit_team_name_or_description_access_level: string, edit_team_visibility_or_trash_team_access_level: string, member_invite_management_access_level: string, guest_invite_management_access_level: string, join_request_management_access_level: string, team_member_removal_access_level: string, team_content_management_access_level: string, endorsed: bool, custom_field_settings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, description, edit_team_name_or_description_access_level, edit_team_visibility_or_trash_team_access_level, endorsed, guest_invite_management_access_level, html_description, join_request_management_access_level, member_invite_management_access_level, name, organization, organization.name, permalink_url, team_content_management_access_level, team_member_removal_access_level, visibility])
]: nothing -> record<data: record<gid: string, resource_type: string, name: string, description: string, html_description: string, organization: record<gid: string, resource_type: string, name: string>, permalink_url: string, visibility: string, edit_team_name_or_description_access_level: string, edit_team_visibility_or_trash_team_access_level: string, member_invite_management_access_level: string, guest_invite_management_access_level: string, join_request_management_access_level: string, team_member_removal_access_level: string, team_content_management_access_level: string, endorsed: bool, custom_field_settings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a team
#
# PUT /teams/{team_gid}
# operationId: updateTeam
export def "teams updateTeam" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, description, edit_team_name_or_description_access_level, edit_team_visibility_or_trash_team_access_level, endorsed, guest_invite_management_access_level, html_description, join_request_management_access_level, member_invite_management_access_level, name, organization, organization.name, permalink_url, team_content_management_access_level, team_member_removal_access_level, visibility])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, name: string, description: string, html_description: string, organization: record<gid: string, resource_type: string, name: string>, permalink_url: string, visibility: string, edit_team_name_or_description_access_level: string, edit_team_visibility_or_trash_team_access_level: string, member_invite_management_access_level: string, guest_invite_management_access_level: string, join_request_management_access_level: string, team_member_removal_access_level: string, team_content_management_access_level: string, endorsed: bool, custom_field_settings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, description, edit_team_name_or_description_access_level, edit_team_visibility_or_trash_team_access_level, endorsed, guest_invite_management_access_level, html_description, join_request_management_access_level, member_invite_management_access_level, name, offset, organization, organization.name, path, permalink_url, team_content_management_access_level, team_member_removal_access_level, uri, visibility])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --organization: string # The workspace or organization to filter teams on. (e.g. 1331)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_field_settings, custom_field_settings.custom_field, custom_field_settings.custom_field.asana_created_field, custom_field_settings.custom_field.created_by, custom_field_settings.custom_field.created_by.name, custom_field_settings.custom_field.currency_code, custom_field_settings.custom_field.custom_label, custom_field_settings.custom_field.custom_label_position, custom_field_settings.custom_field.date_value, custom_field_settings.custom_field.date_value.date, custom_field_settings.custom_field.date_value.date_time, custom_field_settings.custom_field.default_access_level, custom_field_settings.custom_field.description, custom_field_settings.custom_field.display_value, custom_field_settings.custom_field.enabled, custom_field_settings.custom_field.enum_options, custom_field_settings.custom_field.enum_options.color, custom_field_settings.custom_field.enum_options.enabled, custom_field_settings.custom_field.enum_options.name, custom_field_settings.custom_field.enum_value, custom_field_settings.custom_field.enum_value.color, custom_field_settings.custom_field.enum_value.enabled, custom_field_settings.custom_field.enum_value.name, custom_field_settings.custom_field.format, custom_field_settings.custom_field.has_notifications_enabled, custom_field_settings.custom_field.html_text_value, custom_field_settings.custom_field.id_prefix, custom_field_settings.custom_field.input_restrictions, custom_field_settings.custom_field.is_formula_field, custom_field_settings.custom_field.is_global_to_workspace, custom_field_settings.custom_field.is_value_read_only, custom_field_settings.custom_field.multi_enum_values, custom_field_settings.custom_field.multi_enum_values.color, custom_field_settings.custom_field.multi_enum_values.enabled, custom_field_settings.custom_field.multi_enum_values.name, custom_field_settings.custom_field.name, custom_field_settings.custom_field.number_value, custom_field_settings.custom_field.people_value, custom_field_settings.custom_field.people_value.name, custom_field_settings.custom_field.precision, custom_field_settings.custom_field.privacy_setting, custom_field_settings.custom_field.reference_value, custom_field_settings.custom_field.reference_value.name, custom_field_settings.custom_field.representation_type, custom_field_settings.custom_field.resource_subtype, custom_field_settings.custom_field.text_value, custom_field_settings.custom_field.type, custom_field_settings.is_important, custom_field_settings.parent, custom_field_settings.parent.name, custom_field_settings.project, custom_field_settings.project.name, description, edit_team_name_or_description_access_level, edit_team_visibility_or_trash_team_access_level, endorsed, guest_invite_management_access_level, html_description, join_request_management_access_level, member_invite_management_access_level, name, offset, organization, organization.name, path, permalink_url, team_content_management_access_level, team_member_removal_access_level, uri, visibility])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [is_admin, is_guest, is_limited_access, team, team.name, user, user.name])
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> record<data: record<gid: string, resource_type: string, user: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, is_guest: bool, is_limited_access: bool, is_admin: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/addUser" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/removeUser" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [display_name, end_on, parent, parent.display_name, parent.end_on, parent.period, parent.start_on, period, start_on])
]: nothing -> record<data: record<gid: string, resource_type: string, end_on: string, start_on: string, period: string, display_name: string, parent: record<gid: string, resource_type: string, end_on: string, start_on: string, period: string, display_name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/time_periods/($time_period_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --start-on: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --end-on: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --workspace: string # Globally unique identifier for the workspace. (e.g. 31326)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [display_name, end_on, offset, parent, parent.display_name, parent.end_on, parent.period, parent.start_on, path, period, start_on, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, end_on: string, start_on: string, period: string, display_name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "start_on" $start_on "scalar") (serialize-qp "end_on" $end_on "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/time_periods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a time tracking category
#
# GET /time_tracking_categories/{time_tracking_category_gid}
# operationId: getTimeTrackingCategory
export def "time-tracking-categories get" [
  time_tracking_category_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, is_archived, name])
]: nothing -> record<data: record<gid: string, resource_type: string, name: string, color: string, is_archived: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/time_tracking_categories/($time_tracking_category_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a time tracking category
#
# PUT /time_tracking_categories/{time_tracking_category_gid}
# operationId: updateTimeTrackingCategory
export def "time-tracking-categories updateTimeTrackingCategory" [
  time_tracking_category_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, is_archived, name])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, name: string, color: string, is_archived: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/time_tracking_categories/($time_tracking_category_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a time tracking category
#
# DELETE /time_tracking_categories/{time_tracking_category_gid}
# operationId: deleteTimeTrackingCategory
export def "time-tracking-categories delete" [
  time_tracking_category_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/time_tracking_categories/($time_tracking_category_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get time tracking entries for a time tracking category
#
# GET /time_tracking_categories/{time_tracking_category_gid}/time_tracking_entries
# operationId: getTimeTrackingEntriesForTimeTrackingCategory
export def "time-tracking-categories-time-tracking-entries get" [
  time_tracking_category_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # The start date for filtering time tracking entries by their entry date. (format: date, e.g. 2025-01-01)
  --end-date: string # The end date for filtering time tracking entries by their entry date. (format: date, e.g. 2025-12-31)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [attributable_to, attributable_to.name, categories, categories.color, categories.name, created_by, created_by.name, duration_minutes, entered_on, offset, path, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, duration_minutes: int, entered_on: string, attributable_to: record, created_by: record, categories: list>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/time_tracking_categories/($time_tracking_category_gid)/time_tracking_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get time tracking categories for a workspace
#
# GET /time_tracking_categories
# operationId: getTimeTrackingCategories
export def "time-tracking-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspace: string # Globally unique identifier for the workspace. (e.g. 12345)
  --is-archived: string@bool-completer # Filter by archived status. If not provided, defaults to returning non-archived categories. (e.g. false)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, is_archived, name, offset, path, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string, color: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspace" $workspace "scalar") (serialize-qp "is_archived" $is_archived "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/time_tracking_categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a time tracking category
#
# POST /time_tracking_categories
# operationId: createTimeTrackingCategory
export def "time-tracking-categories createTimeTrackingCategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [color, is_archived, name])
  --data: any
]: any -> record<data: record<gid: string, resource_type: string, name: string, color: string, is_archived: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/time_tracking_categories" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get time tracking entries for a task
#
# GET /tasks/{task_gid}/time_tracking_entries
# operationId: getTimeTrackingEntriesForTask
export def "tasks-time-tracking-entries get" [
  task_gid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [attributable_to, attributable_to.name, categories, categories.color, categories.name, created_by, created_by.name, duration_minutes, entered_on, offset, path, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, duration_minutes: int, entered_on: string, attributable_to: record, created_by: record, categories: list>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/time_tracking_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a time tracking entry
#
# POST /tasks/{task_gid}/time_tracking_entries
# operationId: createTimeTrackingEntry
# --data shape: {duration_minutes?: int, entered_on?: string, attributable_to?: string, billable_status?: "billable"|"nonBillable"|"notApplicable", description?: string, categories?: list}
export def "tasks-time-tracking-entries createTimeTrackingEntry" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [approval_status, attributable_to, attributable_to.name, billable_status, categories, categories.color, categories.name, created_at, created_by, created_by.name, description, duration_minutes, entered_on, task, task.created_by, task.name, task.resource_subtype])
  --data: record # shape: {duration_minutes?: int, entered_on?: string, attributable_to?: string, billable_status?: "billable"|"nonBillable"|"notApplicable", description?: string, categories?: list}
]: any -> record<data: record<gid: string, resource_type: string, duration_minutes: int, entered_on: string, attributable_to: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, categories: list<record>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, created_at: string, approval_status: string, billable_status: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($task_gid)/time_tracking_entries" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a time tracking entry
#
# GET /time_tracking_entries/{time_tracking_entry_gid}
# operationId: getTimeTrackingEntry
export def "time-tracking-entries get" [
  time_tracking_entry_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [approval_status, attributable_to, attributable_to.name, billable_status, categories, categories.color, categories.name, created_at, created_by, created_by.name, description, duration_minutes, entered_on, task, task.created_by, task.name, task.resource_subtype])
]: nothing -> record<data: record<gid: string, resource_type: string, duration_minutes: int, entered_on: string, attributable_to: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, categories: list<record>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, created_at: string, approval_status: string, billable_status: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/time_tracking_entries/($time_tracking_entry_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a time tracking entry
#
# PUT /time_tracking_entries/{time_tracking_entry_gid}
# operationId: updateTimeTrackingEntry
# --data shape: {duration_minutes?: int, entered_on?: string, attributable_to?: string, billable_status?: "billable"|"nonBillable"|"notApplicable", description?: string, categories?: list}
export def "time-tracking-entries updateTimeTrackingEntry" [
  time_tracking_entry_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [approval_status, attributable_to, attributable_to.name, billable_status, categories, categories.color, categories.name, created_at, created_by, created_by.name, description, duration_minutes, entered_on, task, task.created_by, task.name, task.resource_subtype])
  --data: record # shape: {duration_minutes?: int, entered_on?: string, attributable_to?: string, billable_status?: "billable"|"nonBillable"|"notApplicable", description?: string, categories?: list}
]: any -> record<data: record<gid: string, resource_type: string, duration_minutes: int, entered_on: string, attributable_to: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, categories: list<record>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string, created_by: record>, created_at: string, approval_status: string, billable_status: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/time_tracking_entries/($time_tracking_entry_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a time tracking entry
#
# DELETE /time_tracking_entries/{time_tracking_entry_gid}
# operationId: deleteTimeTrackingEntry
export def "time-tracking-entries delete" [
  time_tracking_entry_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/time_tracking_entries/($time_tracking_entry_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get multiple time tracking entries
#
# GET /time_tracking_entries
# operationId: getTimeTrackingEntries
export def "time-tracking-entries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --task: string # Globally unique identifier for the task to filter time tracking entries by. (e.g. 12345)
  --attributable-to: string # Globally unique identifier for the project the time tracking entries are attributed to. (e.g. 12345)
  --portfolio: string # Globally unique identifier for the portfolio to filter time tracking entries by. (e.g. 12345)
  --user: string # Globally unique identifier for the user to filter time tracking entries by. (e.g. 12345)
  --workspace: string # Globally unique identifier for the workspace. At least one of `entered_on_start_date` or `entered_on_end_date` must be provided when filtering by workspace. (e.g. 98765)
  --entered-on-start-date: string # The start date for filtering time tracking entries by when they were entered. (format: date, e.g. 2025-01-01)
  --entered-on-end-date: string # The end date for filtering time tracking entries by when they were entered. (format: date, e.g. 2025-12-31)
  --timesheet-approval-status: string # Globally unique identifier for the timesheet approval status to filter time tracking entries by. (e.g. 12345)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [attributable_to, attributable_to.name, categories, categories.color, categories.name, created_by, created_by.name, duration_minutes, entered_on, offset, path, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, duration_minutes: int, entered_on: string, attributable_to: record, created_by: record, categories: list>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "task" $task "scalar") (serialize-qp "attributable_to" $attributable_to "scalar") (serialize-qp "portfolio" $portfolio "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "entered_on_start_date" $entered_on_start_date "scalar") (serialize-qp "entered_on_end_date" $entered_on_end_date "scalar") (serialize-qp "timesheet_approval_status" $timesheet_approval_status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/time_tracking_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a timesheet approval status
#
# GET /timesheet_approval_statuses/{timesheet_approval_status_gid}
# operationId: getTimesheetApprovalStatus
export def "timesheet-approval-statuses get" [
  timesheet_approval_status_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [approval_status, created_at, end_date, start_date, user, user.name, workspace, workspace.name])
]: nothing -> record<data: record<gid: string, resource_type: string, created_at: string, user: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, start_date: string, end_date: string, approval_status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/timesheet_approval_statuses/($timesheet_approval_status_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a timesheet approval status
#
# PUT /timesheet_approval_statuses/{timesheet_approval_status_gid}
# operationId: updateTimesheetApprovalStatus
# --data shape: {approval_status: "submitted"|"draft"|"approved"|"rejected", message?: string}
export def "timesheet-approval-statuses updateTimesheetApprovalStatus" [
  timesheet_approval_status_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [approval_status, created_at, end_date, start_date, user, user.name, workspace, workspace.name])
  --data: record # A request to update a timesheet approval status. — shape: {approval_status: "submitted"|"draft"|"approved"|"rejected", message?: string}
]: any -> record<data: record<gid: string, resource_type: string, created_at: string, user: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, start_date: string, end_date: string, approval_status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/timesheet_approval_statuses/($timesheet_approval_status_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get multiple timesheet approval statuses
#
# GET /timesheet_approval_statuses
# operationId: getTimesheetApprovalStatuses
export def "timesheet-approval-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspace: string # Globally unique identifier for the workspace. (e.g. 12345)
  --user: string # Globally unique identifier for the user to filter timesheet approval statuses by. (e.g. 67890)
  --from-date: string # The start date for filtering timesheet approval statuses. (format: date, e.g. 2025-11-01)
  --to-date: string # The end date for filtering timesheet approval statuses. (format: date, e.g. 2025-11-30)
  --approval-statuses: string # Filter by approval status. Can be one or more of draft, submitted, approved, or rejected. (e.g. draft)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [approval_status, created_at, end_date, offset, path, start_date, uri, user, user.name, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, created_at: string, user: record, workspace: record, start_date: string, end_date: string, approval_status: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspace" $workspace "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "approval_statuses" $approval_statuses "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/timesheet_approval_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a timesheet approval status
#
# POST /timesheet_approval_statuses
# operationId: createTimesheetApprovalStatus
# --data shape: {user: string, workspace: string, start_date: string, end_date: string}
export def "timesheet-approval-statuses createTimesheetApprovalStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [approval_status, created_at, end_date, start_date, user, user.name, workspace, workspace.name])
  --data: record # A request to create a timesheet approval status. — shape: {user: string, workspace: string, start_date: string, end_date: string}
]: any -> record<data: record<gid: string, resource_type: string, created_at: string, user: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, start_date: string, end_date: string, approval_status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/timesheet_approval_statuses" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --resource-type: string@resource-type-completer # The type of values the typeahead should return. You can choose from one of the following: `actor`, `agent`, `custom_field`, `goal`, `project`, `project_template`, `portfolio`, `tag`, `task`, `team`, and `user`. Note that unlike in the names of endpoints, the types listed here are in singular form (e.g. `task`). Using multiple types is not yet supported. The `agent` type returns only agents, currently limited to AI Teammates, which are Asana's first-party agents. The `actor` type returns a combined set of users and agents. (default: user)
  --type: string@type-completer # *Deprecated: new integrations should prefer the resource_type field.* (default: user)
  --qp-query: string # The string that will be used to search for relevant objects. If an empty string is passed in, the API will return results. (e.g. Greg)
  --count: int # The number of results to return. The default is 20 if this parameter is omitted, with a minimum of 1 and a maximum of 100. If there are fewer results found than requested, all will be returned. (e.g. 20)
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource_type" $resource_type "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/typeahead" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [name, owner, workspace])
]: nothing -> record<data: record<gid: string, resource_type: string, name: string, owner: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_task_lists/($user_task_list_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --workspace: string # The workspace in which to get the user task list. (e.g. 1234)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [name, owner, workspace])
]: nothing -> record<data: record<gid: string, resource_type: string, name: string, owner: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)/user_task_list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --workspace: string # The workspace or organization ID to filter users on. (e.g. 1331)
  --team: string # The team ID to filter users on. (e.g. 15627)
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, email, name, offset, path, photo, photo.image_1024x1024, photo.image_128x128, photo.image_21x21, photo.image_27x27, photo.image_36x36, photo.image_60x60, uri, workspaces, workspaces.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspace" $workspace "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --workspace: string # The workspace to filter results on. (e.g. 12345)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, email, name, photo, photo.image_1024x1024, photo.image_128x128, photo.image_21x21, photo.image_27x27, photo.image_36x36, photo.image_60x60, workspaces, workspaces.name])
]: nothing -> record<data: record<workspaces: list<record>, custom_fields: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /users/{user_gid}
# operationId: updateUser
export def "users updateUser" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --workspace: string # The workspace to filter results on. (e.g. 12345)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, email, name, photo, photo.image_1024x1024, photo.image_128x128, photo.image_21x21, photo.image_27x27, photo.image_36x36, photo.image_60x60, workspaces, workspaces.name])
  --data: any
]: any -> record<data: record<workspaces: list<record>, custom_fields: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --resource-type: string@resource-type-completer-1 # The resource type of favorites to be returned. (default: project)
  --workspace: string # The workspace in which to get favorites. (e.g. 1234)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [name, offset, path, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "resource_type" $resource_type "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)/favorites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, email, name, photo, photo.image_1024x1024, photo.image_128x128, photo.image_21x21, photo.image_27x27, photo.image_36x36, photo.image_60x60, workspaces, workspaces.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_gid)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get users in a workspace or organization
#
# GET /workspaces/{workspace_gid}/users
# operationId: getUsersForWorkspace
export def "workspaces-users list" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, email, name, photo, photo.image_1024x1024, photo.image_128x128, photo.image_21x21, photo.image_27x27, photo.image_36x36, photo.image_60x60, workspaces, workspaces.name])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user in a workspace or organization
#
# GET /workspaces/{workspace_gid}/users/{user_gid}
# operationId: getUserForWorkspace
export def "workspaces-users get" [
  workspace_gid: string
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, email, name, photo, photo.image_1024x1024, photo.image_128x128, photo.image_21x21, photo.image_27x27, photo.image_36x36, photo.image_60x60, workspaces, workspaces.name])
]: nothing -> record<data: record<workspaces: list<record>, custom_fields: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/users/($user_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user in a workspace or organization
#
# PUT /workspaces/{workspace_gid}/users/{user_gid}
# operationId: updateUserForWorkspace
export def "workspaces-users updateUserForWorkspace" [
  workspace_gid: string
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [custom_fields, custom_fields.date_value, custom_fields.date_value.date, custom_fields.date_value.date_time, custom_fields.display_value, custom_fields.enabled, custom_fields.enum_options, custom_fields.enum_options.color, custom_fields.enum_options.enabled, custom_fields.enum_options.name, custom_fields.enum_value, custom_fields.enum_value.color, custom_fields.enum_value.enabled, custom_fields.enum_value.name, custom_fields.id_prefix, custom_fields.input_restrictions, custom_fields.is_formula_field, custom_fields.multi_enum_values, custom_fields.multi_enum_values.color, custom_fields.multi_enum_values.enabled, custom_fields.multi_enum_values.name, custom_fields.name, custom_fields.number_value, custom_fields.representation_type, custom_fields.text_value, custom_fields.type, email, name, photo, photo.image_1024x1024, photo.image_128x128, photo.image_21x21, photo.image_27x27, photo.image_36x36, photo.image_60x60, workspaces, workspaces.name])
  --data: any
]: any -> record<data: record<workspaces: list<record>, custom_fields: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/users/($user_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace to query for webhooks in. (e.g. 1331)
  --resource: string # Only return webhooks for the given resource. (e.g. 51648)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [active, created_at, delivery_retry_count, failure_deletion_timestamp, filters, filters.action, filters.fields, filters.resource_subtype, last_failure_at, last_failure_content, last_success_at, next_attempt_after, offset, path, resource, resource.name, target, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, active: bool, resource: record, target: string, created_at: string, last_failure_at: string, last_failure_content: string, last_success_at: string, delivery_retry_count: int, next_attempt_after: string, failure_deletion_timestamp: string, filters: list>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "workspace" $workspace "scalar") (serialize-qp "resource" $resource "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Establish a webhook
#
# POST /webhooks
# operationId: createWebhook
# --data shape: {resource: string, target: string, filters?: list}
export def "webhooks createWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [active, created_at, delivery_retry_count, failure_deletion_timestamp, filters, filters.action, filters.fields, filters.resource_subtype, last_failure_at, last_failure_content, last_success_at, next_attempt_after, resource, resource.name, target])
  --data: record # shape: {resource: string, target: string, filters?: list}
]: any -> record<data: record<gid: string, resource_type: string, active: bool, resource: record<gid: string, resource_type: string, name: string>, target: string, created_at: string, last_failure_at: string, last_failure_content: string, last_success_at: string, delivery_retry_count: int, next_attempt_after: string, failure_deletion_timestamp: string, filters: list<record>>, X_Hook_Secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [active, created_at, delivery_retry_count, failure_deletion_timestamp, filters, filters.action, filters.fields, filters.resource_subtype, last_failure_at, last_failure_content, last_success_at, next_attempt_after, resource, resource.name, target])
]: nothing -> record<data: record<gid: string, resource_type: string, active: bool, resource: record<gid: string, resource_type: string, name: string>, target: string, created_at: string, last_failure_at: string, last_failure_content: string, last_success_at: string, delivery_retry_count: int, next_attempt_after: string, failure_deletion_timestamp: string, filters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [active, created_at, delivery_retry_count, failure_deletion_timestamp, filters, filters.action, filters.fields, filters.resource_subtype, last_failure_at, last_failure_content, last_success_at, next_attempt_after, resource, resource.name, target])
  --data: record # shape: {filters?: list}
]: any -> record<data: record<gid: string, resource_type: string, active: bool, resource: record<gid: string, resource_type: string, name: string>, target: string, created_at: string, last_failure_at: string, last_failure_content: string, last_success_at: string, delivery_retry_count: int, next_attempt_after: string, failure_deletion_timestamp: string, filters: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, is_active, is_admin, is_guest, is_view_only, user, user.name, user_task_list, user_task_list.name, user_task_list.owner, user_task_list.workspace, vacation_dates, vacation_dates.end_on, vacation_dates.start_on, workspace, workspace.name])
]: nothing -> record<data: record<gid: string, resource_type: string, user: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, user_task_list: record<gid: string, resource_type: string, name: string, owner: record, workspace: record>, is_active: bool, is_admin: bool, is_guest: bool, is_view_only: bool, vacation_dates: record<start_on: string, end_on: string>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspace_memberships/($workspace_membership_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, is_active, is_admin, is_guest, is_view_only, offset, path, uri, user, user.name, user_task_list, user_task_list.name, user_task_list.owner, user_task_list.workspace, vacation_dates, vacation_dates.end_on, vacation_dates.start_on, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, user: record, workspace: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_gid)/workspace_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [created_at, is_active, is_admin, is_guest, is_view_only, offset, path, uri, user, user.name, user_task_list, user_task_list.name, user_task_list.owner, user_task_list.workspace, vacation_dates, vacation_dates.end_on, vacation_dates.start_on, workspace, workspace.name])
]: nothing -> record<data: table<gid: string, resource_type: string, user: record, workspace: record>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/workspace_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. *Note: You can only pass in an offset that was returned to you via a previously paginated request.* (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [email_domains, is_organization, name, offset, path, uri])
]: nothing -> record<data: table<gid: string, resource_type: string, name: string>, next_page: record<offset: string, path: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [email_domains, is_organization, name])
]: nothing -> record<data: record<gid: string, resource_type: string, name: string, email_domains: list<string>, is_organization: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a workspace
#
# PUT /workspaces/{workspace_gid}
# operationId: updateWorkspace
# --data shape: {name?: string}
export def "workspaces updateWorkspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [email_domains, is_organization, name])
  --data: record # A *workspace* is the highest-level organizational unit in Asana. All projects and tasks have an associated workspace. — shape: {name?: string}
]: any -> record<data: record<gid: string, resource_type: string, name: string, email_domains: list<string>, is_organization: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list # This endpoint returns a resource which excludes some properties by default. To include those optional properties, set this query parameter to a comma-separated list of the properties you wish to include. (e.g. [email, name, photo, photo.image_1024x1024, photo.image_128x128, photo.image_21x21, photo.image_27x27, photo.image_36x36, photo.image_60x60])
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> record<data: record<gid: string, resource_type: string, name: string, email: string, photo: record<image_21x21: string, image_27x27: string, image_36x36: string, image_60x60: string, image_128x128: string, image_1024x1024: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "opt_fields" $opt_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/addUser" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/removeUser" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workspace events
#
# GET /workspaces/{workspace_gid}/events
# operationId: getWorkspaceEvents
export def "workspaces-events get" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --opt-pretty: string@bool-completer # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --sync: string # A sync token received from the last request, or none on first sync. Events will be returned from the point in time that the sync token was generated. *Note: On your first request, omit the sync token. The response will be the same as for an expired sync token, and will include a new valid sync token. If the sync token is too old (which may happen from time to time) the API will return a `412 Precondition Failed` error, and include a fresh sync token in the response.* (e.g. de4774f6915eae04714ca93bb2f5ee81)
]: nothing -> record<data: table<user: record, resource: record, type: string, action: string, parent: record, created_at: string, change: record>, sync: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "opt_pretty" $opt_pretty "scalar") (serialize-qp "sync" $sync "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace_gid)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
