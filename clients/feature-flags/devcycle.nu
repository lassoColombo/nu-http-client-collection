# Auto-generated client for DevCycle Management API v1.0.0
# Source: https://api.devcycle.com/openapi.json
# Auth: --token flag or $env.DEVCYCLE_MANAGEMENT_API_TOKEN

const BASE_URL = "https://api.devcycle.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DEVCYCLE_MANAGEMENT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.devcycle.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sortBy-completer [] { ["createdAt" "key" "name" "propertyKey" "updatedAt"] }
def sortOrder-completer [] { ["asc" "desc"] }
def type-completer [] { ["development" "disaster_recovery" "production" "staging"] }
def type-completer-1 [] { ["Boolean" "JSON" "Number" "String"] }
def status-completer [] { ["active" "archived"] }
def type-completer-2 [] { ["experiment" "ops" "permission" "release"] }
def status-completer-1 [] { ["active" "archived" "complete"] }
def status-completer-2 [] { ["active" "inactive"] }
def period-completer [] { ["day" "hour" "month"] }
def sdkType-completer [] { ["api" "client" "mobile" "server"] }
def type-completer-3 [] { ["Boolean" "Number" "String"] }
def dimension-completer [] { ["AVERAGE_PER_UNIQUE_USER" "COUNT_PER_UNIQUE_USER" "COUNT_PER_VARIABLE_EVALUATION" "SUM_PER_UNIQUE_USER" "TOTAL_AVERAGE" "TOTAL_SUM"] }
def optimize-completer [] { ["decrease" "increase"] }
def staleness-completer [] { ["all" "notStale" "released" "unmodified" "unused"] }
def status-completer-3 [] { ["applied" "approved" "cancelled" "draft" "pending" "rejected"] }
def method-completer [] { ["PATCH"] }
def action-completer [] { ["approved" "rejected"] }
def action-completer-1 [] { ["applied"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "projects create" } } | get name | first)
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

# Create project in the current organization
#
# POST /v1/projects
# operationId: ProjectsController_create
# --settings shape: {edgeDB: record, optIn: record, sdkTypeVisibility: record, lifeCycle: record, obfuscation: record, disablePassthroughRollouts: bool, dynatrace: record}
export def "projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Project name (e.g. Delivery App)
  key: string # A unique key to identify the Project (e.g. delivery-app)
  --description: string # A description of the Project (e.g. A web app to manage outbound deliveries)
  --color: string # Project display color, used to highlight different projects on the dashboard. Must use Hex color code. (e.g. #4073FF)
  --settings: record # shape: {edgeDB: record, optIn: record, sdkTypeVisibility: record, lifeCycle: record, obfuscation: record, disablePassthroughRollouts: bool, dynatrace: record}
]: any -> record<_id: string, _organization: string, _createdBy: string, name: string, key: string, description: string, color: string, settings: record<edgeDB: record<enabled: bool>, optIn: record<enabled: bool, title: string, description: string, imageURL: string, colors: record, poweredByAlignment: record>, sdkTypeVisibility: record<enabledInFeatureSettings: bool>, lifeCycle: record<disableCodeRefChecks: bool>, obfuscation: record<enabled: bool, required: bool>, featureApprovalWorkflow: record<enabled: bool, allowPublisherBypass: bool, defaultReviewers: list>, disablePassthroughRollouts: bool, staleness: record<enabled: bool, released: record, unmodifiedLong: record, unmodifiedShort: record, unused: record, email: record>, dynatrace: record<enabled: bool, environmentMap: record>>, createdAt: string, updatedAt: string, hasJiraIntegration: bool, hasReceivedCodeUsages: bool, hasUserConfigFetch: bool, jiraBaseUrl: string, readonly: bool, vercelEdgeConfigConnections: table<edgeConfigName: string, configurationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/projects")
  let body = {name: $name, key: $key, description: $description, color: $color, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Projects that the current API Token has permission to view
#
# GET /v1/projects
# operationId: ProjectsController_findAll
export def "projects findAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --search: string
  --createdBy: string
]: nothing -> table<_id: string, _organization: string, _createdBy: string, name: string, key: string, description: string, color: string, settings: record<edgeDB: record, optIn: record, sdkTypeVisibility: record, lifeCycle: record, obfuscation: record, featureApprovalWorkflow: record, disablePassthroughRollouts: bool, staleness: record, dynatrace: record>, createdAt: string, updatedAt: string, hasJiraIntegration: bool, hasReceivedCodeUsages: bool, hasUserConfigFetch: bool, jiraBaseUrl: string, readonly: bool, vercelEdgeConfigConnections: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "createdBy" $createdBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Project
#
# GET /v1/projects/{key}
# operationId: ProjectsController_findOne
export def "projects findOne" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _organization: string, _createdBy: string, name: string, key: string, description: string, color: string, settings: record<edgeDB: record<enabled: bool>, optIn: record<enabled: bool, title: string, description: string, imageURL: string, colors: record, poweredByAlignment: record>, sdkTypeVisibility: record<enabledInFeatureSettings: bool>, lifeCycle: record<disableCodeRefChecks: bool>, obfuscation: record<enabled: bool, required: bool>, featureApprovalWorkflow: record<enabled: bool, allowPublisherBypass: bool, defaultReviewers: list>, disablePassthroughRollouts: bool, staleness: record<enabled: bool, released: record, unmodifiedLong: record, unmodifiedShort: record, unused: record, email: record>, dynatrace: record<enabled: bool, environmentMap: record>>, createdAt: string, updatedAt: string, hasJiraIntegration: bool, hasReceivedCodeUsages: bool, hasUserConfigFetch: bool, jiraBaseUrl: string, readonly: bool, vercelEdgeConfigConnections: table<edgeConfigName: string, configurationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Project
#
# PATCH /v1/projects/{key}
# operationId: ProjectsController_update
# --settings shape: {edgeDB: record, optIn: record, sdkTypeVisibility: record, lifeCycle: record, obfuscation: record, disablePassthroughRollouts: bool, dynatrace: record}
export def "projects update" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Project name (e.g. Delivery App)
  --body-key: string # A unique key to identify the Project (e.g. delivery-app)
  --description: string # A description of the Project (e.g. A web app to manage outbound deliveries)
  --color: string # Project display color, used to highlight different projects on the dashboard. Must use Hex color code. (e.g. #4073FF)
  --settings: record # shape: {edgeDB: record, optIn: record, sdkTypeVisibility: record, lifeCycle: record, obfuscation: record, disablePassthroughRollouts: bool, dynatrace: record}
]: any -> record<_id: string, _organization: string, _createdBy: string, name: string, key: string, description: string, color: string, settings: record<edgeDB: record<enabled: bool>, optIn: record<enabled: bool, title: string, description: string, imageURL: string, colors: record, poweredByAlignment: record>, sdkTypeVisibility: record<enabledInFeatureSettings: bool>, lifeCycle: record<disableCodeRefChecks: bool>, obfuscation: record<enabled: bool, required: bool>, featureApprovalWorkflow: record<enabled: bool, allowPublisherBypass: bool, defaultReviewers: list>, disablePassthroughRollouts: bool, staleness: record<enabled: bool, released: record, unmodifiedLong: record, unmodifiedShort: record, unused: record, email: record>, dynatrace: record<enabled: bool, environmentMap: record>>, createdAt: string, updatedAt: string, hasJiraIntegration: bool, hasReceivedCodeUsages: bool, hasUserConfigFetch: bool, jiraBaseUrl: string, readonly: bool, vercelEdgeConfigConnections: table<edgeConfigName: string, configurationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($key)")
  let body = {name: $name, key: $body_key, description: $description, color: $color, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Project
#
# DELETE /v1/projects/{key}
# operationId: ProjectsController_remove
export def "projects remove" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Publisher Restricted Settings for a Project
#
# PATCH /v1/projects/{key}/settings
# operationId: ProjectsController_updateSettings
# --settings shape: {edgeDB: record, optIn: record, sdkTypeVisibility: record, lifeCycle: record, obfuscation: record, featureApprovalWorkflow: record, disablePassthroughRollouts: bool, staleness: record, dynatrace: record}
export def "projects-settings updateSettings" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  settings: record # shape: {edgeDB: record, optIn: record, sdkTypeVisibility: record, lifeCycle: record, obfuscation: record, featureApprovalWorkflow: record, disablePassthroughRollouts: bool, staleness: record, dynatrace: record}
]: any -> record<_id: string, _organization: string, _createdBy: string, name: string, key: string, description: string, color: string, settings: record<edgeDB: record<enabled: bool>, optIn: record<enabled: bool, title: string, description: string, imageURL: string, colors: record, poweredByAlignment: record>, sdkTypeVisibility: record<enabledInFeatureSettings: bool>, lifeCycle: record<disableCodeRefChecks: bool>, obfuscation: record<enabled: bool, required: bool>, featureApprovalWorkflow: record<enabled: bool, allowPublisherBypass: bool, defaultReviewers: list>, disablePassthroughRollouts: bool, staleness: record<enabled: bool, released: record, unmodifiedLong: record, unmodifiedShort: record, unused: record, email: record>, dynatrace: record<enabled: bool, environmentMap: record>>, createdAt: string, updatedAt: string, hasJiraIntegration: bool, hasReceivedCodeUsages: bool, hasUserConfigFetch: bool, jiraBaseUrl: string, readonly: bool, vercelEdgeConfigConnections: table<edgeConfigName: string, configurationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($key)/settings")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Protected Settings for a Project
#
# PATCH /v1/projects/{key}/settings/protected
# operationId: ProjectsController_updateProtectedSettings
# --settings shape: {featureApprovalWorkflow: record, staleness: record}
export def "projects-settings-protected updateProtectedSettings" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  settings: record # shape: {featureApprovalWorkflow: record, staleness: record}
]: any -> record<_id: string, _organization: string, _createdBy: string, name: string, key: string, description: string, color: string, settings: record<edgeDB: record<enabled: bool>, optIn: record<enabled: bool, title: string, description: string, imageURL: string, colors: record, poweredByAlignment: record>, sdkTypeVisibility: record<enabledInFeatureSettings: bool>, lifeCycle: record<disableCodeRefChecks: bool>, obfuscation: record<enabled: bool, required: bool>, featureApprovalWorkflow: record<enabled: bool, allowPublisherBypass: bool, defaultReviewers: list>, disablePassthroughRollouts: bool, staleness: record<enabled: bool, released: record, unmodifiedLong: record, unmodifiedShort: record, unused: record, email: record>, dynatrace: record<enabled: bool, environmentMap: record>>, createdAt: string, updatedAt: string, hasJiraIntegration: bool, hasReceivedCodeUsages: bool, hasUserConfigFetch: bool, jiraBaseUrl: string, readonly: bool, vercelEdgeConfigConnections: table<edgeConfigName: string, configurationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($key)/settings/protected")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all stale Features for a Project
#
# GET /v1/projects/{key}/staleness
# operationId: ProjectsController_getStaleness
export def "projects-staleness get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --search: string
  --createdBy: string
  --includeSilenced: oneof<nothing, bool> # default: false
]: nothing -> table<key: string, name: string, _feature: string, stale: bool, updatedAt: string, disabled: bool, snoozedUntil: string, reason: string, metaData: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "createdBy" $createdBy "scalar") (serialize-qp "includeSilenced" $includeSilenced "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($key)/staleness" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [Deprecated] Remove Jira Integration Configuration
#
# DELETE /v1/integrations/jira/{token}
# operationId: JiraIntegrationController_remove
export def "integrations-jira remove" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/jira/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Jira Organization Integration Configuration
#
# DELETE /v1/integrations/jira/organization/{token}
# operationId: JiraIntegrationController_removeOrganizationConnection
export def "integrations-jira-organization removeOrganizationConnection" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/jira/organization/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Jira Project Integration Configuration
#
# DELETE /v1/integrations/jira/project/{token}
# operationId: JiraIntegrationController_removeProjectConnection
export def "integrations-jira-project removeProjectConnection" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/jira/project/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Environment
#
# POST /v1/projects/{project}/environments
# operationId: EnvironmentsController_create
export def "projects-environments create" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # A unique display name (e.g. Staging Upcoming)
  key: string # Unique Environment identifier, can be used in the SDK / API to reference by key rather than ID. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. staging-upcoming)
  --description: string # Environment description. (e.g. Pre-production changes)
  --color: string # Environment display color, used to highlight different environments on the dashboard. Must use Hex color code. (e.g. #4073FF)
  type: string@type-completer # The environment type (e.g. staging)
  --settings: any # Environment based settings
]: any -> record<name: string, key: string, description: string, color: string, _id: string, _project: string, type: string, _createdBy: string, createdAt: string, updatedAt: string, sdkKeys: record<mobile: list<record>, client: list<record>, server: list<record>>, settings: record<appIconURI: string>, readonly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/environments")
  let body = {name: $name, key: $key, description: $description, color: $color, type: $type, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Environments
#
# GET /v1/projects/{project}/environments
# operationId: EnvironmentsController_findAll
export def "projects-environments findAll" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --search: string
  --createdBy: string
]: nothing -> table<name: string, key: string, description: string, color: string, _id: string, _project: string, type: string, _createdBy: string, createdAt: string, updatedAt: string, sdkKeys: record<mobile: list, client: list, server: list>, settings: record<appIconURI: string>, readonly: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "createdBy" $createdBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/environments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Environment
#
# GET /v1/projects/{project}/environments/{key}
# operationId: EnvironmentsController_findOne
export def "projects-environments findOne" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, key: string, description: string, color: string, _id: string, _project: string, type: string, _createdBy: string, createdAt: string, updatedAt: string, sdkKeys: record<mobile: list<record>, client: list<record>, server: list<record>>, settings: record<appIconURI: string>, readonly: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/environments/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Environment
#
# PATCH /v1/projects/{project}/environments/{key}
# operationId: EnvironmentsController_update
export def "projects-environments update" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A unique display name (e.g. Staging Upcoming)
  --body-key: string # Unique Environment identifier, can be used in the SDK / API to reference by key rather than ID. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. staging-upcoming)
  --description: string # Environment description. (e.g. Pre-production changes)
  --color: string # Environment display color, used to highlight different environments on the dashboard. Must use Hex color code. (e.g. #4073FF)
  --type: string@type-completer # The environment type (e.g. staging)
  --settings: any # Environment based settings
]: any -> record<name: string, key: string, description: string, color: string, _id: string, _project: string, type: string, _createdBy: string, createdAt: string, updatedAt: string, sdkKeys: record<mobile: list<record>, client: list<record>, server: list<record>>, settings: record<appIconURI: string>, readonly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/environments/($key)")
  let body = {name: $name, key: $body_key, description: $description, color: $color, type: $type, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Environment
#
# DELETE /v1/projects/{project}/environments/{key}
# operationId: EnvironmentsController_remove
export def "projects-environments remove" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/environments/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate SDK Keys
#
# POST /v1/projects/{project}/environments/{environment}/sdk-keys
# operationId: SdkKeysController_generate
export def "projects-environments-sdk-keys generate" [
  environment: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client: oneof<nothing, bool>
  --server: oneof<nothing, bool>
  --mobile: oneof<nothing, bool>
]: any -> record<name: string, key: string, description: string, color: string, _id: string, _project: string, type: string, _createdBy: string, createdAt: string, updatedAt: string, sdkKeys: record<mobile: list<record>, client: list<record>, server: list<record>>, settings: record<appIconURI: string>, readonly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/environments/($environment)/sdk-keys")
  let body = {client: $client, server: $server, mobile: $mobile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invalidate an SDK key
#
# DELETE /v1/projects/{project}/environments/{environment}/sdk-keys/{key}
# operationId: SdkKeysController_invalidate
export def "projects-environments-sdk-keys invalidate" [
  key: string
  environment: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/environments/($environment)/sdk-keys/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Audience
#
# POST /v1/projects/{project}/audiences
# operationId: AudiencesController_create
export def "projects-audiences create" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Audience display name, must be set for project-level audiences. (e.g. Android Users)
  --key: string # Audience unique project-level key, must be set for project-level audiences. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. android-users)
  --description: string # Audience description. (e.g. Users with android devices)
  filters: any # Audience filters, describing logic for segmenting users
  --tags: list # Tags to organize project-level audiences on the dashboard
]: any -> record<name: string, key: string, description: string, _id: string, _project: string, filters: record<filters: list<any>, operator: string>, source: string, _createdBy: string, createdAt: string, updatedAt: string, tags: list<string>, readonly: bool, hasUsage: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/audiences")
  let body = {name: $name, key: $key, description: $description, filters: $filters, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Audiences
#
# GET /v1/projects/{project}/audiences
# operationId: AudiencesController_findAll
export def "projects-audiences findAll" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --search: string
  --createdBy: string
  --includeUsage: oneof<nothing, bool>
]: nothing -> table<name: string, key: string, description: string, _id: string, _project: string, filters: record<filters: list, operator: string>, source: string, _createdBy: string, createdAt: string, updatedAt: string, tags: list<string>, readonly: bool, hasUsage: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "createdBy" $createdBy "scalar") (serialize-qp "includeUsage" $includeUsage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/audiences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Audience
#
# GET /v1/projects/{project}/audiences/{key}
# operationId: AudiencesController_findOne
export def "projects-audiences findOne" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, key: string, description: string, _id: string, _project: string, filters: record<filters: list<any>, operator: string>, source: string, _createdBy: string, createdAt: string, updatedAt: string, tags: list<string>, readonly: bool, hasUsage: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/audiences/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Audience
#
# PATCH /v1/projects/{project}/audiences/{key}
# operationId: AudiencesController_update
export def "projects-audiences update" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Audience display name, must be set for project-level audiences. (e.g. Android Users)
  --body-key: string # Audience unique project-level key, must be set for project-level audiences. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. android-users)
  --description: string # Audience description. (e.g. Users with android devices)
  --filters: any # Audience filters, describing logic for segmenting users
  --tags: list # Tags to organize project-level audiences on the dashboard
]: any -> record<name: string, key: string, description: string, _id: string, _project: string, filters: record<filters: list<any>, operator: string>, source: string, _createdBy: string, createdAt: string, updatedAt: string, tags: list<string>, readonly: bool, hasUsage: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/audiences/($key)")
  let body = {name: $name, key: $body_key, description: $description, filters: $filters, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Audience
#
# DELETE /v1/projects/{project}/audiences/{key}
# operationId: AudiencesController_remove
export def "projects-audiences remove" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/audiences/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all direct usages of an Audience
#
# GET /v1/projects/{project}/audiences/{key}/usage
# operationId: AudiencesController_findUsages
export def "projects-audiences-usage findUsages" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<features: table<key: string, name: string, id: string, environments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/audiences/($key)/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Variable
#
# POST /v1/projects/{project}/variables
# operationId: VariablesController_create
export def "projects-variables create" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Variable name (e.g. Show New Dashboard)
  --description: string # A description of the Variable (e.g. A boolean variable that will toggle the new dashboard feature)
  key: string # Unique Variable identifier, can be used in the SDK / API to reference by key rather then ID. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. show-new-dashboard)
  --feature: string # The ID of the Feature this Variable belongs to (e.g. 61450f3daec96f5cf4a49947)
  type: string@type-completer-1 # The type of Variable. Must be one of [String | Boolean | Number | JSON] (e.g. Boolean)
  --validationSchema: any # Validation schema for variable values
  --tags: list # Feature tags. (e.g. [new, dashboard])
]: any -> record<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record<schemaType: record, enumValues: record, regexPattern: string, jsonSchema: string, description: string, exampleValue: record>, persistent: bool, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/variables")
  let body = {name: $name, description: $description, key: $key, _feature: $feature, type: $type, validationSchema: $validationSchema, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Variables
#
# GET /v1/projects/{project}/variables
# operationId: VariablesController_findAll
export def "projects-variables findAll" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --search: string
  --feature: string
  --type: string@type-completer-1
  --status: string@status-completer
]: nothing -> table<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record<schemaType: record, enumValues: record, regexPattern: string, jsonSchema: string, description: string, exampleValue: record>, persistent: bool, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "feature" $feature "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Variable
#
# GET /v1/projects/{project}/variables/{key}
# operationId: VariablesController_findOne
export def "projects-variables findOne" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record<schemaType: record, enumValues: record, regexPattern: string, jsonSchema: string, description: string, exampleValue: record>, persistent: bool, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/variables/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Variable
#
# PATCH /v1/projects/{project}/variables/{key}
# operationId: VariablesController_update
export def "projects-variables update" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Variable name (e.g. Show New Dashboard)
  --description: string # A description of the Variable (e.g. A boolean variable that will toggle the new dashboard feature)
  --body-key: string # Unique Variable identifier, can be used in the SDK / API to reference by key rather then ID. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. show-new-dashboard)
  --type: string@type-completer-1 # The type of Variable. Must be one of [String | Boolean | Number | JSON] (e.g. Boolean)
  --validationSchema: any # Validation schema for variable values
  --persistent: oneof<nothing, bool> # Boolean indicating if the variable is intended to be long-lived within a feature
  --tags: list # Tags to organize Variables on the dashboard (e.g. [Dashboard, QA])
]: any -> record<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record<schemaType: record, enumValues: record, regexPattern: string, jsonSchema: string, description: string, exampleValue: record>, persistent: bool, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/variables/($key)")
  let body = {name: $name, description: $description, key: $body_key, type: $type, validationSchema: $validationSchema, persistent: $persistent, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Variable
#
# DELETE /v1/projects/{project}/variables/{key}
# operationId: VariablesController_remove
export def "projects-variables remove" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/variables/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Variable status to archived or active
#
# PATCH /v1/projects/{project}/variables/{key}/status
# operationId: VariablesController_updateStatus
export def "projects-variables-status updateStatus" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer # Status field indicating whether a variable is actively being used, or is archived.
]: any -> record<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record<schemaType: record, enumValues: record, regexPattern: string, jsonSchema: string, description: string, exampleValue: record>, persistent: bool, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/variables/($key)/status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Feature
#
# POST /v1/projects/{project}/features
# operationId: FeaturesController_create_v1
# --variations item shape: {key: string, name: string, variables?: record}
# --variables item shape: {name?: string, description?: string, key: string, _feature?: string, type: "String"|"Boolean"|"Number"|"JSON", validationSchema?: any, tags?: list}
export def "projects-features v1-by-project" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string # Unique key by Project, can be used in the SDK / API to reference by 'key' rather than _id. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. new-dash)
  name: string # Name of the Feature (e.g. New Dashboard)
  --description: string # Feature description. (e.g. New Dashboard)
  configurations: record # e.g. {development: {status: active, targets: []}, production: {status: inactive, targets: []}}
  --type: string@type-completer-2 # Feature type. (e.g. release)
  --tags: list # Feature tags. (e.g. [new, dashboard])
  --variations: list # Variation configurations to be used by feature configurations. — item shape: {key: string, name: string, variables?: record}
  --controlVariation: string # The key of the variation that is used as the control variation for Metrics
  --body-variables: list # Variable definitions to be referenced in variations — item shape: {name?: string, description?: string, key: string, _feature?: string, type: "String"|"Boolean"|"Number"|"JSON", validationSchema?: any, tags?: list}
  --settings: any # Feature-level settings.
  --sdkVisibility: any # SDK Type Visibilty Settings
]: any -> record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: table<key: string, name: string, variables: record, _id: string>, controlVariation: string, staticVariation: string, variables: table<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record, persistent: bool, tags: list>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: table<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: list, readonly: bool, hasStaticConfig: bool>, latestUpdate: record<date: string, a0_user: string, changes: list<record>>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features")
  let body = {key: $key, name: $name, description: $description, configurations: $configurations, type: $type, tags: $tags, variations: $variations, controlVariation: $controlVariation, variables: $body_variables, settings: $settings, sdkVisibility: $sdkVisibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Features
#
# GET /v1/projects/{project}/features
# operationId: FeaturesController_findAll_v1
export def "projects-features v1-by-project-1" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --search: string
  --createdBy: string
  --type: string@type-completer-2
  --status: string@status-completer-1
]: nothing -> table<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: list<record>, controlVariation: string, staticVariation: string, variables: list<record>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: list<record>, latestUpdate: record<date: string, a0_user: string, changes: list>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list, links: list, markdown: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "createdBy" $createdBy "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Multiple Features with a single request
#
# POST /v1/projects/{project}/features/multiple
# operationId: FeaturesController_createMultiple_v1
export def "projects-features-multiple v1" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: list<record>, controlVariation: string, staticVariation: string, variables: list<record>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: list<record>, latestUpdate: record<date: string, a0_user: string, changes: list>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list, links: list, markdown: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/multiple")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Feature
#
# GET /v1/projects/{project}/features/{feature}
# operationId: FeaturesController_findOne_v1
export def "projects-features v1-by-feature-key-project" [
  feature: string
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: table<key: string, name: string, variables: record, _id: string>, controlVariation: string, staticVariation: string, variables: table<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record, persistent: bool, tags: list>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: table<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: list, readonly: bool, hasStaticConfig: bool>, latestUpdate: record<date: string, a0_user: string, changes: list<record>>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Feature
#
# PATCH /v1/projects/{project}/features/{feature}
# operationId: FeaturesController_update_v1
# --variations item shape: {key: string, name: string, variables?: record, _id?: string}
# --summary shape: {maintainers?: list, links?: list, markdown?: string}
# --variables item shape: {name?: string, description?: string, key: string, _feature?: string, type: "String"|"Boolean"|"Number"|"JSON", validationSchema?: any, tags?: list}
export def "projects-features v1-by-feature-project" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # Unique key by Project, can be used in the SDK / API to reference by 'key' rather than _id. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. new-dash)
  --name: string # Name of the Feature (e.g. New Dashboard)
  --description: string # Feature description. (e.g. New Dashboard)
  --configurations: record # e.g. {development: {status: active, targets: []}, production: {status: inactive, targets: []}}
  --variations: list # Variation configurations to be used by feature configurations. — item shape: {key: string, name: string, variables?: record, _id?: string}
  --staleness: record
  --summary: record # shape: {maintainers?: list, links?: list, markdown?: string}
  --body-variables: list # Variable definitions to be referenced in variations — item shape: {name?: string, description?: string, key: string, _feature?: string, type: "String"|"Boolean"|"Number"|"JSON", validationSchema?: any, tags?: list}
  --type: string@type-completer-2 # Feature type. (e.g. release)
  --tags: list # Feature tags. (e.g. [new, dashboard])
  --controlVariation: string # The key of the variation that is used as the control variation for Metrics
  --settings: any # Feature-level settings.
  --sdkVisibility: any # SDK Type Visibilty Settings
]: any -> record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: table<key: string, name: string, variables: record, _id: string>, controlVariation: string, staticVariation: string, variables: table<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record, persistent: bool, tags: list>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: table<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: list, readonly: bool, hasStaticConfig: bool>, latestUpdate: record<date: string, a0_user: string, changes: list<record>>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)")
  let body = {key: $key, name: $name, description: $description, configurations: $configurations, variations: $variations, staleness: $staleness, summary: $summary, variables: $body_variables, type: $type, tags: $tags, controlVariation: $controlVariation, settings: $settings, sdkVisibility: $sdkVisibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Feature
#
# DELETE /v1/projects/{project}/features/{feature}
# operationId: FeaturesController_remove_v1
export def "projects-features v1-by-feature-key-project-1" [
  feature: string
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteVariables: oneof<nothing, bool> # Controls whether the feature's associated variables should also be deleted
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteVariables" $deleteVariables "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Feature's status
#
# PATCH /v1/projects/{project}/features/{feature}/status
# operationId: FeaturesController_updateStatus_v1
export def "projects-features-status v1" [
  feature: string
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # The status to set the Feature's status to
  --customStatus: string # The ID of the custom status to set the Feature's status to
  --staticVariation: string # The variation key or ID to serve if the status is set to complete
]: any -> record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: table<key: string, name: string, variables: record, _id: string>, controlVariation: string, staticVariation: string, variables: table<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record, persistent: bool, tags: list>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: table<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: list, readonly: bool, hasStaticConfig: bool>, latestUpdate: record<date: string, a0_user: string, changes: list<record>>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/status")
  let body = {status: $status, _customStatus: $customStatus, staticVariation: $staticVariation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Feature's Static Configuration
#
# GET /v1/projects/{project}/features/{feature}/static-configuration
# operationId: FeaturesController_findStaticConfiguration_v1
export def "projects-features-static-configuration v1-by-feature-key-project" [
  feature: string
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, description: string, variables: record, environments: record, readonly: bool, type: string, tags: list<string>, controlVariation: string, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, staleness: record, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/static-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Feature's Static Configuration
#
# PATCH /v1/projects/{project}/features/{feature}/static-configuration
# operationId: FeaturesController_updateStaticConfiguration_v1
# --summary shape: {maintainers?: list, links?: list, markdown?: string}
export def "projects-features-static-configuration v1-by-feature-key-project-1" [
  feature: string
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-key: string # Unique key by Project, can be used in the SDK / API to reference by 'key' rather than _id. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. new-dash)
  --name: string # Name of the Feature (e.g. New Dashboard)
  --description: string # Feature description. (e.g. New Dashboard)
  --type: string@type-completer-2 # Feature type. (e.g. release)
  --tags: list # Feature tags. (e.g. [new, dashboard])
  --controlVariation: string # The key of the variation that is used as the control variation for Metrics
  --settings: any # Feature-level settings.
  --sdkVisibility: any # SDK Type Visibilty Settings
  --staleness: record
  --summary: record # shape: {maintainers?: list, links?: list, markdown?: string}
  --body-variables: record # The static value of each variable in the feature
  --environments: record # The status of the configuration in each environment
]: any -> record<key: string, name: string, description: string, variables: record, environments: record, readonly: bool, type: string, tags: list<string>, controlVariation: string, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, staleness: record, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/static-configuration")
  let body = {key: $body_key, name: $name, description: $description, type: $type, tags: $tags, controlVariation: $controlVariation, settings: $settings, sdkVisibility: $sdkVisibility, staleness: $staleness, summary: $summary, variables: $body_variables, environments: $environments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Link feature to Jira issue
#
# POST /v1/projects/{project}/features/{feature}/integrations/jira/issues
# operationId: FeaturesController_linkIssue_v1
export def "projects-features-integrations-jira-issues v1-by-feature-project" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  issueId: string
]: any -> record<issueId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/integrations/jira/issues")
  let body = {issueId: $issueId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List linked Jira Issues
#
# GET /v1/projects/{project}/features/{feature}/integrations/jira/issues
# operationId: FeaturesController_findAllLinkedIssues_v1
export def "projects-features-integrations-jira-issues v1-by-feature-project-1" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<issueId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/integrations/jira/issues")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlink feature from Jira issue
#
# DELETE /v1/projects/{project}/features/{feature}/integrations/jira/issues/{issue_id}
# operationId: FeaturesController_removeLinkedIssue_v1
export def "projects-features-integrations-jira-issues v1-by-feature-issue_id-key-project" [
  feature: string
  issue_id: string
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/integrations/jira/issues/($issue_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Feature Variation
#
# POST /v1/projects/{project}/features/{feature}/variations
# operationId: VariationsController_create
export def "projects-features-variations create" [
  project: string
  feature: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string # Unique key by Feature, can be used in the SDK / API to reference by 'key' rather than _id. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. variation-1)
  name: string # Variation display name. (e.g. User's with dashboard access)
  --body-variables: record # A key-value map of variables to their value for this variation (e.g. {show-new-dashboard: true, string-var: hello world, bool-var: true, num-var: 99, json-var: {foo: bar}})
]: any -> record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: table<key: string, name: string, variables: record, _id: string>, controlVariation: string, staticVariation: string, variables: table<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record, persistent: bool, tags: list>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: table<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: list, readonly: bool, hasStaticConfig: bool>, latestUpdate: record<date: string, a0_user: string, changes: list<record>>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/variations")
  let body = {key: $key, name: $name, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Feature Variations
#
# GET /v1/projects/{project}/features/{feature}/variations
# operationId: VariationsController_findAll
export def "projects-features-variations findAll" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: string, name: string, variables: record, _id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/variations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Feature Variation
#
# GET /v1/projects/{project}/features/{feature}/variations/{key}
# operationId: VariationsController_findOne
export def "projects-features-variations findOne" [
  key: string
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, variables: record, _id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/variations/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Feature Variation
#
# PATCH /v1/projects/{project}/features/{feature}/variations/{key}
# operationId: VariationsController_update
export def "projects-features-variations update" [
  key: string
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-key: string # Unique key by Feature, can be used in the SDK / API to reference by 'key' rather than _id. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. variation-1)
  --name: string # Variation display name. (e.g. User's with dashboard access)
  --body-variables: record # A key-value map of variables to their value for this variation (e.g. {show-new-dashboard: true, string-var: hello world, bool-var: true, num-var: 99, json-var: {foo: bar}})
  --id: string
]: any -> record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: table<key: string, name: string, variables: record, _id: string>, controlVariation: string, staticVariation: string, variables: table<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record, persistent: bool, tags: list>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: table<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: list, readonly: bool, hasStaticConfig: bool>, latestUpdate: record<date: string, a0_user: string, changes: list<record>>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/variations/($key)")
  let body = {key: $body_key, name: $name, variables: $body_variables, _id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Feature configurations
#
# GET /v1/projects/{project}/features/{feature}/configurations
# operationId: FeatureConfigsController_findAll
export def "projects-features-configurations findAll" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: string # A Environment key or ID
]: nothing -> table<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: list<record>, readonly: bool, hasStaticConfig: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/configurations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Feature configuration
#
# PATCH /v1/projects/{project}/features/{feature}/configurations
# operationId: FeatureConfigsController_update
# --targets item shape: {_id?: string, name?: string, rollout?: any, distribution: list, audience: any}
export def "projects-features-configurations update" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: string # A Environment key or ID
  --status: string@status-completer-2 # Status of the Feature Configuration
  --targets: list # The targets to evaluate what variation a user should be delivered — item shape: {_id?: string, name?: string, rollout?: any, distribution: list, audience: any}
]: any -> record<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: table<_id: string, name: string, audience: record, rollout: record, distribution: list, bucketingKey: string>, readonly: bool, hasStaticConfig: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/configurations" $qp)
  let body = {status: $status, targets: $targets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Feature Variable Evaluations (total)
#
# GET /v1/projects/{project}/features/{feature}/results/total-evaluations
# operationId: ResultsController_getTotalEvaluationsPerHourByFeature
export def "projects-features-results-total-evaluations get" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: float
  --endDate: float
  --platform: string
  --variable: string
  --environment: string # A Environment key or ID
  --period: string@period-completer
  --sdkType: string@sdkType-completer # SDK type to filter evaluation results by
]: nothing -> record<result: record<evaluations: list<record>>, cached: bool, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "variable" $variable "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "sdkType" $sdkType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/results/total-evaluations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Project Variable Evaluations (unique user)
#
# GET /v1/projects/{project}/results/evaluations
# operationId: ResultsController_getEvaluationsPerHourByProject
export def "projects-results-evaluations get" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: float
  --endDate: float
  --environment: string # A Environment key or ID
  --period: string@period-completer
  --sdkType: string@sdkType-completer # SDK type to filter evaluation results by
]: nothing -> record<result: record<evaluations: list<record>>, cached: bool, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "sdkType" $sdkType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/results/evaluations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Project Variable Evaluations (total)
#
# GET /v1/projects/{project}/results/total-evaluations
# operationId: ResultsController_getTotalEvaluationsPerHourByProject
export def "projects-results-total-evaluations get" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: float
  --endDate: float
  --environment: string # A Environment key or ID
  --period: string@period-completer
  --sdkType: string@sdkType-completer # SDK type to filter evaluation results by
]: nothing -> record<result: record<evaluations: list<record>>, cached: bool, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "sdkType" $sdkType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/results/total-evaluations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Profile for the Current User in the specified Project
#
# GET /v1/projects/{project}/userProfile/current
# operationId: UserProfilesController_findAll
export def "projects-user-profile-current findAll" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _project: string, a0_user: string, dvcUserId: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/userProfile/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or Update User Profile for the Current User in the specified Project
#
# PATCH /v1/projects/{project}/userProfile/current
# operationId: UserProfilesController_createOrUpdate
export def "projects-user-profile-current createOrUpdate" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dvcUserId: string # DVC User Id for User Profile. (nullable, e.g. dvc_sdk_user_id)
]: any -> record<_id: string, _project: string, a0_user: string, dvcUserId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/userProfile/current")
  let body = {dvcUserId: $dvcUserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Audit Log For Feature
#
# GET /v1/projects/{project}/features/{feature}/audit
# operationId: AuditLogController_findAll
export def "projects-features-audit findAll" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --environment: string
  --a0-user: string
  --startDate: string # format: date-time
  --endDate: string # format: date-time
]: nothing -> table<date: string, a0_user: string, changes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "a0_user" $a0_user "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/audit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Property
#
# POST /v1/projects/{project}/customProperties
# operationId: CustomPropertiesController_create
export def "projects-custom-properties create" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Display name for Custom Property. (e.g. Delivery App)
  key: string # Auto generated key to be used by the API to reference by 'key' rather then _id for CRUD operations. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. delivery-app)
  type: string@type-completer-3 # Type of the Custom Propety. Must be one of: "Boolean", "Number" or "String" (e.g. String)
  propertyKey: string # Custom Property key, must be unique by Project. Only to be used by the SDKs to reference the Custom Property.. (e.g. Delivery App Secret Agent Code)
  --schema: any # Schema definition for the custom property.
]: any -> record<name: string, key: string, _id: string, _project: string, _createdBy: string, propertyKey: string, type: string, createdAt: string, updatedAt: string, schema: record<schemaType: string, required: bool, enumSchema: record<allowedValues: list, allowAdditionalValues: bool>>, hasUsage: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/customProperties")
  let body = {name: $name, key: $key, type: $type, propertyKey: $propertyKey, schema: $schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Custom Properties
#
# GET /v1/projects/{project}/customProperties
# operationId: CustomPropertiesController_findAll
export def "projects-custom-properties findAll" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --search: string
  --type: string@type-completer-3
  --includeUsage: oneof<nothing, bool>
]: nothing -> table<name: string, key: string, _id: string, _project: string, _createdBy: string, propertyKey: string, type: string, createdAt: string, updatedAt: string, schema: record<schemaType: string, required: bool, enumSchema: record>, hasUsage: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "includeUsage" $includeUsage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/customProperties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Custom Property
#
# GET /v1/projects/{project}/customProperties/{key}
# operationId: CustomPropertiesController_findOne
export def "projects-custom-properties findOne" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, key: string, _id: string, _project: string, _createdBy: string, propertyKey: string, type: string, createdAt: string, updatedAt: string, schema: record<schemaType: string, required: bool, enumSchema: record<allowedValues: list, allowAdditionalValues: bool>>, hasUsage: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/customProperties/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Custom Property
#
# PATCH /v1/projects/{project}/customProperties/{key}
# operationId: CustomPropertiesController_update
export def "projects-custom-properties update" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Display name for Custom Property. (e.g. Delivery App)
  --body-key: string # Auto generated key to be used by the API to reference by 'key' rather then _id for CRUD operations. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. delivery-app)
  --propertyKey: string # Custom Property key, must be unique by Project. Only to be used by the SDKs to reference the Custom Property.. (e.g. Delivery App Secret Agent Code)
  --type: string@type-completer-3 # Type of the Custom Propety. Must be one of: "Boolean", "Number" or "String"
  --schema: any # Schema definition for the custom property.
]: any -> record<name: string, key: string, _id: string, _project: string, _createdBy: string, propertyKey: string, type: string, createdAt: string, updatedAt: string, schema: record<schemaType: string, required: bool, enumSchema: record<allowedValues: list, allowAdditionalValues: bool>>, hasUsage: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/customProperties/($key)")
  let body = {name: $name, key: $body_key, propertyKey: $propertyKey, type: $type, schema: $schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Custom Property
#
# DELETE /v1/projects/{project}/customProperties/{key}
# operationId: CustomPropertiesController_remove
export def "projects-custom-properties remove" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/customProperties/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Metric
#
# POST /v1/projects/{project}/metrics
# operationId: MetricsController_create
export def "projects-metrics create" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the Metric (e.g. New Signups)
  key: string # Unique key by Project, can be used in the SDK / API to reference by 'key' rather than _id. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. new-signups)
  --description: string # Metric description. (e.g. New signups on the dashboard)
  event: string # Event associated with metric (e.g. Sign Ups)
  dimension: string@dimension-completer # Metric dimension (e.g. COUNT_PER_UNIQUE_USER)
  optimize: string@optimize-completer # Indicates whether the metric is optimized for increase or decreasae (e.g. increase)
]: any -> record<name: string, key: string, description: string, _id: string, _project: string, source: string, event: string, dimension: string, optimize: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/metrics")
  let body = {name: $name, key: $key, description: $description, event: $event, dimension: $dimension, optimize: $optimize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All Metrics
#
# GET /v1/projects/{project}/metrics
# operationId: MetricsController_findAll
export def "projects-metrics findAll" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --search: string
  --dimension: string@dimension-completer
]: nothing -> table<name: string, key: string, description: string, _id: string, _project: string, source: string, event: string, dimension: string, optimize: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "dimension" $dimension "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Metric
#
# GET /v1/projects/{project}/metrics/{key}
# operationId: MetricsController_findOne
export def "projects-metrics findOne" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, key: string, description: string, _id: string, _project: string, source: string, event: string, dimension: string, optimize: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/metrics/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Metric
#
# PATCH /v1/projects/{project}/metrics/{key}
# operationId: MetricsController_update
export def "projects-metrics update" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the Metric (e.g. New Signups)
  --body-key: string # Unique key by Project, can be used in the SDK / API to reference by 'key' rather than _id. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. new-signups)
  --description: string # Metric description. (e.g. New signups on the dashboard)
  --event: string # Event associated with metric (e.g. Sign Ups)
  --dimension: string@dimension-completer # Metric dimension (e.g. COUNT_PER_UNIQUE_USER)
  --optimize: string@optimize-completer # Indicates whether the metric is optimized for increase or decreasae (e.g. increase)
]: any -> record<name: string, key: string, description: string, _id: string, _project: string, source: string, event: string, dimension: string, optimize: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/metrics/($key)")
  let body = {name: $name, key: $body_key, description: $description, event: $event, dimension: $dimension, optimize: $optimize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Metric
#
# DELETE /v1/projects/{project}/metrics/{key}
# operationId: MetricsController_remove
export def "projects-metrics remove" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/metrics/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch results for a Metric
#
# GET /v1/projects/{project}/metrics/{key}/results
# operationId: MetricsController_fetchResults
export def "projects-metrics-results fetchResults" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --feature: string
  --environment: string
  --startDate: string # format: date-time
  --endDate: string # format: date-time
]: nothing -> record<result: record<dataSeries: list<record>, variations: list<record>>, cached: bool, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feature" $feature "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/metrics/($key)/results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test Metric Results
#
# GET /v1/projects/{project}/test-metric-results
# operationId: TestMetricResultsController_fetch
export def "projects-test-metric-results fetch" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --feature: string
  --control: string
  --optimize: string@optimize-completer
  --environment: string
  --event: string
  --dimension: string@dimension-completer
  --startDate: string # format: date-time
  --endDate: string # format: date-time
]: nothing -> record<result: record<dataSeries: list<record>, variations: list<record>>, cached: bool, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feature" $feature "scalar") (serialize-qp "control" $control "scalar") (serialize-qp "optimize" $optimize "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "dimension" $dimension "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/test-metric-results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Metric Associations
#
# GET /v1/projects/{project}/metric-associations
# operationId: MetricAssociationsController_findAll
export def "projects-metric-associations findAll" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metric: string
  --feature: string
]: nothing -> table<_project: string, feature: record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: list, controlVariation: string, staticVariation: string, variables: list, tags: list, ldLink: string, readonly: bool, settings: record, sdkVisibility: record, configurations: list, latestUpdate: record, changeRequests: list, staleness: record, customStatus: record, summary: record>, metric: record<name: string, key: string, description: string, _id: string, _project: string, source: string, event: string, dimension: string, optimize: string, createdAt: string, updatedAt: string>, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metric" $metric "scalar") (serialize-qp "feature" $feature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/metric-associations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Associate a Metric with a Feature
#
# POST /v1/projects/{project}/metric-associations
# operationId: MetricAssociationsController_create
export def "projects-metric-associations create" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  metric: string
  feature: string
]: any -> record<_project: string, feature: record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: list<record>, controlVariation: string, staticVariation: string, variables: list<record>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: list<record>, latestUpdate: record<date: string, a0_user: string, changes: list>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list, links: list, markdown: string>>, metric: record<name: string, key: string, description: string, _id: string, _project: string, source: string, event: string, dimension: string, optimize: string, createdAt: string, updatedAt: string>, createdAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/metric-associations")
  let body = {metric: $metric, feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Association of a Metric and a Feature
#
# DELETE /v1/projects/{project}/metric-associations
# operationId: MetricAssociationsController_remove
export def "projects-metric-associations remove" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metric: string
  --feature: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metric" $metric "scalar") (serialize-qp "feature" $feature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/metric-associations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Overrides for the Current User
#
# PUT /v1/projects/{project}/features/{feature}/overrides/current
# operationId: OverridesController_updateFeatureOverride
export def "projects-features-overrides-current updateFeatureOverride" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  environment: string
  variation: string
]: any -> record<_project: string, _environment: string, _feature: string, _variation: string, dvcUserId: string, createdAt: float, updatedAt: float, a0_user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/overrides/current")
  let body = {environment: $environment, variation: $variation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get feature overrides for current user
#
# GET /v1/projects/{project}/features/{feature}/overrides/current
# operationId: OverridesController_findOne
export def "projects-features-overrides-current findOne" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<overrides: table<_environment: string, _variation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/overrides/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete override for specific feature and environment for the current user
#
# DELETE /v1/projects/{project}/features/{feature}/overrides/current
# operationId: OverridesController_deleteOverridesForFeature
export def "projects-features-overrides-current delete" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: string # A Environment key or ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/overrides/current" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get overrides for feature
#
# GET /v1/projects/{project}/features/{feature}/overrides
# operationId: OverridesController_findOverridesForFeature
export def "projects-features-overrides findOverridesForFeature" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addMetadata: oneof<nothing, bool>
  --environment: string # A Environment key or ID
]: nothing -> record<overrides: record, uniqueTeamMembers: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "addMetadata" $addMetadata "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/features/($feature)/overrides" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all overrides for project for current user
#
# GET /v1/projects/{project}/overrides/current
# operationId: OverridesController_findOverridesForProject
export def "projects-overrides-current findOverridesForProject" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<_feature: string, featureName: string, _environment: string, environmentName: string, _variation: string, variationName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/overrides/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all overrides for project for current user
#
# DELETE /v1/projects/{project}/overrides/current
# operationId: OverridesController_deleteOverridesForProject
export def "projects-overrides-current delete" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/overrides/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [Beta] Semantic Patch Update an Audience
#
# PATCH /v1/semantic/projects/{project}/audiences/{key}
# operationId: SemanticPatchController_semanticUpdate
# --instructions item shape: {op: "addFilterValues"|"removeFilterValues", action: record}
export def "semantic-projects-audiences semanticUpdate" [
  key: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  instructions: list # item shape: {op: "addFilterValues"|"removeFilterValues", action: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/semantic/projects/($project)/audiences/($key)")
  let body = {instructions: $instructions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Feature
#
# PATCH /v2/projects/{project}/features/{feature}
# operationId: FeaturesController_update
# --variations item shape: {key: string, name: string, variables?: record, _id?: string}
# --summary shape: {maintainers?: list, links?: list, markdown?: string}
# --variables item shape: {name?: string, description?: string, key: string, _feature?: string, type: "String"|"Boolean"|"Number"|"JSON", validationSchema?: any, tags?: list}
export def "projects-features update" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # Unique key by Project, can be used in the SDK / API to reference by 'key' rather than _id. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. new-dash)
  --name: string # Name of the Feature (e.g. New Dashboard)
  --description: string # Feature description. (e.g. New Dashboard)
  --configurations: record # e.g. {development: {status: active, targets: []}, production: {status: inactive, targets: []}}
  --variations: list # Variation configurations to be used by feature configurations. — item shape: {key: string, name: string, variables?: record, _id?: string}
  --staleness: record
  --summary: record # shape: {maintainers?: list, links?: list, markdown?: string}
  --body-variables: list # Variable definitions to be referenced in variations — item shape: {name?: string, description?: string, key: string, _feature?: string, type: "String"|"Boolean"|"Number"|"JSON", validationSchema?: any, tags?: list}
  --type: string@type-completer-2 # Feature type. (e.g. release)
  --tags: list # Feature tags. (e.g. [new, dashboard])
  --controlVariation: string # The key of the variation that is used as the control variation for Metrics
  --settings: any # Feature-level settings.
  --sdkVisibility: any # SDK Type Visibilty Settings
]: any -> record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: table<key: string, name: string, variables: record, _id: string>, controlVariation: string, staticVariation: string, variables: table<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record, persistent: bool, tags: list>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: table<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: list, readonly: bool, hasStaticConfig: bool>, latestUpdate: record<date: string, a0_user: string, changes: list<record>>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)")
  let body = {key: $key, name: $name, description: $description, configurations: $configurations, variations: $variations, staleness: $staleness, summary: $summary, variables: $body_variables, type: $type, tags: $tags, controlVariation: $controlVariation, settings: $settings, sdkVisibility: $sdkVisibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Feature
#
# GET /v2/projects/{project}/features/{feature}
# operationId: FeaturesController_findOne
export def "projects-features findOne" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: table<key: string, name: string, variables: record, _id: string>, controlVariation: string, staticVariation: string, variables: table<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record, persistent: bool, tags: list>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: table<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: list, readonly: bool, hasStaticConfig: bool>, latestUpdate: record<date: string, a0_user: string, changes: list<record>>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Feature
#
# POST /v2/projects/{project}/features
# operationId: FeaturesController_create
# --variations item shape: {key: string, name: string, variables?: record}
# --variables item shape: {name?: string, description?: string, key: string, _feature?: string, type: "String"|"Boolean"|"Number"|"JSON", validationSchema?: any, tags?: list}
export def "projects-features create" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string # Unique key by Project, can be used in the SDK / API to reference by 'key' rather than _id. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. new-dash)
  name: string # Name of the Feature (e.g. New Dashboard)
  --description: string # Feature description. (e.g. New Dashboard)
  configurations: record # e.g. {development: {status: active, targets: []}, production: {status: inactive, targets: []}}
  --type: string@type-completer-2 # Feature type. (e.g. release)
  --tags: list # Feature tags. (e.g. [new, dashboard])
  --variations: list # Variation configurations to be used by feature configurations. — item shape: {key: string, name: string, variables?: record}
  --controlVariation: string # The key of the variation that is used as the control variation for Metrics
  --body-variables: list # Variable definitions to be referenced in variations — item shape: {name?: string, description?: string, key: string, _feature?: string, type: "String"|"Boolean"|"Number"|"JSON", validationSchema?: any, tags?: list}
  --settings: any # Feature-level settings.
  --sdkVisibility: any # SDK Type Visibilty Settings
]: any -> record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: table<key: string, name: string, variables: record, _id: string>, controlVariation: string, staticVariation: string, variables: table<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record, persistent: bool, tags: list>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: table<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: list, readonly: bool, hasStaticConfig: bool>, latestUpdate: record<date: string, a0_user: string, changes: list<record>>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features")
  let body = {key: $key, name: $name, description: $description, configurations: $configurations, type: $type, tags: $tags, variations: $variations, controlVariation: $controlVariation, variables: $body_variables, settings: $settings, sdkVisibility: $sdkVisibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Features
#
# GET /v2/projects/{project}/features
# operationId: FeaturesController_findAll
export def "projects-features findAll" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --search: string
  --createdBy: string
  --type: string@type-completer-2
  --status: string@status-completer-1
  --customStatus: list
  --keys: list
  --includeLatestUpdate: oneof<nothing, bool>
  --staleness: string@staleness-completer
]: nothing -> table<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: list<record>, controlVariation: string, staticVariation: string, variables: list<record>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: list<record>, latestUpdate: record<date: string, a0_user: string, changes: list>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list, links: list, markdown: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "createdBy" $createdBy "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "customStatus" $customStatus "multi") (serialize-qp "keys" $keys "multi") (serialize-qp "includeLatestUpdate" $includeLatestUpdate "scalar") (serialize-qp "staleness" $staleness "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($project)/features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Feature's Static Configuration
#
# GET /v2/projects/{project}/features/{feature}/static-configuration
# operationId: FeaturesController_findStaticConfiguration
export def "projects-features-static-configuration findStaticConfiguration" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, description: string, variables: record, environments: record, readonly: bool, type: string, tags: list<string>, controlVariation: string, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, staleness: record, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/static-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Feature's Static Configuration
#
# PATCH /v2/projects/{project}/features/{feature}/static-configuration
# operationId: FeaturesController_updateStaticConfiguration
# --summary shape: {maintainers?: list, links?: list, markdown?: string}
export def "projects-features-static-configuration updateStaticConfiguration" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # Unique key by Project, can be used in the SDK / API to reference by 'key' rather than _id. Must only contain lower-case characters and `_`, `-` or `.`. (e.g. new-dash)
  --name: string # Name of the Feature (e.g. New Dashboard)
  --description: string # Feature description. (e.g. New Dashboard)
  --type: string@type-completer-2 # Feature type. (e.g. release)
  --tags: list # Feature tags. (e.g. [new, dashboard])
  --controlVariation: string # The key of the variation that is used as the control variation for Metrics
  --settings: any # Feature-level settings.
  --sdkVisibility: any # SDK Type Visibilty Settings
  --staleness: record
  --summary: record # shape: {maintainers?: list, links?: list, markdown?: string}
  --body-variables: record # The static value of each variable in the feature
  --environments: record # The status of the configuration in each environment
]: any -> record<key: string, name: string, description: string, variables: record, environments: record, readonly: bool, type: string, tags: list<string>, controlVariation: string, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, staleness: record, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/static-configuration")
  let body = {key: $key, name: $name, description: $description, type: $type, tags: $tags, controlVariation: $controlVariation, settings: $settings, sdkVisibility: $sdkVisibility, staleness: $staleness, summary: $summary, variables: $body_variables, environments: $environments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Feature's status
#
# PATCH /v2/projects/{project}/features/{feature}/status
# operationId: FeaturesController_updateStatus
export def "projects-features-status updateStatus" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # The status to set the Feature's status to
  --customStatus: string # The ID of the custom status to set the Feature's status to
  --staticVariation: string # The variation key or ID to serve if the status is set to complete
]: any -> record<_id: string, _project: string, source: string, status: string, type: string, name: string, key: string, description: string, _createdBy: string, createdAt: string, updatedAt: string, prodTargetingUpdatedAt: string, variations: table<key: string, name: string, variables: record, _id: string>, controlVariation: string, staticVariation: string, variables: table<name: string, description: string, key: string, _id: string, _project: string, _feature: string, type: string, status: string, source: string, _createdBy: string, createdAt: string, updatedAt: string, validationSchema: record, persistent: bool, tags: list>, tags: list<string>, ldLink: string, readonly: bool, settings: record<publicName: string, publicDescription: string, optInEnabled: bool>, sdkVisibility: record<mobile: bool, client: bool, server: bool>, configurations: table<_feature: string, _environment: string, _createdBy: string, status: string, startedAt: string, updatedAt: string, targets: list, readonly: bool, hasStaticConfig: bool>, latestUpdate: record<date: string, a0_user: string, changes: list<record>>, changeRequests: list<record>, staleness: record, customStatus: record<_status: string, updatedAt: string>, summary: record<maintainers: list<string>, links: list<record>, markdown: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/status")
  let body = {status: $status, _customStatus: $customStatus, staticVariation: $staticVariation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Feature's Staleness
#
# GET /v2/projects/{project}/features/{feature}/staleness
# operationId: FeaturesController_getStaleness
export def "projects-features-staleness get" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, _feature: string, stale: bool, updatedAt: string, disabled: bool, snoozedUntil: string, reason: string, metaData: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/staleness")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Feature's Staleness
#
# PATCH /v2/projects/{project}/features/{feature}/staleness
# operationId: FeaturesController_updateStaleness
export def "projects-features-staleness updateStaleness" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --snoozedUntil: string
  --disabled: oneof<nothing, bool>
  --metaData: record
]: any -> record<key: string, name: string, _feature: string, stale: bool, updatedAt: string, disabled: bool, snoozedUntil: string, reason: string, metaData: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/staleness")
  let body = {snoozedUntil: $snoozedUntil, disabled: $disabled, metaData: $metaData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Feature's summary
#
# PATCH /v2/projects/{project}/features/{feature}/summary
# operationId: FeaturesController_updateSummary
# --links item shape: {url: string, title: string}
export def "projects-features-summary updateSummary" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maintainers: list # Auth0 maintainers of the feature
  --links: list # Array of links associated with the feature — item shape: {url: string, title: string}
  --markdown: string
]: any -> record<maintainers: list<string>, links: table<url: string, title: string>, markdown: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/summary")
  let body = {maintainers: $maintainers, links: $links, markdown: $markdown} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of Feature Change Requests for a Project
#
# GET /v2/projects/{project}/change-requests
# operationId: ProjectChangeRequestsController_getFeatureChangeRequests
export def "projects-change-requests get" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --search: string
  --createdBy: string
  --status: string@status-completer-3
  --reviewer: string
]: nothing -> table<_id: string, _project: string, _feature: string, status: string, operation: string, description: string, reviewers: record, reviews: list<record>, _createdBy: string, _updatedBy: string, createdAt: string, updatedAt: string, feature: record<key: string, name: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "createdBy" $createdBy "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "reviewer" $reviewer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($project)/change-requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Feature Change Request
#
# POST /v2/projects/{project}/features/{feature}/change-requests
# operationId: FeatureChangeRequestsController_createChangeRequest
export def "projects-features-change-requests createChangeRequest" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  path: string
  method: string@method-completer
  --body-body: record
]: any -> record<_id: string, _project: string, _baseFeatureSnapshot: string, _feature: string, status: string, changes: list<record>, operation: string, description: string, reviewers: record, reviews: list<record>, _createdBy: string, _updatedBy: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/change-requests")
  let body = {path: $path, method: $method, body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of Pending Feature Change Requests for a Feature
#
# GET /v2/projects/{project}/features/{feature}/change-requests
# operationId: FeatureChangeRequestsController_getPendingFeatureChangeRequests
export def "projects-features-change-requests list" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<_id: string, _project: string, _baseFeatureSnapshot: string, _feature: string, status: string, changes: list<record>, operation: string, description: string, reviewers: record, reviews: list<record>, _createdBy: string, _updatedBy: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/change-requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the latest non-draft Feature Change Request for a Feature
#
# GET /v2/projects/{project}/features/{feature}/change-requests/latest
# operationId: FeatureChangeRequestsController_getLatestFeatureChangeRequest
export def "projects-features-change-requests-latest get" [
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _project: string, _baseFeatureSnapshot: string, _feature: string, status: string, changes: list<record>, operation: string, description: string, reviewers: record, reviews: list<record>, _createdBy: string, _updatedBy: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/change-requests/latest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Feature Change Request
#
# GET /v2/projects/{project}/features/{feature}/change-requests/{id}
# operationId: FeatureChangeRequestsController_getFeatureChangeRequest
export def "projects-features-change-requests get" [
  id: string
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_id: string, _project: string, _baseFeatureSnapshot: string, _feature: string, status: string, changes: list<record>, operation: string, description: string, reviewers: record, reviews: list<record>, _createdBy: string, _updatedBy: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/change-requests/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Feature Change Request for Review
#
# PATCH /v2/projects/{project}/features/{feature}/change-requests/{id}/submit
# operationId: FeatureChangeRequestsController_submitChangeRequestForReview
export def "projects-features-change-requests-submit submitChangeRequestForReview" [
  id: string
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string
  reviewers: list
]: any -> record<_id: string, _project: string, _baseFeatureSnapshot: string, _feature: string, status: string, changes: list<record>, operation: string, description: string, reviewers: record, reviews: list<record>, _createdBy: string, _updatedBy: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/change-requests/($id)/submit")
  let body = {description: $description, reviewers: $reviewers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Review a Pending Feature Change Request
#
# PATCH /v2/projects/{project}/features/{feature}/change-requests/{id}/review
# operationId: FeatureChangeRequestsController_reviewFeatureChangeRequest
export def "projects-features-change-requests-review reviewFeatureChangeRequest" [
  id: string
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apply: oneof<nothing, bool> # Controls whether the review should also apply the change request to the feature
  action: string@action-completer
  comment: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/change-requests/($id)/review" $qp)
  let body = {action: $action, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Review a Pending Feature Change Request
#
# PATCH /v2/projects/{project}/features/{feature}/change-requests/{id}/apply
# operationId: FeatureChangeRequestsController_applyFeatureChangeRequest
export def "projects-features-change-requests-apply applyFeatureChangeRequest" [
  id: string
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string
  action: string@action-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/change-requests/($id)/apply")
  let body = {description: $description, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a Pending Feature Change Request
#
# PATCH /v2/projects/{project}/features/{feature}/change-requests/{id}/cancel
# operationId: FeatureChangeRequestsController_cancelFeatureChangeRequest
export def "projects-features-change-requests-cancel cancelFeatureChangeRequest" [
  id: string
  feature: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($project)/features/($feature)/change-requests/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Webhook
#
# POST /v1/projects/{project}/webhooks
# operationId: WebhooksController_create
export def "projects-webhooks create" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the Webhook (e.g. Slack)
  --description: string # The description of the Webhook (e.g. Post in Slack when a feature is updated)
  --outputFormat: record
  --feature: string
  --environments: list
  events: list # The events that trigger the webhook (e.g. [createdFeature, modifiedFeature])
  --body-url: string # The URL to call once the type is triggered (e.g. https://hooks.slack.com/services/...)
]: any -> record<name: string, description: string, _id: string, _project: string, _feature: string, _environments: list<string>, url: string, events: list<string>, source: string, createdBy: string, createdAt: string, updatedAt: string, outputFormat: record, _slackIntegration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/webhooks")
  let body = {name: $name, description: $description, outputFormat: $outputFormat, _feature: $feature, _environments: $environments, events: $events, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Webhooks
#
# GET /v1/projects/{project}/webhooks
# operationId: WebhooksController_findAll
export def "projects-webhooks findAll" [
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # default: 1
  --perPage: float # default: 100
  --sortBy: string@sortBy-completer # default: createdAt
  --sortOrder: string@sortOrder-completer # default: desc
  --search: string
  --createdBy: string
]: nothing -> table<name: string, description: string, _id: string, _project: string, _feature: string, _environments: list<string>, url: string, events: list<string>, source: string, createdBy: string, createdAt: string, updatedAt: string, outputFormat: record, _slackIntegration: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "createdBy" $createdBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Webhook
#
# PATCH /v1/projects/{project}/webhooks/{id}
# operationId: WebhooksController_update
export def "projects-webhooks update" [
  id: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the Webhook (e.g. Slack)
  --description: string # The description of the Webhook (e.g. Post in Slack when a feature is updated)
  feature: string
  environments: list
  --events: list # The events that trigger the webhook (e.g. [createdFeature, modifiedFeature])
  --body-url: string # The URL to call once the type is triggered (e.g. https://hooks.slack.com/services/...)
  --outputFormat: record
]: any -> record<name: string, description: string, _id: string, _project: string, _feature: string, _environments: list<string>, url: string, events: list<string>, source: string, createdBy: string, createdAt: string, updatedAt: string, outputFormat: record, _slackIntegration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/webhooks/($id)")
  let body = {name: $name, description: $description, _feature: $feature, _environments: $environments, events: $events, url: $body_url, outputFormat: $outputFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Webhook
#
# GET /v1/projects/{project}/webhooks/{id}
# operationId: WebhooksController_findOne
export def "projects-webhooks findOne" [
  id: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, _id: string, _project: string, _feature: string, _environments: list<string>, url: string, events: list<string>, source: string, createdBy: string, createdAt: string, updatedAt: string, outputFormat: record, _slackIntegration: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Webhook
#
# DELETE /v1/projects/{project}/webhooks/{id}
# operationId: WebhooksController_remove
export def "projects-webhooks remove" [
  id: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, _id: string, _project: string, _feature: string, _environments: list<string>, url: string, events: list<string>, source: string, createdBy: string, createdAt: string, updatedAt: string, outputFormat: record, _slackIntegration: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project)/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or Update Organization Dynatrace Integration
#
# POST /v1/integrations/dynatrace
# operationId: DynatraceIntegrationController_createIntegration
export def "integrations-dynatrace createIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dynatraceEnvironmentId: string
  accessToken: string
  environmentUrl: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations/dynatrace")
  let body = {dynatraceEnvironmentId: $dynatraceEnvironmentId, accessToken: $accessToken, environmentUrl: $environmentUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Dynatrace Integrations
#
# GET /v1/integrations/dynatrace
# operationId: DynatraceIntegrationController_getIntegrations
export def "integrations-dynatrace get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<environments: table<dynatraceEnvironmentId: string, accessToken: string, environmentUrl: string, projects: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations/dynatrace")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Dynatrace Environment
#
# DELETE /v1/integrations/dynatrace/{dynatraceEnvironmentId}
# operationId: DynatraceIntegrationController_deleteEnvironment
export def "integrations-dynatrace delete" [
  dynatraceEnvironmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/dynatrace/($dynatraceEnvironmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
