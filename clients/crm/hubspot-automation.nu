# Auto-generated client for Custom Workflow Actions vv4
# Source: https://api.apis.guru/v2/specs/hubapi.com/automation/v4/openapi.json
# Auth: --token flag or $env.CUSTOM_WORKFLOW_ACTIONS_TOKEN

const BASE_URL = "https://api.hubapi.com"
const DEFAULT_AUTH = "query-hapikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CUSTOM_WORKFLOW_ACTIONS_TOKEN | default "" }
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


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "automation-actions-callbacks-complete completeBatch" } } | get name | first)
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

# Complete a batch of callbacks
#
# POST /automation/v4/actions/callbacks/complete
# operationId: post-/automation/v4/actions/callbacks/complete_completeBatch
# --inputs item shape: {callbackId: string, outputFields: record}
export def "automation-actions-callbacks-complete completeBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  inputs: list # item shape: {callbackId: string, outputFields: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/automation/v4/actions/callbacks/complete")
  let body = {inputs: $inputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete a callback
#
# POST /automation/v4/actions/callbacks/{callbackId}/complete
# operationId: post-/automation/v4/actions/callbacks/{callbackId}/complete_complete
export def "automation-actions-callbacks-complete complete" [
  callbackId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  outputFields: record # A map of action output names and values.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation/v4/actions/callbacks/($callbackId)/complete")
  let body = {outputFields: $outputFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all custom actions
#
# GET /automation/v4/actions/{appId}
# operationId: get-/automation/v4/actions/{appId}_getPage
export def "automation-actions list" [
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results per page. (format: int32)
  --after: string # The paging cursor token of the last successfully read resource will be returned as the `paging.next.after` JSON property of a paged response containing more results.
  --archived: oneof<nothing, bool> # Whether to include archived custom actions. (default: false)
]: nothing -> record<paging: record<next: record<after: string, link: string>>, results: table<actionUrl: string, archivedAt: int, functions: list, id: string, inputFieldDependencies: list, inputFields: list, labels: record, objectRequestOptions: record, objectTypes: list, published: bool, revisionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/automation/v4/actions/($appId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new custom action
#
# POST /automation/v4/actions/{appId}
# operationId: post-/automation/v4/actions/{appId}_create
# --functions item shape: {functionSource: string, functionType: "PRE_ACTION_EXECUTION"|"PRE_FETCH_OPTIONS"|"POST_FETCH_OPTIONS", id?: string}
# --inputFields item shape: {isRequired: bool, supportedValueTypes?: list, typeDefinition: record}
# --objectRequestOptions shape: {properties: list}
export def "automation-actions create" [
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  actionUrl: string # The URL that will accept an HTTPS request each time workflows executes the custom action.
  --archivedAt: int # The date that this custom action was archived, if the custom action is archived. (format: int64)
  functions: list # A list of functions associated with the custom workflow action. — item shape: {functionSource: string, functionType: "PRE_ACTION_EXECUTION"|"PRE_FETCH_OPTIONS"|"POST_FETCH_OPTIONS", id?: string}
  --inputFieldDependencies: list # A list of dependencies between the input fields. These configure when the input fields should be visible.
  inputFields: list # The list of input fields to display in this custom action. — item shape: {isRequired: bool, supportedValueTypes?: list, typeDefinition: record}
  labels: record # The user-facing labels for the custom action.
  --objectRequestOptions: record # Configures what properties of the enrolled CRM object are included in the action execution request — shape: {properties: list}
  objectTypes: list # The object types that this custom action supports.
  --published: oneof<nothing, bool> # Whether this custom action is published to customers.
]: any -> record<actionUrl: string, archivedAt: int, functions: table<functionType: string, id: string>, id: string, inputFieldDependencies: list<any>, inputFields: table<isRequired: bool, supportedValueTypes: list, typeDefinition: record>, labels: record, objectRequestOptions: record<properties: list<string>>, objectTypes: list<string>, published: bool, revisionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation/v4/actions/($appId)")
  let body = {actionUrl: $actionUrl, archivedAt: $archivedAt, functions: $functions, inputFieldDependencies: $inputFieldDependencies, inputFields: $inputFields, labels: $labels, objectRequestOptions: $objectRequestOptions, objectTypes: $objectTypes, published: $published} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive a custom action
#
# DELETE /automation/v4/actions/{appId}/{definitionId}
# operationId: delete-/automation/v4/actions/{appId}/{definitionId}_archive
export def "automation-actions archive" [
  definitionId: string
  appId: int
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
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a custom action
#
# GET /automation/v4/actions/{appId}/{definitionId}
# operationId: get-/automation/v4/actions/{appId}/{definitionId}_getById
export def "automation-actions get" [
  definitionId: string
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool> # Whether to include archived custom actions. (default: false)
]: nothing -> record<actionUrl: string, archivedAt: int, functions: table<functionType: string, id: string>, id: string, inputFieldDependencies: list<any>, inputFields: table<isRequired: bool, supportedValueTypes: list, typeDefinition: record>, labels: record, objectRequestOptions: record<properties: list<string>>, objectTypes: list<string>, published: bool, revisionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a custom action
#
# PATCH /automation/v4/actions/{appId}/{definitionId}
# operationId: patch-/automation/v4/actions/{appId}/{definitionId}_update
# --inputFields item shape: {isRequired: bool, supportedValueTypes?: list, typeDefinition: record}
# --objectRequestOptions shape: {properties: list}
export def "automation-actions update" [
  definitionId: string
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actionUrl: string # The URL that will accept an HTTPS request each time workflows executes the custom action.
  --inputFieldDependencies: list # A list of dependencies between the input fields. These configure when the input fields should be visible.
  --inputFields: list # The list of input fields to display in this custom action. — item shape: {isRequired: bool, supportedValueTypes?: list, typeDefinition: record}
  --labels: record # The user-facing labels for the custom action.
  --objectRequestOptions: record # Configures what properties of the enrolled CRM object are included in the action execution request — shape: {properties: list}
  --objectTypes: list # The object types that this custom action supports.
  --published: oneof<nothing, bool> # Whether this custom action is published to customers.
]: any -> record<actionUrl: string, archivedAt: int, functions: table<functionType: string, id: string>, id: string, inputFieldDependencies: list<any>, inputFields: table<isRequired: bool, supportedValueTypes: list, typeDefinition: record>, labels: record, objectRequestOptions: record<properties: list<string>>, objectTypes: list<string>, published: bool, revisionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)")
  let body = {actionUrl: $actionUrl, inputFieldDependencies: $inputFieldDependencies, inputFields: $inputFields, labels: $labels, objectRequestOptions: $objectRequestOptions, objectTypes: $objectTypes, published: $published} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all custom action functions
#
# GET /automation/v4/actions/{appId}/{definitionId}/functions
# operationId: get-/automation/v4/actions/{appId}/{definitionId}/functions_getPage
export def "automation-actions-functions get-by-definitionId-appId" [
  definitionId: string
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<functionType: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)/functions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a custom action function
#
# DELETE /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}
# operationId: delete-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}_archiveByFunctionType
export def "automation-actions-functions archiveByFunctionType" [
  definitionId: string
  functionType: string
  appId: int
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
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)/functions/($functionType)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a custom action function
#
# GET /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}
# operationId: get-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}_getByFunctionType
export def "automation-actions-functions get-by-definitionId-functionType-appId" [
  definitionId: string
  functionType: string
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<functionSource: string, functionType: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)/functions/($functionType)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or replace a custom action function
#
# PUT /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}
# operationId: put-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}_createOrReplaceByFunctionType
export def "automation-actions-functions createOrReplaceByFunctionType" [
  definitionId: string
  functionType: string
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<functionType: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)/functions/($functionType)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Delete a custom action function
#
# DELETE /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}
# operationId: delete-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}_archive
export def "automation-actions-functions archive" [
  definitionId: string
  functionType: string
  functionId: string
  appId: int
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
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)/functions/($functionType)/($functionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a custom action function
#
# GET /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}
# operationId: get-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}_getById
export def "automation-actions-functions get-by-definitionId-functionType-functionId-appId" [
  definitionId: string
  functionType: string
  functionId: string
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<functionSource: string, functionType: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)/functions/($functionType)/($functionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or replace a custom action function
#
# PUT /automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}
# operationId: put-/automation/v4/actions/{appId}/{definitionId}/functions/{functionType}/{functionId}_createOrReplace
export def "automation-actions-functions createOrReplace" [
  definitionId: string
  functionType: string
  functionId: string
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<functionType: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)/functions/($functionType)/($functionId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Get all revisions for a custom action
#
# GET /automation/v4/actions/{appId}/{definitionId}/revisions
# operationId: get-/automation/v4/actions/{appId}/{definitionId}/revisions_getPage
export def "automation-actions-revisions list" [
  definitionId: string
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of results per page. (format: int32)
  --after: string # The paging cursor token of the last successfully read resource will be returned as the `paging.next.after` JSON property of a paged response containing more results.
]: nothing -> record<paging: record<next: record<after: string, link: string>>, results: table<createdAt: string, definition: record, id: string, revisionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)/revisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a revision for a custom action
#
# GET /automation/v4/actions/{appId}/{definitionId}/revisions/{revisionId}
# operationId: get-/automation/v4/actions/{appId}/{definitionId}/revisions/{revisionId}_getById
export def "automation-actions-revisions get" [
  definitionId: string
  revisionId: string
  appId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, definition: record<actionUrl: string, archivedAt: int, functions: list<record>, id: string, inputFieldDependencies: list<any>, inputFields: list<record>, labels: record, objectRequestOptions: record<properties: list>, objectTypes: list<string>, published: bool, revisionId: string>, id: string, revisionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-hapikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/automation/v4/actions/($appId)/($definitionId)/revisions/($revisionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
