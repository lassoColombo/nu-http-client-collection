# Auto-generated client for Kestra EE v2.0.0-SNAPSHOT
# Source: https://raw.githubusercontent.com/kestra-io/client-sdk/main/kestra-ee.yml
# Auth: --token flag or $env.KESTRA_EE_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KESTRA_EE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["basic" "bearer"] }

# Completers for enum parameters
def type-completer [] { ["ERROR" "INFO" "WARNING"] }
def serviceType-completer [] { ["CONTROLLER" "EXECUTOR" "INDEXER" "INVALID" "SCHEDULER" "WEBSERVER" "WORKER"] }
def mode-completer [] { ["ELASTIC" "STRICT" "UNKNOWN"] }
def evaluationType-completer [] { ["CANCEL" "IGNORE" "KILL" "PASS"] }
def resource-completer [] { ["APP" "APP_EXECUTION" "ASSET" "AUDITLOG" "BINDING" "BLUEPRINT" "COPILOT" "CREDENTIAL" "DASHBOARD" "EXECUTION" "FLOW" "GROUP" "INSTANCE" "INVITATION" "KILL_SWITCH" "KVSTORE" "MCP_SERVER" "NAMESPACE" "NAMESPACE_FILE" "ROLE" "SECRET" "SECURITY_INTEGRATION" "SERVICE_ACCOUNT" "SYSTEM_SETTINGS" "TENANT" "TENANT_ACCESS" "TENANT_SETTINGS" "TESTSUITE" "TESTSUITE_RUN" "TRIGGER" "UNKNOWN" "USER" "VERSIONED_PLUGIN" "WORKER_GROUP" "WORKER_QUEUE"] }
def type-completer-1 [] { ["GROUP" "USER"] }
def kind-completer [] { ["APP" "DASHBOARD" "FLOW"] }
def type-completer-2 [] { ["GITHUB_APP" "OAUTH2"] }
def newStatus-completer [] { ["BREAKPOINT" "CANCELLED" "CREATED" "FAILED" "KILLED" "KILLING" "PAUSED" "QUEUED" "RESTARTED" "RESUBMITTED" "RETRIED" "RETRYING" "RUNNING" "SKIPPED" "SUBMITTED" "SUCCESS" "WARNING"] }
def field-completer [] { ["ACTION" "ARTIFACT_ID" "ASSET_ID" "ATTEMPT_NUMBER" "CHILD_FILTER" "CREATED" "DETAILS" "EMAIL" "ENABLED" "END_DATE" "EXECUTION_ID" "EXISTING_ONLY" "EXPIRATION_DATE" "EXPIRED_AT" "EXTERNAL_ID" "FLOW_ID" "FLOW_REVISION" "GROUP" "ID" "KIND" "LABELS" "LAST_TRIGGERED_DATE" "LEVEL" "LOCKED" "METADATA" "NAME" "NAMESPACE" "NEXT_EXECUTION_DATE" "PARENT_ID" "PARENT_PATH" "PATH" "QUERY" "RESOURCES" "SCOPE" "SOURCE" "START_DATE" "STATE" "STATUS" "SUPER_ADMIN" "TAGS" "TASK_ID" "TASK_RUN_ID" "TIME_RANGE" "TRIGGER_EXECUTION_ID" "TRIGGER_ID" "TRIGGER_STATE" "TYPE" "UPDATED" "USERNAME" "USER_ID" "VERSION" "WORKER_ID"] }
def state-completer [] { ["BREAKPOINT" "CANCELLED" "CREATED" "FAILED" "KILLED" "KILLING" "PAUSED" "QUEUED" "RESTARTED" "RESUBMITTED" "RETRIED" "RETRYING" "RUNNING" "SKIPPED" "SUBMITTED" "SUCCESS" "WARNING"] }
def status-completer [] { ["BREAKPOINT" "CANCELLED" "CREATED" "FAILED" "KILLED" "KILLING" "PAUSED" "QUEUED" "RESTARTED" "RESUBMITTED" "RETRIED" "RETRYING" "RUNNING" "SKIPPED" "SUBMITTED" "SUCCESS" "WARNING"] }
def section-completer [] { ["TASKS" "TRIGGERS"] }
def membership-completer [] { ["MEMBER" "OWNER"] }
def type-completer-3 [] { ["SCIM"] }
def dateFilter-completer [] { ["LAST_TRIGGERED_DATE" "NEXT_EXECUTION_DATE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auditlogs-export exportAuditLogsForAllTenants" } } | get name | first)
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

# Export all audit logs as a streamed CSV file
#
# GET /api/v1/auditlogs/export
# operationId: exportAuditLogsForAllTenants
export def "auditlogs-export exportAuditLogsForAllTenants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A string filter (nullable)
  --namespace: string # A namespace filter (nullable)
  --flowId: string # A flow id filter (nullable)
  --executionId: string # An execution filter (nullable)
  --userId: string # A user id filter (nullable)
  --id: string # A id filter (nullable)
  --resources: list # A resource filter (nullable)
  --startDate: string # The start datetime (nullable, format: date-time)
  --endDate: string # The end datetime (nullable, format: date-time)
  --details: record # A list of auditLog details (nullable)
  --type: string # The event that create the audit log (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "flowId" $flowId "scalar") (serialize-qp "executionId" $executionId "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "resources" $resources "csv") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "details" $details "csv") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/auditlogs/export" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for audit logs across all tenants, required to be SuperAdmin
#
# GET /api/v1/auditlogs/search
# operationId: searchAuditLogsForAllTenants
export def "auditlogs-search searchAuditLogsForAllTenants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # A list of query filters (nullable)
]: nothing -> record<results: table<auditLog: record, user: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/auditlogs/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the diff between audit logs from global resource like users
#
# GET /api/v1/auditlogs/{id}/diff
# operationId: getGlobalResourceDiffFromAuditLog
export def "auditlogs-diff list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --previousId: string # The id of a previous audit log to compare with (nullable)
]: nothing -> record<before: string, after: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "previousId" $previousId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/auditlogs/($id)/diff" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve list of authentication methods
#
# GET /api/v1/auths
# operationId: index
export def "auths index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<loginPassword: bool, mailsEnabled: bool, passwordless: bool, oauths: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auths")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an announcement banner
#
# POST /api/v1/banners
# operationId: createBanner
export def "banners createBanner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  message: string
  --type: string@type-completer
  --startDate: string # nullable, format: date-time
  --endDate: string # nullable, format: date-time
  --tenantId: string # nullable
  --active: oneof<nothing, bool>
]: any -> record<id: string, message: string, type: string, startDate: string, endDate: string, tenantId: string, active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/banners")
  let body = {id: $id, message: $message, type: $type, startDate: $startDate, endDate: $endDate, tenantId: $tenantId, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all announcement banners
#
# GET /api/v1/banners/search
# operationId: searchBanners
export def "banners-search searchBanners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # A list of query filters (nullable)
]: nothing -> table<id: string, message: string, type: string, startDate: string, endDate: string, tenantId: string, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/banners/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an announcement banner
#
# PUT /api/v1/banners/{id}
# operationId: updateBanner
export def "banners updateBanner" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  message: string
  --type: string@type-completer
  --startDate: string # nullable, format: date-time
  --endDate: string # nullable, format: date-time
  --tenantId: string # nullable
  --active: oneof<nothing, bool>
]: any -> record<id: string, message: string, type: string, startDate: string, endDate: string, tenantId: string, active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/banners/($id)")
  let body = {id: $body_id, message: $message, type: $type, startDate: $startDate, endDate: $endDate, tenantId: $tenantId, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an announcement banner
#
# DELETE /api/v1/banners/{id}
# operationId: deleteBanner
export def "banners delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/banners/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the instance configuration.
#
# GET /api/v1/basicAuthValidationErrors
# operationId: getBasicAuthConfigErrors
export def "basic-auth-validation-errors get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/basicAuthValidationErrors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the instance configuration.
#
# GET /api/v1/configs
# operationId: getConfiguration
export def "configs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/configs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends an email to reset a password.
#
# GET /api/v1/forgotten-password
# operationId: forgottenPassword
export def "forgotten-password forgottenPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # User that has forgotten his password
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/forgotten-password" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enter cluster maintenance mode
#
# POST /api/v1/instance/maintenance/enter
# operationId: enterMaintenance
export def "instance-maintenance-enter enterMaintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/maintenance/enter")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exit cluster maintenance mode
#
# POST /api/v1/instance/maintenance/exit
# operationId: exitMaintenance
export def "instance-maintenance-exit exitMaintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/maintenance/exit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get maintenance mode status
#
# GET /api/v1/instance/maintenance/status
# operationId: maintenanceStatus
export def "instance-maintenance-status maintenanceStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<maintenance: bool, ready: bool, services: record<EXECUTOR: record<total: int, inMaintenance: int>, INDEXER: record<total: int, inMaintenance: int>, SCHEDULER: record<total: int, inMaintenance: int>, WEBSERVER: record<total: int, inMaintenance: int>, WORKER: record<total: int, inMaintenance: int>, CONTROLLER: record<total: int, inMaintenance: int>, INVALID: record<total: int, inMaintenance: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/maintenance/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all MCP servers across all tenants
#
# GET /api/v1/instance/mcp/servers
# operationId: listAllMcpServers
export def "instance-mcp-servers listAllMcpServers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 100)
  --qp-sort: list # The sort of current page (nullable)
]: nothing -> record<results: table<tenantId: string, id: string, description: string, serverType: record, authType: record, disabled: bool, isDefault: bool, created: string, updated: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/instance/mcp/servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics for running services
#
# GET /api/v1/instance/metrics/{serviceType}
# operationId: metrics
export def "instance-metrics metrics" [
  serviceType: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --serviceType: string@serviceType-completer
]: nothing -> table<name: string, type: string, description: string, baseUnit: string, tags: list<record>, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceType" $serviceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/instance/metrics/($serviceType)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all active services
#
# GET /api/v1/instance/services/active
# operationId: getActiveServices
export def "instance-services-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<total: int, services: table<type: string, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/services/active")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for a service (e.g. Worker, Executor, etc)
#
# GET /api/v1/instance/services/search
# operationId: searchServices
export def "instance-services-search searchServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<id: string, type: string, state: string, server: record, createdAt: string, updatedAt: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/instance/services/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve details of a specific service
#
# GET /api/v1/instance/services/{id}
# operationId: getService
export def "instance-services get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<server: record<id: string, type: string, version: string, hostname: string, props: record, metrics: list<record>>, metrics: table<name: string, type: string, description: string, baseUnit: string, tags: list, value: float>, state: string, id: string, type: string, createdAt: string, updatedAt: string, events: table<ts: string, value: string, type: string, state: string>, props: record, seqId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/services/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List installed plugin artifacts
#
# GET /api/v1/instance/versioned-plugins
# operationId: listVersionedPlugin
export def "instance-versioned-plugins listVersionedPlugin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<title: string, icon: string, groupId: string, artifactId: string, versions: list, releaseNotesUrl: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/instance/versioned-plugins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available plugin artifacts
#
# GET /api/v1/instance/versioned-plugins/available
# operationId: listAvailableVersionedPlugins
export def "instance-versioned-plugins-available listAvailableVersionedPlugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/versioned-plugins/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available plugin artifacts for Kestra Secret Manager
#
# GET /api/v1/instance/versioned-plugins/available/secrets-managers
# operationId: listAvailableVersionedPluginsForSecretManager
export def "instance-versioned-plugins-available-secrets-managers listAvailableVersionedPluginsForSecretManager" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/versioned-plugins/available/secrets-managers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available plugin artifacts for Kestra Internal Storage
#
# GET /api/v1/instance/versioned-plugins/available/storages
# operationId: listAvailableVersionedPluginsForStorage
export def "instance-versioned-plugins-available-storages listAvailableVersionedPluginsForStorage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/versioned-plugins/available/storages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Install specified plugin artifacts
#
# POST /api/v1/instance/versioned-plugins/install
# operationId: installVersionedPlugins
export def "instance-versioned-plugins-install installVersionedPlugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --plugins: list
]: any -> record<total: int, results: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/versioned-plugins/install")
  let body = {plugins: $plugins} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resolve versions for specified plugin artifacts
#
# POST /api/v1/instance/versioned-plugins/resolve
# operationId: resolveVersionedPlugins
export def "instance-versioned-plugins-resolve resolveVersionedPlugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --plugins: list
]: any -> record<total: int, results: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/versioned-plugins/resolve")
  let body = {plugins: $plugins} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Uninstall plugin artifacts
#
# DELETE /api/v1/instance/versioned-plugins/uninstall
# operationId: uninstallVersionedPlugins
export def "instance-versioned-plugins-uninstall uninstallVersionedPlugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --plugins: list
]: any -> record<total: int, results: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/versioned-plugins/uninstall")
  let body = {plugins: $plugins} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload a plugin artifact JAR file
#
# POST /api/v1/instance/versioned-plugins/upload
# operationId: uploadVersionedPlugins
export def "instance-versioned-plugins-upload uploadVersionedPlugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # format: binary
  --forceInstallOnExistingVersions: oneof<nothing, bool> # nullable
]: any -> record<groupId: string, artifactId: string, extension: string, classifier: string, version: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/versioned-plugins/upload")
  let body = {file: $file, forceInstallOnExistingVersions: $forceInstallOnExistingVersions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve details of a plugin artifact
#
# GET /api/v1/instance/versioned-plugins/{groupId}/{artifactId}
# operationId: getVersionedPluginDetails
export def "instance-versioned-plugins list" [
  groupId: string
  artifactId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<groupId: string, artifactId: string, versions: table<version: string, metadata: record, releaseNotesUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/versioned-plugins/($groupId)/($artifactId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch release notes content for a plugin version
#
# GET /api/v1/instance/versioned-plugins/{groupId}/{artifactId}/release-notes
# operationId: getPluginReleaseNotesContent
export def "instance-versioned-plugins-release-notes get" [
  groupId: string
  artifactId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/instance/versioned-plugins/($groupId)/($artifactId)/release-notes" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve details of a specific plugin artifact version
#
# GET /api/v1/instance/versioned-plugins/{groupId}/{artifactId}/{version}
# operationId: getVersionedPluginDetailsFromVersion
export def "instance-versioned-plugins get" [
  groupId: string
  artifactId: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<artifactId: string, groupId: string, version: string, title: string, description: string, icon: string, classes: table<type: string, classes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/versioned-plugins/($groupId)/($artifactId)/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all worker groups
#
# GET /api/v1/instance/worker-groups
# operationId: list
export def "instance-worker-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # A list of query filters (nullable)
]: nothing -> record<workerGroups: table<id: string, name: string, description: string, subscriptions: list, tokens: list, deletable: bool, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/instance/worker-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a worker group
#
# POST /api/v1/instance/worker-groups
# operationId: create
# --subscriptions item shape: {workerQueueId: string, reservedPercent?: int, mode?: "STRICT"|"ELASTIC"|"UNKNOWN"}
export def "instance-worker-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string
  name: string
  --description: string
  subscriptions: list # item shape: {workerQueueId: string, reservedPercent?: int, mode?: "STRICT"|"ELASTIC"|"UNKNOWN"}
]: any -> record<id: string, name: string, description: string, subscriptions: table<queue: record, reservedPercent: int, mode: string>, tokens: table<uid: string, name: string, description: string, tokenPrefix: string, createdAt: string, expiresAt: string, useCount: int, revoked: bool, valid: bool>, deletable: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/worker-groups")
  let body = {id: $id, name: $name, description: $description, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get worker group detail
#
# GET /api/v1/instance/worker-groups/{id}
# operationId: get
export def "instance-worker-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, subscriptions: table<queue: record, reservedPercent: int, mode: string>, tokens: table<uid: string, name: string, description: string, tokenPrefix: string, createdAt: string, expiresAt: string, useCount: int, revoked: bool, valid: bool>, deletable: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a worker group
#
# PUT /api/v1/instance/worker-groups/{id}
# operationId: update
# --subscriptions item shape: {workerQueueId: string, reservedPercent?: int, mode?: "STRICT"|"ELASTIC"|"UNKNOWN"}
export def "instance-worker-groups update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  subscriptions: list # item shape: {workerQueueId: string, reservedPercent?: int, mode?: "STRICT"|"ELASTIC"|"UNKNOWN"}
]: any -> record<id: string, name: string, description: string, subscriptions: table<queue: record, reservedPercent: int, mode: string>, tokens: table<uid: string, name: string, description: string, tokenPrefix: string, createdAt: string, expiresAt: string, useCount: int, revoked: bool, valid: bool>, deletable: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-groups/($id)")
  let body = {name: $name, description: $description, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a worker group
#
# DELETE /api/v1/instance/worker-groups/{id}
# operationId: delete
export def "instance-worker-groups delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Live capacity snapshot for a worker group
#
# GET /api/v1/instance/worker-groups/{id}/capacity
# operationId: getCapacity
export def "instance-worker-groups-capacity get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workerGroupId: string, totalAllocated: int, totalUsed: int, totalInflight: int, subscriptions: table<workerQueueId: string, allocated: int, used: int>, shared: record<allocated: int, used: int>, snapshotAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-groups/($id)/capacity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Worker Queue subscription to a worker group
#
# POST /api/v1/instance/worker-groups/{id}/subscriptions
# operationId: addSubscription
export def "instance-worker-groups-subscriptions addSubscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  workerQueueId: string
  --reservedPercent: int # format: int32
  --mode: string@mode-completer
]: any -> record<id: string, name: string, description: string, subscriptions: table<queue: record, reservedPercent: int, mode: string>, tokens: table<uid: string, name: string, description: string, tokenPrefix: string, createdAt: string, expiresAt: string, useCount: int, revoked: bool, valid: bool>, deletable: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-groups/($id)/subscriptions")
  let body = {workerQueueId: $workerQueueId, reservedPercent: $reservedPercent, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a subscription by WorkerQueue id
#
# DELETE /api/v1/instance/worker-groups/{id}/subscriptions/{workerQueueId}
# operationId: removeSubscription
export def "instance-worker-groups-subscriptions removeSubscription" [
  id: string
  workerQueueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, subscriptions: table<queue: record, reservedPercent: int, mode: string>, tokens: table<uid: string, name: string, description: string, tokenPrefix: string, createdAt: string, expiresAt: string, useCount: int, revoked: bool, valid: bool>, deletable: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-groups/($id)/subscriptions/($workerQueueId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a subscription's reserved capacity
#
# PATCH /api/v1/instance/worker-groups/{id}/subscriptions/{workerQueueId}
# operationId: updateSubscriptionReservation
export def "instance-worker-groups-subscriptions updateSubscriptionReservation" [
  id: string
  workerQueueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservedPercent: int # format: int32
]: any -> record<id: string, name: string, description: string, subscriptions: table<queue: record, reservedPercent: int, mode: string>, tokens: table<uid: string, name: string, description: string, tokenPrefix: string, createdAt: string, expiresAt: string, useCount: int, revoked: bool, valid: bool>, deletable: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-groups/($id)/subscriptions/($workerQueueId)")
  let body = {reservedPercent: $reservedPercent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate a registration token
#
# POST /api/v1/instance/worker-groups/{id}/tokens
# operationId: generateToken
export def "instance-worker-groups-tokens generateToken" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --expiresAt: string # format: date-time
]: any -> record<token: string, details: record<uid: string, name: string, description: string, tokenPrefix: string, createdAt: string, expiresAt: string, useCount: int, revoked: bool, valid: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-groups/($id)/tokens")
  let body = {name: $name, description: $description, expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a registration token
#
# DELETE /api/v1/instance/worker-groups/{id}/tokens/{tokenId}
# operationId: deleteToken
export def "instance-worker-groups-tokens delete" [
  id: string
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-groups/($id)/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke a registration token
#
# POST /api/v1/instance/worker-groups/{id}/tokens/{tokenId}/revoke
# operationId: revokeToken
export def "instance-worker-groups-tokens-revoke revokeToken" [
  id: string
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, subscriptions: table<queue: record, reservedPercent: int, mode: string>, tokens: table<uid: string, name: string, description: string, tokenPrefix: string, createdAt: string, expiresAt: string, useCount: int, revoked: bool, valid: bool>, deletable: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-groups/($id)/tokens/($tokenId)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List running workers for a worker group
#
# GET /api/v1/instance/worker-groups/{id}/workers
# operationId: listRunningWorkers
export def "instance-worker-groups-workers listRunningWorkers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workers: table<workerId: string, workerName: string, credentialId: string, tokenUid: string, state: string, createdAt: string, updatedAt: string, registeredAt: string, capacity: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-groups/($id)/workers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Worker Queues
#
# GET /api/v1/instance/worker-queues
# operationId: list_1
export def "instance-worker-queues list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workerQueues: table<id: string, name: string, description: string, tags: list, allowedTenants: list, activeWorkers: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/worker-queues")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Worker Queue
#
# POST /api/v1/instance/worker-queues
# operationId: create_1
export def "instance-worker-queues create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # User-supplied RFC 1123 label, used as the routing identity, the Prometheus tag value, and in log output. Immutable.
  --name: string # Optional human-readable name.
  tags: list # The canonical tag set of the Worker Queue (non-empty).
  --description: string # The description of the Worker Queue.
  --allowedTenants: list # The tenant scope; empty means unrestricted.
]: any -> record<id: string, name: string, description: string, tags: list<string>, allowedTenants: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/worker-queues")
  let body = {id: $id, name: $name, tags: $tags, description: $description, allowedTenants: $allowedTenants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Worker Queue detail
#
# GET /api/v1/instance/worker-queues/{id}
# operationId: get_1
export def "instance-worker-queues get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, tags: list<string>, allowedTenants: list<string>, workers: table<server: record, metrics: list, state: string, id: string, type: string, createdAt: string, updatedAt: string, events: list, props: record, seqId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-queues/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Worker Queue
#
# PUT /api/v1/instance/worker-queues/{id}
# operationId: update_1
export def "instance-worker-queues update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # User-supplied RFC 1123 label, used as the routing identity, the Prometheus tag value, and in log output. Immutable.
  --name: string # Optional human-readable name.
  tags: list # The canonical tag set of the Worker Queue (non-empty).
  --description: string # The description of the Worker Queue.
  --allowedTenants: list # The tenant scope; empty means unrestricted.
]: any -> record<id: string, name: string, description: string, tags: list<string>, allowedTenants: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-queues/($id)")
  let body = {id: $body_id, name: $name, tags: $tags, description: $description, allowedTenants: $allowedTenants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Worker Queue
#
# DELETE /api/v1/instance/worker-queues/{id}
# operationId: delete_1
export def "instance-worker-queues delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/worker-queues/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all registered workers
#
# GET /api/v1/instance/workers/credentials
# operationId: list_2
export def "instance-workers-credentials list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workers: table<id: string, workerId: string, workerName: string, tokenUid: string, createdAt: string, lastSeenAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/instance/workers/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get worker credentials ID
#
# GET /api/v1/instance/workers/credentials/{id}
# operationId: get_2
export def "instance-workers-credentials get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, workerId: string, workerName: string, tokenUid: string, createdAt: string, lastSeenAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/workers/credentials/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke worker credentials
#
# POST /api/v1/instance/workers/credentials/{id}/revoke
# operationId: revoke
export def "instance-workers-credentials-revoke revoke" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, workerId: string, workerName: string, tokenUid: string, createdAt: string, lastSeenAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/instance/workers/credentials/($id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/invitation/accept/{invitationId}
#
# operationId: acceptInvitation
export def "invitation-accept acceptInvitation" [
  invitationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/invitation/accept/($invitationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/invitation/create/{invitationId}
#
# operationId: createFromInvitation
export def "invitation-create createFromInvitation" [
  invitationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  firstName: string
  lastName: string
  password: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/invitation/create/($invitationId)")
  let body = {firstName: $firstName, lastName: $lastName, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a kill switch
#
# POST /api/v1/kill-switches
# operationId: createKillSwitch
export def "kill-switches createKillSwitch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  name: string
  --tenantId: string
  --namespace: string
  --flowId: string
  --executionIds: list
  startDate: string # format: date-time
  --endDate: string # format: date-time
  --description: string
  evaluationType: string@evaluationType-completer
  --enabled: oneof<nothing, bool>
  --deleted: oneof<nothing, bool>
]: any -> record<id: string, name: string, tenantId: string, namespace: string, flowId: string, executionIds: list<string>, startDate: string, endDate: string, description: string, evaluationType: string, enabled: bool, deleted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/kill-switches")
  let body = {id: $id, name: $name, tenantId: $tenantId, namespace: $namespace, flowId: $flowId, executionIds: $executionIds, startDate: $startDate, endDate: $endDate, description: $description, evaluationType: $evaluationType, enabled: $enabled, deleted: $deleted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all kill switches
#
# GET /api/v1/kill-switches/search
# operationId: searchKillSwitches
export def "kill-switches-search searchKillSwitches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, tenantId: string, namespace: string, flowId: string, executionIds: list<string>, startDate: string, endDate: string, description: string, evaluationType: string, enabled: bool, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/kill-switches/search")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a kill switch
#
# PUT /api/v1/kill-switches/{id}
# operationId: updateKillSwitch
export def "kill-switches updateKillSwitch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  name: string
  --tenantId: string
  --namespace: string
  --flowId: string
  --executionIds: list
  startDate: string # format: date-time
  --endDate: string # format: date-time
  --description: string
  evaluationType: string@evaluationType-completer
  --enabled: oneof<nothing, bool>
  --deleted: oneof<nothing, bool>
]: any -> record<id: string, name: string, tenantId: string, namespace: string, flowId: string, executionIds: list<string>, startDate: string, endDate: string, description: string, evaluationType: string, enabled: bool, deleted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/kill-switches/($id)")
  let body = {id: $body_id, name: $name, tenantId: $tenantId, namespace: $namespace, flowId: $flowId, executionIds: $executionIds, startDate: $startDate, endDate: $endDate, description: $description, evaluationType: $evaluationType, enabled: $enabled, deleted: $deleted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a kill switch
#
# DELETE /api/v1/kill-switches/{id}
# operationId: deleteKillSwitch
export def "kill-switches delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/kill-switches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve license information
#
# GET /api/v1/license-info
# operationId: licenseInfo
export def "license-info licenseInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, expiry: string, expired: bool, maxServers: int, standalone: bool, workerGroups: bool, online: bool, gracePeriod: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/license-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force the refresh of the license online
#
# GET /api/v1/license/refresh
# operationId: refreshLicense
export def "license-refresh refreshLicense" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/license/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if flows are present on the main tenant.
#
# GET /api/v1/main-tenant-flows
# operationId: mainTenantFlows
export def "main-tenant-flows mainTenantFlows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/main-tenant-flows")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details about the authenticated user
#
# GET /api/v1/me
# operationId: getCurrentUser
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, superAdmin: bool, restricted: bool, profile: record<email: string, firstName: string, lastName: string, username: string>, auths: table<name: string, type: string>, tenants: table<id: string, name: string, logo: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update authenticated user details
#
# PATCH /api/v1/me
# operationId: patchCurrentUser
export def "me patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --firstName: string
  --lastName: string
  --email: string
]: any -> record<id: string, superAdmin: bool, restricted: bool, profile: record<email: string, firstName: string, lastName: string, username: string>, auths: table<name: string, type: string>, tenants: table<id: string, name: string, logo: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/me")
  let body = {firstName: $firstName, lastName: $lastName, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List API tokens for authenticated user
#
# GET /api/v1/me/api-tokens
# operationId: listApiTokensForCurrentUser
export def "me-api-tokens listApiTokensForCurrentUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<total: int, results: table<id: string, name: string, description: string, prefix: string, iat: string, exp: string, lastUsed: string, extended: bool, expired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/me/api-tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create API token for the authenticated user
#
# POST /api/v1/me/api-tokens
# operationId: createApiTokenForCurrentUser
export def "me-api-tokens createApiTokenForCurrentUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --maxAge: string
  --extended: oneof<nothing, bool>
]: any -> record<id: string, name: string, fullToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/me/api-tokens")
  let body = {name: $name, description: $description, maxAge: $maxAge, extended: $extended} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete API token for the authenticated user
#
# DELETE /api/v1/me/api-tokens/{tokenId}
# operationId: deleteApiTokenForCurrentUser
export def "me-api-tokens delete" [
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/me/api-tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List invitations for the authenticated user
#
# GET /api/v1/me/invitations
# operationId: findAllInvitationsForCurrentUser
export def "me-invitations findAllInvitationsForCurrentUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<isExpired: bool, email: string, id: string, bindings: list<record>, groupIds: list<string>, tenantId: string, status: string, sentAt: string, expiredAt: string, acceptedAt: string, deleted: bool, userType: string, superAdmin: bool, link: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/me/invitations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update authenticated user password
#
# PUT /api/v1/me/password
# operationId: updateCurrentUserPassword
export def "me-password updateCurrentUserPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --oldPassword: string
  --newPassword: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/me/password")
  let body = {oldPassword: $oldPassword, newPassword: $newPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the list of available Pebble expression filters.
#
# GET /api/v1/pebble/filters
# operationId: getExpressionFilters
export def "pebble-filters get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/pebble/filters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the available Pebble expression functions with their arguments and defaults.
#
# GET /api/v1/pebble/functions
# operationId: getExpressionFunctions
export def "pebble-functions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, arguments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/pebble/functions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of plugins
#
# GET /api/v1/plugins
# operationId: listPlugins
export def "plugins listPlugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10000)
  --qp-sort: list # A list of sort fields (nullable)
  --filters: list # A list of query filters (nullable)
]: nothing -> record<results: table<name: string, title: string, description: string, license: string, longDescription: string, group: string, version: string, manifest: record, guides: list, aliases: list, tasks: list, triggers: list, controllers: list, storages: list, secrets: list, taskRunners: list, apps: list, appBlocks: list, charts: list, dataFilters: list, dataFiltersKPI: list, logExporters: list, additionalPlugins: list, categories: list, subGroup: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/plugins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plugins group by subgroups
#
# GET /api/v1/plugins/groups/subgroups
# operationId: getPluginBySubgroups
export def "plugins-groups-subgroups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, title: string, description: string, license: string, longDescription: string, group: string, version: string, manifest: record, guides: list<string>, aliases: list<string>, tasks: list<record>, triggers: list<record>, controllers: list<record>, storages: list<record>, secrets: list<record>, taskRunners: list<record>, apps: list<record>, appBlocks: list<record>, charts: list<record>, dataFilters: list<record>, dataFiltersKPI: list<record>, logExporters: list<record>, additionalPlugins: list<record>, categories: list<string>, subGroup: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/groups/subgroups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plugins icons
#
# GET /api/v1/plugins/icons
# operationId: getPluginIcons
export def "plugins-icons get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/icons")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plugins icons
#
# GET /api/v1/plugins/icons/groups
# operationId: getPluginGroupIcons
export def "plugins-icons-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/icons/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all types for an inputs
#
# GET /api/v1/plugins/inputs
# operationId: getAllInputTypes
export def "plugins-inputs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<type: string, cls: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/inputs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the JSON schema for an input type
#
# GET /api/v1/plugins/inputs/{type}
# operationId: getSchemaFromInputType
export def "plugins-inputs get" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<markdown: string, schema: record<properties: record, outputs: record, definitions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/plugins/inputs/($type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plugins group by subgroups
#
# POST /api/v1/plugins/pluginUiManifest
# operationId: getPluginUiManifest
export def "plugins-plugin-ui-manifest post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<manifest: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/pluginUiManifest")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the properties part of the JSON schema for a type
#
# GET /api/v1/plugins/properties/{type}
# operationId: getPropertiesFromType
export def "plugins-properties get" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/plugins/properties/($type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the JSON schema for a type
#
# GET /api/v1/plugins/schemas/{type}
# operationId: getSchemasFromType
export def "plugins-schemas get" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --arrayOf: oneof<nothing, bool> # If schema should be an array of requested type (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "arrayOf" $arrayOf "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/plugins/schemas/($type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of trigger plugins grouped by category
#
# GET /api/v1/plugins/triggers
# operationId: listTriggerPlugins
export def "plugins-triggers listTriggerPlugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<type: string, name: string, description: string, group: string, ee: bool, icon: string, deprecated: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/triggers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plugin documentation
#
# GET /api/v1/plugins/{cls}
# operationId: getPluginDocumentation
export def "plugins get" [
  cls: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Include all the properties (default: false)
]: nothing -> record<markdown: string, schema: record<properties: record, outputs: record, definitions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/plugins/($cls)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all versions for a plugin
#
# GET /api/v1/plugins/{cls}/versions
# operationId: getPluginVersions
export def "plugins-versions list" [
  cls: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, versions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/plugins/($cls)/versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plugin documentation
#
# GET /api/v1/plugins/{cls}/versions/{version}
# operationId: getPluginDocumentationFromVersion
export def "plugins-versions get" [
  cls: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Include all the properties (default: false)
]: nothing -> record<markdown: string, schema: record<properties: record, outputs: record, definitions: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/plugins/($cls)/versions/($version)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plugins group by subgroups
#
# GET /api/v1/plugins/{group}/pluginUi/{path}
# operationId: getPluginUi
export def "plugins-plugin-ui get" [
  group: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/plugins/($group)/pluginUi/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request an authentication code for login verification
#
# GET /api/v1/request-code/{email}
# operationId: requestCode
export def "request-code requestCode" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/request-code/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change a password for given token.
#
# POST /api/v1/reset-password
# operationId: resetPassword
export def "reset-password resetPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string
  --password: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/reset-password")
  let body = {token: $body_token, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List service accounts. Superadmin-only. 
#
# GET /api/v1/service-accounts
# operationId: listServiceAccounts
export def "service-accounts listServiceAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<id: string, name: string, description: string, tenants: list, superAdmin: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/service-accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a service account
#
# POST /api/v1/service-accounts
# operationId: createServiceAccount
export def "service-accounts createServiceAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --superAdmin: oneof<nothing, bool>
  --tenants: list
]: any -> record<id: string, name: string, description: string, tenants: table<id: string, name: string>, superAdmin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/service-accounts")
  let body = {name: $name, description: $description, superAdmin: $superAdmin, tenants: $tenants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a service account
#
# GET /api/v1/service-accounts/{id}
# operationId: getServiceAccount
export def "service-accounts list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, tenants: table<id: string, name: string>, superAdmin: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service-accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a service account
#
# DELETE /api/v1/service-accounts/{id}
# operationId: deleteServiceAccount
export def "service-accounts delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service-accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update service account details
#
# PATCH /api/v1/service-accounts/{id}
# operationId: patchServiceAccountDetails
export def "service-accounts patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
]: any -> record<id: string, name: string, description: string, tenants: table<id: string, name: string>, superAdmin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service-accounts/($id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List API tokens for a specific service account
#
# GET /api/v1/service-accounts/{id}/api-tokens
# operationId: listApiTokensForServiceAccount
export def "service-accounts-api-tokens listApiTokensForServiceAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service-accounts/($id)/api-tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new API Token for a specific service account
#
# POST /api/v1/service-accounts/{id}/api-tokens
# operationId: createApiTokensForServiceAccount
export def "service-accounts-api-tokens createApiTokensForServiceAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --maxAge: string
  --extended: oneof<nothing, bool>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service-accounts/($id)/api-tokens")
  let body = {name: $name, description: $description, maxAge: $maxAge, extended: $extended} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an API Token for specific service account and token id
#
# DELETE /api/v1/service-accounts/{id}/api-tokens/{tokenId}
# operationId: deleteApiTokenForServiceAccount
export def "service-accounts-api-tokens delete-by-id-tokenId" [
  id: string
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service-accounts/($id)/api-tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update service account superadmin privileges
#
# PATCH /api/v1/service-accounts/{id}/superadmin
# operationId: patchServiceAccountSuperAdmin
export def "service-accounts-superadmin patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --superAdmin: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service-accounts/($id)/superadmin")
  let body = {superAdmin: $superAdmin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve current setup configuration
#
# GET /api/v1/setup
# operationId: setupConfiguration
export def "setup setupConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<done: bool, repositoryType: string, queueType: string, storageType: string, secretType: string, passwordConfiguration: record<passwordMinLength: int, passwordRequireSpecial: bool, passwordMinDigits: int, passwordMinLowerCase: int, passwordMinUpperCase: int, passwordAllowedSpecialCharacters: string, passwordReset: record<cooldown: string, rateLimit: record>>, haveAuthNotBasic: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/setup")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the first Superadmin user
#
# POST /api/v1/setup
# operationId: setupKestra
# --tenant shape: {storageIsolation?: record, secretIsolation?: record, id: string, name: string, deleted: bool, defaultWorkerSelector?: record, storageType?: string, storageConfiguration?: record, secretType?: string, secretReadOnly?: bool, secretConfiguration?: record, requireExistingNamespace?: bool, outputsInInternalStorage?: bool, appCatalogConfig?: record, settings?: record, sdkDefaultAuthentication?: record}
export def "setup setupKestra" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string
  --password: string
  --tenant: record # shape: {storageIsolation?: record, secretIsolation?: record, id: string, name: string, deleted: bool, defaultWorkerSelector?: record, storageType?: string, storageConfiguration?: record, secretType?: string, secretReadOnly?: bool, secretConfiguration?: record, requireExistingNamespace?: bool, outputsInInternalStorage?: bool, appCatalogConfig?: record, settings?: record, sdkDefaultAuthentication?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/setup")
  let body = {username: $username, password: $password, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve debug information for a support ticket
#
# GET /api/v1/support/debug-info
# operationId: supportDebugInfo
export def "support-debug-info supportDebugInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<kestraVersion: string, licenseId: string, authType: string, deploymentType: string, queueType: string, queueVersion: string, storageType: string, repositoryType: string, repositoryVersion: string, secretType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/support/debug-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Forward support ticket to configured registry proxy
#
# POST /api/v1/support/forward
# operationId: forwardSupportTicket
export def "support-forward forwardSupportTicket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
  --filesPublisher: list # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/support/forward")
  let body = {payload: $payload, filesPublisher: $filesPublisher} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Create a tenant
#
# POST /api/v1/tenants
# operationId: create_2
# --storageIsolation shape: {deniedServices?: list, enabled?: bool}
# --secretIsolation shape: {deniedServices?: list, enabled?: bool}
# --defaultWorkerSelector shape: {tags?: list, match?: any, fallback?: any}
# --appCatalogConfig shape: {title?: string, titleColor?: string, primaryColor?: string}
# --settings shape: {dashboard?: record}
# --sdkDefaultAuthentication shape: {apiToken?: string, username?: string, password?: string}
export def "tenants create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storageIsolation: record # shape: {deniedServices?: list, enabled?: bool}
  --secretIsolation: record # shape: {deniedServices?: list, enabled?: bool}
  id: string
  name: string
  --deleted: oneof<nothing, bool>
  --defaultWorkerSelector: record # shape: {tags?: list, match?: any, fallback?: any}
  --storageType: string
  --storageConfiguration: record
  --secretType: string
  --secretReadOnly: oneof<nothing, bool>
  --secretConfiguration: record
  --requireExistingNamespace: oneof<nothing, bool>
  --outputsInInternalStorage: oneof<nothing, bool>
  --appCatalogConfig: record # shape: {title?: string, titleColor?: string, primaryColor?: string}
  --settings: record # shape: {dashboard?: record}
  --sdkDefaultAuthentication: record # shape: {apiToken?: string, username?: string, password?: string}
]: any -> record<storageIsolation: record<deniedServices: list<string>, enabled: bool>, secretIsolation: record<deniedServices: list<string>, enabled: bool>, id: string, name: string, deleted: bool, defaultWorkerSelector: record<tags: list<string>, match: record, fallback: record>, storageType: string, storageConfiguration: record, secretType: string, secretReadOnly: bool, secretConfiguration: record, requireExistingNamespace: bool, outputsInInternalStorage: bool, appCatalogConfig: record<title: string, titleColor: string, primaryColor: string>, settings: record<dashboard: record<defaultHomeDashboard: string, defaultFlowOverviewDashboard: string, defaultNamespaceOverviewDashboard: string>>, sdkDefaultAuthentication: record<apiToken: string, username: string, password: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/tenants")
  let body = {storageIsolation: $storageIsolation, secretIsolation: $secretIsolation, id: $id, name: $name, deleted: $deleted, defaultWorkerSelector: $defaultWorkerSelector, storageType: $storageType, storageConfiguration: $storageConfiguration, secretType: $secretType, secretReadOnly: $secretReadOnly, secretConfiguration: $secretConfiguration, requireExistingNamespace: $requireExistingNamespace, outputsInInternalStorage: $outputsInInternalStorage, appCatalogConfig: $appCatalogConfig, settings: $settings, sdkDefaultAuthentication: $sdkDefaultAuthentication} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for tenants
#
# GET /api/v1/tenants/search
# operationId: find
export def "tenants-search find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters (nullable)
]: nothing -> record<results: table<storageIsolation: record, secretIsolation: record, id: string, name: string, deleted: bool, defaultWorkerSelector: record, storageType: string, storageConfiguration: record, secretType: string, secretReadOnly: bool, secretConfiguration: record, requireExistingNamespace: bool, outputsInInternalStorage: bool, appCatalogConfig: record, settings: record, sdkDefaultAuthentication: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/tenants/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a tenant
#
# GET /api/v1/tenants/{id}
# operationId: get_3
export def "tenants get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<storageIsolation: record<deniedServices: list<string>, enabled: bool>, secretIsolation: record<deniedServices: list<string>, enabled: bool>, id: string, name: string, deleted: bool, defaultWorkerSelector: record<tags: list<string>, match: record, fallback: record>, storageType: string, storageConfiguration: record, secretType: string, secretReadOnly: bool, secretConfiguration: record, requireExistingNamespace: bool, outputsInInternalStorage: bool, appCatalogConfig: record<title: string, titleColor: string, primaryColor: string>, settings: record<dashboard: record<defaultHomeDashboard: string, defaultFlowOverviewDashboard: string, defaultNamespaceOverviewDashboard: string>>, sdkDefaultAuthentication: record<apiToken: string, username: string, password: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenants/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a tenant
#
# PUT /api/v1/tenants/{id}
# operationId: update_2
# --storageIsolation shape: {deniedServices?: list, enabled?: bool}
# --secretIsolation shape: {deniedServices?: list, enabled?: bool}
# --defaultWorkerSelector shape: {tags?: list, match?: any, fallback?: any}
# --appCatalogConfig shape: {title?: string, titleColor?: string, primaryColor?: string}
# --settings shape: {dashboard?: record}
# --sdkDefaultAuthentication shape: {apiToken?: string, username?: string, password?: string}
export def "tenants update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storageIsolation: record # shape: {deniedServices?: list, enabled?: bool}
  --secretIsolation: record # shape: {deniedServices?: list, enabled?: bool}
  --body-id: string
  name: string
  --deleted: oneof<nothing, bool>
  --defaultWorkerSelector: record # shape: {tags?: list, match?: any, fallback?: any}
  --storageType: string
  --storageConfiguration: record
  --secretType: string
  --secretReadOnly: oneof<nothing, bool>
  --secretConfiguration: record
  --requireExistingNamespace: oneof<nothing, bool>
  --outputsInInternalStorage: oneof<nothing, bool>
  --appCatalogConfig: record # shape: {title?: string, titleColor?: string, primaryColor?: string}
  --settings: record # shape: {dashboard?: record}
  --sdkDefaultAuthentication: record # shape: {apiToken?: string, username?: string, password?: string}
]: any -> record<storageIsolation: record<deniedServices: list<string>, enabled: bool>, secretIsolation: record<deniedServices: list<string>, enabled: bool>, id: string, name: string, deleted: bool, defaultWorkerSelector: record<tags: list<string>, match: record, fallback: record>, storageType: string, storageConfiguration: record, secretType: string, secretReadOnly: bool, secretConfiguration: record, requireExistingNamespace: bool, outputsInInternalStorage: bool, appCatalogConfig: record<title: string, titleColor: string, primaryColor: string>, settings: record<dashboard: record<defaultHomeDashboard: string, defaultFlowOverviewDashboard: string, defaultNamespaceOverviewDashboard: string>>, sdkDefaultAuthentication: record<apiToken: string, username: string, password: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenants/($id)")
  let body = {storageIsolation: $storageIsolation, secretIsolation: $secretIsolation, id: $body_id, name: $name, deleted: $deleted, defaultWorkerSelector: $defaultWorkerSelector, storageType: $storageType, storageConfiguration: $storageConfiguration, secretType: $secretType, secretReadOnly: $secretReadOnly, secretConfiguration: $secretConfiguration, requireExistingNamespace: $requireExistingNamespace, outputsInInternalStorage: $outputsInInternalStorage, appCatalogConfig: $appCatalogConfig, settings: $settings, sdkDefaultAuthentication: $sdkDefaultAuthentication} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a tenant and all its resources
#
# DELETE /api/v1/tenants/{id}
# operationId: delete_2
export def "tenants delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenants/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the apps catalog config for the specified tenant.
#
# GET /api/v1/tenants/{id}/apps-catalog
# operationId: getAppsCatalogConfig
export def "tenants-apps-catalog get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<title: string, titleColor: string, primaryColor: string, logo: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenants/($id)/apps-catalog")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the apps catalog config for the specified tenant.
#
# POST /api/v1/tenants/{id}/apps-catalog
# operationId: setAppsCatalogConfig
export def "tenants-apps-catalog setAppsCatalogConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string
  --titleColor: string
  --primaryColor: string
]: any -> record<title: string, titleColor: string, primaryColor: string, logo: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenants/($id)/apps-catalog")
  let body = {title: $title, titleColor: $titleColor, primaryColor: $primaryColor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set the apps catalog logo for the specified tenant.
#
# POST /api/v1/tenants/{id}/apps-catalog/logo
# operationId: setAppsCatalogLogo
export def "tenants-apps-catalog-logo setAppsCatalogLogo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --logo: string # The logo file (format: binary)
]: any -> record<title: string, titleColor: string, primaryColor: string, logo: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenants/($id)/apps-catalog/logo")
  let body = {logo: $logo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Remove the apps catalog logo for the specified tenant.
#
# DELETE /api/v1/tenants/{id}/apps-catalog/logo
# operationId: deleteAppsCatalogLogo
export def "tenants-apps-catalog-logo delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenants/($id)/apps-catalog/logo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set a tenant logo
#
# POST /api/v1/tenants/{id}/logo
# operationId: setLogo
export def "tenants-logo setLogo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --logo: string # The logo file (format: binary)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenants/($id)/logo")
  let body = {logo: $logo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get default dashboards for this tenant
#
# GET /api/v1/tenants/{id}/settings/default-dashboards
# operationId: getDefaultDashboards
export def "tenants-settings-default-dashboards get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultHomeDashboard: string, defaultFlowOverviewDashboard: string, defaultNamespaceOverviewDashboard: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenants/($id)/settings/default-dashboards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update default dashboards for the entire tenant
#
# POST /api/v1/tenants/{id}/settings/default-dashboards
# operationId: setTenantDefaultDashboards
export def "tenants-settings-default-dashboards setTenantDefaultDashboards" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaultHomeDashboard: string
  --defaultFlowOverviewDashboard: string
  --defaultNamespaceOverviewDashboard: string
]: any -> record<defaultHomeDashboard: string, defaultFlowOverviewDashboard: string, defaultNamespaceOverviewDashboard: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenants/($id)/settings/default-dashboards")
  let body = {defaultHomeDashboard: $defaultHomeDashboard, defaultFlowOverviewDashboard: $defaultFlowOverviewDashboard, defaultNamespaceOverviewDashboard: $defaultNamespaceOverviewDashboard} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve users
#
# GET /api/v1/users
# operationId: listUsers
export def "users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<id: string, username: string, displayName: string, tenants: list, auths: list, superAdmin: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user account
#
# POST /api/v1/users
# operationId: createUser
export def "users createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tenants: list
  --groups: list
  --firstName: string
  --lastName: string
  email: string
  --password: string
  --superAdmin: oneof<nothing, bool>
  --restricted: oneof<nothing, bool>
]: any -> record<id: string, username: string, displayName: string, firstName: string, lastName: string, email: string, tenants: table<id: string, name: string>, auths: table<id: string, name: string, type: string>, groups: table<id: string, tenantId: string>, superAdmin: bool, restricted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users")
  let body = {tenants: $tenants, groups: $groups, firstName: $firstName, lastName: $lastName, email: $email, password: $password, superAdmin: $superAdmin, restricted: $restricted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a user
#
# GET /api/v1/users/{id}
# operationId: getUser
export def "users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, username: string, displayName: string, firstName: string, lastName: string, email: string, tenants: table<id: string, name: string>, auths: table<id: string, name: string, type: string>, groups: table<id: string, tenantId: string>, superAdmin: bool, restricted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user account
#
# PUT /api/v1/users/{id}
# operationId: updateUser
export def "users updateUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tenants: list
  --groups: list
  --firstName: string
  --lastName: string
  email: string
  --password: string
  --superAdmin: oneof<nothing, bool>
  --restricted: oneof<nothing, bool>
]: any -> record<id: string, username: string, displayName: string, firstName: string, lastName: string, email: string, tenants: table<id: string, name: string>, auths: table<id: string, name: string, type: string>, groups: table<id: string, tenantId: string>, superAdmin: bool, restricted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)")
  let body = {tenants: $tenants, groups: $groups, firstName: $firstName, lastName: $lastName, email: $email, password: $password, superAdmin: $superAdmin, restricted: $restricted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /api/v1/users/{id}
# operationId: deleteUser
export def "users delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user details
#
# PATCH /api/v1/users/{id}
# operationId: patchUser
export def "users patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --firstName: string
  --lastName: string
  --email: string
]: any -> record<id: string, username: string, displayName: string, firstName: string, lastName: string, email: string, tenants: table<id: string, name: string>, auths: table<id: string, name: string, type: string>, groups: table<id: string, tenantId: string>, superAdmin: bool, restricted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)")
  let body = {firstName: $firstName, lastName: $lastName, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List API tokens for a specific user
#
# GET /api/v1/users/{id}/api-tokens
# operationId: listApiTokensForUser
export def "users-api-tokens listApiTokensForUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<total: int, results: table<id: string, name: string, description: string, prefix: string, iat: string, exp: string, lastUsed: string, extended: bool, expired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/api-tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new API Token for a specific user
#
# POST /api/v1/users/{id}/api-tokens
# operationId: createApiTokensForUser
export def "users-api-tokens createApiTokensForUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --maxAge: string
  --extended: oneof<nothing, bool>
]: any -> record<id: string, name: string, fullToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/api-tokens")
  let body = {name: $name, description: $description, maxAge: $maxAge, extended: $extended} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an API Token for specific user and token id
#
# DELETE /api/v1/users/{id}/api-tokens/{tokenId}
# operationId: deleteApiTokenForUser
export def "users-api-tokens delete" [
  id: string
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/api-tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user password
#
# DELETE /api/v1/users/{id}/auths/{auth}
# operationId: deleteUserAuthMethod
export def "users-auths delete" [
  id: string
  auth: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, username: string, displayName: string, firstName: string, lastName: string, email: string, tenants: table<id: string, name: string>, auths: table<id: string, name: string, type: string>, groups: table<id: string, tenantId: string>, superAdmin: bool, restricted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/auths/($auth)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Impersonate a user
#
# POST /api/v1/users/{id}/impersonate
# operationId: impersonate
export def "users-impersonate impersonate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/impersonate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user password
#
# PATCH /api/v1/users/{id}/password
# operationId: patchUserPassword
export def "users-password patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
]: any -> record<id: string, username: string, displayName: string, firstName: string, lastName: string, email: string, tenants: table<id: string, name: string>, auths: table<id: string, name: string, type: string>, groups: table<id: string, tenantId: string>, superAdmin: bool, restricted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a user refresh token
#
# DELETE /api/v1/users/{id}/refresh-token
# operationId: deleteRefreshToken
export def "users-refresh-token delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/refresh-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user demo
#
# PATCH /api/v1/users/{id}/restricted
# operationId: patchUserDemo
export def "users-restricted patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --restricted: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/restricted")
  let body = {restricted: $restricted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update user superadmin privileges
#
# PATCH /api/v1/users/{id}/superadmin
# operationId: patchUserSuperAdmin
export def "users-superadmin patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --superAdmin: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/superadmin")
  let body = {superAdmin: $superAdmin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/validate-password
#
# operationId: validatePassword
export def "validate-password validatePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/validate-password")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Retrieve resource-to-actions mapping
#
# GET /api/v1/{tenant}/acls/permissions
# operationId: listPermissions
export def "acls-permissions listPermissions" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<FLOW: list<any>, EXECUTION: list<any>, TRIGGER: list<any>, NAMESPACE: list<any>, KVSTORE: list<any>, DASHBOARD: list<any>, SECRET: list<any>, CREDENTIAL: list<any>, BLUEPRINT: list<any>, APP: list<any>, AUDITLOG: list<any>, SYSTEM_SETTINGS: list<any>, TENANT_SETTINGS: list<any>, TESTSUITE: list<any>, ASSET: list<any>, USER: list<any>, GROUP: list<any>, ROLE: list<any>, BINDING: list<any>, SERVICE_ACCOUNT: list<any>, INVITATION: list<any>, COPILOT: list<any>, MCP_SERVER: list<any>, APP_EXECUTION: list<any>, NAMESPACE_FILE: list<any>, TESTSUITE_RUN: list<any>, TENANT_ACCESS: list<any>, SECURITY_INTEGRATION: list<any>, KILL_SWITCH: list<any>, TENANT: list<any>, VERSIONED_PLUGIN: list<any>, WORKER_GROUP: list<any>, WORKER_QUEUE: list<any>, INSTANCE: list<any>, UNKNOWN: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/acls/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve managed role templates
#
# GET /api/v1/{tenant}/acls/templates
# operationId: listTemplates
export def "acls-templates listTemplates" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ADMIN: record<empty: bool>, VIEWER: record<empty: bool>, EDITOR: record<empty: bool>, LAUNCHER: record<empty: bool>, DEVELOPER: record<empty: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/acls/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate or regenerate an app based on a prompt (EE only)
#
# POST /api/v1/{tenant}/ai/generate/app
# operationId: generateApp
export def "ai-generate-app generateApp" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conversationId: string
  --userPrompt: string
  --yaml: string
  --providerId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/ai/generate/app")
  let body = {conversationId: $conversationId, userPrompt: $userPrompt, yaml: $yaml, providerId: $providerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate or regenerate a dashboard based on a prompt
#
# POST /api/v1/{tenant}/ai/generate/dashboard
# operationId: generateDashboard
export def "ai-generate-dashboard generateDashboard" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  conversationId: string
  userPrompt: string
  --yaml: string
  --providerId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/ai/generate/dashboard")
  let body = {conversationId: $conversationId, userPrompt: $userPrompt, yaml: $yaml, providerId: $providerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate or regenerate a flow based on a prompt
#
# POST /api/v1/{tenant}/ai/generate/flow
# operationId: generateFlow
export def "ai-generate-flow generateFlow" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  conversationId: string
  userPrompt: string
  --yaml: string
  --namespace: string
  --providerId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/ai/generate/flow")
  let body = {conversationId: $conversationId, userPrompt: $userPrompt, yaml: $yaml, namespace: $namespace, providerId: $providerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate or regenerate a test suite based on a prompt (EE only)
#
# POST /api/v1/{tenant}/ai/generate/test
# operationId: generateTestSuite
export def "ai-generate-test generateTestSuite" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  conversationId: string
  userPrompt: string
  --yaml: string
  --providerId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/ai/generate/test")
  let body = {conversationId: $conversationId, userPrompt: $userPrompt, yaml: $yaml, providerId: $providerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List available AI providers
#
# GET /api/v1/{tenant}/ai/providers
# operationId: getProviders
export def "ai-providers get" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, displayName: string, isDefault: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/ai/providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new app
#
# POST /api/v1/{tenant}/apps
# operationId: createApp
export def "apps createApp" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<uid: string, name: string, namespace: string, tags: list<string>, disabled: bool, source: string, created: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Delete existing apps
#
# DELETE /api/v1/{tenant}/apps
# operationId: bulkDeleteApps
export def "apps bulkDeleteApps" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --uids: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps")
  let body = {uids: $uids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for apps from catalog
#
# GET /api/v1/{tenant}/apps/catalog
# operationId: searchAppsFromCatalog
export def "apps-catalog searchAppsFromCatalog" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --filters: list # Filters
]: nothing -> record<results: table<uid: string, name: string, description: string, type: string, tags: list, thumbnail: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/catalog" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable existing apps
#
# POST /api/v1/{tenant}/apps/disable
# operationId: bulkDisableApps
export def "apps-disable bulkDisableApps" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --uids: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/disable")
  let body = {uids: $uids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enable existing apps
#
# POST /api/v1/{tenant}/apps/enable
# operationId: bulkEnableApps
export def "apps-enable bulkEnableApps" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --uids: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/enable")
  let body = {uids: $uids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export apps as a ZIP archive of YAML sources.
#
# POST /api/v1/{tenant}/apps/export
# operationId: bulkExportApps
export def "apps-export bulkExportApps" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --uids: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/export")
  let body = {uids: $uids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#     Import apps as a ZIP archive of yaml sources or a multi-objects YAML file.     When sending a Yaml that contains one or more apps, a list of index is returned.     When sending a ZIP archive, a list of files that couldn't be imported is returned.
#
# POST /api/v1/{tenant}/apps/import
# operationId: bulkImportApps
export def "apps-import bulkImportApps" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fileUpload: string # The file to import, can be a ZIP archive or a multi-objects YAML file (format: binary)
]: any -> record<success: list<string>, errors: table<source: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/import")
  let body = {fileUpload: $fileUpload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Open the app for the given source
#
# POST /api/v1/{tenant}/apps/preview
# operationId: previewApp
export def "apps-preview previewApp" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<dispatch: string, stream: string, layout: record<blocks: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/preview")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Search for apps
#
# GET /api/v1/{tenant}/apps/search
# operationId: searchApps
export def "apps-search searchApps" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<uid: string, id: string, name: string, type: string, namespace: string, flowId: string, tags: list, enabled: bool, created: string, updated: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the app tags
#
# GET /api/v1/{tenant}/apps/tags
# operationId: listTags
export def "apps-tags listTags" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Dispatch for a given app.
#
# POST /api/v1/{tenant}/apps/view/{id}/dispatch/{dispatch}
# operationId: dispatchApp
export def "apps-view-dispatch dispatchApp" [
  id: string
  dispatch: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<dispatch: string, stream: string, layout: record<blocks: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/view/($id)/dispatch/($dispatch)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Download file from an app execution
#
# GET /api/v1/{tenant}/apps/view/{id}/file/download
# operationId: downloadFileFromAppExecution
export def "apps-view-file-download downloadFileFromAppExecution" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri (format: uri)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/view/($id)/file/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file meta information from an app execution
#
# GET /api/v1/{tenant}/apps/view/{id}/file/meta
# operationId: getFileMetaFromAppExecution
export def "apps-view-file-meta get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri (format: uri)
]: nothing -> record<size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/view/($id)/file/meta" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file preview from an app execution
#
# GET /api/v1/{tenant}/apps/view/{id}/file/preview
# operationId: getFilePreviewFromAppExecution
export def "apps-view-file-preview get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri (format: uri)
  --maxRows: int # The max row returns (nullable, format: int32)
  --encoding: string # The file encoding as Java charset name. Defaults to UTF-8 (default: UTF-8, e.g. ISO-8859-1)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "maxRows" $maxRows "scalar") (serialize-qp "encoding" $encoding "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/view/($id)/file/preview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an event stream from a given app.
#
# GET /api/v1/{tenant}/apps/view/{id}/streams/{stream}
# operationId: getStreamEventsFromApp
export def "apps-view-streams get" [
  id: string
  stream: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/view/($id)/streams/($stream)")
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Open an app
#
# GET /api/v1/{tenant}/apps/view/{uid}
# operationId: openApp
export def "apps-view openApp" [
  uid: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dispatch: string, stream: string, layout: record<blocks: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/view/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download logs for an app execution
#
# GET /api/v1/{tenant}/apps/view/{uid}/logs/download
# operationId: getLogsFromAppExecution
export def "apps-view-logs-download get" [
  uid: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --executionId: string # The ID of the execution.
  --minLevel: string # The min log level filter (nullable)
  --taskIds: list # The tasks' IDs (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "executionId" $executionId "scalar") (serialize-qp "minLevel" $minLevel "scalar") (serialize-qp "taskIds" $taskIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/view/($uid)/logs/download" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an app
#
# GET /api/v1/{tenant}/apps/{uid}
# operationId: getApp
export def "apps get" [
  uid: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uid: string, name: string, namespace: string, tags: list<string>, disabled: bool, source: string, created: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing app
#
# PUT /api/v1/{tenant}/apps/{uid}
# operationId: updateApp
export def "apps updateApp" [
  uid: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<uid: string, name: string, namespace: string, tags: list<string>, disabled: bool, source: string, created: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/($uid)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Delete an existing app
#
# DELETE /api/v1/{tenant}/apps/{uid}
# operationId: deleteApp
export def "apps delete" [
  uid: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable the app.
#
# POST /api/v1/{tenant}/apps/{uid}/disable
# operationId: disableApp
export def "apps-disable disableApp" [
  uid: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uid: string, id: string, name: string, type: string, namespace: string, flowId: string, tags: list<string>, enabled: bool, created: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/($uid)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable the app.
#
# POST /api/v1/{tenant}/apps/{uid}/enable
# operationId: enableApp
export def "apps-enable enableApp" [
  uid: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uid: string, id: string, name: string, type: string, namespace: string, flowId: string, tags: list<string>, enabled: bool, created: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/apps/($uid)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new asset
#
# POST /api/v1/{tenant}/assets
# operationId: createAsset
export def "assets createAsset" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<namespace: string, id: string, type: string, displayName: string, description: string, metadata: record, created: string, updated: string, deleted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/assets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Delete assets by asset ids
#
# DELETE /api/v1/{tenant}/assets/by-ids
# operationId: deleteAssetsByIds
export def "assets-by-ids delete" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/assets/by-ids")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete assets by query
#
# DELETE /api/v1/{tenant}/assets/by-query
# operationId: deleteAssetsByQuery
export def "assets-by-query delete" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters
  --purge: oneof<nothing, bool> # If true, will purge instead of soft-delete (default: false)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv") (serialize-qp "purge" $purge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/assets/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete asset lineage events by query, hard-delete (purge) only
#
# DELETE /api/v1/{tenant}/assets/lineage-events/by-query
# operationId: deleteAssetLineageEventsByQuery
export def "assets-lineage-events-by-query delete" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/assets/lineage-events/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for asset lineage events
#
# GET /api/v1/{tenant}/assets/lineage-events/search
# operationId: searchAssetLineageEvents
export def "assets-lineage-events-search searchAssetLineageEvents" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<uid: string, namespace: string, flowId: string, flowRevision: int, executionId: string, taskId: string, taskRunId: string, state: string, inputs: list, outputs: list, created: string, startDate: string, endDate: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/assets/lineage-events/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for assets
#
# GET /api/v1/{tenant}/assets/search
# operationId: searchAssets
export def "assets-search searchAssets" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<namespace: string, id: string, type: string, displayName: string, description: string, metadata: record, created: string, updated: string, deleted: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/assets/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete asset usages by query, hard-delete (purge) only
#
# DELETE /api/v1/{tenant}/assets/usages/by-query
# operationId: deleteAssetUsagesByQuery
export def "assets-usages-by-query delete" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/assets/usages/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for asset usages
#
# GET /api/v1/{tenant}/assets/usages/search
# operationId: searchAssetUsages
export def "assets-usages-search searchAssetUsages" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<assetId: string, namespace: string, flowId: string, flowRevision: int, executionId: string, taskId: string, taskRunId: string, created: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/assets/usages/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an asset
#
# GET /api/v1/{tenant}/assets/{id}
# operationId: getAsset
export def "assets get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowDeleted: oneof<nothing, bool> # Get asset even if soft deleted (default: false)
]: nothing -> record<namespace: string, id: string, type: string, displayName: string, description: string, metadata: record, created: string, updated: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowDeleted" $allowDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/assets/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an asset
#
# DELETE /api/v1/{tenant}/assets/{id}
# operationId: deleteAsset
export def "assets delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/assets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an asset dependencies
#
# GET /api/v1/{tenant}/assets/{id}/dependencies
# operationId: getAssetDependencies
export def "assets-dependencies get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --destinationOnly: oneof<nothing, bool> # If true, list only destination dependencies, otherwise list also source dependencies (default: false)
  --expandAll: oneof<nothing, bool> # If true, expand all dependencies recursively (default: false)
]: nothing -> record<nodes: table<uid: string, namespace: string, id: string, type: string>, edges: table<source: string, target: string, relation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "destinationOnly" $destinationOnly "scalar") (serialize-qp "expandAll" $expandAll "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/assets/($id)/dependencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export all audit logs as a streamed CSV file
#
# GET /api/v1/{tenant}/auditlogs/export
# operationId: exportAuditLogs
export def "auditlogs-export exportAuditLogs" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A string filter (nullable)
  --namespace: string # A namespace filter (nullable)
  --flowId: string # A flow id filter (nullable)
  --executionId: string # An execution filter (nullable)
  --userId: string # A user id filter (nullable)
  --id: string # A id filter (nullable)
  --resources: list # A resource filter (nullable)
  --startDate: string # The start datetime (nullable, format: date-time)
  --endDate: string # The end datetime (nullable, format: date-time)
  --details: record # A list of auditLog details (nullable)
  --type: string # The event that create the audit log (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "flowId" $flowId "scalar") (serialize-qp "executionId" $executionId "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "resources" $resources "csv") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "details" $details "csv") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/auditlogs/export" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find a specific audit log
#
# POST /api/v1/{tenant}/auditlogs/find
# operationId: findAuditLog
export def "auditlogs-find findAuditLog" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer
  --type: any # nullable
  --detail: record
]: any -> record<auditLog: record, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/auditlogs/find")
  let body = {resource: $resource, type: $type, detail: $detail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Find all audit logs about a specific resource.
#
# GET /api/v1/{tenant}/auditlogs/history/{detailId}
# operationId: listAuditLogFromResourceId
export def "auditlogs-history listAuditLogFromResourceId" [
  detailId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, date: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/auditlogs/history/($detailId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for audit logs
#
# GET /api/v1/{tenant}/auditlogs/search
# operationId: searchAuditLogs
export def "auditlogs-search searchAuditLogs" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # A list of query filters (nullable)
]: nothing -> record<results: table<auditLog: record, user: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/auditlogs/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the diff between audit logs
#
# GET /api/v1/{tenant}/auditlogs/{id}/diff
# operationId: getResourceDiffFromAuditLog
export def "auditlogs-diff get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --previousId: string # The id of a previous audit log to compare with (nullable)
]: nothing -> record<before: string, after: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "previousId" $previousId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/auditlogs/($id)/diff" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure basic authentication for the instance.
#
# POST /api/v1/{tenant}/basicAuth
# operationId: createBasicAuth
export def "basic-auth createBasicAuth" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --uid: string
  --username: string
  --password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/basicAuth")
  let body = {uid: $uid, username: $username, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a binding
#
# POST /api/v1/{tenant}/bindings
# operationId: createBinding
export def "bindings createBinding" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-1
  externalId: string
  roleId: string
  --namespaceId: string # nullable
]: any -> record<id: string, type: string, namespace: string, role: record<id: string, name: string>, group: record<id: string, name: string>, user: record<id: string, username: string, displayName: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/bindings")
  let body = {type: $type, externalId: $externalId, roleId: $roleId, namespaceId: $namespaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create multiple bindings
#
# POST /api/v1/{tenant}/bindings/bulk
# operationId: bulkCreateBinding
export def "bindings-bulk bulkCreateBinding" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<id: string, type: string, namespace: string, role: record<id: string, name: string>, group: record<id: string, name: string>, user: record<id: string, username: string, displayName: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/bindings/bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for bindings
#
# GET /api/v1/{tenant}/bindings/search
# operationId: searchBindings
export def "bindings-search searchBindings" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --type: string # Binding type filter (nullable)
  --id: string # External id filter (nullable)
  --namespace: string # A namespace filter (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<id: string, type: string, namespace: string, role: record, group: record, user: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "type" $type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/bindings/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a binding
#
# GET /api/v1/{tenant}/bindings/{id}
# operationId: getBinding
export def "bindings get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, type: string, namespace: string, role: record<id: string, name: string>, group: record<id: string, name: string>, user: record<id: string, username: string, displayName: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/bindings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a binding
#
# DELETE /api/v1/{tenant}/bindings/{id}
# operationId: deleteBinding
export def "bindings delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/bindings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all blueprints
#
# GET /api/v1/{tenant}/blueprints/community/{kind}
# operationId: searchBlueprints
export def "blueprints-community searchBlueprints" [
  kind: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # The sort of current page (nullable)
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 1)
  --filters: list # A list of query filters (nullable)
]: nothing -> record<results: table<id: string, title: string, description: string, includedTasks: list, tags: list, publishedAt: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/community/($kind)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List blueprint tags matching the filter
#
# GET /api/v1/{tenant}/blueprints/community/{kind}/tags
# operationId: listBlueprintTags
export def "blueprints-community-tags listBlueprintTags" [
  kind: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # A list of query filters (nullable)
]: nothing -> table<id: string, name: string, publishedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/community/($kind)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a blueprint
#
# GET /api/v1/{tenant}/blueprints/community/{kind}/{id}
# operationId: getBlueprint
export def "blueprints-community get" [
  id: string
  kind: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/community/($kind)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a blueprint graph
#
# GET /api/v1/{tenant}/blueprints/community/{kind}/{id}/graph
# operationId: getBlueprintGraph
export def "blueprints-community-graph get" [
  id: string
  kind: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/community/($kind)/($id)/graph")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a blueprint source code
#
# GET /api/v1/{tenant}/blueprints/community/{kind}/{id}/source
# operationId: getBlueprintSource
export def "blueprints-community-source get" [
  id: string
  kind: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/community/($kind)/($id)/source")
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all internal blueprints
#
# GET /api/v1/{tenant}/blueprints/custom
# operationId: searchInternalBlueprints
export def "blueprints-custom searchInternalBlueprints" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # The sort of current page (nullable)
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 1)
  --qp-source: oneof<nothing, bool> # Whether to include the flow source in the response (nullable, default: false)
  --filters: list # A list of query filters (nullable)
]: nothing -> record<results: table<id: string, title: string, description: string, tags: list, includedTasks: list, publishedAt: string, deleted: bool, template: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/custom" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new internal blueprint
#
# POST /api/v1/{tenant}/blueprints/custom
# DEPRECATED
# operationId: createInternalBlueprints
@deprecated
export def "blueprints-custom createInternalBlueprints" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --title: string
  --description: string
  --includedTasks: list
  --tags: list
  --publishedAt: string # format: date-time
  --body-source: string
  --kind: string@kind-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/custom")
  let body = {id: $id, title: $title, description: $description, includedTasks: $includedTasks, tags: $tags, publishedAt: $publishedAt, source: $body_source, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all internal blueprint tags
#
# GET /api/v1/{tenant}/blueprints/custom/tags
# operationId: internalBlueprintTags
export def "blueprints-custom-tags internalBlueprintTags" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # A list of query filters (nullable)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/custom/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an internal blueprint
#
# GET /api/v1/{tenant}/blueprints/custom/{id}
# operationId: internalBlueprint
export def "blueprints-custom internalBlueprint" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, title: string, description: string, includedTasks: list<string>, tags: list<string>, source: string, publishedAt: string, template: record<source: string, templateArguments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/custom/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an internal blueprint
#
# PUT /api/v1/{tenant}/blueprints/custom/{id}
# DEPRECATED
# operationId: updateInternalBlueprints
@deprecated
export def "blueprints-custom updateInternalBlueprints" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  --title: string
  --description: string
  --includedTasks: list
  --tags: list
  --publishedAt: string # format: date-time
  --body-source: string
  --kind: string@kind-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/custom/($id)")
  let body = {id: $body_id, title: $title, description: $description, includedTasks: $includedTasks, tags: $tags, publishedAt: $publishedAt, source: $body_source, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an internal blueprint
#
# DELETE /api/v1/{tenant}/blueprints/custom/{id}
# DEPRECATED
# operationId: deleteInternalBlueprints
@deprecated
export def "blueprints-custom delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/custom/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an internal blueprint source code
#
# GET /api/v1/{tenant}/blueprints/custom/{id}/source
# operationId: internalBlueprintFlow
export def "blueprints-custom-source internalBlueprintFlow" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/custom/($id)/source")
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an flow blueprint
#
# GET /api/v1/{tenant}/blueprints/flow/{id}
# operationId: getFlowBlueprint
export def "blueprints-flow get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, title: string, description: string, includedTasks: list<string>, tags: list<string>, source: string, publishedAt: string, template: record<source: string, templateArguments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/flow/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Flow Blueprint
#
# POST /api/v1/{tenant}/blueprints/flows
# operationId: createFlowBlueprint
export def "blueprints-flows createFlowBlueprint" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
  --body-source: string
  --description: string
  --tags: list
]: any -> record<id: string, title: string, description: string, includedTasks: list<string>, tags: list<string>, source: string, publishedAt: string, template: record<source: string, templateArguments: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/flows")
  let body = {title: $title, source: $body_source, description: $description, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an flow blueprint
#
# GET /api/v1/{tenant}/blueprints/flows/{id}
# operationId: getFlowBlueprintById
export def "blueprints-flows get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, title: string, description: string, includedTasks: list<string>, tags: list<string>, source: string, publishedAt: string, template: record<source: string, templateArguments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/flows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Flow Blueprint
#
# PUT /api/v1/{tenant}/blueprints/flows/{id}
# operationId: updateFlowBlueprint
export def "blueprints-flows updateFlowBlueprint" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
  --body-source: string
  --description: string
  --tags: list
]: any -> record<id: string, title: string, description: string, includedTasks: list<string>, tags: list<string>, source: string, publishedAt: string, template: record<source: string, templateArguments: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/flows/($id)")
  let body = {title: $title, source: $body_source, description: $description, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Flow Blueprint
#
# DELETE /api/v1/{tenant}/blueprints/flows/{id}
# operationId: deleteFlowBlueprints
export def "blueprints-flows delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/flows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use a Flow Blueprint template to generate a Flow source
#
# POST /api/v1/{tenant}/blueprints/flows/{id}/use-template
# operationId: useBlueprintTemplate
export def "blueprints-flows-use-template useBlueprintTemplate" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateArgumentsInputs: record
]: any -> record<generatedFlowSource: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/blueprints/flows/($id)/use-template")
  let body = {templateArgumentsInputs: $templateArgumentsInputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for flow concurrency limits
#
# GET /api/v1/{tenant}/concurrency-limit/search
# operationId: searchConcurrencyLimits
export def "concurrency-limit-search searchConcurrencyLimits" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<results: table<tenantId: string, namespace: string, flowId: string, running: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/concurrency-limit/search")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a flow concurrency limit
#
# PUT /api/v1/{tenant}/concurrency-limit/{namespace}/{flowId}
# operationId: updateConcurrencyLimit
export def "concurrency-limit updateConcurrencyLimit" [
  namespace: string
  flowId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tenantId: string
  --body-namespace: string
  --body-flowId: string
  --running: int # format: int32
]: any -> record<tenantId: string, namespace: string, flowId: string, running: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/concurrency-limit/($namespace)/($flowId)")
  let body = {tenantId: $tenantId, namespace: $body_namespace, flowId: $body_flowId, running: $running} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all tenant-level credentials
#
# GET /api/v1/{tenant}/credentials
# operationId: listCredentials
export def "credentials listCredentials" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: list<record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new tenant-level credential
#
# POST /api/v1/{tenant}/credentials
# Discriminator (request): type = OAUTH2, GITHUB_APP
# operationId: createCredential
export def "credentials createCredential" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: any@type-completer-2 # Credential type discriminator (e.g. oauth2)
  --name: string # Credential name (e.g. salesforce-prod)
  --description: string # Credential description
  --namespace: string # Namespace (null for tenant-level)
  --tokenEndpoint: string # OAuth2 token endpoint URL (e.g. https://login.salesforce.com/services/oauth2/token)
  --scopes: list # OAuth2 scopes
  --audience: string # OAuth2 audience
  --tokenCaching: any # Token caching configuration
  --authConfig: any # OAuth2 authentication configuration
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/credentials")
  let body = {type: $type, name: $name, description: $description, namespace: $namespace, tokenEndpoint: $tokenEndpoint, scopes: $scopes, audience: $audience, tokenCaching: $tokenCaching, authConfig: $authConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a credential by ID
#
# GET /api/v1/{tenant}/credentials/{id}
# Discriminator (response): type = OAUTH2, GITHUB_APP
# operationId: getCredential
export def "credentials get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/credentials/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing credential
#
# PUT /api/v1/{tenant}/credentials/{id}
# Discriminator (request): type = OAUTH2, GITHUB_APP
# operationId: updateCredential
export def "credentials updateCredential" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: any@type-completer-2 # Credential type discriminator (e.g. oauth2)
  --description: string # Credential description
  --tokenEndpoint: string # OAuth2 token endpoint URL
  --scopes: list # OAuth2 scopes
  --audience: string # OAuth2 audience
  --tokenCaching: any # Token caching configuration
  --authConfig: any # OAuth2 authentication configuration
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/credentials/($id)")
  let body = {type: $type, description: $description, tokenEndpoint: $tokenEndpoint, scopes: $scopes, audience: $audience, tokenCaching: $tokenCaching, authConfig: $authConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a credential
#
# DELETE /api/v1/{tenant}/credentials/{id}
# operationId: deleteCredential
export def "credentials delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/credentials/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test a credential connection by attempting to fetch a token
#
# POST /api/v1/{tenant}/credentials/{id}/test
# operationId: testConnection
export def "credentials-test testConnection" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/credentials/($id)/test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for dashboards
#
# GET /api/v1/{tenant}/dashboards
# operationId: searchDashboards
export def "dashboards searchDashboards" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --q: string # The filter query (nullable)
  --qp-sort: list # The sort of current page (nullable)
]: nothing -> record<results: table<tenantId: string, id: string, title: string, description: string, timeWindow: record, charts: list, deleted: bool, created: string, updated: string, sourceCode: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a dashboard from yaml source
#
# POST /api/v1/{tenant}/dashboards
# operationId: createDashboard
export def "dashboards createDashboard" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<tenantId: string, id: string, title: string, description: string, timeWindow: record<default: string, max: string>, charts: table<id: string, type: string, chartOptions: record>, deleted: bool, created: string, updated: string, sourceCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Export a table chart data to CSV
#
# POST /api/v1/{tenant}/dashboards/charts/export/to-csv
# operationId: exportChartToCsv
export def "dashboards-charts-export-to-csv exportChartToCsv" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chart: string
  --globalFilter: any # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards/charts/export/to-csv")
  let body = {chart: $chart, globalFilter: $globalFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview a chart data
#
# POST /api/v1/{tenant}/dashboards/charts/preview
# operationId: previewChart
export def "dashboards-charts-preview previewChart" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chart: string
  --globalFilter: any # nullable
]: any -> record<results: list<record>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards/charts/preview")
  let body = {chart: $chart, globalFilter: $globalFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get default dashboards
#
# GET /api/v1/{tenant}/dashboards/settings/default-dashboards
# operationId: getDefaultDashboards_1
export def "dashboards-settings-default-dashboards get-by-tenant" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultHomeDashboard: string, defaultFlowOverviewDashboard: string, defaultNamespaceOverviewDashboard: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards/settings/default-dashboards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate dashboard from yaml source
#
# POST /api/v1/{tenant}/dashboards/validate
# operationId: validateDashboard
export def "dashboards-validate validateDashboard" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<index: int, filename: string, namespace: string, flow: string, constraints: string, outdated: bool, deprecationPaths: list<string>, warnings: list<string>, infos: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards/validate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Validate a chart from yaml source
#
# POST /api/v1/{tenant}/dashboards/validate/chart
# operationId: validateChart
export def "dashboards-validate-chart validateChart" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<index: int, filename: string, namespace: string, flow: string, constraints: string, outdated: bool, deprecationPaths: list<string>, warnings: list<string>, infos: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards/validate/chart")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Get a dashboard
#
# GET /api/v1/{tenant}/dashboards/{id}
# operationId: getDashboard
export def "dashboards get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tenantId: string, id: string, title: string, description: string, timeWindow: record<default: string, max: string>, charts: table<id: string, type: string, chartOptions: record>, deleted: bool, created: string, updated: string, sourceCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a dashboard
#
# PUT /api/v1/{tenant}/dashboards/{id}
# operationId: updateDashboard
export def "dashboards updateDashboard" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<tenantId: string, id: string, title: string, description: string, timeWindow: record<default: string, max: string>, charts: table<id: string, type: string, chartOptions: record>, deleted: bool, created: string, updated: string, sourceCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Delete a dashboard
#
# DELETE /api/v1/{tenant}/dashboards/{id}
# operationId: deleteDashboard
export def "dashboards delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a dashboard chart data
#
# POST /api/v1/{tenant}/dashboards/{id}/charts/{chartId}
# operationId: getDashboardChartData
# --filters item shape: {field?: "QUERY"|"SCOPE"|"NAMESPACE"|"KIND"|"LABELS"|"TAGS"|"METADATA"|"FLOW_ID"|"FLOW_REVISION"|"ID"|"ASSET_ID"|"TYPE"|"ACTION"|"CREATED"|"UPDATED"|"START_DATE"|"END_DATE"|"EXPIRATION_DATE"|"STATE"|"STATUS"|"EMAIL"|"TIME_RANGE"|"PARENT_ID"|"TRIGGER_EXECUTION_ID"|"TRIGGER_ID"|"TRIGGER_STATE"|"EXECUTION_ID"|"TASK_ID"|"TASK_RUN_ID"|"ATTEMPT_NUMBER"|"CHILD_FILTER"|"WORKER_ID"|"EXISTING_ONLY"|"USER_ID"|"RESOURCES"|"DETAILS"|"LEVEL"|"PATH"|"PARENT_PATH"|"VERSION"|"ENABLED"|"USERNAME"|"NAME"|"GROUP"|"EXTERNAL_ID"|"EXPIRED_AT"|"SUPER_ADMIN"|"SOURCE"|"LOCKED"|"LAST_TRIGGERED_DATE"|"NEXT_EXECUTION_DATE"|"ARTIFACT_ID", operation?: "EQUALS"|"NOT_EQUALS"|"GREATER_THAN"|"LESS_THAN"|"GREATER_THAN_OR_EQUAL_TO"|"LESS_THAN_OR_EQUAL_TO"|"IN"|"NOT_IN"|"STARTS_WITH"|"ENDS_WITH"|"CONTAINS"|"REGEX"|"PREFIX", value?: record, logical?: "AND"|"OR", children?: list}
export def "dashboards-charts post" [
  id: string
  chartId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # format: date-time
  --endDate: string # format: date-time
  --pageSize: int # format: int32
  --pageNumber: int # format: int32
  --namespace: string
  --labels: record
  --filters: list # item shape: {field?: "QUERY"|"SCOPE"|"NAMESPACE"|"KIND"|"LABELS"|"TAGS"|"METADATA"|"FLOW_ID"|"FLOW_REVISION"|"ID"|"ASSET_ID"|"TYPE"|"ACTION"|"CREATED"|"UPDATED"|"START_DATE"|"END_DATE"|"EXPIRATION_DATE"|"STATE"|"STATUS"|"EMAIL"|"TIME_RANGE"|"PARENT_ID"|"TRIGGER_EXECUTION_ID"|"TRIGGER_ID"|"TRIGGER_STATE"|"EXECUTION_ID"|"TASK_ID"|"TASK_RUN_ID"|"ATTEMPT_NUMBER"|"CHILD_FILTER"|"WORKER_ID"|"EXISTING_ONLY"|"USER_ID"|"RESOURCES"|"DETAILS"|"LEVEL"|"PATH"|"PARENT_PATH"|"VERSION"|"ENABLED"|"USERNAME"|"NAME"|"GROUP"|"EXTERNAL_ID"|"EXPIRED_AT"|"SUPER_ADMIN"|"SOURCE"|"LOCKED"|"LAST_TRIGGERED_DATE"|"NEXT_EXECUTION_DATE"|"ARTIFACT_ID", operation?: "EQUALS"|"NOT_EQUALS"|"GREATER_THAN"|"LESS_THAN"|"GREATER_THAN_OR_EQUAL_TO"|"LESS_THAN_OR_EQUAL_TO"|"IN"|"NOT_IN"|"STARTS_WITH"|"ENDS_WITH"|"CONTAINS"|"REGEX"|"PREFIX", value?: record, logical?: "AND"|"OR", children?: list}
]: any -> record<results: list<record>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards/($id)/charts/($chartId)")
  let body = {startDate: $startDate, endDate: $endDate, pageSize: $pageSize, pageNumber: $pageNumber, namespace: $namespace, labels: $labels, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export a dashboard chart data to CSV
#
# POST /api/v1/{tenant}/dashboards/{id}/charts/{chartId}/export/to-csv
# operationId: exportDashboardChartDataToCSV
# --filters item shape: {field?: "QUERY"|"SCOPE"|"NAMESPACE"|"KIND"|"LABELS"|"TAGS"|"METADATA"|"FLOW_ID"|"FLOW_REVISION"|"ID"|"ASSET_ID"|"TYPE"|"ACTION"|"CREATED"|"UPDATED"|"START_DATE"|"END_DATE"|"EXPIRATION_DATE"|"STATE"|"STATUS"|"EMAIL"|"TIME_RANGE"|"PARENT_ID"|"TRIGGER_EXECUTION_ID"|"TRIGGER_ID"|"TRIGGER_STATE"|"EXECUTION_ID"|"TASK_ID"|"TASK_RUN_ID"|"ATTEMPT_NUMBER"|"CHILD_FILTER"|"WORKER_ID"|"EXISTING_ONLY"|"USER_ID"|"RESOURCES"|"DETAILS"|"LEVEL"|"PATH"|"PARENT_PATH"|"VERSION"|"ENABLED"|"USERNAME"|"NAME"|"GROUP"|"EXTERNAL_ID"|"EXPIRED_AT"|"SUPER_ADMIN"|"SOURCE"|"LOCKED"|"LAST_TRIGGERED_DATE"|"NEXT_EXECUTION_DATE"|"ARTIFACT_ID", operation?: "EQUALS"|"NOT_EQUALS"|"GREATER_THAN"|"LESS_THAN"|"GREATER_THAN_OR_EQUAL_TO"|"LESS_THAN_OR_EQUAL_TO"|"IN"|"NOT_IN"|"STARTS_WITH"|"ENDS_WITH"|"CONTAINS"|"REGEX"|"PREFIX", value?: record, logical?: "AND"|"OR", children?: list}
export def "dashboards-charts-export-to-csv exportDashboardChartDataToCSV" [
  id: string
  chartId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # format: date-time
  --endDate: string # format: date-time
  --pageSize: int # format: int32
  --pageNumber: int # format: int32
  --namespace: string
  --labels: record
  --filters: list # item shape: {field?: "QUERY"|"SCOPE"|"NAMESPACE"|"KIND"|"LABELS"|"TAGS"|"METADATA"|"FLOW_ID"|"FLOW_REVISION"|"ID"|"ASSET_ID"|"TYPE"|"ACTION"|"CREATED"|"UPDATED"|"START_DATE"|"END_DATE"|"EXPIRATION_DATE"|"STATE"|"STATUS"|"EMAIL"|"TIME_RANGE"|"PARENT_ID"|"TRIGGER_EXECUTION_ID"|"TRIGGER_ID"|"TRIGGER_STATE"|"EXECUTION_ID"|"TASK_ID"|"TASK_RUN_ID"|"ATTEMPT_NUMBER"|"CHILD_FILTER"|"WORKER_ID"|"EXISTING_ONLY"|"USER_ID"|"RESOURCES"|"DETAILS"|"LEVEL"|"PATH"|"PARENT_PATH"|"VERSION"|"ENABLED"|"USERNAME"|"NAME"|"GROUP"|"EXTERNAL_ID"|"EXPIRED_AT"|"SUPER_ADMIN"|"SOURCE"|"LOCKED"|"LAST_TRIGGERED_DATE"|"NEXT_EXECUTION_DATE"|"ARTIFACT_ID", operation?: "EQUALS"|"NOT_EQUALS"|"GREATER_THAN"|"LESS_THAN"|"GREATER_THAN_OR_EQUAL_TO"|"LESS_THAN_OR_EQUAL_TO"|"IN"|"NOT_IN"|"STARTS_WITH"|"ENDS_WITH"|"CONTAINS"|"REGEX"|"PREFIX", value?: record, logical?: "AND"|"OR", children?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/dashboards/($id)/charts/($chartId)/export/to-csv")
  let body = {startDate: $startDate, endDate: $endDate, pageSize: $pageSize, pageNumber: $pageNumber, namespace: $namespace, labels: $labels, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tenant dependencies
#
# GET /api/v1/{tenant}/dependencies
# operationId: getFlowDependenciesFromTenant
export def "dependencies get" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --destinationOnly: oneof<nothing, bool> # if true, list only destination dependencies, otherwise list also source dependencies (default: false)
]: nothing -> record<nodes: table<uid: string, namespace: string, id: string>, edges: table<source: string, target: string, relation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "destinationOnly" $destinationOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/dependencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for executions for a flow
#
# GET /api/v1/{tenant}/executions
# operationId: searchExecutionsByFlowId
export def "executions searchExecutionsByFlowId" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The flow namespace
  --flowId: string # The flow id
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
]: nothing -> record<results: table<tenantId: string, id: string, namespace: string, flowId: string, flowRevision: int, inputs: record, outputs: record, labels: list, state: record, parentId: string, originalId: string, trigger: record, scheduleDate: string, kind: string, loopRun: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "flowId" $flowId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a list of executions
#
# DELETE /api/v1/{tenant}/executions/by-ids
# operationId: deleteExecutionsByIds
export def "executions-by-ids delete" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeNonTerminated: oneof<nothing, bool> # Whether to delete non-terminated executions (nullable, default: false)
  --deleteLogs: oneof<nothing, bool> # Whether to delete execution logs (default: true)
  --deleteMetrics: oneof<nothing, bool> # Whether to delete execution metrics (default: true)
  --deleteStorage: oneof<nothing, bool> # Whether to delete execution files in the internal storage (default: true)
  --body: record
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeNonTerminated" $includeNonTerminated "scalar") (serialize-qp "deleteLogs" $deleteLogs "scalar") (serialize-qp "deleteMetrics" $deleteMetrics "scalar") (serialize-qp "deleteStorage" $deleteStorage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/by-ids" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete executions filter by query parameters
#
# DELETE /api/v1/{tenant}/executions/by-query
# operationId: deleteExecutionsByQuery
export def "executions-by-query delete" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[timeRange][EQUALS]=PT168H`, `filters[scope][EQUALS]=USER`, `filters[state][IN]=FAILED,CANCELLED`, `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
  --includeNonTerminated: oneof<nothing, bool> # Whether to delete non-terminated executions (nullable, default: false)
  --deleteLogs: oneof<nothing, bool> # Whether to delete execution logs (default: true)
  --deleteMetrics: oneof<nothing, bool> # Whether to delete execution metrics (default: true)
  --deleteStorage: oneof<nothing, bool> # Whether to delete execution files in the internal storage (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv") (serialize-qp "includeNonTerminated" $includeNonTerminated "scalar") (serialize-qp "deleteLogs" $deleteLogs "scalar") (serialize-qp "deleteMetrics" $deleteMetrics "scalar") (serialize-qp "deleteStorage" $deleteStorage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change executions state by id asynchronously
#
# POST /api/v1/{tenant}/executions/change-status/by-ids
# operationId: updateExecutionsStatusByIds
export def "executions-change-status-by-ids updateExecutionsStatusByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --newStatus: string@newStatus-completer # The new state of the executions
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "newStatus" $newStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/change-status/by-ids" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change executions state by query parameters asynchronously
#
# POST /api/v1/{tenant}/executions/change-status/by-query
# operationId: updateExecutionsStatusByQuery
export def "executions-change-status-by-query updateExecutionsStatusByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[timeRange][EQUALS]=PT168H`, `filters[scope][EQUALS]=USER`, `filters[state][IN]=FAILED,CANCELLED`, `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
  --newStatus: string@newStatus-completer # The new state of the executions
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv") (serialize-qp "newStatus" $newStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/change-status/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List distinct values for one of the executions filter fields, optionally narrowed by additional query filters
#
# GET /api/v1/{tenant}/executions/distinct-field-values
# operationId: findDistinctFieldValues
export def "executions-distinct-field-values findDistinctFieldValues" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --field: string@field-completer # The field whose distinct values to return. Must be a field supported by the EXECUTION resource.
  --filters: list # Additional filters to narrow the distinct values. PHP-style nested query is used - examples: `filters[flowId][CONTAINS]=test`, `filters[state][IN]=FAILED,WARNING`
  --size: int # Maximum number of distinct values to return. (format: int32, default: 100)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "field" $field "scalar") (serialize-qp "filters" $filters "csv") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/distinct-field-values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export all executions as a streamed CSV file
#
# GET /api/v1/{tenant}/executions/export/by-query/csv
# operationId: exportExecutions
export def "executions-export-by-query-csv exportExecutions" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # A list of filters
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/export/by-query/csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flow information's for an execution
#
# GET /api/v1/{tenant}/executions/flows/{namespace}/{flowId}
# operationId: getFlowFromExecution
export def "executions-flows get" [
  namespace: string
  flowId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: int # The flow revision (nullable, format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "revision" $revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/flows/($namespace)/($flowId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force run a list of executions asynchronously
#
# POST /api/v1/{tenant}/executions/force-run/by-ids
# operationId: forceRunByIds
export def "executions-force-run-by-ids forceRunByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/force-run/by-ids")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Force run executions filter by query parameters asynchronously
#
# POST /api/v1/{tenant}/executions/force-run/by-query
# operationId: forceRunExecutionsByQuery
export def "executions-force-run-by-query forceRunExecutionsByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[timeRange][EQUALS]=PT168H`, `filters[scope][EQUALS]=USER`, `filters[state][IN]=FAILED,CANCELLED`, `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/force-run/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kill a list of executions asynchronously
#
# DELETE /api/v1/{tenant}/executions/kill/by-ids
# operationId: killExecutionsByIds
export def "executions-kill-by-ids killExecutionsByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/kill/by-ids")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Kill executions filter by query parameters
#
# DELETE /api/v1/{tenant}/executions/kill/by-query
# operationId: killExecutionsByQuery
export def "executions-kill-by-query killExecutionsByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[timeRange][EQUALS]=PT168H`, `filters[scope][EQUALS]=USER`, `filters[state][IN]=FAILED,CANCELLED`, `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/kill/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set labels on a list of executions asynchronously
#
# POST /api/v1/{tenant}/executions/labels/by-ids
# operationId: setLabelsOnTerminatedExecutionsByIds
# --executionLabels item shape: {key: string, value: string}
export def "executions-labels-by-ids setLabelsOnTerminatedExecutionsByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  executionsId: list
  executionLabels: list # item shape: {key: string, value: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/labels/by-ids")
  let body = {executionsId: $executionsId, executionLabels: $executionLabels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set label on executions filter by query parameters asynchronously
#
# POST /api/v1/{tenant}/executions/labels/by-query
# operationId: setLabelsOnTerminatedExecutionsByQuery
export def "executions-labels-by-query setLabelsOnTerminatedExecutionsByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[timeRange][EQUALS]=PT168H`, `filters[scope][EQUALS]=USER`, `filters[state][IN]=FAILED,CANCELLED`, `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/labels/by-query" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the latest execution for given flows
#
# POST /api/v1/{tenant}/executions/latest
# operationId: getLatestExecutions
export def "executions-latest post" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<id: string, flowId: string, namespace: string, startDate: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/latest")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all namespaces that have executable flows
#
# GET /api/v1/{tenant}/executions/namespaces
# operationId: listExecutableDistinctNamespaces
export def "executions-namespaces listExecutableDistinctNamespaces" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/namespaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all flow ids for a namespace. Data returned are FlowForExecution containing minimal information about a Flow for when you are allowed to executing but not reading.
#
# GET /api/v1/{tenant}/executions/namespaces/{namespace}/flows
# operationId: listFlowExecutionsByNamespace
export def "executions-namespaces-flows listFlowExecutionsByNamespace" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/namespaces/($namespace)/flows")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pause a list of running executions asynchronously
#
# POST /api/v1/{tenant}/executions/pause/by-ids
# operationId: pauseExecutionsByIds
export def "executions-pause-by-ids pauseExecutionsByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/pause/by-ids")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Pause executions filter by query parameters asynchronously
#
# POST /api/v1/{tenant}/executions/pause/by-query
# operationId: pauseExecutionsByQuery
export def "executions-pause-by-query pauseExecutionsByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[timeRange][EQUALS]=PT168H`, `filters[scope][EQUALS]=USER`, `filters[state][IN]=FAILED,CANCELLED`, `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/pause/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new executions from old ones asynchronously. Keep the flow revision
#
# POST /api/v1/{tenant}/executions/replay/by-ids
# operationId: replayExecutionsByIds
export def "executions-replay-by-ids replayExecutionsByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --latestRevision: oneof<nothing, bool> # If latest revision should be used (nullable, default: false)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "latestRevision" $latestRevision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/replay/by-ids" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create new executions from old ones filter by query parameters asynchronously. Keep the flow revision
#
# POST /api/v1/{tenant}/executions/replay/by-query
# operationId: replayExecutionsByQuery
export def "executions-replay-by-query replayExecutionsByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[timeRange][EQUALS]=PT168H`, `filters[scope][EQUALS]=USER`, `filters[state][IN]=FAILED,CANCELLED`, `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
  --latestRevision: oneof<nothing, bool> # If latest revision should be used (nullable, default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv") (serialize-qp "latestRevision" $latestRevision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/replay/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restart a list of executions asynchronously
#
# POST /api/v1/{tenant}/executions/restart/by-ids
# operationId: restartExecutionsByIds
export def "executions-restart-by-ids restartExecutionsByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/restart/by-ids")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restart executions filter by query parameters asynchronously
#
# POST /api/v1/{tenant}/executions/restart/by-query
# operationId: restartExecutionsByQuery
export def "executions-restart-by-query restartExecutionsByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[timeRange][EQUALS]=PT168H`, `filters[scope][EQUALS]=USER`, `filters[state][IN]=FAILED,CANCELLED`, `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/restart/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resume a list of paused executions asynchronously
#
# POST /api/v1/{tenant}/executions/resume/by-ids
# operationId: resumeExecutionsByIds
export def "executions-resume-by-ids resumeExecutionsByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/resume/by-ids")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resume executions filter by query parameters asynchronously
#
# POST /api/v1/{tenant}/executions/resume/by-query
# operationId: resumeExecutionsByQuery
export def "executions-resume-by-query resumeExecutionsByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[timeRange][EQUALS]=PT168H`, `filters[scope][EQUALS]=USER`, `filters[state][IN]=FAILED,CANCELLED`, `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/resume/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for executions
#
# GET /api/v1/{tenant}/executions/search
# operationId: searchExecutions
export def "executions-search searchExecutions" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[timeRange][EQUALS]=PT168H`, `filters[scope][EQUALS]=USER`, `filters[state][IN]=FAILED,CANCELLED`, `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
  --dateFilter: string # Which execution date field the time interval is applied to (nullable)
]: nothing -> record<results: table<tenantId: string, id: string, namespace: string, flowId: string, flowRevision: int, inputs: record, outputs: record, labels: list, state: record, parentId: string, originalId: string, trigger: record, scheduleDate: string, kind: string, loopRun: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv") (serialize-qp "dateFilter" $dateFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unqueue a list of executions asynchronously
#
# POST /api/v1/{tenant}/executions/unqueue/by-ids
# operationId: unqueueExecutionsByIds
export def "executions-unqueue-by-ids unqueueExecutionsByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # The new state of the unqueued executions
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/unqueue/by-ids" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unqueue executions filter by query parameters asynchronously
#
# POST /api/v1/{tenant}/executions/unqueue/by-query
# operationId: unqueueExecutionsByQuery
export def "executions-unqueue-by-query unqueueExecutionsByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[timeRange][EQUALS]=PT168H`, `filters[scope][EQUALS]=USER`, `filters[state][IN]=FAILED,CANCELLED`, `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
  --newState: string # The new state of the unqueued executions (nullable)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv") (serialize-qp "newState" $newState "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/unqueue/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger a new execution by GET webhook trigger
#
# GET /api/v1/{tenant}/executions/webhook/{namespace}/{id}/{key}
# operationId: triggerExecutionByGetWebhook
export def "executions-webhook triggerExecutionByGetWebhook" [
  namespace: string
  id: string
  key: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tenantId: string, id: string, namespace: string, flowId: string, flowRevision: int, trigger: record<id: string, type: string, variables: record, logFile: string>, outputs: record, labels: table<key: string, value: string>, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/webhook/($namespace)/($id)/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger a new execution by PUT webhook trigger
#
# PUT /api/v1/{tenant}/executions/webhook/{namespace}/{id}/{key}
# operationId: triggerExecutionByPutWebhook
export def "executions-webhook triggerExecutionByPutWebhook" [
  namespace: string
  id: string
  key: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tenantId: string, id: string, namespace: string, flowId: string, flowRevision: int, trigger: record<id: string, type: string, variables: record, logFile: string>, outputs: record, labels: table<key: string, value: string>, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/webhook/($namespace)/($id)/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger a new execution by POST webhook trigger
#
# POST /api/v1/{tenant}/executions/webhook/{namespace}/{id}/{key}
# operationId: triggerExecutionByPostWebhook
export def "executions-webhook triggerExecutionByPostWebhook" [
  namespace: string
  id: string
  key: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tenantId: string, id: string, namespace: string, flowId: string, flowRevision: int, trigger: record<id: string, type: string, variables: record, logFile: string>, outputs: record, labels: table<key: string, value: string>, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/webhook/($namespace)/($id)/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger a new execution by GET webhook trigger
#
# GET /api/v1/{tenant}/executions/webhook/{namespace}/{id}/{key}/{path}
# operationId: triggerExecutionByGetWebhookWithPath
export def "executions-webhook triggerExecutionByGetWebhookWithPath" [
  namespace: string
  id: string
  key: string
  path: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tenantId: string, id: string, namespace: string, flowId: string, flowRevision: int, trigger: record<id: string, type: string, variables: record, logFile: string>, outputs: record, labels: table<key: string, value: string>, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/webhook/($namespace)/($id)/($key)/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger a new execution by PUT webhook trigger
#
# PUT /api/v1/{tenant}/executions/webhook/{namespace}/{id}/{key}/{path}
# operationId: triggerExecutionByPutWebhookWithPath
export def "executions-webhook triggerExecutionByPutWebhookWithPath" [
  namespace: string
  id: string
  key: string
  path: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tenantId: string, id: string, namespace: string, flowId: string, flowRevision: int, trigger: record<id: string, type: string, variables: record, logFile: string>, outputs: record, labels: table<key: string, value: string>, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/webhook/($namespace)/($id)/($key)/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger a new execution by POST webhook trigger
#
# POST /api/v1/{tenant}/executions/webhook/{namespace}/{id}/{key}/{path}
# operationId: triggerExecutionByPostWebhookWithPath
export def "executions-webhook triggerExecutionByPostWebhookWithPath" [
  namespace: string
  id: string
  key: string
  path: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tenantId: string, id: string, namespace: string, flowId: string, flowRevision: int, trigger: record<id: string, type: string, variables: record, logFile: string>, outputs: record, labels: table<key: string, value: string>, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/webhook/($namespace)/($id)/($key)/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an execution
#
# GET /api/v1/{tenant}/executions/{executionId}
# operationId: getExecution
export def "executions get" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tenantId: string, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, labels: table<key: string, value: string>, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: string, breakpoints: table<id: string, value: string>, loopRun: record<parent: record<labels: list, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: list, inputs: record, outputs: record, variables: record, state: record, parentId: string, originalId: string, trigger: record, deleted: bool, metadata: record, scheduleDate: string, traceParent: string, fixtures: list, kind: record, breakpoints: list, loopRun: record>, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an execution
#
# DELETE /api/v1/{tenant}/executions/{executionId}
# operationId: deleteExecution
export def "executions delete" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleteLogs: oneof<nothing, bool> # Whether to delete execution logs (default: true)
  --deleteMetrics: oneof<nothing, bool> # Whether to delete execution metrics (default: true)
  --deleteStorage: oneof<nothing, bool> # Whether to delete execution files in the internal storage (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteLogs" $deleteLogs "scalar") (serialize-qp "deleteMetrics" $deleteMetrics "scalar") (serialize-qp "deleteStorage" $deleteStorage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change the state of an execution
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/change-status
# operationId: updateExecutionStatus
export def "executions-actions-change-status updateExecutionStatus" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # The new state of the execution
]: nothing -> record<labels: table<key: string, value: string>, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, executionId: string, namespace: string, flowId: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, deleted: bool, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: record, breakpoints: table<id: string, value: string>, loopRun: record<parent: any, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/change-status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Evaluate a variable expression for this execution
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/eval
# operationId: evalExpression
export def "executions-actions-eval evalExpression" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<result: string, error: string, stackTrace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/eval")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Evaluate a variable expression for this taskrun
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/eval/{taskRunId}
# operationId: evalTaskRunExpression
export def "executions-actions-eval evalTaskRunExpression" [
  executionId: string
  taskRunId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<result: string, error: string, stackTrace: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/eval/($taskRunId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Force run an execution
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/force-run
# operationId: forceRunExecution
export def "executions-actions-force-run forceRunExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<labels: table<key: string, value: string>, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, executionId: string, namespace: string, flowId: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, deleted: bool, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: record, breakpoints: table<id: string, value: string>, loopRun: record<parent: any, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/force-run")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kill an execution
#
# DELETE /api/v1/{tenant}/executions/{executionId}/actions/kill
# operationId: killExecution
export def "executions-actions-kill killExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isOnKillCascade: oneof<nothing, bool> # Specifies whether killing the execution also kill all subflow executions. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isOnKillCascade" $isOnKillCascade "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/kill" $qp)
  let accept_val = "text/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or update labels of a terminated execution
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/labels
# operationId: setLabelsOnTerminatedExecution
export def "executions-actions-labels setLabelsOnTerminatedExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<labels: table<key: string, value: string>, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, executionId: string, namespace: string, flowId: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, deleted: bool, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: record, breakpoints: table<id: string, value: string>, loopRun: record<parent: any, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/labels")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Pause a running execution.
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/pause
# operationId: pauseExecution
export def "executions-actions-pause pauseExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<labels: table<key: string, value: string>, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, executionId: string, namespace: string, flowId: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, deleted: bool, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: record, breakpoints: table<id: string, value: string>, loopRun: record<parent: any, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new execution from an old one and start it from a specified task run id
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/replay
# operationId: replayExecution
export def "executions-actions-replay replayExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskRunId: string # The taskrun id (nullable)
  --revision: int # The flow revision to use for new execution (nullable, format: int32)
  --breakpoints: string # Set a list of breakpoints at specific tasks 'id.value', separated by a coma. (nullable)
]: nothing -> record<labels: table<key: string, value: string>, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, executionId: string, namespace: string, flowId: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, deleted: bool, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: record, breakpoints: table<id: string, value: string>, loopRun: record<parent: any, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "taskRunId" $taskRunId "scalar") (serialize-qp "revision" $revision "scalar") (serialize-qp "breakpoints" $breakpoints "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/replay" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new execution from an old one and start it from a specified task run id
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/replay-with-inputs
# operationId: replayExecutionWithinputs
export def "executions-actions-replay-with-inputs replayExecutionWithinputs" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskRunId: string # The taskrun id (nullable)
  --revision: int # The flow revision to use for new execution (nullable, format: int32)
  --breakpoints: string # Set a list of breakpoints at specific tasks 'id.value', separated by a coma. (nullable)
  --body: record
]: any -> record<labels: table<key: string, value: string>, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, executionId: string, namespace: string, flowId: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, deleted: bool, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: record, breakpoints: table<id: string, value: string>, loopRun: record<parent: any, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "taskRunId" $taskRunId "scalar") (serialize-qp "revision" $revision "scalar") (serialize-qp "breakpoints" $breakpoints "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/replay-with-inputs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Restart a new execution from an old one
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/restart
# operationId: restartExecution
export def "executions-actions-restart restartExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: int # The flow revision to use for new execution (nullable, format: int32)
]: nothing -> record<labels: table<key: string, value: string>, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, executionId: string, namespace: string, flowId: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, deleted: bool, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: record, breakpoints: table<id: string, value: string>, loopRun: record<parent: any, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "revision" $revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resume a paused execution.
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/resume
# operationId: resumeExecution
export def "executions-actions-resume resumeExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<labels: table<key: string, value: string>, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, executionId: string, namespace: string, flowId: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, deleted: bool, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: record, breakpoints: table<id: string, value: string>, loopRun: record<parent: any, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/resume")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Resume an execution from a breakpoint (in the 'BREAKPOINT' state).
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/resume-from-breakpoint
# operationId: resumeExecutionFromBreakpoint
export def "executions-actions-resume-from-breakpoint resumeExecutionFromBreakpoint" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --breakpoints: string # "Set a list of breakpoints at specific tasks 'id.value', separated by a coma. (nullable)
]: nothing -> record<labels: table<key: string, value: string>, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, executionId: string, namespace: string, flowId: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, deleted: bool, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: record, breakpoints: table<id: string, value: string>, loopRun: record<parent: any, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "breakpoints" $breakpoints "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/resume-from-breakpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate inputs to resume a paused execution.
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/resume/validate
# operationId: validateResumeExecutionInputs
export def "executions-actions-resume-validate validateResumeExecutionInputs" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<id: string, namespace: string, inputs: list<record>, checks: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/resume/validate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Change state for a taskrun in an execution
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/state
# operationId: updateTaskRunState
export def "executions-actions-state updateTaskRunState" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  taskRunId: string
  state: string@state-completer
]: any -> record<labels: table<key: string, value: string>, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, executionId: string, namespace: string, flowId: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, deleted: bool, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: record, breakpoints: table<id: string, value: string>, loopRun: record<parent: any, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/state")
  let body = {taskRunId: $taskRunId, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unqueue an execution
#
# POST /api/v1/{tenant}/executions/{executionId}/actions/unqueue
# operationId: unqueueExecution
export def "executions-actions-unqueue unqueueExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # The new state of the execution
]: nothing -> record<labels: table<key: string, value: string>, id: string, namespace: string, flowId: string, flowRevision: int, taskRunList: table<id: string, executionId: string, namespace: string, flowId: string, taskId: string, parentTaskRunId: string, value: string, attempts: list, assets: record, state: record, iteration: int, dynamic: bool, forceExecution: bool>, inputs: record, outputs: record, variables: record, state: record<duration: string, startDate: string, endDate: string, current: string, histories: list<record>, getDuration: string, getStartDate: string, getEndDate: string>, parentId: string, originalId: string, trigger: record<id: string, type: string, variables: record, logFile: string>, deleted: bool, metadata: record<attemptNumber: int, originalCreatedDate: string>, scheduleDate: string, traceParent: string, fixtures: table<id: string, value: string, state: string, outputs: record, assets: list, description: record>, kind: record, breakpoints: table<id: string, value: string>, loopRun: record<parent: any, taskId: string, taskRunId: string, index: int, key: string, value: string, parents: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/actions/unqueue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download file for an execution
#
# GET /api/v1/{tenant}/executions/{executionId}/file
# operationId: downloadFileFromExecution
export def "executions-file downloadFileFromExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri (format: uri)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/file" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file meta information for an execution
#
# GET /api/v1/{tenant}/executions/{executionId}/file/metas
# operationId: getFileMetadatasFromExecution
export def "executions-file-metas get" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri (format: uri)
]: nothing -> record<size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/file/metas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file preview for an execution
#
# GET /api/v1/{tenant}/executions/{executionId}/file/preview
# operationId: previewFileFromExecution
export def "executions-file-preview previewFileFromExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri (format: uri)
  --maxRows: int # The max row returns (format: int32)
  --encoding: string # The file encoding as Java charset name. Defaults to UTF-8 (default: UTF-8, e.g. ISO-8859-1)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "maxRows" $maxRows "scalar") (serialize-qp "encoding" $encoding "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/file/preview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flow information's for an execution
#
# GET /api/v1/{tenant}/executions/{executionId}/flow
# operationId: getFlowFromExecutionById
export def "executions-flow get" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/flow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow an execution
#
# GET /api/v1/{tenant}/executions/{executionId}/follow
# operationId: followExecution
export def "executions-follow followExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/follow")
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow all execution dependencies executions
#
# GET /api/v1/{tenant}/executions/{executionId}/follow-dependencies
# operationId: followDependenciesExecutions
export def "executions-follow-dependencies followDependenciesExecutions" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --destinationOnly: oneof<nothing, bool> # If true, list only destination dependencies, otherwise list also source dependencies (default: false)
  --expandAll: oneof<nothing, bool> # If true, expand all dependencies recursively (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "destinationOnly" $destinationOnly "scalar") (serialize-qp "expandAll" $expandAll "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/follow-dependencies" $qp)
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a graph for an execution
#
# GET /api/v1/{tenant}/executions/{executionId}/graph
# operationId: getExecutionFlowGraph
export def "executions-graph get" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subflows: list # The subflow tasks to display (nullable)
]: nothing -> record<nodes: table<uid: string, type: string, branchType: string>, edges: table<source: string, target: string, relation: record>, clusters: table<cluster: record, nodes: list, parents: list, start: string, end: string>, flowables: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subflows" $subflows "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($executionId)/graph" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new execution for a flow
#
# POST /api/v1/{tenant}/executions/{namespace}/{id}
# operationId: createExecution
export def "executions createExecution" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: list # The labels as a list of 'key:value' (nullable)
  --wait: oneof<nothing, bool> # If the server will wait the end of the execution (default: false)
  --revision: int # The flow revision or latest if null (nullable, format: int32)
  --scheduleDate: string # Schedule the flow on a specific date (nullable, format: date-time)
  --breakpoints: string # Set a list of breakpoints at specific tasks 'id.value', separated by a coma. (nullable)
  --kind: string # Specific execution kind (nullable)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "labels" $labels "multi") (serialize-qp "wait" $wait "scalar") (serialize-qp "revision" $revision "scalar") (serialize-qp "scheduleDate" $scheduleDate "scalar") (serialize-qp "breakpoints" $breakpoints "scalar") (serialize-qp "kind" $kind "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($namespace)/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Validate the creation of a new execution for a flow
#
# POST /api/v1/{tenant}/executions/{namespace}/{id}/validate
# operationId: validateNewExecutionInputs
export def "executions-validate validateNewExecutionInputs" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: list # The labels as a list of 'key:value'
  --revision: int # The flow revision or latest if null (nullable, format: int32)
  --body: record
]: any -> table<id: string, namespace: string, inputs: list<record>, checks: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "labels" $labels "multi") (serialize-qp "revision" $revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/executions/($namespace)/($id)/validate" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Create a flow from yaml source
#
# POST /api/v1/{tenant}/flows
# operationId: createFlow
export def "flows createFlow" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/flows")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Update from multiples yaml sources
#
# POST /api/v1/{tenant}/flows/bulk
# operationId: bulkUpdateFlows
export def "flows-bulk bulkUpdateFlows" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete: oneof<nothing, bool> # If missing flow should be deleted (default: true)
  --namespace: string # The namespace where to update flows (nullable)
  --allowNamespaceChild: oneof<nothing, bool> # If namespace child should are allowed to be updated (default: false)
  --body: record
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete" $delete "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "allowNamespaceChild" $allowNamespaceChild "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/bulk" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Delete flows by their IDs.
#
# DELETE /api/v1/{tenant}/flows/delete/by-ids
# operationId: deleteFlowsByIds
export def "flows-delete-by-ids delete" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/delete/by-ids")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete flows returned by the query parameters.
#
# DELETE /api/v1/{tenant}/flows/delete/by-query
# operationId: deleteFlowsByQuery
export def "flows-delete-by-query delete" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/delete/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List flows containing deprecated tasks
#
# GET /api/v1/{tenant}/flows/deprecated
# operationId: listDeprecated
export def "flows-deprecated listDeprecated" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # A namespace filter prefix (nullable)
]: nothing -> table<namespace: string, flowId: string, revision: int, deprecatedTasks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/deprecated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable flows by their IDs.
#
# POST /api/v1/{tenant}/flows/disable/by-ids
# operationId: disableFlowsByIds
export def "flows-disable-by-ids disableFlowsByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/disable/by-ids")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable flows returned by the query parameters.
#
# POST /api/v1/{tenant}/flows/disable/by-query
# operationId: disableFlowsByQuery
export def "flows-disable-by-query disableFlowsByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/disable/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all distinct namespaces
#
# GET /api/v1/{tenant}/flows/distinct-namespaces
# operationId: listDistinctNamespaces
export def "flows-distinct-namespaces listDistinctNamespaces" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # A string filter (nullable)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/distinct-namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable flows by their IDs.
#
# POST /api/v1/{tenant}/flows/enable/by-ids
# operationId: enableFlowsByIds
export def "flows-enable-by-ids enableFlowsByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/enable/by-ids")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enable flows returned by the query parameters.
#
# POST /api/v1/{tenant}/flows/enable/by-query
# operationId: enableFlowsByQuery
export def "flows-enable-by-query enableFlowsByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/enable/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export flows as a ZIP archive of yaml sources.
#
# POST /api/v1/{tenant}/flows/export/by-ids
# operationId: exportFlowsByIds
export def "flows-export-by-ids exportFlowsByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/export/by-ids")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export flows as a ZIP archive of yaml sources.
#
# GET /api/v1/{tenant}/flows/export/by-query
# operationId: exportFlowsByQuery
export def "flows-export-by-query exportFlowsByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/export/by-query" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export all flows as a streamed CSV file
#
# GET /api/v1/{tenant}/flows/export/by-query/csv
# operationId: exportFlows
export def "flows-export-by-query-csv exportFlows" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # A list of filters
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/export/by-query/csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get available Pebble expressions for a flow
#
# POST /api/v1/{tenant}/flows/expressions
# operationId: expressions
export def "flows-expressions expressions" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskId: string # Optional task ID to scope outputs to prior tasks (nullable)
  --body: record
]: any -> record<categories: record<TASK_OUTPUTS: list<any>, EXECUTION_CONTEXT: list<any>, INPUTS: list<any>, VARIABLES: list<any>, SECRETS: list<any>, KV_PAIRS: list<any>, NAMESPACE_FILES: list<any>, FILTERS: list<any>, FUNCTIONS: list<any>, APP_CONTEXT: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "taskId" $taskId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/expressions" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Generate a graph for a flow source
#
# POST /api/v1/{tenant}/flows/graph
# operationId: generateFlowGraphFromSource
export def "flows-graph generateFlowGraphFromSource" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subflows: list # The subflow tasks to display (nullable)
  --body: record
]: any -> record<nodes: table<uid: string, type: string, branchType: string>, edges: table<source: string, target: string, relation: record>, clusters: table<cluster: record, nodes: list, parents: list, start: string, end: string>, flowables: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subflows" $subflows "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/graph" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

#     Import flows as a ZIP archive of yaml sources or a multi-objects YAML file.     When sending a Yaml that contains one or more flows, a list of index is returned.     When sending a ZIP archive, a list of files that couldn't be imported is returned.
#
# POST /api/v1/{tenant}/flows/import
# operationId: importFlows
export def "flows-import importFlows" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --failOnError: oneof<nothing, bool> # If should fail on invalid flows (default: false)
  --fileUpload: string # The file to import, can be a ZIP archive or a multi-objects YAML file (format: binary)
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "failOnError" $failOnError "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/import" $qp)
  let body = {fileUpload: $fileUpload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Search for flows
#
# GET /api/v1/{tenant}/flows/search
# operationId: searchFlows
export def "flows-search searchFlows" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[labels][NOT_EQUALS][foo]=bar`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record<results: list<record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for flows source code
#
# GET /api/v1/{tenant}/flows/source
# operationId: searchFlowsBySourceCode
export def "flows-source searchFlowsBySourceCode" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --q: string # A string filter (nullable)
  --namespace: string # A namespace filter prefix (nullable)
]: nothing -> record<results: table<model: record, fragments: list>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar") (serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/source" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate a list of flows
#
# POST /api/v1/{tenant}/flows/validate
# operationId: validateFlows
export def "flows-validate validateFlows" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<index: int, filename: string, namespace: string, flow: string, constraints: string, outdated: bool, deprecationPaths: list<string>, warnings: list<string>, infos: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/validate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Validate a task
#
# POST /api/v1/{tenant}/flows/validate/task
# operationId: validateTask
export def "flows-validate-task validateTask" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --section: string@section-completer # The type of task
  --body: record
]: any -> record<index: int, filename: string, namespace: string, flow: string, constraints: string, outdated: bool, deprecationPaths: list<string>, warnings: list<string>, infos: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "section" $section "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/validate/task" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validate trigger
#
# POST /api/v1/{tenant}/flows/validate/trigger
# operationId: validateTrigger
export def "flows-validate-trigger validateTrigger" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<index: int, filename: string, namespace: string, flow: string, constraints: string, outdated: bool, deprecationPaths: list<string>, warnings: list<string>, infos: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/validate/trigger")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all flows from a given namespace
#
# GET /api/v1/{tenant}/flows/{namespace}
# operationId: listFlowsByNamespace
export def "flows listFlowsByNamespace" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a complete namespace from yaml source
#
# POST /api/v1/{tenant}/flows/{namespace}
# operationId: updateFlowsInNamespace
export def "flows updateFlowsInNamespace" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete: oneof<nothing, bool> # If missing flows should be deleted (default: true)
  --override: oneof<nothing, bool> # If namespace of all provided flows should be overridden (default: false)
  --body: record
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete" $delete "scalar") (serialize-qp "override" $override "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/($namespace)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Get a flow
#
# GET /api/v1/{tenant}/flows/{namespace}/{id}
# operationId: getFlow
export def "flows get" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-source: oneof<nothing, bool> # Include the source code (default: false)
  --revision: int # Get latest revision by default (nullable, format: int32)
  --allowDeleted: oneof<nothing, bool> # Get flow even if deleted (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "revision" $revision "scalar") (serialize-qp "allowDeleted" $allowDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/($namespace)/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a flow
#
# PUT /api/v1/{tenant}/flows/{namespace}/{id}
# operationId: updateFlow
export def "flows updateFlow" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/($namespace)/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Delete a flow
#
# DELETE /api/v1/{tenant}/flows/{namespace}/{id}
# operationId: deleteFlow
export def "flows delete" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/($namespace)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flow dependencies
#
# GET /api/v1/{tenant}/flows/{namespace}/{id}/dependencies
# operationId: getFlowDependencies
export def "flows-dependencies get" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --destinationOnly: oneof<nothing, bool> # If true, list only destination dependencies, otherwise list also source dependencies (default: false)
  --expandAll: oneof<nothing, bool> # If true, expand all dependencies recursively (default: false)
]: nothing -> record<nodes: table<uid: string, namespace: string, id: string>, edges: table<source: string, target: string, relation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "destinationOnly" $destinationOnly "scalar") (serialize-qp "expandAll" $expandAll "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/($namespace)/($id)/dependencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a graph for a flow
#
# GET /api/v1/{tenant}/flows/{namespace}/{id}/graph
# operationId: generateFlowGraph
export def "flows-graph generateFlowGraph" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: int # The flow revision (nullable, format: int32)
  --subflows: list # The subflow tasks to display (nullable)
]: nothing -> record<nodes: table<uid: string, type: string, branchType: string>, edges: table<source: string, target: string, relation: record>, clusters: table<cluster: record, nodes: list, parents: list, start: string, end: string>, flowables: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "revision" $revision "scalar") (serialize-qp "subflows" $subflows "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/($namespace)/($id)/graph" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get revisions for a flow
#
# GET /api/v1/{tenant}/flows/{namespace}/{id}/revisions
# operationId: listFlowRevisions
export def "flows-revisions listFlowRevisions" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowDelete: oneof<nothing, bool> # default: false
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowDelete" $allowDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/($namespace)/($id)/revisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete revisions for a flow
#
# DELETE /api/v1/{tenant}/flows/{namespace}/{id}/revisions
# operationId: deleteRevisions
export def "flows-revisions delete" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revisions: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "revisions" $revisions "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/($namespace)/($id)/revisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a flow task
#
# GET /api/v1/{tenant}/flows/{namespace}/{id}/tasks/{taskId}
# operationId: getTaskFromFlow
export def "flows-tasks get" [
  namespace: string
  id: string
  taskId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: int # The flow revision (nullable, format: int32)
]: nothing -> record<id: string, type: string, version: string, description: string, retry: record, timeout: record<expression: string, value: string>, disabled: bool, workerSelector: record<tags: list<string>, match: record, fallback: record>, logLevel: string, allowFailure: bool, logToFile: bool, runIf: string, allowWarning: bool, taskCache: record<enabled: bool, ttl: string>, assets: record<enableAuto: record<expression: string, value: bool>, inputs: record<expression: string, value: list>, outputs: record<expression: string, value: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "revision" $revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/flows/($namespace)/($id)/tasks/($taskId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a group
#
# POST /api/v1/{tenant}/groups
# operationId: createGroup
export def "groups createGroup" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --membersId: list
]: any -> record<id: string, name: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/groups")
  let body = {name: $name, description: $description, membersId: $membersId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List groups for autocomplete
#
# POST /api/v1/{tenant}/groups/autocomplete
# operationId: autocompleteGroups
export def "groups-autocomplete autocompleteGroups" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters
  --q: string # nullable
  --ids: list # nullable
  --existingOnly: oneof<nothing, bool>
]: any -> table<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/groups/autocomplete" $qp)
  let body = {q: $q, ids: $ids, existingOnly: $existingOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List groups by ids
#
# POST /api/v1/{tenant}/groups/ids
# operationId: listGroupIds
export def "groups-ids listGroupIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list
]: any -> table<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/groups/ids")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for groups
#
# GET /api/v1/{tenant}/groups/search
# operationId: searchGroups
export def "groups-search searchGroups" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<id: string, name: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/groups/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a group
#
# GET /api/v1/{tenant}/groups/{id}
# operationId: getGroup
export def "groups get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a group
#
# PUT /api/v1/{tenant}/groups/{id}
# operationId: updateGroup
export def "groups updateGroup" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # of the group.
  --description: string # of the group.
]: any -> record<id: string, name: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/groups/($id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a group
#
# DELETE /api/v1/{tenant}/groups/{id}
# operationId: deleteGroup
export def "groups delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for users in a group
#
# GET /api/v1/{tenant}/groups/{id}/members
# operationId: searchGroupMembers
export def "groups-members searchGroupMembers" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<id: string, username: string, displayName: string, groups: list>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/groups/($id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user's membership type in a group
#
# PUT /api/v1/{tenant}/groups/{id}/members/membership/{userId}
# operationId: setUserMembershipForGroup
export def "groups-members-membership setUserMembershipForGroup" [
  id: string
  userId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --membership: string@membership-completer # The new membership type to assign to the user.
]: nothing -> record<id: string, username: string, displayName: string, groups: table<id: string, name: string, external: bool, membership: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "membership" $membership "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/groups/($id)/members/membership/($userId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a user to a group
#
# PUT /api/v1/{tenant}/groups/{id}/members/{userId}
# operationId: addUserToGroup
export def "groups-members addUserToGroup" [
  id: string
  userId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, username: string, displayName: string, groups: table<id: string, name: string, external: bool, membership: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/groups/($id)/members/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a user from a group
#
# DELETE /api/v1/{tenant}/groups/{id}/members/{userId}
# operationId: deleteUserFromGroup
export def "groups-members delete" [
  id: string
  userId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, username: string, displayName: string, groups: table<id: string, name: string, external: bool, membership: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/groups/($id)/members/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find by a combination of query parameters
#
# GET /api/v1/{tenant}/integrations/{integration}/scim/v2/Groups
# operationId: queryGroups
export def "integrations-scim-groups queryGroups" [
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # nullable
  --excludedAttributes: string # nullable
  --filter: string # nullable
  --sortBy: string # nullable
  --sortOrder: string # nullable
  --startIndex: int # nullable, format: int32
  --count: int # nullable, format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Groups" $qp)
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /api/v1/{tenant}/integrations/{integration}/scim/v2/Groups
# operationId: createSCIMResourceByIdGroups
export def "integrations-scim-groups createSCIMResourceByIdGroups" [
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # nullable
  --excludedAttributes: string # nullable
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Groups" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Search
#
# POST /api/v1/{tenant}/integrations/{integration}/scim/v2/Groups/.search
# operationId: findGroups
export def "integrations-scim-groups-search findGroups" [
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Groups/.search")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Find by id
#
# GET /api/v1/{tenant}/integrations/{integration}/scim/v2/Groups/{id}
# operationId: getSCIMResourceByIdGroups
export def "integrations-scim-groups get" [
  id: string
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # nullable
  --excludedAttributes: string # nullable
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Groups/($id)" $qp)
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /api/v1/{tenant}/integrations/{integration}/scim/v2/Groups/{id}
# operationId: updateGroups
export def "integrations-scim-groups updateGroups" [
  id: string
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # nullable
  --excludedAttributes: string # nullable
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Groups/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Delete from the backing store
#
# DELETE /api/v1/{tenant}/integrations/{integration}/scim/v2/Groups/{id}
# operationId: deleteGroups
export def "integrations-scim-groups delete" [
  id: string
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch a portion of the backing store
#
# PATCH /api/v1/{tenant}/integrations/{integration}/scim/v2/Groups/{id}
# operationId: patchGroups
export def "integrations-scim-groups patch" [
  id: string
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # nullable
  --excludedAttributes: string # nullable
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Groups/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Get All Resource Types
#
# GET /api/v1/{tenant}/integrations/{integration}/scim/v2/ResourceTypes
# operationId: getAllResourceTypes
export def "integrations-scim-resource-types list" [
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/ResourceTypes")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Resource Type by URN
#
# GET /api/v1/{tenant}/integrations/{integration}/scim/v2/ResourceTypes/{name}
# operationId: getResourceType
export def "integrations-scim-resource-types get" [
  name: string
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/ResourceTypes/($name)")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get All Schemas
#
# GET /api/v1/{tenant}/integrations/{integration}/scim/v2/Schemas
# operationId: getAllSchemas
export def "integrations-scim-schemas list" [
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Schemas")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Schemas by URN
#
# GET /api/v1/{tenant}/integrations/{integration}/scim/v2/Schemas/{uri}
# operationId: getSchema
export def "integrations-scim-schemas get" [
  uri: string
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Schemas/($uri)")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Service Provider Configuration
#
# GET /api/v1/{tenant}/integrations/{integration}/scim/v2/ServiceProviderConfig
# operationId: getServiceProviderConfiguration
export def "integrations-scim-service-provider-config get" [
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/ServiceProviderConfig")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find by a combination of query parameters
#
# GET /api/v1/{tenant}/integrations/{integration}/scim/v2/Users
# operationId: queryUsers
export def "integrations-scim-users queryUsers" [
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # nullable
  --excludedAttributes: string # nullable
  --filter: string # nullable
  --sortBy: string # nullable
  --sortOrder: string # nullable
  --startIndex: int # nullable, format: int32
  --count: int # nullable, format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Users" $qp)
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /api/v1/{tenant}/integrations/{integration}/scim/v2/Users
# operationId: createSCIMResourceByIdUsers
export def "integrations-scim-users createSCIMResourceByIdUsers" [
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # nullable
  --excludedAttributes: string # nullable
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Users" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Search
#
# POST /api/v1/{tenant}/integrations/{integration}/scim/v2/Users/.search
# operationId: findUsers
export def "integrations-scim-users-search findUsers" [
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Users/.search")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Find by id
#
# GET /api/v1/{tenant}/integrations/{integration}/scim/v2/Users/{id}
# operationId: getSCIMResourceByIdUsers
export def "integrations-scim-users get" [
  id: string
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # nullable
  --excludedAttributes: string # nullable
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Users/($id)" $qp)
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /api/v1/{tenant}/integrations/{integration}/scim/v2/Users/{id}
# operationId: updateUsers
export def "integrations-scim-users updateUsers" [
  id: string
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # nullable
  --excludedAttributes: string # nullable
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Users/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Delete from the backing store
#
# DELETE /api/v1/{tenant}/integrations/{integration}/scim/v2/Users/{id}
# operationId: deleteUsers
export def "integrations-scim-users delete" [
  id: string
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch a portion of the backing store
#
# PATCH /api/v1/{tenant}/integrations/{integration}/scim/v2/Users/{id}
# operationId: patchUsers
export def "integrations-scim-users patch" [
  id: string
  integration: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # nullable
  --excludedAttributes: string # nullable
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/integrations/($integration)/scim/v2/Users/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Create an invitation
#
# POST /api/v1/{tenant}/invitations
# operationId: createInvitation
# --roles item shape: {id: string, namespaces?: list}
export def "invitations createInvitation" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --createUserIfNotExist: oneof<nothing, bool>
  --superAdmin: oneof<nothing, bool>
  --roles: list # item shape: {id: string, namespaces?: list}
  --groups: list
  email: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/invitations")
  let body = {createUserIfNotExist: $createUserIfNotExist, superAdmin: $superAdmin, roles: $roles, groups: $groups, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all invitations for a given email
#
# GET /api/v1/{tenant}/invitations/email/{email}
# operationId: listInvitationsByEmail
export def "invitations-email listInvitationsByEmail" [
  email: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, roles: list<record>, groups: list<record>, tenantId: string, email: string, status: string, sentAt: string, expiredAt: string, acceptedAt: string, superAdmin: bool, link: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/invitations/email/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for invitations
#
# GET /api/v1/{tenant}/invitations/search
# operationId: searchInvitations
export def "invitations-search searchInvitations" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<id: string, roles: list, groups: list, tenantId: string, email: string, status: string, sentAt: string, expiredAt: string, acceptedAt: string, superAdmin: bool, link: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/invitations/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an invitation
#
# GET /api/v1/{tenant}/invitations/{id}
# operationId: getInvitation
export def "invitations get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, roles: table<id: string, name: string, isDefault: bool, isManaged: bool>, groups: table<id: string, name: string>, tenantId: string, email: string, status: string, sentAt: string, expiredAt: string, acceptedAt: string, superAdmin: bool, link: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/invitations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an invitation
#
# DELETE /api/v1/{tenant}/invitations/{id}
# operationId: deleteInvitation
export def "invitations delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/invitations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all keys
#
# GET /api/v1/{tenant}/kv
# operationId: listAllKeys
export def "kv listAllKeys" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters. PHP-style nested query is used - example: `filters[namespace][IN]=company.team` (nullable)
]: nothing -> record<results: table<namespace: string, key: string, version: int, description: string, creationDate: string, updateDate: string, expirationDate: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/kv" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for logs
#
# GET /api/v1/{tenant}/logs/search
# operationId: searchLogs
export def "logs-search searchLogs" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[flowId][EQUALS]=hello-world`, `filters[timeRange][EQUALS]=P7D`, `filters[level][EQUALS]=DEBUG` (nullable)
]: nothing -> record<results: table<namespace: string, flowId: string, taskId: string, executionId: string, taskRunId: string, attemptNumber: int, triggerId: string, timestamp: string, level: string, thread: string, message: string, executionKind: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/logs/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get logs for a specific execution, taskrun or task
#
# GET /api/v1/{tenant}/logs/{executionId}
# operationId: listLogsFromExecution
export def "logs listLogsFromExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters (nullable)
]: nothing -> table<namespace: string, flowId: string, taskId: string, executionId: string, taskRunId: string, attemptNumber: int, triggerId: string, timestamp: string, level: string, thread: string, message: string, executionKind: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/logs/($executionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete logs for a specific execution, taskrun or task
#
# DELETE /api/v1/{tenant}/logs/{executionId}
# operationId: deleteLogsFromExecution
export def "logs delete-by-executionId-tenant" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --minLevel: string # The min log level filter (nullable)
  --taskRunId: string # The taskrun id (nullable)
  --taskId: string # The task id (nullable)
  --attempt: int # The attempt number (nullable, format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minLevel" $minLevel "scalar") (serialize-qp "taskRunId" $taskRunId "scalar") (serialize-qp "taskId" $taskId "scalar") (serialize-qp "attempt" $attempt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/logs/($executionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download logs for a specific execution, taskrun or task
#
# GET /api/v1/{tenant}/logs/{executionId}/download
# operationId: downloadLogsFromExecution
export def "logs-download downloadLogsFromExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/logs/($executionId)/download" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow logs for a specific execution
#
# GET /api/v1/{tenant}/logs/{executionId}/follow
# operationId: followLogsFromExecution
export def "logs-follow followLogsFromExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/logs/($executionId)/follow" $qp)
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete logs for a specific execution, taskrun or task
#
# DELETE /api/v1/{tenant}/logs/{namespace}/{flowId}
# operationId: deleteLogsFromFlow
export def "logs delete-by-namespace-flowId-tenant" [
  namespace: string
  flowId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --triggerId: string # The trigger id
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "triggerId" $triggerId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/logs/($namespace)/($flowId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List MCP servers
#
# GET /api/v1/{tenant}/mcp/servers
# operationId: listMcps
export def "mcp-servers listMcps" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
]: nothing -> record<results: table<id: string, description: string, instructions: string, serverType: record, authType: record, oauthProvider: string, oauthScopesSupported: list, disabled: bool, isDefault: bool, created: string, updated: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/mcp/servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an MCP server
#
# POST /api/v1/{tenant}/mcp/servers
# operationId: createMcp
export def "mcp-servers createMcp" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Unique identifier of the MCP server.
  --description: string # Human-readable description of the MCP server.
  --instructions: string # Instructions sent to the AI model when using this server.
  --serverType: any # Visibility of the server.
  --authType: any # Authentication type for private servers.
  --oauthProvider: string # OAuth provider key from micronaut.security.oauth2.clients. Required when authType is OAUTH.
  --oauthScopesSupported: list # Scopes advertised in the server's RFC 9728 Protected Resource Metadata document. Only meaningful when authType is OAUTH. When null or empty the field is omitted from the PRM document.
  --disabled: oneof<nothing, bool> # Whether the MCP server is disabled.
]: any -> record<id: string, description: string, instructions: string, serverType: record, authType: record, oauthProvider: string, oauthScopesSupported: list<string>, disabled: bool, isDefault: bool, created: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/mcp/servers")
  let body = {id: $id, description: $description, instructions: $instructions, serverType: $serverType, authType: $authType, oauthProvider: $oauthProvider, oauthScopesSupported: $oauthScopesSupported, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an MCP server
#
# GET /api/v1/{tenant}/mcp/servers/{id}
# operationId: getMcp
export def "mcp-servers get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, description: string, instructions: string, serverType: record, authType: record, oauthProvider: string, oauthScopesSupported: list<string>, disabled: bool, isDefault: bool, created: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/mcp/servers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an MCP server
#
# PUT /api/v1/{tenant}/mcp/servers/{id}
# operationId: updateMcp
export def "mcp-servers updateMcp" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # Unique identifier of the MCP server.
  --description: string # Human-readable description of the MCP server.
  --instructions: string # Instructions sent to the AI model when using this server.
  --serverType: any # Visibility of the server.
  --authType: any # Authentication type for private servers.
  --oauthProvider: string # OAuth provider key from micronaut.security.oauth2.clients. Required when authType is OAUTH.
  --oauthScopesSupported: list # Scopes advertised in the server's RFC 9728 Protected Resource Metadata document. Only meaningful when authType is OAUTH. When null or empty the field is omitted from the PRM document.
  --disabled: oneof<nothing, bool> # Whether the MCP server is disabled.
]: any -> record<id: string, description: string, instructions: string, serverType: record, authType: record, oauthProvider: string, oauthScopesSupported: list<string>, disabled: bool, isDefault: bool, created: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/mcp/servers/($id)")
  let body = {id: $body_id, description: $description, instructions: $instructions, serverType: $serverType, authType: $authType, oauthProvider: $oauthProvider, oauthScopesSupported: $oauthScopesSupported, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an MCP server
#
# DELETE /api/v1/{tenant}/mcp/servers/{id}
# operationId: deleteMcp
export def "mcp-servers delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/mcp/servers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Toggle an MCP server's enabled state
#
# PATCH /api/v1/{tenant}/mcp/servers/{id}/toggle
# operationId: toggleMcp
export def "mcp-servers-toggle toggleMcp" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, description: string, instructions: string, serverType: record, authType: record, oauthProvider: string, oauthScopesSupported: list<string>, disabled: bool, isDefault: bool, created: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/mcp/servers/($id)/toggle")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tools exposed by an MCP server
#
# GET /api/v1/{tenant}/mcp/servers/{id}/tools
# operationId: listTools
export def "mcp-servers-tools listTools" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<toolName: string, triggerId: string, title: string, description: string, annotations: record<readOnly: bool, openWorld: bool, destructive: bool, idempotent: bool, returnDirect: bool>, namespace: string, flowId: string, flowRevision: int, disabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/mcp/servers/($id)/tools")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics aggregations for a specific flow
#
# GET /api/v1/{tenant}/metrics/aggregates/{namespace}/{flowId}/{metric}
# operationId: aggregateMetricsFromFlow
export def "metrics-aggregates aggregateMetricsFromFlow" [
  namespace: string
  flowId: string
  metric: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # The start datetime, default to now - 30 days (nullable, format: date-time)
  --endDate: string # The end datetime, default to now (nullable, format: date-time)
  --aggregation: string # The type of aggregation: avg, sum, min or max (default: sum)
]: nothing -> record<groupBy: string, aggregations: table<name: string, value: float, date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "aggregation" $aggregation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/metrics/aggregates/($namespace)/($flowId)/($metric)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics aggregations for a specific flow
#
# GET /api/v1/{tenant}/metrics/aggregates/{namespace}/{flowId}/{taskId}/{metric}
# operationId: aggregateMetricsFromTask
export def "metrics-aggregates aggregateMetricsFromTask" [
  namespace: string
  flowId: string
  taskId: string
  metric: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # The start datetime, default to now - 30 days (nullable, format: date-time)
  --endDate: string # The end datetime, default to now (nullable, format: date-time)
  --aggregation: string # The type of aggregation: avg, sum, min or max (default: sum)
]: nothing -> record<groupBy: string, aggregations: table<name: string, value: float, date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "aggregation" $aggregation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/metrics/aggregates/($namespace)/($flowId)/($taskId)/($metric)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics names for a specific flow
#
# GET /api/v1/{tenant}/metrics/names/{namespace}/{flowId}
# operationId: listFlowMetrics
export def "metrics-names listFlowMetrics" [
  namespace: string
  flowId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/metrics/names/($namespace)/($flowId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics names for a specific task in a flow
#
# GET /api/v1/{tenant}/metrics/names/{namespace}/{flowId}/{taskId}
# operationId: listTaskMetrics
export def "metrics-names listTaskMetrics" [
  namespace: string
  flowId: string
  taskId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/metrics/names/($namespace)/($flowId)/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tasks id that have metrics for a specific flow, include deleted or renamed tasks
#
# GET /api/v1/{tenant}/metrics/tasks/{namespace}/{flowId}
# operationId: listTasksWithMetrics
export def "metrics-tasks listTasksWithMetrics" [
  namespace: string
  flowId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/metrics/tasks/($namespace)/($flowId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics for a specific execution
#
# GET /api/v1/{tenant}/metrics/{executionId}
# operationId: searchByExecution
export def "metrics searchByExecution" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --taskRunId: string # The taskrun id (nullable)
  --taskId: string # The task id (nullable)
]: nothing -> record<results: table<namespace: string, flowId: string, taskId: string, executionId: string, taskRunId: string, type: string, name: string, value: float, timestamp: string, tags: record, executionKind: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "taskRunId" $taskRunId "scalar") (serialize-qp "taskId" $taskId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/metrics/($executionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a namespace
#
# POST /api/v1/{tenant}/namespaces
# operationId: createNamespace
# --allowedTriggers item shape: {namespace: string, flowId?: string}
# --storageIsolation shape: {deniedServices?: list, enabled?: bool}
# --secretIsolation shape: {deniedServices?: list, enabled?: bool}
# --pluginDefaults item shape: {type: string, forced?: bool, values?: record}
# --allowedNamespaces item shape: {namespace: string}
# --defaultWorkerSelector shape: {tags?: list, match?: any, fallback?: any}
# --sdkDefaultAuthentication shape: {apiToken?: string, username?: string, password?: string}
@deprecated --flag allowedTriggers
export def "namespaces createNamespace" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string
  --allowedTriggers: list # DEPRECATED — item shape: {namespace: string, flowId?: string}
  --storageIsolation: record # shape: {deniedServices?: list, enabled?: bool}
  --secretIsolation: record # shape: {deniedServices?: list, enabled?: bool}
  --deleted: oneof<nothing, bool>
  --description: string
  --body-variables: record
  --pluginDefaults: list # item shape: {type: string, forced?: bool, values?: record}
  --allowedNamespaces: list # item shape: {namespace: string}
  --defaultWorkerSelector: record # shape: {tags?: list, match?: any, fallback?: any}
  --storageType: string
  --storageConfiguration: record
  --secretType: string
  --secretReadOnly: oneof<nothing, bool>
  --secretConfiguration: record
  --outputsInInternalStorage: oneof<nothing, bool>
  --sdkDefaultAuthentication: record # shape: {apiToken?: string, username?: string, password?: string}
]: any -> record<id: string, allowedTriggers: table<namespace: string, flowId: string>, storageIsolation: record<deniedServices: list<string>, enabled: bool>, secretIsolation: record<deniedServices: list<string>, enabled: bool>, deleted: bool, description: string, variables: record, pluginDefaults: table<type: string, forced: bool, values: record>, allowedNamespaces: table<namespace: string>, defaultWorkerSelector: record<tags: list<string>, match: record, fallback: record>, storageType: string, storageConfiguration: record, secretType: string, secretReadOnly: bool, secretConfiguration: record, outputsInInternalStorage: bool, sdkDefaultAuthentication: record<apiToken: string, username: string, password: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces")
  let body = {id: $id, allowedTriggers: $allowedTriggers, storageIsolation: $storageIsolation, secretIsolation: $secretIsolation, deleted: $deleted, description: $description, variables: $body_variables, pluginDefaults: $pluginDefaults, allowedNamespaces: $allowedNamespaces, defaultWorkerSelector: $defaultWorkerSelector, storageType: $storageType, storageConfiguration: $storageConfiguration, secretType: $secretType, secretReadOnly: $secretReadOnly, secretConfiguration: $secretConfiguration, outputsInInternalStorage: $outputsInInternalStorage, sdkDefaultAuthentication: $sdkDefaultAuthentication} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List namespaces for autocomplete
#
# POST /api/v1/{tenant}/namespaces/autocomplete
# operationId: autocompleteNamespaces
export def "namespaces-autocomplete autocompleteNamespaces" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # nullable
  --ids: list # nullable
  --existingOnly: oneof<nothing, bool>
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/autocomplete")
  let body = {q: $q, ids: $ids, existingOnly: $existingOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for namespaces
#
# GET /api/v1/{tenant}/namespaces/search
# operationId: searchNamespaces
export def "namespaces-search searchNamespaces" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --existing: oneof<nothing, bool> # Return only existing namespace (default: false)
  --filters: list # A list of query filters
]: nothing -> record<results: table<id: string, allowedTriggers: list, storageIsolation: record, secretIsolation: record, deleted: bool, description: string, variables: record, pluginDefaults: list, allowedNamespaces: list, defaultWorkerSelector: record, storageType: string, storageConfiguration: record, secretType: string, secretReadOnly: bool, secretConfiguration: record, outputsInInternalStorage: bool, sdkDefaultAuthentication: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "existing" $existing "scalar") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a namespace
#
# GET /api/v1/{tenant}/namespaces/{id}
# operationId: getNamespace
export def "namespaces get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, allowedTriggers: table<namespace: string, flowId: string>, storageIsolation: record<deniedServices: list<string>, enabled: bool>, secretIsolation: record<deniedServices: list<string>, enabled: bool>, deleted: bool, description: string, variables: record, pluginDefaults: table<type: string, forced: bool, values: record>, allowedNamespaces: table<namespace: string>, defaultWorkerSelector: record<tags: list<string>, match: record, fallback: record>, storageType: string, storageConfiguration: record, secretType: string, secretReadOnly: bool, secretConfiguration: record, outputsInInternalStorage: bool, sdkDefaultAuthentication: record<apiToken: string, username: string, password: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a namespace
#
# PUT /api/v1/{tenant}/namespaces/{id}
# operationId: updateNamespace
# --allowedTriggers item shape: {namespace: string, flowId?: string}
# --storageIsolation shape: {deniedServices?: list, enabled?: bool}
# --secretIsolation shape: {deniedServices?: list, enabled?: bool}
# --pluginDefaults item shape: {type: string, forced?: bool, values?: record}
# --allowedNamespaces item shape: {namespace: string}
# --defaultWorkerSelector shape: {tags?: list, match?: any, fallback?: any}
# --sdkDefaultAuthentication shape: {apiToken?: string, username?: string, password?: string}
@deprecated --flag allowedTriggers
export def "namespaces updateNamespace" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  --allowedTriggers: list # DEPRECATED — item shape: {namespace: string, flowId?: string}
  --storageIsolation: record # shape: {deniedServices?: list, enabled?: bool}
  --secretIsolation: record # shape: {deniedServices?: list, enabled?: bool}
  --deleted: oneof<nothing, bool>
  --description: string
  --body-variables: record
  --pluginDefaults: list # item shape: {type: string, forced?: bool, values?: record}
  --allowedNamespaces: list # item shape: {namespace: string}
  --defaultWorkerSelector: record # shape: {tags?: list, match?: any, fallback?: any}
  --storageType: string
  --storageConfiguration: record
  --secretType: string
  --secretReadOnly: oneof<nothing, bool>
  --secretConfiguration: record
  --outputsInInternalStorage: oneof<nothing, bool>
  --sdkDefaultAuthentication: record # shape: {apiToken?: string, username?: string, password?: string}
]: any -> record<id: string, allowedTriggers: table<namespace: string, flowId: string>, storageIsolation: record<deniedServices: list<string>, enabled: bool>, secretIsolation: record<deniedServices: list<string>, enabled: bool>, deleted: bool, description: string, variables: record, pluginDefaults: table<type: string, forced: bool, values: record>, allowedNamespaces: table<namespace: string>, defaultWorkerSelector: record<tags: list<string>, match: record, fallback: record>, storageType: string, storageConfiguration: record, secretType: string, secretReadOnly: bool, secretConfiguration: record, outputsInInternalStorage: bool, sdkDefaultAuthentication: record<apiToken: string, username: string, password: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($id)")
  let body = {id: $body_id, allowedTriggers: $allowedTriggers, storageIsolation: $storageIsolation, secretIsolation: $secretIsolation, deleted: $deleted, description: $description, variables: $body_variables, pluginDefaults: $pluginDefaults, allowedNamespaces: $allowedNamespaces, defaultWorkerSelector: $defaultWorkerSelector, storageType: $storageType, storageConfiguration: $storageConfiguration, secretType: $secretType, secretReadOnly: $secretReadOnly, secretConfiguration: $secretConfiguration, outputsInInternalStorage: $outputsInInternalStorage, sdkDefaultAuthentication: $sdkDefaultAuthentication} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a namespace
#
# DELETE /api/v1/{tenant}/namespaces/{id}
# operationId: deleteNamespace
export def "namespaces delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List inherited plugin defaults
#
# GET /api/v1/{tenant}/namespaces/{id}/inherited-plugindefaults
# operationId: inheritedPluginDefaults
export def "namespaces-inherited-plugindefaults inheritedPluginDefaults" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<type: string, forced: bool, values: record, namespace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($id)/inherited-plugindefaults")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List inherited variables
#
# GET /api/v1/{tenant}/namespaces/{id}/inherited-variables
# operationId: inheritedVariables
export def "namespaces-inherited-variables inheritedVariables" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($id)/inherited-variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export this namespace plugin defaults
#
# POST /api/v1/{tenant}/namespaces/{id}/plugindefaults/export
# operationId: exportPluginDefaults
export def "namespaces-plugindefaults-export exportPluginDefaults" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($id)/plugindefaults/export")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import plugin defaults in this namespace
#
# POST /api/v1/{tenant}/namespaces/{id}/plugindefaults/import
# operationId: importPluginDefaults
export def "namespaces-plugindefaults-import importPluginDefaults" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fileUpload: string # format: binary
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($id)/plugindefaults/import")
  let body = {fileUpload: $fileUpload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# List credentials in a namespace
#
# GET /api/v1/{tenant}/namespaces/{namespace}/credentials
# operationId: listNamespaceCredentials
export def "namespaces-credentials listNamespaceCredentials" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: list<record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a credential in a namespace
#
# POST /api/v1/{tenant}/namespaces/{namespace}/credentials
# Discriminator (request): type = OAUTH2, GITHUB_APP
# operationId: createNamespaceCredential
export def "namespaces-credentials createNamespaceCredential" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: any@type-completer-2 # Credential type discriminator (e.g. oauth2)
  --name: string # Credential name (e.g. salesforce-prod)
  --description: string # Credential description
  --body-namespace: string # Namespace (null for tenant-level)
  --tokenEndpoint: string # OAuth2 token endpoint URL (e.g. https://login.salesforce.com/services/oauth2/token)
  --scopes: list # OAuth2 scopes
  --audience: string # OAuth2 audience
  --tokenCaching: any # Token caching configuration
  --authConfig: any # OAuth2 authentication configuration
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/credentials")
  let body = {type: $type, name: $name, description: $description, namespace: $body_namespace, tokenEndpoint: $tokenEndpoint, scopes: $scopes, audience: $audience, tokenCaching: $tokenCaching, authConfig: $authConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get inherited credentials from parent namespaces
#
# GET /api/v1/{tenant}/namespaces/{namespace}/credentials/inherited
# operationId: getInheritedCredentials
export def "namespaces-credentials-inherited get" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<levels: table<namespace: string, credentials: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/credentials/inherited")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a credential by name in a namespace
#
# GET /api/v1/{tenant}/namespaces/{namespace}/credentials/{name}
# Discriminator (response): type = OAUTH2, GITHUB_APP
# operationId: getNamespaceCredential
export def "namespaces-credentials get" [
  namespace: string
  name: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/credentials/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a credential in a namespace
#
# PUT /api/v1/{tenant}/namespaces/{namespace}/credentials/{name}
# Discriminator (request): type = OAUTH2, GITHUB_APP
# operationId: updateNamespaceCredential
export def "namespaces-credentials updateNamespaceCredential" [
  namespace: string
  name: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: any@type-completer-2 # Credential type discriminator (e.g. oauth2)
  --description: string # Credential description
  --tokenEndpoint: string # OAuth2 token endpoint URL
  --scopes: list # OAuth2 scopes
  --audience: string # OAuth2 audience
  --tokenCaching: any # Token caching configuration
  --authConfig: any # OAuth2 authentication configuration
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/credentials/($name)")
  let body = {type: $type, description: $description, tokenEndpoint: $tokenEndpoint, scopes: $scopes, audience: $audience, tokenCaching: $tokenCaching, authConfig: $authConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a credential from a namespace
#
# DELETE /api/v1/{tenant}/namespaces/{namespace}/credentials/{name}
# operationId: deleteNamespaceCredential
export def "namespaces-credentials delete" [
  namespace: string
  name: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/credentials/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test a credential connection
#
# POST /api/v1/{tenant}/namespaces/{namespace}/credentials/{name}/test
# operationId: testNamespaceConnection
export def "namespaces-credentials-test testNamespaceConnection" [
  namespace: string
  name: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/credentials/($name)/test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve flow dependencies
#
# GET /api/v1/{tenant}/namespaces/{namespace}/dependencies
# operationId: getFlowDependenciesFromNamespace
export def "namespaces-dependencies get" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --destinationOnly: oneof<nothing, bool> # if true, list only destination dependencies, otherwise list also source dependencies (default: false)
]: nothing -> record<nodes: table<uid: string, namespace: string, id: string>, edges: table<source: string, target: string, relation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "destinationOnly" $destinationOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/dependencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get namespace file content
#
# GET /api/v1/{tenant}/namespaces/{namespace}/files
# operationId: getFileContent
export def "namespaces-files get" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri
  --revision: int # The revision, if not provided, the latest revision will be returned (nullable, format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "revision" $revision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/files" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move a file or directory
#
# PUT /api/v1/{tenant}/namespaces/{namespace}/files
# operationId: moveFileDirectory
export def "namespaces-files moveFileDirectory" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The internal storage uri to move from (format: uri)
  --qp-to: string # The internal storage uri to move to (format: uri)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a file
#
# POST /api/v1/{tenant}/namespaces/{namespace}/files
# operationId: createNamespaceFile
export def "namespaces-files createNamespaceFile" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri
  --fileContent: string # The file to upload (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/files" $qp)
  let body = {fileContent: $fileContent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete a file or directory
#
# DELETE /api/v1/{tenant}/namespaces/{namespace}/files
# operationId: deleteFileDirectory
export def "namespaces-files delete" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri of the file / directory to delete
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List directory content
#
# GET /api/v1/{tenant}/namespaces/{namespace}/files/directory
# operationId: listNamespaceDirectoryFiles
export def "namespaces-files-directory listNamespaceDirectoryFiles" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri (nullable)
]: nothing -> table<fileName: string, lastModifiedTime: int, creationTime: int, type: string, size: int, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/files/directory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a directory
#
# POST /api/v1/{tenant}/namespaces/{namespace}/files/directory
# operationId: createNamespaceDirectory
export def "namespaces-files-directory createNamespaceDirectory" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/files/directory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export namespace files as a ZIP
#
# GET /api/v1/{tenant}/namespaces/{namespace}/files/export
# operationId: exportNamespaceFiles
export def "namespaces-files-export exportNamespaceFiles" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/files/export")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get namespace file revisions
#
# GET /api/v1/{tenant}/namespaces/{namespace}/files/revisions
# operationId: getFileRevisions
export def "namespaces-files-revisions get" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri (nullable)
]: nothing -> table<revision: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/files/revisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find files which path contain the given string in their URI
#
# GET /api/v1/{tenant}/namespaces/{namespace}/files/search
# operationId: searchNamespaceFiles
export def "namespaces-files-search searchNamespaceFiles" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The string the file path should contain
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/files/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get namespace file stats such as size, creation & modification dates and type
#
# GET /api/v1/{tenant}/namespaces/{namespace}/files/stats
# operationId: getFileMetadatas
export def "namespaces-files-stats get" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The internal storage uri (nullable)
]: nothing -> record<fileName: string, lastModifiedTime: int, creationTime: int, type: string, size: int, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/files/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List inherited secrets
#
# GET /api/v1/{tenant}/namespaces/{namespace}/inherited-secrets
# operationId: getInheritedSecrets
export def "namespaces-inherited-secrets get" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/inherited-secrets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk-delete multiple key/value pairs from the given namespace.
#
# DELETE /api/v1/{tenant}/namespaces/{namespace}/kv
# operationId: deleteKeyValues
export def "namespaces-kv delete-by-namespace-tenant" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keys: list
]: any -> record<keys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/kv")
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all keys for inherited namespaces
#
# GET /api/v1/{tenant}/namespaces/{namespace}/kv/inheritance
# operationId: listKeysWithInheritence
export def "namespaces-kv-inheritance listKeysWithInheritence" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<namespace: string, key: string, version: int, description: string, creationDate: string, updateDate: string, expirationDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/kv/inheritance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get value for a key
#
# GET /api/v1/{tenant}/namespaces/{namespace}/kv/{key}
# operationId: getKeyValue
export def "namespaces-kv get" [
  namespace: string
  key: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<type: string, value: record, revision: int, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/kv/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Puts a key-value pair in store
#
# PUT /api/v1/{tenant}/namespaces/{namespace}/kv/{key}
# operationId: setKeyValue
export def "namespaces-kv setKeyValue" [
  namespace: string
  key: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/kv/($key)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Delete a key-value pair
#
# DELETE /api/v1/{tenant}/namespaces/{namespace}/kv/{key}
# operationId: deleteKeyValue
export def "namespaces-kv delete-by-namespace-key-tenant" [
  namespace: string
  key: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/kv/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update secrets for a namespace
#
# PUT /api/v1/{tenant}/namespaces/{namespace}/secrets
# operationId: putSecrets
# --tags item shape: {key: string, value: string}
export def "namespaces-secrets put" [
  namespace: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: list # item shape: {key: string, value: string}
  key: string
  value: string
  --description: string
]: any -> table<namespace: string, description: string, tags: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/secrets")
  let body = {tags: $tags, key: $key, value: $value, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a secret for a namespace
#
# DELETE /api/v1/{tenant}/namespaces/{namespace}/secrets/{key}
# operationId: deleteSecret
export def "namespaces-secrets delete" [
  namespace: string
  key: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/secrets/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch a secret metadata for a namespace
#
# PATCH /api/v1/{tenant}/namespaces/{namespace}/secrets/{key}
# operationId: patchSecret
# --tags item shape: {key: string, value: string}
export def "namespaces-secrets patch" [
  namespace: string
  key: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --description: string
  tags: list # item shape: {key: string, value: string}
  --body-key: string
]: any -> table<namespace: string, description: string, tags: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/namespaces/($namespace)/secrets/($key)")
  let body = {namespace: $body_namespace, description: $description, tags: $tags, key: $body_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get task run outputs
#
# GET /api/v1/{tenant}/outputs/{executionId}
# operationId: getTaskOutputsInformation
export def "outputs list" [
  executionId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<taskId: string, taskRunId: string, value: string, iteration: int, inline: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/outputs/($executionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get task run outputs
#
# GET /api/v1/{tenant}/outputs/{executionId}/{taskRunId}
# operationId: getTaskRunOutputs
export def "outputs get" [
  executionId: string
  taskRunId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/outputs/($executionId)/($taskRunId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role
#
# POST /api/v1/{tenant}/roles
# operationId: createRole
# --permissions shape: {FLOW?: list, EXECUTION?: list, TRIGGER?: list, NAMESPACE?: list, KVSTORE?: list, DASHBOARD?: list, SECRET?: list, CREDENTIAL?: list, BLUEPRINT?: list, APP?: list, AUDITLOG?: list, SYSTEM_SETTINGS?: list, TENANT_SETTINGS?: list, TESTSUITE?: list, ASSET?: list, USER?: list, GROUP?: list, ROLE?: list, BINDING?: list, SERVICE_ACCOUNT?: list, INVITATION?: list, COPILOT?: list, MCP_SERVER?: list, APP_EXECUTION?: list, NAMESPACE_FILE?: list, TESTSUITE_RUN?: list, TENANT_ACCESS?: list, SECURITY_INTEGRATION?: list, KILL_SWITCH?: list, TENANT?: list, VERSIONED_PLUGIN?: list, WORKER_GROUP?: list, WORKER_QUEUE?: list, INSTANCE?: list, UNKNOWN?: list}
export def "roles createRole" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  permissions: record # shape: {FLOW?: list, EXECUTION?: list, TRIGGER?: list, NAMESPACE?: list, KVSTORE?: list, DASHBOARD?: list, SECRET?: list, CREDENTIAL?: list, BLUEPRINT?: list, APP?: list, AUDITLOG?: list, SYSTEM_SETTINGS?: list, TENANT_SETTINGS?: list, TESTSUITE?: list, ASSET?: list, USER?: list, GROUP?: list, ROLE?: list, BINDING?: list, SERVICE_ACCOUNT?: list, INVITATION?: list, COPILOT?: list, MCP_SERVER?: list, APP_EXECUTION?: list, NAMESPACE_FILE?: list, TESTSUITE_RUN?: list, TENANT_ACCESS?: list, SECURITY_INTEGRATION?: list, KILL_SWITCH?: list, TENANT?: list, VERSIONED_PLUGIN?: list, WORKER_GROUP?: list, WORKER_QUEUE?: list, INSTANCE?: list, UNKNOWN?: list}
  name: string
  --description: string
  --isDefault: oneof<nothing, bool>
]: any -> record<id: string, name: string, description: string, permissions: record<FLOW: list<any>, EXECUTION: list<any>, TRIGGER: list<any>, NAMESPACE: list<any>, KVSTORE: list<any>, DASHBOARD: list<any>, SECRET: list<any>, CREDENTIAL: list<any>, BLUEPRINT: list<any>, APP: list<any>, AUDITLOG: list<any>, SYSTEM_SETTINGS: list<any>, TENANT_SETTINGS: list<any>, TESTSUITE: list<any>, ASSET: list<any>, USER: list<any>, GROUP: list<any>, ROLE: list<any>, BINDING: list<any>, SERVICE_ACCOUNT: list<any>, INVITATION: list<any>, COPILOT: list<any>, MCP_SERVER: list<any>, APP_EXECUTION: list<any>, NAMESPACE_FILE: list<any>, TESTSUITE_RUN: list<any>, TENANT_ACCESS: list<any>, SECURITY_INTEGRATION: list<any>, KILL_SWITCH: list<any>, TENANT: list<any>, VERSIONED_PLUGIN: list<any>, WORKER_GROUP: list<any>, WORKER_QUEUE: list<any>, INSTANCE: list<any>, UNKNOWN: list<any>>, isDefault: bool, isManaged: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/roles")
  let body = {permissions: $permissions, name: $name, description: $description, isDefault: $isDefault} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List roles for autocomplete
#
# POST /api/v1/{tenant}/roles/autocomplete
# operationId: autocompleteRoles
export def "roles-autocomplete autocompleteRoles" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # nullable
  --ids: list # nullable
  --existingOnly: oneof<nothing, bool>
]: any -> table<id: string, name: string, isDefault: bool, isManaged: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/roles/autocomplete")
  let body = {q: $q, ids: $ids, existingOnly: $existingOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List roles by ids
#
# POST /api/v1/{tenant}/roles/ids
# operationId: listRolesFromGivenIds
export def "roles-ids listRolesFromGivenIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list
]: any -> table<isManaged: bool, permissions: record<FLOW: list, EXECUTION: list, TRIGGER: list, NAMESPACE: list, KVSTORE: list, DASHBOARD: list, SECRET: list, CREDENTIAL: list, BLUEPRINT: list, APP: list, AUDITLOG: list, SYSTEM_SETTINGS: list, TENANT_SETTINGS: list, TESTSUITE: list, ASSET: list, USER: list, GROUP: list, ROLE: list, BINDING: list, SERVICE_ACCOUNT: list, INVITATION: list, COPILOT: list, MCP_SERVER: list, APP_EXECUTION: list, NAMESPACE_FILE: list, TESTSUITE_RUN: list, TENANT_ACCESS: list, SECURITY_INTEGRATION: list, KILL_SWITCH: list, TENANT: list, VERSIONED_PLUGIN: list, WORKER_GROUP: list, WORKER_QUEUE: list, INSTANCE: list, UNKNOWN: list>, id: string, name: string, description: string, isDefault: bool, deleted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/roles/ids")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for roles
#
# GET /api/v1/{tenant}/roles/search
# operationId: searchRoles
export def "roles-search searchRoles" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<id: string, name: string, isDefault: bool, isManaged: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/roles/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a role
#
# GET /api/v1/{tenant}/roles/{id}
# operationId: getRole
export def "roles get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, permissions: record<FLOW: list<any>, EXECUTION: list<any>, TRIGGER: list<any>, NAMESPACE: list<any>, KVSTORE: list<any>, DASHBOARD: list<any>, SECRET: list<any>, CREDENTIAL: list<any>, BLUEPRINT: list<any>, APP: list<any>, AUDITLOG: list<any>, SYSTEM_SETTINGS: list<any>, TENANT_SETTINGS: list<any>, TESTSUITE: list<any>, ASSET: list<any>, USER: list<any>, GROUP: list<any>, ROLE: list<any>, BINDING: list<any>, SERVICE_ACCOUNT: list<any>, INVITATION: list<any>, COPILOT: list<any>, MCP_SERVER: list<any>, APP_EXECUTION: list<any>, NAMESPACE_FILE: list<any>, TESTSUITE_RUN: list<any>, TENANT_ACCESS: list<any>, SECURITY_INTEGRATION: list<any>, KILL_SWITCH: list<any>, TENANT: list<any>, VERSIONED_PLUGIN: list<any>, WORKER_GROUP: list<any>, WORKER_QUEUE: list<any>, INSTANCE: list<any>, UNKNOWN: list<any>>, isDefault: bool, isManaged: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role
#
# PUT /api/v1/{tenant}/roles/{id}
# operationId: updateRole
# --permissions shape: {FLOW?: list, EXECUTION?: list, TRIGGER?: list, NAMESPACE?: list, KVSTORE?: list, DASHBOARD?: list, SECRET?: list, CREDENTIAL?: list, BLUEPRINT?: list, APP?: list, AUDITLOG?: list, SYSTEM_SETTINGS?: list, TENANT_SETTINGS?: list, TESTSUITE?: list, ASSET?: list, USER?: list, GROUP?: list, ROLE?: list, BINDING?: list, SERVICE_ACCOUNT?: list, INVITATION?: list, COPILOT?: list, MCP_SERVER?: list, APP_EXECUTION?: list, NAMESPACE_FILE?: list, TESTSUITE_RUN?: list, TENANT_ACCESS?: list, SECURITY_INTEGRATION?: list, KILL_SWITCH?: list, TENANT?: list, VERSIONED_PLUGIN?: list, WORKER_GROUP?: list, WORKER_QUEUE?: list, INSTANCE?: list, UNKNOWN?: list}
export def "roles updateRole" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  permissions: record # shape: {FLOW?: list, EXECUTION?: list, TRIGGER?: list, NAMESPACE?: list, KVSTORE?: list, DASHBOARD?: list, SECRET?: list, CREDENTIAL?: list, BLUEPRINT?: list, APP?: list, AUDITLOG?: list, SYSTEM_SETTINGS?: list, TENANT_SETTINGS?: list, TESTSUITE?: list, ASSET?: list, USER?: list, GROUP?: list, ROLE?: list, BINDING?: list, SERVICE_ACCOUNT?: list, INVITATION?: list, COPILOT?: list, MCP_SERVER?: list, APP_EXECUTION?: list, NAMESPACE_FILE?: list, TESTSUITE_RUN?: list, TENANT_ACCESS?: list, SECURITY_INTEGRATION?: list, KILL_SWITCH?: list, TENANT?: list, VERSIONED_PLUGIN?: list, WORKER_GROUP?: list, WORKER_QUEUE?: list, INSTANCE?: list, UNKNOWN?: list}
  name: string
  --description: string
  --isDefault: oneof<nothing, bool>
]: any -> record<id: string, name: string, description: string, permissions: record<FLOW: list<any>, EXECUTION: list<any>, TRIGGER: list<any>, NAMESPACE: list<any>, KVSTORE: list<any>, DASHBOARD: list<any>, SECRET: list<any>, CREDENTIAL: list<any>, BLUEPRINT: list<any>, APP: list<any>, AUDITLOG: list<any>, SYSTEM_SETTINGS: list<any>, TENANT_SETTINGS: list<any>, TESTSUITE: list<any>, ASSET: list<any>, USER: list<any>, GROUP: list<any>, ROLE: list<any>, BINDING: list<any>, SERVICE_ACCOUNT: list<any>, INVITATION: list<any>, COPILOT: list<any>, MCP_SERVER: list<any>, APP_EXECUTION: list<any>, NAMESPACE_FILE: list<any>, TESTSUITE_RUN: list<any>, TENANT_ACCESS: list<any>, SECURITY_INTEGRATION: list<any>, KILL_SWITCH: list<any>, TENANT: list<any>, VERSIONED_PLUGIN: list<any>, WORKER_GROUP: list<any>, WORKER_QUEUE: list<any>, INSTANCE: list<any>, UNKNOWN: list<any>>, isDefault: bool, isManaged: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/roles/($id)")
  let body = {permissions: $permissions, name: $name, description: $description, isDefault: $isDefault} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role
#
# DELETE /api/v1/{tenant}/roles/{id}
# operationId: deleteRole
export def "roles delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search secrets of all namespaces
#
# GET /api/v1/{tenant}/secrets
# operationId: listSecrets
export def "secrets listSecrets" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<readOnly: bool, results: table<namespace: string, description: string, tags: list>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all security integrations
#
# GET /api/v1/{tenant}/security-integrations
# DEPRECATED
# operationId: listSecurityIntegrations
@deprecated
export def "security-integrations listSecurityIntegrations" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/security-integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a security integration
#
# POST /api/v1/{tenant}/security-integrations
# operationId: createSecurityIntegration
export def "security-integrations createSecurityIntegration" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of security integration.
  description: string # The description of security integration.
  type: string@type-completer-3
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/security-integrations")
  let body = {name: $name, description: $description, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve security integrations filtered by Filters
#
# GET /api/v1/{tenant}/security-integrations/search
# operationId: searchSecurityIntegration
export def "security-integrations-search searchSecurityIntegration" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --page: int # The current page (format: int32, default: 1)
  --filters: list # Filters
]: nothing -> record<results: table<id: string, name: string, type: string, description: string, tenantId: string, enabled: bool, deleted: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "page" $page "scalar") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/security-integrations/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a security integration
#
# GET /api/v1/{tenant}/security-integrations/{id}
# operationId: getSecurityIntegration
export def "security-integrations get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/security-integrations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a security integration
#
# DELETE /api/v1/{tenant}/security-integrations/{id}
# operationId: deleteSecurityIntegration
export def "security-integrations delete" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/security-integrations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable a security integration
#
# POST /api/v1/{tenant}/security-integrations/{id}/disable
# operationId: disableSecurityIntegration
export def "security-integrations-disable disableSecurityIntegration" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/security-integrations/($id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a security integration
#
# POST /api/v1/{tenant}/security-integrations/{id}/enable
# operationId: enableSecurityIntegration
export def "security-integrations-enable enableSecurityIntegration" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/security-integrations/($id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List service accounts for the given tenant
#
# GET /api/v1/{tenant}/service-accounts
# operationId: listServiceAccountsForTenant
export def "service-accounts listServiceAccountsForTenant" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<id: string, username: string, displayName: string, description: string, groups: list, auths: list>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/service-accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a service account for the given tenant
#
# POST /api/v1/{tenant}/service-accounts
# operationId: createServiceAccountForTenant
# --groups item shape: {id?: string}
export def "service-accounts createServiceAccountForTenant" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list # item shape: {id?: string}
  name: string
  --description: string
  --superAdmin: oneof<nothing, bool>
]: any -> record<id: string, name: string, description: string, groups: table<id: string>, superAdmin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/service-accounts")
  let body = {groups: $groups, name: $name, description: $description, superAdmin: $superAdmin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a service account
#
# GET /api/v1/{tenant}/service-accounts/{id}
# operationId: getServiceAccountForTenant
export def "service-accounts get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, groups: table<id: string>, superAdmin: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/service-accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user service account
#
# PUT /api/v1/{tenant}/service-accounts/{id}
# operationId: updateServiceAccount
# --groups item shape: {id?: string}
export def "service-accounts updateServiceAccount" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list # item shape: {id?: string}
  name: string
  --description: string
  --superAdmin: oneof<nothing, bool>
]: any -> record<id: string, name: string, description: string, groups: table<id: string>, superAdmin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/service-accounts/($id)")
  let body = {groups: $groups, name: $name, description: $description, superAdmin: $superAdmin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a service account
#
# DELETE /api/v1/{tenant}/service-accounts/{id}
# operationId: deleteServiceAccountForTenant
export def "service-accounts delete-by-id-tenant" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/service-accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List API tokens for a specific service account
#
# GET /api/v1/{tenant}/service-accounts/{id}/api-tokens
# operationId: listApiTokensForServiceAccountWithTenant
export def "service-accounts-api-tokens listApiTokensForServiceAccountWithTenant" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/service-accounts/($id)/api-tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new API Token for a specific service account
#
# POST /api/v1/{tenant}/service-accounts/{id}/api-tokens
# operationId: createApiTokensForServiceAccountWithTenant
export def "service-accounts-api-tokens createApiTokensForServiceAccountWithTenant" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --maxAge: string
  --extended: oneof<nothing, bool>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/service-accounts/($id)/api-tokens")
  let body = {name: $name, description: $description, maxAge: $maxAge, extended: $extended} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an API Token for specific service account and token id
#
# DELETE /api/v1/{tenant}/service-accounts/{id}/api-tokens/{tokenId}
# operationId: deleteApiTokenForServiceAccountWithTenant
export def "service-accounts-api-tokens delete-by-id-tokenId-tenant" [
  id: string
  tokenId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/service-accounts/($id)/api-tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/{tenant}/stats/generate-reports
#
# operationId: generate
export def "stats-generate-reports generate" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The start date (nullable, format: date)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/stats/generate-reports" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve users belonging to the tenant
#
# GET /api/v1/{tenant}/tenant-access
# operationId: listTenantAccess
export def "tenant-access listTenantAccess" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters
]: nothing -> record<results: table<id: string, username: string, displayName: string, description: string, groups: list, auths: list>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/tenant-access" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create tenant access for a user
#
# POST /api/v1/{tenant}/tenant-access
# operationId: createTenantAccess
export def "tenant-access createTenantAccess" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tenant-access")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List users for autocomplete
#
# POST /api/v1/{tenant}/tenant-access/autocomplete
# operationId: autocompleteUsers
export def "tenant-access-autocomplete autocompleteUsers" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # nullable
  --ids: list # nullable
  --existingOnly: oneof<nothing, bool>
  --username: string # nullable
]: any -> table<id: string, username: string, displayName: string, description: string, groups: list<record>, auths: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tenant-access/autocomplete")
  let body = {q: $q, ids: $ids, existingOnly: $existingOnly, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve tenant access for a user
#
# GET /api/v1/{tenant}/tenant-access/{userId}
# operationId: getTenantAccess
export def "tenant-access get" [
  userId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tenantId: string, userId: string, username: string, displayName: string, groups: table<id: string, name: string, external: bool>, roles: table<id: string, name: string, namespace: string, origin: string, sourceId: string, permissions: list>, superAdmin: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tenant-access/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create tenant access for a user
#
# PUT /api/v1/{tenant}/tenant-access/{userId}
# operationId: createTenantAccess_1
export def "tenant-access createTenantAccess-by-userId-tenant" [
  userId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tenant-access/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete tenant access for a user
#
# DELETE /api/v1/{tenant}/tenant-access/{userId}
# operationId: deleteTenantAccess
export def "tenant-access delete" [
  userId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tenant-access/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a test from YAML source
#
# POST /api/v1/{tenant}/tests
# operationId: createTestSuite
export def "tests createTestSuite" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<id: string, description: string, namespace: string, flowId: string, source: string, testCases: table<id: string, type: string, disabled: bool, description: string, fixtures: record, assertions: list, expectedState: string>, deleted: bool, disabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Delete multiple tests by id
#
# DELETE /api/v1/{tenant}/tests/by-ids
# operationId: deleteTestSuitesByIds
# --ids item shape: {namespace: string, id: string}
export def "tests-by-ids delete" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list # item shape: {namespace: string, id: string}
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/by-ids")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable multiple tests by id
#
# POST /api/v1/{tenant}/tests/disable/by-ids
# operationId: disableTestSuitesByIds
# --ids item shape: {namespace: string, id: string}
export def "tests-disable-by-ids disableTestSuitesByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list # item shape: {namespace: string, id: string}
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/disable/by-ids")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enable multiple tests by id
#
# POST /api/v1/{tenant}/tests/enable/by-ids
# operationId: enableTestSuitesByIds
# --ids item shape: {namespace: string, id: string}
export def "tests-enable-by-ids enableTestSuitesByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list # item shape: {namespace: string, id: string}
]: any -> record<count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/enable/by-ids")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for tests results
#
# GET /api/v1/{tenant}/tests/results/search
# operationId: searchTestSuitesResults
export def "tests-results-search searchTestSuitesResults" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --testSuiteId: string # The test suite id to filter on (nullable)
  --namespace: string # The namespace to filter on (nullable)
  --flowId: string # The flow id to filter on (nullable)
]: nothing -> record<results: table<id: string, testSuiteId: string, namespace: string, flowId: string, state: string, startDate: string, endDate: string, results: list>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "testSuiteId" $testSuiteId "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "flowId" $flowId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/results/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tests last result
#
# POST /api/v1/{tenant}/tests/results/search/last
# operationId: getTestsLastResult
# --testSuiteIds item shape: {namespace: string, id: string}
export def "tests-results-search-last post" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --testSuiteIds: list # item shape: {namespace: string, id: string}
]: any -> record<results: table<id: string, testSuiteId: string, namespace: string, flowId: string, state: string, startDate: string, endDate: string, results: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/results/search/last")
  let body = {testSuiteIds: $testSuiteIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a test result
#
# GET /api/v1/{tenant}/tests/results/{id}
# operationId: getTestResult
export def "tests-results get" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, testSuiteId: string, namespace: string, flowId: string, state: string, startDate: string, endDate: string, results: table<testId: string, testType: string, executionId: string, url: string, state: string, assertionResults: list, errors: list, fixtures: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/results/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run multiple TestSuites by query
#
# POST /api/v1/{tenant}/tests/run
# operationId: runTestSuitesByQuery
export def "tests-run runTestSuitesByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # nullable
  --flowId: string # nullable
  --includeChildNamespaces: oneof<nothing, bool> # Should child namespaces be included or not (default: true)
]: any -> record<requestMade: record<namespace: string, flowId: string, includeChildNamespaces: bool>, tenantId: string, numberOfTestSuitesToBeRun: int, numberOfTestCasesToBeRun: int, results: table<id: string, testSuiteId: string, namespace: string, flowId: string, state: string, startDate: string, endDate: string, results: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/run")
  let body = {namespace: $namespace, flowId: $flowId, includeChildNamespaces: $includeChildNamespaces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for tests
#
# GET /api/v1/{tenant}/tests/search
# operationId: searchTestSuites
export def "tests-search searchTestSuites" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --namespace: string # The namespace to filter on (nullable)
  --flowId: string # The flow id to filter on (nullable)
  --includeChildNamespaces: oneof<nothing, bool> # Include child namespaces in filter or not (default: true)
]: nothing -> record<results: table<id: string, description: string, namespace: string, flowId: string, source: string, testCases: list, deleted: bool, disabled: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "flowId" $flowId "scalar") (serialize-qp "includeChildNamespaces" $includeChildNamespaces "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate a test
#
# POST /api/v1/{tenant}/tests/validate
# operationId: validateTestSuite
export def "tests-validate validateTestSuite" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<index: int, filename: string, namespace: string, flow: string, constraints: string, outdated: bool, deprecationPaths: list<string>, warnings: list<string>, infos: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/validate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Retrieve a test
#
# GET /api/v1/{tenant}/tests/{namespace}/{id}
# operationId: getTestSuite
export def "tests get" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, description: string, namespace: string, flowId: string, source: string, testCases: table<id: string, type: string, disabled: bool, description: string, fixtures: record, assertions: list, expectedState: string>, deleted: bool, disabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/($namespace)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a test from YAML source
#
# PUT /api/v1/{tenant}/tests/{namespace}/{id}
# operationId: updateTestSuite
export def "tests updateTestSuite" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<id: string, description: string, namespace: string, flowId: string, source: string, testCases: table<id: string, type: string, disabled: bool, description: string, fixtures: record, assertions: list, expectedState: string>, deleted: bool, disabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/($namespace)/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $body
}

# Delete a test
#
# DELETE /api/v1/{tenant}/tests/{namespace}/{id}
# operationId: deleteTestSuite
export def "tests delete" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/($namespace)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run a full test
#
# POST /api/v1/{tenant}/tests/{namespace}/{id}/run
# operationId: runTestSuite
export def "tests-run runTestSuite" [
  namespace: string
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --testCases: list
]: any -> record<id: string, testSuiteId: string, namespace: string, flowId: string, state: string, startDate: string, endDate: string, results: table<testId: string, testType: string, executionId: string, url: string, state: string, assertionResults: list, errors: list, fixtures: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/tests/($namespace)/($id)/run")
  let body = {testCases: $testCases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a backfill
#
# PUT /api/v1/{tenant}/triggers/backfill/create
# operationId: createBackfill
# --backfill shape: {start?: string, end?: string, inputs?: record, labels?: list}
export def "triggers-backfill-create createBackfill" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --flowId: string
  --triggerId: string
  --backfill: record # shape: {start?: string, end?: string, inputs?: record, labels?: list}
]: any -> record<namespace: string, flowId: string, triggerId: string, updatedAt: string, evaluatedAt: string, nextEvaluationDate: string, backfill: record<start: string, end: string, currentDate: string, paused: bool, inputs: record, labels: list<record>, previousNextExecutionDate: string>, stopAfter: list<string>, disabled: bool, locked: bool, workerId: string, lastTriggeredDate: string, executionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/backfill/create")
  let body = {namespace: $namespace, flowId: $flowId, triggerId: $triggerId, backfill: $backfill} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a backfill
#
# POST /api/v1/{tenant}/triggers/backfill/delete
# operationId: deleteBackfill
export def "triggers-backfill-delete post" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --flowId: string
  --triggerId: string
]: any -> record<namespace: string, flowId: string, triggerId: string, updatedAt: string, evaluatedAt: string, nextEvaluationDate: string, backfill: record<start: string, end: string, currentDate: string, paused: bool, inputs: record, labels: list<record>, previousNextExecutionDate: string>, stopAfter: list<string>, disabled: bool, locked: bool, workerId: string, lastTriggeredDate: string, executionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/backfill/delete")
  let body = {namespace: $namespace, flowId: $flowId, triggerId: $triggerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete backfill for triggers matching query asynchronously
#
# POST /api/v1/{tenant}/triggers/backfill/delete/by-query
# operationId: deleteBackfillByQuery
export def "triggers-backfill-delete-by-query post" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[flowId][EQUALS]=hello-world`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record<operationId: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/backfill/delete/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete backfill for given triggers asynchronously
#
# POST /api/v1/{tenant}/triggers/backfill/delete/by-triggers
# operationId: deleteBackfillByIds
export def "triggers-backfill-delete-by-triggers post" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<operationId: string, totalItems: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/backfill/delete/by-triggers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Pause a backfill
#
# PUT /api/v1/{tenant}/triggers/backfill/pause
# operationId: pauseBackfill
export def "triggers-backfill-pause pauseBackfill" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --flowId: string
  --triggerId: string
]: any -> record<namespace: string, flowId: string, triggerId: string, updatedAt: string, evaluatedAt: string, nextEvaluationDate: string, backfill: record<start: string, end: string, currentDate: string, paused: bool, inputs: record, labels: list<record>, previousNextExecutionDate: string>, stopAfter: list<string>, disabled: bool, locked: bool, workerId: string, lastTriggeredDate: string, executionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/backfill/pause")
  let body = {namespace: $namespace, flowId: $flowId, triggerId: $triggerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Pause backfill for triggers matching query asynchronously
#
# POST /api/v1/{tenant}/triggers/backfill/pause/by-query
# operationId: pauseBackfillByQuery
export def "triggers-backfill-pause-by-query pauseBackfillByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[flowId][EQUALS]=hello-world`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record<operationId: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/backfill/pause/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pause backfill for given triggers asynchronously
#
# POST /api/v1/{tenant}/triggers/backfill/pause/by-triggers
# operationId: pauseBackfillByIds
export def "triggers-backfill-pause-by-triggers pauseBackfillByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<operationId: string, totalItems: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/backfill/pause/by-triggers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unpause a backfill
#
# PUT /api/v1/{tenant}/triggers/backfill/unpause
# operationId: unpauseBackfill
export def "triggers-backfill-unpause unpauseBackfill" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --flowId: string
  --triggerId: string
]: any -> record<namespace: string, flowId: string, triggerId: string, updatedAt: string, evaluatedAt: string, nextEvaluationDate: string, backfill: record<start: string, end: string, currentDate: string, paused: bool, inputs: record, labels: list<record>, previousNextExecutionDate: string>, stopAfter: list<string>, disabled: bool, locked: bool, workerId: string, lastTriggeredDate: string, executionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/backfill/unpause")
  let body = {namespace: $namespace, flowId: $flowId, triggerId: $triggerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unpause backfill for triggers matching query asynchronously
#
# POST /api/v1/{tenant}/triggers/backfill/unpause/by-query
# operationId: unpauseBackfillByQuery
export def "triggers-backfill-unpause-by-query unpauseBackfillByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[flowId][EQUALS]=hello-world`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record<operationId: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/backfill/unpause/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unpause backfill for given triggers asynchronously
#
# POST /api/v1/{tenant}/triggers/backfill/unpause/by-triggers
# operationId: unpauseBackfillByIds
export def "triggers-backfill-unpause-by-triggers unpauseBackfillByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<operationId: string, totalItems: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/backfill/unpause/by-triggers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete triggers by query parameters asynchronously
#
# DELETE /api/v1/{tenant}/triggers/delete/by-query
# operationId: deleteTriggersByQuery
# --filters item shape: {field?: "QUERY"|"SCOPE"|"NAMESPACE"|"KIND"|"LABELS"|"TAGS"|"METADATA"|"FLOW_ID"|"FLOW_REVISION"|"ID"|"ASSET_ID"|"TYPE"|"ACTION"|"CREATED"|"UPDATED"|"START_DATE"|"END_DATE"|"EXPIRATION_DATE"|"STATE"|"STATUS"|"EMAIL"|"TIME_RANGE"|"PARENT_ID"|"TRIGGER_EXECUTION_ID"|"TRIGGER_ID"|"TRIGGER_STATE"|"EXECUTION_ID"|"TASK_ID"|"TASK_RUN_ID"|"ATTEMPT_NUMBER"|"CHILD_FILTER"|"WORKER_ID"|"EXISTING_ONLY"|"USER_ID"|"RESOURCES"|"DETAILS"|"LEVEL"|"PATH"|"PARENT_PATH"|"VERSION"|"ENABLED"|"USERNAME"|"NAME"|"GROUP"|"EXTERNAL_ID"|"EXPIRED_AT"|"SUPER_ADMIN"|"SOURCE"|"LOCKED"|"LAST_TRIGGERED_DATE"|"NEXT_EXECUTION_DATE"|"ARTIFACT_ID", operation?: "EQUALS"|"NOT_EQUALS"|"GREATER_THAN"|"LESS_THAN"|"GREATER_THAN_OR_EQUAL_TO"|"LESS_THAN_OR_EQUAL_TO"|"IN"|"NOT_IN"|"STARTS_WITH"|"ENDS_WITH"|"CONTAINS"|"REGEX"|"PREFIX", value?: record, logical?: "AND"|"OR", children?: list}
export def "triggers-delete-by-query delete" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[flowId][EQUALS]=hello-world`, `filters[namespace][CONTAINS]=test` — item shape: {field?: "QUERY"|"SCOPE"|"NAMESPACE"|"KIND"|"LABELS"|"TAGS"|"METADATA"|"FLOW_ID"|"FLOW_REVISION"|"ID"|"ASSET_ID"|"TYPE"|"ACTION"|"CREATED"|"UPDATED"|"START_DATE"|"END_DATE"|"EXPIRATION_DATE"|"STATE"|"STATUS"|"EMAIL"|"TIME_RANGE"|"PARENT_ID"|"TRIGGER_EXECUTION_ID"|"TRIGGER_ID"|"TRIGGER_STATE"|"EXECUTION_ID"|"TASK_ID"|"TASK_RUN_ID"|"ATTEMPT_NUMBER"|"CHILD_FILTER"|"WORKER_ID"|"EXISTING_ONLY"|"USER_ID"|"RESOURCES"|"DETAILS"|"LEVEL"|"PATH"|"PARENT_PATH"|"VERSION"|"ENABLED"|"USERNAME"|"NAME"|"GROUP"|"EXTERNAL_ID"|"EXPIRED_AT"|"SUPER_ADMIN"|"SOURCE"|"LOCKED"|"LAST_TRIGGERED_DATE"|"NEXT_EXECUTION_DATE"|"ARTIFACT_ID", operation?: "EQUALS"|"NOT_EQUALS"|"GREATER_THAN"|"LESS_THAN"|"GREATER_THAN_OR_EQUAL_TO"|"LESS_THAN_OR_EQUAL_TO"|"IN"|"NOT_IN"|"STARTS_WITH"|"ENDS_WITH"|"CONTAINS"|"REGEX"|"PREFIX", value?: record, logical?: "AND"|"OR", children?: list}
]: any -> record<operationId: string, totalItems: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/delete/by-query")
  let body = {filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete given triggers asynchronously
#
# DELETE /api/v1/{tenant}/triggers/delete/by-triggers
# operationId: deleteTriggersByIds
export def "triggers-delete-by-triggers delete" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<operationId: string, totalItems: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/delete/by-triggers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export all triggers as a streamed CSV file
#
# GET /api/v1/{tenant}/triggers/export/by-query/csv
# operationId: exportTriggers
export def "triggers-export-by-query-csv exportTriggers" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # A list of filters
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/export/by-query/csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for triggers
#
# GET /api/v1/{tenant}/triggers/search
# operationId: searchTriggers
export def "triggers-search searchTriggers" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[flowId][EQUALS]=hello-world`, `filters[namespace][CONTAINS]=test` (nullable)
  --dateFilter: string@dateFilter-completer # Which trigger date field the time interval is applied to (nullable)
]: nothing -> record<results: table<trigger: record, state: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "filters" $filters "csv") (serialize-qp "dateFilter" $dateFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable/enable a trigger
#
# PUT /api/v1/{tenant}/triggers/set-disabled
# operationId: disableTriggerById
export def "triggers-set-disabled disableTriggerById" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --flowId: string
  --triggerId: string
  --disabled: oneof<nothing, bool>
]: any -> record<namespace: string, flowId: string, triggerId: string, updatedAt: string, evaluatedAt: string, nextEvaluationDate: string, backfill: record<start: string, end: string, currentDate: string, paused: bool, inputs: record, labels: list<record>, previousNextExecutionDate: string>, stopAfter: list<string>, disabled: bool, locked: bool, workerId: string, lastTriggeredDate: string, executionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/set-disabled")
  let body = {namespace: $namespace, flowId: $flowId, triggerId: $triggerId, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable/enable triggers by query parameters asynchronously
#
# POST /api/v1/{tenant}/triggers/set-disabled/by-query
# operationId: disabledTriggersByQuery
export def "triggers-set-disabled-by-query disabledTriggersByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[flowId][EQUALS]=hello-world`, `filters[namespace][CONTAINS]=test` (nullable)
  --disabled: oneof<nothing, bool> # The disabled state (default: true)
]: nothing -> record<operationId: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv") (serialize-qp "disabled" $disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/set-disabled/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable/enable given triggers asynchronously
#
# POST /api/v1/{tenant}/triggers/set-disabled/by-triggers
# operationId: disabledTriggersByIds
# --triggers item shape: {namespace?: string, flowId?: string, triggerId?: string}
export def "triggers-set-disabled-by-triggers disabledTriggersByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  triggers: list # item shape: {namespace?: string, flowId?: string, triggerId?: string}
  --disabled: oneof<nothing, bool>
]: any -> record<operationId: string, totalItems: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/set-disabled/by-triggers")
  let body = {triggers: $triggers, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unlock triggers by query parameters asynchronously
#
# POST /api/v1/{tenant}/triggers/unlock/by-query
# operationId: unlockTriggersByQuery
export def "triggers-unlock-by-query unlockTriggersByQuery" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # Filters. PHP-style nested query is used - examples: `filters[flowId][EQUALS]=hello-world`, `filters[namespace][CONTAINS]=test` (nullable)
]: nothing -> record<operationId: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/unlock/by-query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unlock given triggers asynchronously
#
# POST /api/v1/{tenant}/triggers/unlock/by-triggers
# operationId: unlockTriggersByIds
export def "triggers-unlock-by-triggers unlockTriggersByIds" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<operationId: string, totalItems: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/unlock/by-triggers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all triggers for a flow
#
# GET /api/v1/{tenant}/triggers/{namespace}/{flowId}
# operationId: searchTriggersForFlow
export def "triggers searchTriggersForFlow" [
  namespace: string
  flowId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The current page (format: int32, default: 1)
  --size: int # The current page size (format: int32, default: 10)
  --qp-sort: list # The sort of current page (nullable)
  --q: string # A string filter (nullable)
]: nothing -> record<results: table<namespace: string, flowId: string, triggerId: string, updatedAt: string, evaluatedAt: string, nextEvaluationDate: string, backfill: record, stopAfter: list, disabled: bool, locked: bool, workerId: string, lastTriggeredDate: string, executionId: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/($namespace)/($flowId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a trigger
#
# DELETE /api/v1/{tenant}/triggers/{namespace}/{flowId}/{triggerId}
# operationId: deleteTrigger
export def "triggers delete" [
  namespace: string
  flowId: string
  triggerId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/($namespace)/($flowId)/($triggerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restart a trigger
#
# POST /api/v1/{tenant}/triggers/{namespace}/{flowId}/{triggerId}/restart
# operationId: restartTrigger
export def "triggers-restart restartTrigger" [
  namespace: string
  flowId: string
  triggerId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<namespace: string, flowId: string, triggerId: string, updatedAt: string, evaluatedAt: string, nextEvaluationDate: string, backfill: record<start: string, end: string, currentDate: string, paused: bool, inputs: record, labels: list<record>, previousNextExecutionDate: string>, stopAfter: list<string>, disabled: bool, locked: bool, workerId: string, lastTriggeredDate: string, executionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/($namespace)/($flowId)/($triggerId)/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unlock a trigger
#
# POST /api/v1/{tenant}/triggers/{namespace}/{flowId}/{triggerId}/unlock
# operationId: unlockTrigger
export def "triggers-unlock unlockTrigger" [
  namespace: string
  flowId: string
  triggerId: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<namespace: string, flowId: string, triggerId: string, updatedAt: string, evaluatedAt: string, nextEvaluationDate: string, backfill: record<start: string, end: string, currentDate: string, paused: bool, inputs: record, labels: list<record>, previousNextExecutionDate: string>, stopAfter: list<string>, disabled: bool, locked: bool, workerId: string, lastTriggeredDate: string, executionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/triggers/($namespace)/($flowId)/($triggerId)/unlock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve usage information for the current tenant
#
# GET /api/v1/{tenant}/usages
# operationId: tenantUsage
export def "usages tenantUsage" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<groups: record<count: int>, users: record<count: int, apiKeyCount: int, oidcCount: int, basicAuthCount: int, passwordlessCount: int>, roles: record<count: int>, tenants: record<count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/usages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve instance usage information
#
# GET /api/v1/{tenant}/usages/all
# operationId: getUsages
export def "usages-all get" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<groups: record<count: int>, users: record<count: int, apiKeyCount: int, oidcCount: int, basicAuthCount: int, passwordlessCount: int>, roles: record<count: int>, tenants: record<count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/usages/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the list of groups a user belongs to for the given tenant
#
# PUT /api/v1/{tenant}/users/{id}/groups
# operationId: updateUserGroups
export def "users-groups updateUserGroups" [
  id: string
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/users/($id)/groups")
  let body = {groupIds: $groupIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List worker-selector tags available to the current tenant
#
# GET /api/v1/{tenant}/worker-selectors/tags
# operationId: workerSelectorTags
export def "worker-selectors-tags workerSelectorTags" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/($tenant)/worker-selectors/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /login
#
# operationId: login
export def "login login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # nullable
  --password: string # nullable
  --identity: string # nullable
  --secret: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/login")
  let body = {username: $username, password: $password, identity: $identity, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
