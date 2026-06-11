# Auto-generated client for n8n Public API v1.1.1
# Source: https://docs.n8n.io/api/v1/openapi.yml
# Auth: --token flag or $env.N8N_PUBLIC_API_TOKEN

const BASE_URL = "http://localhost/api/v1"
const DEFAULT_AUTH = "x-n8n-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o N8N_PUBLIC_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-n8n-api-key" => { {headers: {X-N8N-API-KEY: $token_val}, query: ""} }
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
def base-url-completer [] { ["http://localhost/api/v1"] }
def auth-scheme-completer [] { ["x-n8n-api-key" "bearer"] }

# Completers for enum parameters
def status-completer [] { ["canceled" "crashed" "error" "new" "running" "success" "unknown" "waiting"] }
def autoPublish-completer [] { ["all" "none" "published"] }
def state-completer [] { ["empty"] }
def returnType-completer [] { ["all" "count" "id"] }
def type-completer [] { ["boolean" "date" "number" "string"] }
def include-completer [] { ["schemas"] }
def sortBy-completer [] { ["createdAt:asc" "createdAt:desc" "name:asc" "name:desc" "updatedAt:asc" "updatedAt:desc"] }
def credentialMatchingMode-completer [] { ["id-only"] }
def credentialMissingMode-completer [] { ["must-preexist"] }
def workflowConflictPolicy-completer [] { ["fail" "new-version" "skip"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "audit post" } } | get name | first)
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

# Generate an audit
#
# POST /audit
# --additionalOptions shape: {daysAbandonedWorkflow?: int, categories?: list}
export def "audit post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalOptions: record # shape: {daysAbandonedWorkflow?: int, categories?: list}
]: any -> record<Credentials_Risk_Report: record, Database_Risk_Report: record, Filesystem_Risk_Report: record, Nodes_Risk_Report: record, Instance_Risk_Report: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audit")
  let body = {additionalOptions: $additionalOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List credentials
#
# GET /credentials
# operationId: getCredentials
export def "credentials list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The maximum number of items to return. (default: 100, e.g. 100)
  --cursor: string # Paginate by setting the cursor parameter to the nextCursor attribute returned by the previous request's response. Default value fetches the first "page" of the collection. See pagination for more detail.
]: nothing -> record<data: table<id: string, name: string, type: string, isManaged: bool, isGlobal: bool, isResolvable: bool, resolvableAllowFallback: bool, resolverId: string, createdAt: string, updatedAt: string, shared: list>, nextCursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a credential
#
# POST /credentials
# operationId: createCredential
export def "credentials createCredential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. Joe's Github Credentials
  type: string # e.g. githubApi
  data: record # e.g. {accessToken: ada612vad6fa5df4adf5a5dsf4389adsf76da7s}
  --isResolvable: string@bool-completer # Whether this credential has resolvable fields (e.g. false)
  --projectId: string # Project to create the credential in. Defaults to the user's personal project. (e.g. VmwOO9HeTEj20kxM)
]: any -> record<id: string, name: string, type: string, isManaged: bool, isGlobal: bool, isResolvable: bool, resolvableAllowFallback: bool, resolverId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credentials")
  let body = {name: $name, type: $type, data: $data, isResolvable: $isResolvable, projectId: $projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get credential by ID
#
# GET /credentials/{id}
# operationId: getCredential
export def "credentials get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, type: string, isManaged: bool, isGlobal: bool, isResolvable: bool, resolvableAllowFallback: bool, resolverId: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credentials/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update credential by ID
#
# PATCH /credentials/{id}
# operationId: updateCredential
export def "credentials updateCredential" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the credential (e.g. Updated Credential Name)
  --type: string # The credential type. If changing type, data must also be provided. (e.g. githubApi)
  --data: record # The credential data. Required when changing credential type. (e.g. {accessToken: new_token_value})
  --isGlobal: string@bool-completer # Whether this credential is available globally (e.g. false)
  --isResolvable: string@bool-completer # Whether this credential has resolvable fields (e.g. false)
  --isPartialData: string@bool-completer # If true, unredacts and merges existing credential data with the provided data. If false, replaces the entire data object. (default: false, e.g. false)
]: any -> record<id: string, name: string, type: string, isManaged: bool, isGlobal: bool, isResolvable: bool, resolvableAllowFallback: bool, resolverId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credentials/($id)")
  let body = {name: $name, type: $type, data: $data, isGlobal: $isGlobal, isResolvable: $isResolvable, isPartialData: $isPartialData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete credential by ID
#
# DELETE /credentials/{id}
# operationId: deleteCredential
export def "credentials delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, type: string, data: record, isResolvable: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credentials/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test credential by ID
#
# POST /credentials/{id}/test
# operationId: testCredential
export def "credentials-test testCredential" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credentials/($id)/test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show credential data schema
#
# GET /credentials/schema/{credentialTypeName}
export def "credentials-schema get" [
  credentialTypeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credentials/schema/($credentialTypeName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transfer a credential to another project.
#
# PUT /credentials/{id}/transfer
export def "credentials-transfer put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationProjectId: string # The ID of the project to transfer the credential to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/credentials/($id)/transfer")
  let body = {destinationProjectId: $destinationProjectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all executions
#
# GET /executions
export def "executions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeData: string@bool-completer # Whether or not to include the execution's detailed data.
  --redactExecutionData: string@bool-completer # Controls execution data redaction. When `true`, execution output data is always redacted. When `false`, requests unredacted (revealed) data — requires the `execution:reveal` scope. When omitted, follows the workflow redaction policy.
  --status: string@status-completer # Status to filter the executions by.
  --workflowId: string # Workflow to filter the executions by. (e.g. 1000)
  --projectId: string # e.g. VmwOO9HeTEj20kxM
  --limit: float # The maximum number of items to return. (default: 100, e.g. 100)
  --cursor: string # Paginate by setting the cursor parameter to the nextCursor attribute returned by the previous request's response. Default value fetches the first "page" of the collection. See pagination for more detail.
]: nothing -> record<data: table<id: float, data: record, finished: bool, mode: string, retryOf: float, retrySuccessId: float, startedAt: string, stoppedAt: string, workflowId: float, waitTill: string, customData: record, status: string>, nextCursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeData" $includeData "scalar") (serialize-qp "redactExecutionData" $redactExecutionData "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "workflowId" $workflowId "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/executions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an execution
#
# GET /executions/{id}
export def "executions get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeData: string@bool-completer # Whether or not to include the execution's detailed data.
  --redactExecutionData: string@bool-completer # Controls execution data redaction. When `true`, execution output data is always redacted. When `false`, requests unredacted (revealed) data — requires the `execution:reveal` scope. When omitted, follows the workflow redaction policy.
]: nothing -> record<id: float, data: record<redactionInfo: record<isRedacted: bool, reason: string, canReveal: bool>>, finished: bool, mode: string, retryOf: float, retrySuccessId: float, startedAt: string, stoppedAt: string, workflowId: float, waitTill: string, customData: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeData" $includeData "scalar") (serialize-qp "redactExecutionData" $redactExecutionData "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/executions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an execution
#
# DELETE /executions/{id}
export def "executions delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, data: record<redactionInfo: record<isRedacted: bool, reason: string, canReveal: bool>>, finished: bool, mode: string, retryOf: float, retrySuccessId: float, startedAt: string, stoppedAt: string, workflowId: float, waitTill: string, customData: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/executions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retry an execution
#
# POST /executions/{id}/retry
export def "executions-retry post" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loadWorkflow: string@bool-completer # Whether to load the currently saved workflow to execute instead of the one saved at the time of the execution. If set to true, it will retry with the latest version of the workflow.
]: any -> record<id: float, data: record<redactionInfo: record<isRedacted: bool, reason: string, canReveal: bool>>, finished: bool, mode: string, retryOf: float, retrySuccessId: float, startedAt: string, stoppedAt: string, workflowId: float, waitTill: string, customData: record, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/executions/($id)/retry")
  let body = {loadWorkflow: $loadWorkflow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stop an execution
#
# POST /executions/{id}/stop
export def "executions-stop post-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, data: record<redactionInfo: record<isRedacted: bool, reason: string, canReveal: bool>>, finished: bool, mode: string, retryOf: float, retrySuccessId: float, startedAt: string, stoppedAt: string, workflowId: float, waitTill: string, customData: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/executions/($id)/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop multiple executions
#
# POST /executions/stop
export def "executions-stop post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: list # Array of execution statuses to stop. Must include at least one status. (e.g. [queued, running, waiting])
  --workflowId: string # Optional workflow ID to filter executions. If not provided, will stop executions across all accessible workflows. (e.g. 2tUt1wbLX592XDdX)
  --startedAfter: string # Only stop executions that started after this time. (format: date-time, e.g. 2024-01-01T00:00:00.000Z)
  --startedBefore: string # Only stop executions that started before this time. (format: date-time, e.g. 2024-12-31T23:59:59.999Z)
]: any -> record<stopped: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/executions/stop")
  let body = {status: $status, workflowId: $workflowId, startedAfter: $startedAfter, startedBefore: $startedBefore} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get execution tags
#
# GET /executions/{id}/tags
export def "executions-tags get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/executions/($id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tags of an execution
#
# PUT /executions/{id}/tags
export def "executions-tags put" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, name: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/executions/($id)/tags")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a tag
#
# POST /tags
export def "tags post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. Production
]: any -> record<id: string, name: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all tags
#
# GET /tags
export def "tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The maximum number of items to return. (default: 100, e.g. 100)
  --cursor: string # Paginate by setting the cursor parameter to the nextCursor attribute returned by the previous request's response. Default value fetches the first "page" of the collection. See pagination for more detail.
]: nothing -> record<data: table<id: string, name: string, createdAt: string, updatedAt: string>, nextCursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a tag
#
# GET /tags/{id}
export def "tags get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a tag
#
# DELETE /tags/{id}
export def "tags delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a tag
#
# PUT /tags/{id}
export def "tags put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. Production
]: any -> record<id: string, name: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a workflow
#
# POST /workflows
# --nodes item shape: {id?: string, name?: string, webhookId?: string, disabled?: bool, notesInFlow?: bool, notes?: string, type?: string, typeVersion?: float, executeOnce?: bool, alwaysOutputData?: bool, retryOnFail?: bool, maxTries?: float, waitBetweenTries?: float, continueOnFail?: bool, onError?: string, position?: list, parameters?: record, credentials?: record, customTelemetryTags?: record}
# --settings shape: {saveExecutionProgress?: bool, saveManualExecutions?: bool, saveDataErrorExecution?: "all"|"none", saveDataSuccessExecution?: "all"|"none", executionTimeout?: float, errorWorkflow?: string, timezone?: string, executionOrder?: string, callerPolicy?: "any"|"none"|"workflowsFromAList"|"workflowsFromSameOwner", callerIds?: string, timeSavedPerExecution?: float, redactionPolicy?: "none"|"non-manual"|"manual-only"|"all", availableInMCP?: bool, customTelemetryTags?: list}
# --meta shape: {onboardingId?: string, templateId?: string, instanceId?: string, templateCredsSetupCompleted?: bool}
# --tags item shape: {name: string}
# --shared item shape: {role?: string, workflowId?: string, projectId?: string, project?: record}
export def "workflows post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. Workflow 1
  nodes: list # item shape: {id?: string, name?: string, webhookId?: string, disabled?: bool, notesInFlow?: bool, notes?: string, type?: string, typeVersion?: float, executeOnce?: bool, alwaysOutputData?: bool, retryOnFail?: bool, maxTries?: float, waitBetweenTries?: float, continueOnFail?: bool, onError?: string, position?: list, parameters?: record, credentials?: record, customTelemetryTags?: record}
  connections: record # e.g. {Jira: {main: [[{node: Jira, type: main, index: 0}]]}}
  settings: record # shape: {saveExecutionProgress?: bool, saveManualExecutions?: bool, saveDataErrorExecution?: "all"|"none", saveDataSuccessExecution?: "all"|"none", executionTimeout?: float, errorWorkflow?: string, timezone?: string, executionOrder?: string, callerPolicy?: "any"|"none"|"workflowsFromAList"|"workflowsFromSameOwner", callerIds?: string, timeSavedPerExecution?: float, redactionPolicy?: "none"|"non-manual"|"manual-only"|"all", availableInMCP?: bool, customTelemetryTags?: list}
  --staticData: any # e.g. {lastId: 1}
  --pinData: record # Pinned sample data for nodes, keyed by node name (nullable)
  --projectId: string # Target project to create the workflow in. Defaults to the user's personal project. (e.g. VmwOO9HeTEj20kxM)
  --shared: list # item shape: {role?: string, workflowId?: string, projectId?: string, project?: record}
]: any -> record<id: string, name: string, description: string, active: bool, createdAt: string, updatedAt: string, isArchived: bool, versionId: string, triggerCount: int, nodes: table<id: string, name: string, webhookId: string, disabled: bool, notesInFlow: bool, notes: string, type: string, typeVersion: float, executeOnce: bool, alwaysOutputData: bool, retryOnFail: bool, maxTries: float, waitBetweenTries: float, continueOnFail: bool, onError: string, position: list, parameters: record, credentials: record, customTelemetryTags: record, createdAt: string, updatedAt: string>, connections: record, settings: record<saveExecutionProgress: bool, saveManualExecutions: bool, saveDataErrorExecution: string, saveDataSuccessExecution: string, executionTimeout: float, errorWorkflow: string, timezone: string, executionOrder: string, callerPolicy: string, callerIds: string, timeSavedPerExecution: float, redactionPolicy: string, availableInMCP: bool, customTelemetryTags: list<record>>, staticData: any, pinData: record, meta: record<onboardingId: string, templateId: string, instanceId: string, templateCredsSetupCompleted: bool>, tags: table<id: string, name: string, createdAt: string, updatedAt: string>, shared: table<role: string, workflowId: string, projectId: string, project: record, createdAt: string, updatedAt: string>, activeVersion: record<versionId: string, workflowId: string, nodes: list<record>, connections: record, authors: string, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/workflows")
  let body = {name: $name, nodes: $nodes, connections: $connections, settings: $settings, staticData: $staticData, pinData: $pinData, projectId: $projectId, shared: $shared} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all workflows
#
# GET /workflows
export def "workflows get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # e.g. true
  --tags: string # e.g. test,production
  --name: string # e.g. My Workflow
  --projectId: string # e.g. VmwOO9HeTEj20kxM
  --excludePinnedData: string@bool-completer # Set this to avoid retrieving pinned data (e.g. true)
  --limit: float # The maximum number of items to return. (default: 100, e.g. 100)
  --cursor: string # Paginate by setting the cursor parameter to the nextCursor attribute returned by the previous request's response. Default value fetches the first "page" of the collection. See pagination for more detail.
]: nothing -> record<data: table<id: string, name: string, description: string, active: bool, createdAt: string, updatedAt: string, isArchived: bool, versionId: string, triggerCount: int, nodes: list, connections: record, settings: record, staticData: any, pinData: record, meta: record, tags: list, shared: list, activeVersion: record>, nextCursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "excludePinnedData" $excludePinnedData "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a workflow
#
# GET /workflows/{id}
export def "workflows get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --excludePinnedData: string@bool-completer # Set this to avoid retrieving pinned data (e.g. true)
]: nothing -> record<id: string, name: string, description: string, active: bool, createdAt: string, updatedAt: string, isArchived: bool, versionId: string, triggerCount: int, nodes: table<id: string, name: string, webhookId: string, disabled: bool, notesInFlow: bool, notes: string, type: string, typeVersion: float, executeOnce: bool, alwaysOutputData: bool, retryOnFail: bool, maxTries: float, waitBetweenTries: float, continueOnFail: bool, onError: string, position: list, parameters: record, credentials: record, customTelemetryTags: record, createdAt: string, updatedAt: string>, connections: record, settings: record<saveExecutionProgress: bool, saveManualExecutions: bool, saveDataErrorExecution: string, saveDataSuccessExecution: string, executionTimeout: float, errorWorkflow: string, timezone: string, executionOrder: string, callerPolicy: string, callerIds: string, timeSavedPerExecution: float, redactionPolicy: string, availableInMCP: bool, customTelemetryTags: list<record>>, staticData: any, pinData: record, meta: record<onboardingId: string, templateId: string, instanceId: string, templateCredsSetupCompleted: bool>, tags: table<id: string, name: string, createdAt: string, updatedAt: string>, shared: table<role: string, workflowId: string, projectId: string, project: record, createdAt: string, updatedAt: string>, activeVersion: record<versionId: string, workflowId: string, nodes: list<record>, connections: record, authors: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludePinnedData" $excludePinnedData "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workflows/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a workflow
#
# DELETE /workflows/{id}
export def "workflows delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, active: bool, createdAt: string, updatedAt: string, isArchived: bool, versionId: string, triggerCount: int, nodes: table<id: string, name: string, webhookId: string, disabled: bool, notesInFlow: bool, notes: string, type: string, typeVersion: float, executeOnce: bool, alwaysOutputData: bool, retryOnFail: bool, maxTries: float, waitBetweenTries: float, continueOnFail: bool, onError: string, position: list, parameters: record, credentials: record, customTelemetryTags: record, createdAt: string, updatedAt: string>, connections: record, settings: record<saveExecutionProgress: bool, saveManualExecutions: bool, saveDataErrorExecution: string, saveDataSuccessExecution: string, executionTimeout: float, errorWorkflow: string, timezone: string, executionOrder: string, callerPolicy: string, callerIds: string, timeSavedPerExecution: float, redactionPolicy: string, availableInMCP: bool, customTelemetryTags: list<record>>, staticData: any, pinData: record, meta: record<onboardingId: string, templateId: string, instanceId: string, templateCredsSetupCompleted: bool>, tags: table<id: string, name: string, createdAt: string, updatedAt: string>, shared: table<role: string, workflowId: string, projectId: string, project: record, createdAt: string, updatedAt: string>, activeVersion: record<versionId: string, workflowId: string, nodes: list<record>, connections: record, authors: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a workflow
#
# PUT /workflows/{id}
# --nodes item shape: {id?: string, name?: string, webhookId?: string, disabled?: bool, notesInFlow?: bool, notes?: string, type?: string, typeVersion?: float, executeOnce?: bool, alwaysOutputData?: bool, retryOnFail?: bool, maxTries?: float, waitBetweenTries?: float, continueOnFail?: bool, onError?: string, position?: list, parameters?: record, credentials?: record, customTelemetryTags?: record}
# --settings shape: {saveExecutionProgress?: bool, saveManualExecutions?: bool, saveDataErrorExecution?: "all"|"none", saveDataSuccessExecution?: "all"|"none", executionTimeout?: float, errorWorkflow?: string, timezone?: string, executionOrder?: string, callerPolicy?: "any"|"none"|"workflowsFromAList"|"workflowsFromSameOwner", callerIds?: string, timeSavedPerExecution?: float, redactionPolicy?: "none"|"non-manual"|"manual-only"|"all", availableInMCP?: bool, customTelemetryTags?: list}
# --meta shape: {onboardingId?: string, templateId?: string, instanceId?: string, templateCredsSetupCompleted?: bool}
# --tags item shape: {name: string}
# --shared item shape: {role?: string, workflowId?: string, projectId?: string, project?: record}
export def "workflows put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. Workflow 1
  --description: string # Description of the workflow (e.g. My workflow description)
  nodes: list # item shape: {id?: string, name?: string, webhookId?: string, disabled?: bool, notesInFlow?: bool, notes?: string, type?: string, typeVersion?: float, executeOnce?: bool, alwaysOutputData?: bool, retryOnFail?: bool, maxTries?: float, waitBetweenTries?: float, continueOnFail?: bool, onError?: string, position?: list, parameters?: record, credentials?: record, customTelemetryTags?: record}
  connections: record # e.g. {Jira: {main: [[{node: Jira, type: main, index: 0}]]}}
  settings: record # shape: {saveExecutionProgress?: bool, saveManualExecutions?: bool, saveDataErrorExecution?: "all"|"none", saveDataSuccessExecution?: "all"|"none", executionTimeout?: float, errorWorkflow?: string, timezone?: string, executionOrder?: string, callerPolicy?: "any"|"none"|"workflowsFromAList"|"workflowsFromSameOwner", callerIds?: string, timeSavedPerExecution?: float, redactionPolicy?: "none"|"non-manual"|"manual-only"|"all", availableInMCP?: bool, customTelemetryTags?: list}
  --staticData: any # e.g. {lastId: 1}
  --pinData: record # Pinned sample data for nodes, keyed by node name (nullable)
  --shared: list # item shape: {role?: string, workflowId?: string, projectId?: string, project?: record}
]: any -> record<id: string, name: string, description: string, active: bool, createdAt: string, updatedAt: string, isArchived: bool, versionId: string, triggerCount: int, nodes: table<id: string, name: string, webhookId: string, disabled: bool, notesInFlow: bool, notes: string, type: string, typeVersion: float, executeOnce: bool, alwaysOutputData: bool, retryOnFail: bool, maxTries: float, waitBetweenTries: float, continueOnFail: bool, onError: string, position: list, parameters: record, credentials: record, customTelemetryTags: record, createdAt: string, updatedAt: string>, connections: record, settings: record<saveExecutionProgress: bool, saveManualExecutions: bool, saveDataErrorExecution: string, saveDataSuccessExecution: string, executionTimeout: float, errorWorkflow: string, timezone: string, executionOrder: string, callerPolicy: string, callerIds: string, timeSavedPerExecution: float, redactionPolicy: string, availableInMCP: bool, customTelemetryTags: list<record>>, staticData: any, pinData: record, meta: record<onboardingId: string, templateId: string, instanceId: string, templateCredsSetupCompleted: bool>, tags: table<id: string, name: string, createdAt: string, updatedAt: string>, shared: table<role: string, workflowId: string, projectId: string, project: record, createdAt: string, updatedAt: string>, activeVersion: record<versionId: string, workflowId: string, nodes: list<record>, connections: record, authors: string, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($id)")
  let body = {name: $name, description: $description, nodes: $nodes, connections: $connections, settings: $settings, staticData: $staticData, pinData: $pinData, shared: $shared} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a specific version of a workflow
#
# GET /workflows/{id}/{versionId}
export def "workflows get-by-id-versionId" [
  id: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<versionId: string, workflowId: string, nodes: table<id: string, name: string, webhookId: string, disabled: bool, notesInFlow: bool, notes: string, type: string, typeVersion: float, executeOnce: bool, alwaysOutputData: bool, retryOnFail: bool, maxTries: float, waitBetweenTries: float, continueOnFail: bool, onError: string, position: list, parameters: record, credentials: record, customTelemetryTags: record, createdAt: string, updatedAt: string>, connections: record, authors: string, name: string, description: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($id)/($versionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish a workflow
#
# POST /workflows/{id}/activate
export def "workflows-activate post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versionId: string # The specific version ID to activate or publish. If not provided, the latest version is used.
  --name: string # Optional name for the workflow version during activation.
  --description: string # Optional description for the workflow version during activation.
]: any -> record<id: string, name: string, description: string, active: bool, createdAt: string, updatedAt: string, isArchived: bool, versionId: string, triggerCount: int, nodes: table<id: string, name: string, webhookId: string, disabled: bool, notesInFlow: bool, notes: string, type: string, typeVersion: float, executeOnce: bool, alwaysOutputData: bool, retryOnFail: bool, maxTries: float, waitBetweenTries: float, continueOnFail: bool, onError: string, position: list, parameters: record, credentials: record, customTelemetryTags: record, createdAt: string, updatedAt: string>, connections: record, settings: record<saveExecutionProgress: bool, saveManualExecutions: bool, saveDataErrorExecution: string, saveDataSuccessExecution: string, executionTimeout: float, errorWorkflow: string, timezone: string, executionOrder: string, callerPolicy: string, callerIds: string, timeSavedPerExecution: float, redactionPolicy: string, availableInMCP: bool, customTelemetryTags: list<record>>, staticData: any, pinData: record, meta: record<onboardingId: string, templateId: string, instanceId: string, templateCredsSetupCompleted: bool>, tags: table<id: string, name: string, createdAt: string, updatedAt: string>, shared: table<role: string, workflowId: string, projectId: string, project: record, createdAt: string, updatedAt: string>, activeVersion: record<versionId: string, workflowId: string, nodes: list<record>, connections: record, authors: string, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($id)/activate")
  let body = {versionId: $versionId, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate a workflow
#
# POST /workflows/{id}/deactivate
export def "workflows-deactivate post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, active: bool, createdAt: string, updatedAt: string, isArchived: bool, versionId: string, triggerCount: int, nodes: table<id: string, name: string, webhookId: string, disabled: bool, notesInFlow: bool, notes: string, type: string, typeVersion: float, executeOnce: bool, alwaysOutputData: bool, retryOnFail: bool, maxTries: float, waitBetweenTries: float, continueOnFail: bool, onError: string, position: list, parameters: record, credentials: record, customTelemetryTags: record, createdAt: string, updatedAt: string>, connections: record, settings: record<saveExecutionProgress: bool, saveManualExecutions: bool, saveDataErrorExecution: string, saveDataSuccessExecution: string, executionTimeout: float, errorWorkflow: string, timezone: string, executionOrder: string, callerPolicy: string, callerIds: string, timeSavedPerExecution: float, redactionPolicy: string, availableInMCP: bool, customTelemetryTags: list<record>>, staticData: any, pinData: record, meta: record<onboardingId: string, templateId: string, instanceId: string, templateCredsSetupCompleted: bool>, tags: table<id: string, name: string, createdAt: string, updatedAt: string>, shared: table<role: string, workflowId: string, projectId: string, project: record, createdAt: string, updatedAt: string>, activeVersion: record<versionId: string, workflowId: string, nodes: list<record>, connections: record, authors: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($id)/deactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive a workflow
#
# POST /workflows/{id}/archive
export def "workflows-archive post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, active: bool, createdAt: string, updatedAt: string, isArchived: bool, versionId: string, triggerCount: int, nodes: table<id: string, name: string, webhookId: string, disabled: bool, notesInFlow: bool, notes: string, type: string, typeVersion: float, executeOnce: bool, alwaysOutputData: bool, retryOnFail: bool, maxTries: float, waitBetweenTries: float, continueOnFail: bool, onError: string, position: list, parameters: record, credentials: record, customTelemetryTags: record, createdAt: string, updatedAt: string>, connections: record, settings: record<saveExecutionProgress: bool, saveManualExecutions: bool, saveDataErrorExecution: string, saveDataSuccessExecution: string, executionTimeout: float, errorWorkflow: string, timezone: string, executionOrder: string, callerPolicy: string, callerIds: string, timeSavedPerExecution: float, redactionPolicy: string, availableInMCP: bool, customTelemetryTags: list<record>>, staticData: any, pinData: record, meta: record<onboardingId: string, templateId: string, instanceId: string, templateCredsSetupCompleted: bool>, tags: table<id: string, name: string, createdAt: string, updatedAt: string>, shared: table<role: string, workflowId: string, projectId: string, project: record, createdAt: string, updatedAt: string>, activeVersion: record<versionId: string, workflowId: string, nodes: list<record>, connections: record, authors: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($id)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive a workflow
#
# POST /workflows/{id}/unarchive
export def "workflows-unarchive post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, active: bool, createdAt: string, updatedAt: string, isArchived: bool, versionId: string, triggerCount: int, nodes: table<id: string, name: string, webhookId: string, disabled: bool, notesInFlow: bool, notes: string, type: string, typeVersion: float, executeOnce: bool, alwaysOutputData: bool, retryOnFail: bool, maxTries: float, waitBetweenTries: float, continueOnFail: bool, onError: string, position: list, parameters: record, credentials: record, customTelemetryTags: record, createdAt: string, updatedAt: string>, connections: record, settings: record<saveExecutionProgress: bool, saveManualExecutions: bool, saveDataErrorExecution: string, saveDataSuccessExecution: string, executionTimeout: float, errorWorkflow: string, timezone: string, executionOrder: string, callerPolicy: string, callerIds: string, timeSavedPerExecution: float, redactionPolicy: string, availableInMCP: bool, customTelemetryTags: list<record>>, staticData: any, pinData: record, meta: record<onboardingId: string, templateId: string, instanceId: string, templateCredsSetupCompleted: bool>, tags: table<id: string, name: string, createdAt: string, updatedAt: string>, shared: table<role: string, workflowId: string, projectId: string, project: record, createdAt: string, updatedAt: string>, activeVersion: record<versionId: string, workflowId: string, nodes: list<record>, connections: record, authors: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($id)/unarchive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transfer a workflow to another project
#
# PUT /workflows/{id}/transfer
export def "workflows-transfer put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinationProjectId: string # The ID of the project to transfer the workflow to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($id)/transfer")
  let body = {destinationProjectId: $destinationProjectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workflow tags
#
# GET /workflows/{id}/tags
export def "workflows-tags get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($id)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tags of a workflow
#
# PUT /workflows/{id}/tags
export def "workflows-tags put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, name: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($id)/tags")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all users
#
# GET /users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The maximum number of items to return. (default: 100, e.g. 100)
  --offset: float # The number of items to skip before starting to collect the result set. (default: 0, e.g. 0)
  --cursor: string # Paginate by setting the cursor parameter to the nextCursor attribute returned by the previous request's response. Default value fetches the first "page" of the collection. See pagination for more detail.
  --includeRole: string@bool-completer # Whether to include the user's role or not. (default: false, e.g. true)
  --projectId: string # e.g. VmwOO9HeTEj20kxM
]: nothing -> record<data: table<id: string, email: string, firstName: string, lastName: string, isPending: bool, createdAt: string, updatedAt: string, role: string, mfaEnabled: bool>, nextCursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "includeRole" $includeRole "scalar") (serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create multiple users
#
# POST /users
export def "users post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<user: record<id: string, email: string, inviteAcceptUrl: string, emailSent: bool>, error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user by ID/Email
#
# GET /users/{id}
export def "users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeRole: string@bool-completer # Whether to include the user's role or not. (default: false, e.g. true)
]: nothing -> record<id: string, email: string, firstName: string, lastName: string, isPending: bool, createdAt: string, updatedAt: string, role: string, mfaEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeRole" $includeRole "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user
#
# DELETE /users/{id}
export def "users delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change a user's global role
#
# PATCH /users/{id}/role
export def "users-role patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  newRoleName: string # e.g. global:member
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/role")
  let body = {newRoleName: $newRoleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pull changes from the remote repository
#
# POST /source-control/pull
export def "source-control-pull post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string@bool-completer # e.g. true
  --autoPublish: string@autoPublish-completer # Controls automatic workflow publishing after import: - `none`: Keep workflows in their local published state (default) - `all`: Publish all imported workflows - `published`: Publish only workflows that were published locally before import  (default: none, e.g. published)
]: any -> table<file: string, id: string, name: string, type: string, status: string, location: string, conflict: bool, updatedAt: string, pushed: bool, isLocalPublished: bool, isRemoteArchived: bool, parentFolderId: string, folderPath: list<string>, owner: record<type: string, projectId: string, projectName: string>, publishingError: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/source-control/pull")
  let body = {force: $force, autoPublish: $autoPublish} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a variable
#
# POST /variables
export def "variables post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string
  value: string # e.g. test
  --projectId: string # nullable, e.g. VmwOO9HeTEj20kxM
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/variables")
  let body = {key: $key, value: $value, projectId: $projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve variables
#
# GET /variables
export def "variables get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The maximum number of items to return. (default: 100, e.g. 100)
  --cursor: string # Paginate by setting the cursor parameter to the nextCursor attribute returned by the previous request's response. Default value fetches the first "page" of the collection. See pagination for more detail.
  --projectId: string # e.g. VmwOO9HeTEj20kxM
  --state: string@state-completer
]: nothing -> record<data: table<id: string, key: string, value: string, type: string, project: record>, nextCursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a variable
#
# DELETE /variables/{id}
export def "variables delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a variable
#
# PUT /variables/{id}
export def "variables put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string
  value: string # e.g. test
  --projectId: string # nullable, e.g. VmwOO9HeTEj20kxM
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/variables/($id)")
  let body = {key: $key, value: $value, projectId: $projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all data tables
#
# GET /data-tables
# operationId: list-data-tables
export def "data-tables list-data-tables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The maximum number of items to return. (default: 100, e.g. 100)
  --cursor: string # Paginate by setting the cursor parameter to the nextCursor attribute returned by the previous request's response. Default value fetches the first "page" of the collection. See pagination for more detail.
  --filter: string # JSON string of filter conditions (format: jsonString, e.g. {"name":"my-table"})
  --sortBy: string # Sort format: field:asc or field:desc (e.g. name:asc)
]: nothing -> record<data: table<id: string, name: string, columns: list, projectId: string, createdAt: string, updatedAt: string>, nextCursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data-tables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new data table
#
# POST /data-tables
# operationId: create-data-table
# --columns item shape: {name: string, type: "string"|"number"|"boolean"|"date"|"json"}
export def "data-tables create-data-table" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the data table
  columns: list # Column definitions for the table — item shape: {name: string, type: "string"|"number"|"boolean"|"date"|"json"}
  --projectId: string # ID of the project to create the table in. When omitted, the table is created in the user's personal project.
]: any -> record<id: string, name: string, columns: table<id: string, name: string, type: string, index: int>, projectId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data-tables")
  let body = {name: $name, columns: $columns, projectId: $projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a data table
#
# GET /data-tables/{dataTableId}
# operationId: get-data-table
export def "data-tables get-data-table" [
  dataTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, columns: table<id: string, name: string, type: string, index: int>, projectId: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-tables/($dataTableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a data table
#
# PATCH /data-tables/{dataTableId}
# operationId: update-data-table
export def "data-tables update-data-table" [
  dataTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # New name for the data table
]: any -> record<id: string, name: string, columns: table<id: string, name: string, type: string, index: int>, projectId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-tables/($dataTableId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a data table
#
# DELETE /data-tables/{dataTableId}
# operationId: delete-data-table
export def "data-tables delete-data-table" [
  dataTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-tables/($dataTableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve rows from a data table
#
# GET /data-tables/{dataTableId}/rows
# operationId: get-data-table-rows
export def "data-tables-rows get-data-table-rows" [
  dataTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The maximum number of items to return. (default: 100, e.g. 100)
  --cursor: string # Paginate by setting the cursor parameter to the nextCursor attribute returned by the previous request's response. Default value fetches the first "page" of the collection. See pagination for more detail.
  --filter: string # JSON string of filter conditions (format: jsonString, e.g. {"type":"and","filters":[{"columnName":"status","condition":"eq","value":"active"}]})
  --sortBy: string # Sort format: columnName:asc or columnName:desc (e.g. createdAt:desc)
  --search: string # Search text across all string columns
]: nothing -> record<data: table<id: int, createdAt: string, updatedAt: string>, nextCursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data-tables/($dataTableId)/rows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Insert rows into a data table
#
# POST /data-tables/{dataTableId}/rows
# operationId: insert-data-table-rows
export def "data-tables-rows insert-data-table-rows" [
  dataTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # Array of rows to insert. Each row is an object with column names as keys.
  --returnType: string@returnType-completer # - count: Return only the number of rows inserted - id: Return an array of inserted row IDs - all: Return the full row data for all inserted rows  (default: count)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-tables/($dataTableId)/rows")
  let body = {data: $data, returnType: $returnType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update rows in a data table
#
# PATCH /data-tables/{dataTableId}/rows/update
# operationId: update-data-table-rows
# --filter shape: {type?: "and"|"or", filters: list}
export def "data-tables-rows-update update-data-table-rows" [
  dataTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filter: record # Filter conditions to match rows for update — shape: {type?: "and"|"or", filters: list}
  data: record # Column values to update
  --returnData: string@bool-completer # If true, return the updated rows; if false, return true on success (default: false)
  --dryRun: string@bool-completer # If true, preview changes without persisting them (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-tables/($dataTableId)/rows/update")
  let body = {filter: $filter, data: $data, returnData: $returnData, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert a row in a data table
#
# POST /data-tables/{dataTableId}/rows/upsert
# operationId: upsert-data-table-row
# --filter shape: {type?: "and"|"or", filters: list}
export def "data-tables-rows-upsert upsert-data-table-row" [
  dataTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filter: record # Filter conditions to match existing row. If no row matches, a new row is inserted. — shape: {type?: "and"|"or", filters: list}
  data: record # Column values for the row
  --returnData: string@bool-completer # If true, return the upserted row; if false, return true on success (default: false)
  --dryRun: string@bool-completer # If true, preview changes without persisting them (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-tables/($dataTableId)/rows/upsert")
  let body = {filter: $filter, data: $data, returnData: $returnData, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete rows from a data table
#
# DELETE /data-tables/{dataTableId}/rows/delete
# operationId: delete-data-table-rows
export def "data-tables-rows-delete delete-data-table-rows" [
  dataTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # JSON string of filter conditions. Required to prevent accidental deletion of all data. (format: jsonString, e.g. {"type":"and","filters":[{"columnName":"status","condition":"eq","value":"archived"}]})
  --returnData: string@bool-completer # If true, return the deleted rows; if false, return true on success (default: false)
  --dryRun: string@bool-completer # If true, preview which rows would be deleted without actually deleting them (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "returnData" $returnData "scalar") (serialize-qp "dryRun" $dryRun "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data-tables/($dataTableId)/rows/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List columns of a data table
#
# GET /data-tables/{dataTableId}/columns
# operationId: list-data-table-columns
export def "data-tables-columns list-data-table-columns" [
  dataTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, dataTableId: string, type: string, index: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-tables/($dataTableId)/columns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a column to a data table
#
# POST /data-tables/{dataTableId}/columns
# operationId: create-data-table-column
export def "data-tables-columns create-data-table-column" [
  dataTableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Column name. Must start with a letter; only letters, digits, and underscores after that; maximum 63 characters.
  type: string@type-completer # Column data type
  --index: int # Column position (optional, appended to end if omitted)
]: any -> record<id: string, name: string, dataTableId: string, type: string, index: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-tables/($dataTableId)/columns")
  let body = {name: $name, type: $type, index: $index} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a column
#
# DELETE /data-tables/{dataTableId}/columns/{columnId}
# operationId: delete-data-table-column
export def "data-tables-columns delete-data-table-column" [
  dataTableId: string
  columnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-tables/($dataTableId)/columns/($columnId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a column
#
# PATCH /data-tables/{dataTableId}/columns/{columnId}
# operationId: update-data-table-column
export def "data-tables-columns update-data-table-column" [
  dataTableId: string
  columnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Column name. Must start with a letter; only letters, digits, and underscores after that; maximum 63 characters.
  --index: int # New zero-based position for the column
]: any -> record<id: string, name: string, dataTableId: string, type: string, index: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-tables/($dataTableId)/columns/($columnId)")
  let body = {name: $name, index: $index} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a project
#
# POST /projects
export def "projects post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve projects
#
# GET /projects
export def "projects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The maximum number of items to return. (default: 100, e.g. 100)
  --cursor: string # Paginate by setting the cursor parameter to the nextCursor attribute returned by the previous request's response. Default value fetches the first "page" of the collection. See pagination for more detail.
]: nothing -> record<data: table<id: string, name: string, type: string>, nextCursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a project
#
# DELETE /projects/{projectId}
export def "projects delete" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a project
#
# PUT /projects/{projectId}
export def "projects put" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List project members
#
# GET /projects/{projectId}/users
export def "projects-users get" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The maximum number of items to return. (default: 100, e.g. 100)
  --cursor: string # Paginate by setting the cursor parameter to the nextCursor attribute returned by the previous request's response. Default value fetches the first "page" of the collection. See pagination for more detail.
]: nothing -> record<data: table<id: string, email: string, firstName: string, lastName: string, createdAt: string, updatedAt: string, role: string>, nextCursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add one or more users to a project
#
# POST /projects/{projectId}/users
# --relations item shape: {userId: string, role: string}
export def "projects-users post" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  relations: list # A list of userIds and roles to add to the project. — item shape: {userId: string, role: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/users")
  let body = {relations: $relations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user from a project
#
# DELETE /projects/{projectId}/users/{userId}
export def "projects-users delete" [
  projectId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change a user's role in a project
#
# PATCH /projects/{projectId}/users/{userId}
export def "projects-users patch" [
  projectId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role: string # The role assigned to the user in the project. (e.g. project:viewer)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/users/($userId)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Install a community package
#
# POST /community-packages
export def "community-packages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # npm package name (must start with n8n-nodes-)
  --version: string # Specific semver version to install
  --verify: string@bool-completer # Whether to verify the package against the n8n-vetted package list. Required when the instance has N8N_UNVERIFIED_PACKAGES_ENABLED=false.
]: any -> record<packageName: string, installedVersion: string, authorName: string, authorEmail: string, installedNodes: table<name: string, type: string, latestVersion: float>, createdAt: string, updatedAt: string, updateAvailable: string, failedLoading: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community-packages")
  let body = {name: $name, version: $version, verify: $verify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List installed community packages
#
# GET /community-packages
export def "community-packages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<packageName: string, installedVersion: string, authorName: string, authorEmail: string, installedNodes: list<record>, createdAt: string, updatedAt: string, updateAvailable: string, failedLoading: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/community-packages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a community package
#
# PATCH /community-packages/{name}
export def "community-packages patch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # Specific semver version to update to
  --verify: string@bool-completer # Whether to verify the package against the n8n-vetted package list. Setting to false will allow installing or updating to an unverified version. Default is true.
]: any -> record<packageName: string, installedVersion: string, authorName: string, authorEmail: string, installedNodes: table<name: string, type: string, latestVersion: float>, createdAt: string, updatedAt: string, updateAvailable: string, failedLoading: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/community-packages/($name)")
  let body = {version: $version, verify: $verify} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Uninstall a community package
#
# DELETE /community-packages/{name}
export def "community-packages delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/community-packages/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Discover available API capabilities
#
# GET /discover
export def "discover get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer # Include additional data. Use "schemas" to inline request body schemas per endpoint, eliminating the need to fetch the full OpenAPI spec.
  --resource: string # Filter to a specific resource (e.g. "workflow", "tags", "credential").
  --operation: string # Filter to endpoints with a specific operation (e.g. "read", "create", "list").
]: nothing -> record<data: record<scopes: list<string>, resources: record, filters: record, specUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "resource" $resource "scalar") (serialize-qp "operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve insights summary
#
# GET /insights/summary
export def "insights-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # ISO 8601 start date. Defaults to 7 days ago. (format: date-time)
  --endDate: string # ISO 8601 end date. Defaults to now. (format: date-time)
  --projectId: string # Project identifier to filter insights by project. (e.g. VmwOO9HeTEj20kxM)
]: nothing -> record<total: record<value: float, deviation: float, unit: string>, failed: record<value: float, deviation: float, unit: string>, failureRate: record<value: float, deviation: float, unit: string>, timeSaved: record<value: float, deviation: float, unit: string>, averageRunTime: record<value: float, deviation: float, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/insights/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a folder
#
# POST /projects/{projectId}/folders
export def "projects-folders post" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. My Folder
  --parentFolderId: string # e.g. abc123
]: any -> record<id: string, name: string, parentFolderId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/folders")
  let body = {name: $name, parentFolderId: $parentFolderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve folders
#
# GET /projects/{projectId}/folders
export def "projects-folders list" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # JSON-encoded filter object. Supported fields — parentFolderId, name, tags (array of tag names), excludeFolderIdAndDescendants. (e.g. {"parentFolderId":"abc123","name":"My Folder"})
  --select: string # JSON-encoded array of fields to include. Valid fields — id, name, createdAt, updatedAt, project, tags, parentFolder, workflowCount, subFolderCount, path. (e.g. ["id","name","tags","workflowCount"])
  --sortBy: string@sortBy-completer # Sort order for results.
  --skip: string # Number of items to skip for pagination. Defaults to 0.
  --take: string # Number of items to return. Defaults to 10.
]: nothing -> record<count: int, data: table<id: string, name: string, parentFolderId: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a folder
#
# DELETE /projects/{projectId}/folders/{folderId}
export def "projects-folders delete" [
  projectId: string
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transferToFolderId: string # Optional target folder ID to move workflows and sub-folders into before deleting.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "transferToFolderId" $transferToFolderId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/folders/($folderId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get folder details
#
# GET /projects/{projectId}/folders/{folderId}
export def "projects-folders get" [
  projectId: string
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, parentFolderId: string, createdAt: string, updatedAt: string, totalSubFolders: int, totalWorkflows: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/folders/($folderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a folder
#
# PATCH /projects/{projectId}/folders/{folderId}
export def "projects-folders patch" [
  projectId: string
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # e.g. Renamed Folder
  --parentFolderId: string # e.g. abc123
]: any -> record<id: string, name: string, parentFolderId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/folders/($folderId)")
  let body = {name: $name, parentFolderId: $parentFolderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Beta: Export workflows as an n8n package
#
# POST /n8n-packages/export
export def "n8n-packages-export post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workflowIds: list # IDs of the workflows to include in the exported package. (e.g. [2tUt1wbLX592XDdX])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/n8n-packages/export")
  let body = {workflowIds: $workflowIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/gzip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Beta: Import an n8n package into a project
#
# POST /n8n-packages/import
export def "n8n-packages-import post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package: string # Gzip-compressed tar package (`.n8np`). (format: binary)
  --projectId: string # Target project id. Omit or send empty to import into the caller's personal project.
  --folderId: string # Optional folder within the target project. Omit or send empty for project root.
  --credentialMatchingMode: string@credentialMatchingMode-completer # How credential references in `requirements.credentials` are matched on the target instance. Only `id-only` is supported today.  (default: id-only)
  --credentialMissingMode: string@credentialMissingMode-completer # What to do when a credential reference cannot be resolved. `must-preexist` requires every referenced credential to already exist and be accessible on the target instance.  (default: must-preexist)
  workflowConflictPolicy: string@workflowConflictPolicy-completer # `new-version` updates matching workflows and creates a new version, `fail` rejects the import when any matching workflow exists, and       description: Workflow id on the target instance (newly created for `created`, existing for `updated`/`skipped`).
]: any -> record<package: record<sourceN8nVersion: string, sourceId: string, exportedAt: string>, workflows: table<sourceWorkflowId: string, localId: string, name: string, projectId: string, parentFolderId: string, activeVersionId: string, status: string>, bindings: record<workflows: record, credentials: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-n8n-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/n8n-packages/import")
  let body = {package: $package, projectId: $projectId, folderId: $folderId, credentialMatchingMode: $credentialMatchingMode, credentialMissingMode: $credentialMissingMode, workflowConflictPolicy: $workflowConflictPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}
