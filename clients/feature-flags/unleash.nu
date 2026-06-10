# Auto-generated client for Admin API v1.0.0
# Source: https://docs.getunleash.io/api/openapi.json
# Auth: --token flag or $env.ADMIN_API_TOKEN

const BASE_URL = "https://app.unleash-instance.example.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADMIN_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://app.unleash-instance.example.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["discarded" "kept"] }
def timeRange-completer [] { ["day" "hour" "month" "week"] }
def yAxisMin-completer [] { ["auto" "zero"] }
def aggregationMode-completer [] { ["avg" "count" "p50" "p95" "p99" "rps" "sum"] }
def source-completer [] { ["external" "internal"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-insights get-instance-insights" } } | get name | first)
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

# Get instance information
#
# GET /api/admin/insights
# operationId: get-instance-insights
export def "admin-insights get-instance-insights" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # The beginning of the date range in yyyy-MM-dd format
  --qp-to: string # The end of the date range in yyyy-MM-dd format
  --Authorization: string # API key needed to access this API
]: nothing -> record<userTrends: table<date: string, total: float, active: float, inactive: float>, flagTrends: table<date: string, total: float, active: float, stale: float, potentiallyStale: float>, projectFlagTrends: table<week: string, project: string, health: float, technicalDebt: float, timeToProduction: float, date: string, total: float, active: float, stale: float, potentiallyStale: float, users: float>, metricsSummaryTrends: table<week: string, date: string, project: string, totalRequests: float, totalYes: float, totalNo: float, totalApps: float, totalFlags: float, totalEnvironments: float>, environmentTypeTrends: table<date: string, week: string, environmentType: string, totalUpdates: float>, lifecycleTrends: table<week: string, date: string, newProductionFlags: float, project: string>, creationArchiveTrends: table<week: string, date: string, project: string, createdFlags: record, archivedFlags: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/admin/insights" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SCIM settings.
#
# GET /api/admin/scim-settings
# operationId: get-scim-settings
export def "admin-scim-settings get-scim-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<enabled: bool, hasToken: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/scim-settings")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set SCIM settings.
#
# POST /api/admin/scim-settings
# operationId: set-scim-settings
export def "admin-scim-settings set-scim-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --enabled: string@bool-completer # Whether SCIM provisioning is currently enabled.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/scim-settings")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generates a new SCIM API token.
#
# POST /api/admin/scim-settings/generate-new-token
# operationId: generate-new-token
export def "admin-scim-settings-generate-new-token generate-new-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/scim-settings/generate-new-token")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Gets configured context fields
#
# GET /api/admin/projects/{projectId}/context
# operationId: get-context-fields-for-project
export def "admin-projects-context get-context-fields-for-project" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Whether the response should include project-specific or root context fields in addition to the fields in the default response. When querying the root context API, `include=project` will yield a response that includes all project-specific context fields in addition to all root context fields. Conversely, when querying a project-specific context API, using `include=root` will yield a response that includes all root context fields in addition to the project-specific context fields. The other combinations have no effect, because the responses already include those fields. When including project-specific context fields via the root-level API, context fields in private projects the user does not have access to will be omitted.
  --Authorization: string # API key needed to access this API
]: nothing -> table<name: string, description: string, stickiness: bool, sortOrder: int, createdAt: string, usedInFeatures: int, usedInProjects: int, legalValues: list<record>, project: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/context" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Create a context field
#
# POST /api/admin/projects/{projectId}/context
# operationId: create-context-field-for-project
# --legalValues item shape: {value: string, description?: string}
export def "admin-projects-context create-context-field-for-project" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --description: string # A description of the context field
  --stickiness: string@bool-completer # `true` if this field should be available for use with [custom stickiness](https://docs.getunleash.io/concepts/stickiness#custom-stickiness), otherwise `false`
  --sortOrder: int # How this context field should be sorted if no other sort order is selected
  --legalValues: list # A list of allowed values for this context field — item shape: {value: string, description?: string}
  --project: string # The project this context field belongs to (if it is project-specific)
  name: string # The name of the context field.
]: any -> record<name: string, description: string, stickiness: bool, sortOrder: int, createdAt: string, usedInFeatures: int, usedInProjects: int, legalValues: table<value: string, description: string>, project: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/context")
  let body = {description: $description, stickiness: $stickiness, sortOrder: $sortOrder, legalValues: $legalValues, project: $project, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Gets context field
#
# GET /api/admin/projects/{projectId}/context/{contextField}
# operationId: get-context-field-for-project
export def "admin-projects-context get-context-field-for-project" [
  projectId: string
  contextField: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<name: string, description: string, stickiness: bool, sortOrder: int, createdAt: string, usedInFeatures: int, usedInProjects: int, legalValues: table<value: string, description: string>, project: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/context/($contextField)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Update an existing context field
#
# PUT /api/admin/projects/{projectId}/context/{contextField}
# operationId: update-context-field-for-project
# --legalValues item shape: {value: string, description?: string}
export def "admin-projects-context update-context-field-for-project" [
  projectId: string
  contextField: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --description: string # A description of the context field
  --stickiness: string@bool-completer # `true` if this field should be available for use with [custom stickiness](https://docs.getunleash.io/concepts/stickiness#custom-stickiness), otherwise `false`
  --sortOrder: int # How this context field should be sorted if no other sort order is selected
  --legalValues: list # A list of allowed values for this context field — item shape: {value: string, description?: string}
  --project: string # The project this context field belongs to (if it is project-specific)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/context/($contextField)")
  let body = {description: $description, stickiness: $stickiness, sortOrder: $sortOrder, legalValues: $legalValues, project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Delete an existing context field
#
# DELETE /api/admin/projects/{projectId}/context/{contextField}
# operationId: delete-context-field-for-project
export def "admin-projects-context delete-context-field-for-project" [
  projectId: string
  contextField: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/context/($contextField)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Add or update legal value for the context field
#
# POST /api/admin/projects/{projectId}/context/{contextField}/legal-values
# operationId: update-context-field-legal-value-for-project
export def "admin-projects-context-legal-values update-context-field-legal-value-for-project" [
  projectId: string
  contextField: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  value: string # The valid value
  --description: string # Describes this specific legal value
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/context/($contextField)/legal-values")
  let body = {value: $value, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Delete legal value for the context field
#
# DELETE /api/admin/projects/{projectId}/context/{contextField}/legal-values/{legalValue}
# operationId: delete-context-field-legal-value-for-project
export def "admin-projects-context-legal-values delete-context-field-legal-value-for-project" [
  projectId: string
  contextField: string
  legalValue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/context/($contextField)/legal-values/($legalValue)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Validate a context field
#
# POST /api/admin/projects/{projectId}/context/validate
# operationId: validate-context-field-name-for-project
export def "admin-projects-context-validate validate-context-field-name-for-project" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  name: string # The name of the represented object.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/context/validate")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a milestone strategy
#
# PUT /api/admin/projects/{project}/features/{featureName}/environments/{environment}/milestone-strategies/{strategyId}
# operationId: update-project-milestone-strategy
# --constraints item shape: {contextName: string, operator: "NOT_IN"|"IN"|"STR_ENDS_WITH"|"STR_STARTS_WITH"|"STR_CONTAINS"|"NUM_EQ"|"NUM_GT"|"NUM_GTE"|"NUM_LT"|"NUM_LTE"|"DATE_AFTER"|"DATE_BEFORE"|"SEMVER_EQ"|"SEMVER_GT"|"SEMVER_LT"|"REGEX", caseInsensitive?: bool, inverted?: bool, values?: list, value?: string}
# --variants item shape: {name: string, weight: int, weightType: "variable"|"fix", stickiness: string, payload?: record}
export def "admin-projects-features-environments-milestone-strategies update-project-milestone-strategy" [
  project: string
  featureName: string
  environment: string
  strategyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --sortOrder: float # The order of the strategy in the list in feature environment configuration (format: double)
  --constraints: list # A list of the constraints attached to the strategy. See https://docs.getunleash.io/concepts/activation-strategies#constraints — item shape: {contextName: string, operator: "NOT_IN"|"IN"|"STR_ENDS_WITH"|"STR_STARTS_WITH"|"STR_CONTAINS"|"NUM_EQ"|"NUM_GT"|"NUM_GTE"|"NUM_LT"|"NUM_LTE"|"DATE_AFTER"|"DATE_BEFORE"|"SEMVER_EQ"|"SEMVER_GT"|"SEMVER_LT"|"REGEX", caseInsensitive?: bool, inverted?: bool, values?: list, value?: string}
  --title: string # A descriptive title for the strategy (nullable)
  --disabled: string@bool-completer # A toggle to disable the strategy. defaults to true. Disabled strategies are not evaluated or returned to the SDKs (nullable)
  --variants: list # Strategy level variants — item shape: {name: string, weight: int, weightType: "variable"|"fix", stickiness: string, payload?: record}
  --segments: list # A list of segment ids attached to the strategy
  --parameters: record # A list of parameters for a strategy
]: any -> record<id: string, milestoneId: string, sortOrder: float, title: string, name: string, strategyName: string, parameters: record, constraints: table<contextName: string, operator: string, caseInsensitive: bool, inverted: bool, values: list, value: string>, variants: table<name: string, weight: int, weightType: string, stickiness: string, payload: record>, segments: list<float>, disabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($project)/features/($featureName)/environments/($environment)/milestone-strategies/($strategyId)")
  let body = {sortOrder: $sortOrder, constraints: $constraints, title: $title, disabled: $disabled, variants: $variants, segments: $segments, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Get partial updates (SDK)
#
# GET /api/client/delta
# operationId: get-delta
export def "client-delta get-delta" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<events: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client/delta")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Change a feature environment safeguard
#
# PUT /api/admin/projects/{project}/features/{featureName}/environments/{environment}/safeguards
# operationId: change-feature-env-safeguard
# --impactMetric shape: {metricName: string, timeRange: "hour"|"day"|"week"|"month", aggregationMode: "rps"|"count"|"avg"|"sum"|"p95"|"p99"|"p50", labelSelectors: record, source?: "internal"|"external"}
# --triggerCondition shape: {operator: ">"|"<", threshold: float}
export def "admin-projects-features-environments-safeguards change-feature-env-safeguard" [
  project: string
  featureName: string
  environment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  impactMetric: record # Metric configuration that should be evaluated for the safeguard. — shape: {metricName: string, timeRange: "hour"|"day"|"week"|"month", aggregationMode: "rps"|"count"|"avg"|"sum"|"p95"|"p99"|"p50", labelSelectors: record, source?: "internal"|"external"}
  triggerCondition: record # The condition that triggers the safeguard. — shape: {operator: ">"|"<", threshold: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($project)/features/($featureName)/environments/($environment)/safeguards")
  let body = {impactMetric: $impactMetric, triggerCondition: $triggerCondition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Delete a feature environment safeguard
#
# DELETE /api/admin/projects/{project}/features/{featureName}/environments/{environment}/safeguards/{safeguardId}
# operationId: delete-feature-env-safeguard
export def "admin-projects-features-environments-safeguards delete-feature-env-safeguard" [
  project: string
  featureName: string
  environment: string
  safeguardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($project)/features/($featureName)/environments/($environment)/safeguards/($safeguardId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get feature lifecycle
#
# GET /api/admin/projects/{projectId}/features/{featureName}/lifecycle
# operationId: get-feature-lifecycle
export def "admin-projects-features-lifecycle get-feature-lifecycle" [
  projectId: string
  featureName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> table<stage: string, status: string, enteredStageAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/features/($featureName)/lifecycle")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set feature completed
#
# POST /api/admin/projects/{projectId}/features/{featureName}/lifecycle/complete
# operationId: complete
export def "admin-projects-features-lifecycle-complete complete" [
  projectId: string
  featureName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  status: string@status-completer # The status of the feature after it has been marked as completed
  --statusValue: string # The metadata value passed in together with status
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/features/($featureName)/lifecycle/complete")
  let body = {status: $status, statusValue: $statusValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set feature uncompleted
#
# POST /api/admin/projects/{projectId}/features/{featureName}/lifecycle/uncomplete
# operationId: uncomplete
export def "admin-projects-features-lifecycle-uncomplete uncomplete" [
  projectId: string
  featureName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/features/($featureName)/lifecycle/uncomplete")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a feature link
#
# POST /api/admin/projects/{projectId}/features/{featureName}/link
# operationId: create-feature-link
export def "admin-projects-features-link create-feature-link" [
  projectId: string
  featureName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --body-url: string # The URL the feature is linked to
  --title: string # The description of the link (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/features/($featureName)/link")
  let body = {url: $body_url, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a feature link
#
# PUT /api/admin/projects/{projectId}/features/{featureName}/link/{linkId}
# operationId: update-feature-link
export def "admin-projects-features-link update-feature-link" [
  projectId: string
  featureName: string
  linkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --body-url: string # The URL the feature is linked to
  --title: string # The description of the link (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/features/($featureName)/link/($linkId)")
  let body = {url: $body_url, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a feature link
#
# DELETE /api/admin/projects/{projectId}/features/{featureName}/link/{linkId}
# operationId: delete-feature-link
export def "admin-projects-features-link delete-feature-link" [
  projectId: string
  featureName: string
  linkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/features/($featureName)/link/($linkId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all features lifecycle stage count
#
# GET /api/admin/lifecycle/count
# operationId: get-feature-lifecycle-stage-count
export def "admin-lifecycle-count get-feature-lifecycle-stage-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<initial: float, preLive: float, live: float, completed: float, archived: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/lifecycle/count")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get aggregated metered connections for a given time period.
#
# GET /api/admin/metrics/connection
# operationId: get-connections-for-period
export def "admin-metrics-connection get-connections-for-period" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --grouping: string # Whether to aggregate the data by month or by day
  --qp-from: string # The starting date of the traffic data usage search in IS:yyyy-MM-dd format (format: date)
  --qp-to: string # The starting date of the traffic data usage search in IS:yyyy-MM-dd format (format: date)
  --Authorization: string # API key needed to access this API
]: nothing -> record<grouping: string, dateRange: record<from: string, to: string>, apiData: table<meteredGroup: string, dataPoints: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "grouping" $grouping "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/admin/metrics/connection" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get aggregated metered requests for a given time period.
#
# GET /api/admin/metrics/request
# operationId: get-requests-for-period
export def "admin-metrics-request get-requests-for-period" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --grouping: string # Whether to aggregate the data by month or by day
  --qp-from: string # The starting date of the traffic data usage search in IS:yyyy-MM-dd format (format: date)
  --qp-to: string # The starting date of the traffic data usage search in IS:yyyy-MM-dd format (format: date)
  --Authorization: string # API key needed to access this API
]: nothing -> record<grouping: string, dateRange: record<from: string, to: string>, apiData: table<meteredGroup: string, dataPoints: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "grouping" $grouping "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/admin/metrics/request" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get impact metrics configurations for a single feature
#
# GET /api/admin/projects/{projectId}/features/{featureName}/impact-metrics/config
# operationId: get-flag-impact-metrics-configs-by-feature
export def "admin-projects-features-impact-metrics-config get-flag-impact-metrics-configs-by-feature" [
  projectId: string
  featureName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<configs: table<id: string, metricName: string, timeRange: string, aggregationMode: string, labelSelectors: record, source: string, displayName: string, yAxisMin: string, step: any, title: string, mode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/features/($featureName)/impact-metrics/config")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Save flag level impact metrics configuration
#
# POST /api/admin/projects/{projectId}/features/{featureName}/impact-metrics/config
# operationId: save-feature-impact-metrics-config
export def "admin-projects-features-impact-metrics-config save-feature-impact-metrics-config" [
  projectId: string
  featureName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --id: string # The unique ULID identifier for this impact metric configuration. Generated automatically if not provided.
  metricName: string # The Prometheus metric series to query. It includes both unleash prefix and metric type and display name
  timeRange: string@timeRange-completer # The time range for the metric data.
  yAxisMin: string@yAxisMin-completer # Whether the chart should begin at zero on the y-axis.
  aggregationMode: string@aggregationMode-completer # The aggregation mode for the metric data.
  labelSelectors: record # The selected labels and their values for filtering the metric data.
  --title: string # Optional title for the impact metric chart.
  --body-source: string@source-completer # The Prometheus data source for this metric. Defaults to internal.
]: any -> record<id: string, metricName: string, timeRange: string, aggregationMode: string, labelSelectors: record, source: string, displayName: string, yAxisMin: string, step: any, title: string, mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/features/($featureName)/impact-metrics/config")
  let body = {id: $id, metricName: $metricName, timeRange: $timeRange, yAxisMin: $yAxisMin, aggregationMode: $aggregationMode, labelSelectors: $labelSelectors, title: $title, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Get impact metrics configuration for the instance
#
# GET /api/admin/impact-metrics/config
# operationId: get-instance-impact-metrics-configs
export def "admin-impact-metrics-config get-instance-impact-metrics-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<configs: table<id: string, metricName: string, timeRange: string, aggregationMode: string, labelSelectors: record, source: string, displayName: string, yAxisMin: string, step: any, title: string, mode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/impact-metrics/config")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Save instance level impact metrics configuration
#
# POST /api/admin/impact-metrics/config
# operationId: save-instance-impact-metrics-config
export def "admin-impact-metrics-config save-instance-impact-metrics-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --id: string # The unique ULID identifier for this impact metric configuration. Generated automatically if not provided.
  metricName: string # The Prometheus metric series to query. It includes both unleash prefix and metric type and display name
  timeRange: string@timeRange-completer # The time range for the metric data.
  yAxisMin: string@yAxisMin-completer # Whether the chart should begin at zero on the y-axis.
  aggregationMode: string@aggregationMode-completer # The aggregation mode for the metric data.
  labelSelectors: record # The selected labels and their values for filtering the metric data.
  --title: string # Optional title for the impact metric chart.
  --body-source: string@source-completer # The Prometheus data source for this metric. Defaults to internal.
]: any -> record<id: string, metricName: string, timeRange: string, aggregationMode: string, labelSelectors: record, source: string, displayName: string, yAxisMin: string, step: any, title: string, mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/impact-metrics/config")
  let body = {id: $id, metricName: $metricName, timeRange: $timeRange, yAxisMin: $yAxisMin, aggregationMode: $aggregationMode, labelSelectors: $labelSelectors, title: $title, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Delete flag level impact metric configuration
#
# DELETE /api/admin/projects/{projectId}/features/{featureName}/impact-metrics/config/{id}
# operationId: delete-flag-impact-metric-config
export def "admin-projects-features-impact-metrics-config delete-flag-impact-metric-config" [
  projectId: string
  featureName: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/features/($featureName)/impact-metrics/config/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Delete instance level impact metric configuration
#
# DELETE /api/admin/impact-metrics/config/{id}
# operationId: delete-instance-impact-metric-config
export def "admin-impact-metrics-config delete-instance-impact-metric-config" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/impact-metrics/config/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get the external impact-metrics source.
#
# GET /api/admin/impact-metrics/external-source
# operationId: get-external-impact-metrics-source
export def "admin-impact-metrics-external-source get-external-impact-metrics-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<enabled: bool, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/impact-metrics/external-source")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Set the external impact-metrics source.
#
# POST /api/admin/impact-metrics/external-source
# operationId: set-external-impact-metrics-source
export def "admin-impact-metrics-external-source set-external-impact-metrics-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --enabled: string@bool-completer # Whether the external impact-metrics source is active. When `true`, `url` must be a valid non-empty URL.
  --body-url: string # Base URL of the external impact-metrics source. Basic-Auth credentials may be embedded in the URL (e.g. `https://user:pass@metrics.example.com`); they are extracted into an `Authorization` header on outbound requests. Required (non-empty, valid URL) when `enabled` is true; an empty string is discarded when `enabled` is false.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/impact-metrics/external-source")
  let body = {enabled: $enabled, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Validate an external impact-metrics source URL.
#
# POST /api/admin/impact-metrics/external-source/validate
# operationId: validate-external-impact-metrics-source
export def "admin-impact-metrics-external-source-validate validate-external-impact-metrics-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --body-url: string # Base URL of the external impact-metrics source to test. Basic-Auth credentials may be embedded in the URL (e.g. `https://user:pass@metrics.example.com`); they are extracted into an `Authorization` header on outbound requests.
]: any -> record<metrics: list<string>, error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/impact-metrics/external-source/validate")
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Subscribe to email subscription
#
# PUT /api/admin/email-subscription/{subscription}
# operationId: subscribe-email-subscription
export def "admin-email-subscription subscribe-email-subscription" [
  subscription: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/email-subscription/($subscription)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Unsubscribe from email subscription
#
# DELETE /api/admin/email-subscription/{subscription}
# operationId: unsubscribe-email-subscription
export def "admin-email-subscription unsubscribe-email-subscription" [
  subscription: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/email-subscription/($subscription)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get all signal endpoints.
#
# GET /api/admin/signal-endpoints
# operationId: get-signal-endpoints
export def "admin-signal-endpoints get-signal-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<signalEndpoints: table<id: int, enabled: bool, name: string, description: string, createdAt: string, createdByUserId: int, url: string, tokens: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/signal-endpoints")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Create a signal endpoint.
#
# POST /api/admin/signal-endpoints
# operationId: create-signal-endpoint
export def "admin-signal-endpoints create-signal-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --enabled: string@bool-completer # Whether the signal endpoint is currently enabled. If not specified, defaults to true.
  name: string # The signal endpoint name. Must be URL-safe.
  --description: string # A more detailed description of the signal endpoint and its intended use. (nullable)
]: any -> record<id: int, enabled: bool, name: string, description: string, createdAt: string, createdByUserId: int, url: string, tokens: table<id: int, token: string, name: string, signalEndpointId: int, createdAt: string, createdByUserId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/signal-endpoints")
  let body = {enabled: $enabled, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Update a signal endpoint.
#
# PUT /api/admin/signal-endpoints/{id}
# operationId: update-signal-endpoint
export def "admin-signal-endpoints update-signal-endpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --enabled: string@bool-completer # Whether the signal endpoint is currently enabled. If not specified, defaults to true.
  name: string # The signal endpoint name. Must be URL-safe.
  --description: string # A more detailed description of the signal endpoint and its intended use. (nullable)
]: any -> record<id: int, enabled: bool, name: string, description: string, createdAt: string, createdByUserId: int, url: string, tokens: table<id: int, token: string, name: string, signalEndpointId: int, createdAt: string, createdByUserId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/signal-endpoints/($id)")
  let body = {enabled: $enabled, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Delete a signal endpoint.
#
# DELETE /api/admin/signal-endpoints/{id}
# operationId: delete-signal-endpoint
export def "admin-signal-endpoints delete-signal-endpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/signal-endpoints/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Enables a signal endpoint.
#
# POST /api/admin/signal-endpoints/{id}/on
# operationId: enable-signal-endpoint
export def "admin-signal-endpoints-on enable-signal-endpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<id: int, enabled: bool, name: string, description: string, createdAt: string, createdByUserId: int, url: string, tokens: table<id: int, token: string, name: string, signalEndpointId: int, createdAt: string, createdByUserId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/signal-endpoints/($id)/on")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Disables a signal endpoint.
#
# POST /api/admin/signal-endpoints/{id}/off
# operationId: disable-signal-endpoint
export def "admin-signal-endpoints-off disable-signal-endpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<id: int, enabled: bool, name: string, description: string, createdAt: string, createdByUserId: int, url: string, tokens: table<id: int, token: string, name: string, signalEndpointId: int, createdAt: string, createdByUserId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/signal-endpoints/($id)/off")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get all signal endpoint tokens for a specific signal endpoint.
#
# GET /api/admin/signal-endpoints/{signalEndpointId}/tokens
# operationId: get-signal-endpoint-tokens
export def "admin-signal-endpoints-tokens get-signal-endpoint-tokens" [
  signalEndpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<signalEndpointTokens: table<id: int, token: string, name: string, signalEndpointId: int, createdAt: string, createdByUserId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/signal-endpoints/($signalEndpointId)/tokens")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Create a signal endpoint token for a specific signal endpoint.
#
# POST /api/admin/signal-endpoints/{signalEndpointId}/tokens
# operationId: create-signal-endpoint-token
export def "admin-signal-endpoints-tokens create-signal-endpoint-token" [
  signalEndpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  name: string # The signal endpoint token name.
]: any -> record<id: int, token: string, name: string, signalEndpointId: int, createdAt: string, createdByUserId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/signal-endpoints/($signalEndpointId)/tokens")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Update a signal endpoint token.
#
# PUT /api/admin/signal-endpoints/{signalEndpointId}/tokens/{id}
# operationId: update-signal-endpoint-token
export def "admin-signal-endpoints-tokens update-signal-endpoint-token" [
  signalEndpointId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  name: string # The signal endpoint token name.
]: any -> record<id: int, token: string, name: string, signalEndpointId: int, createdAt: string, createdByUserId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/signal-endpoints/($signalEndpointId)/tokens/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Delete a signal endpoint token.
#
# DELETE /api/admin/signal-endpoints/{signalEndpointId}/tokens/{id}
# operationId: delete-signal-endpoint-token
export def "admin-signal-endpoints-tokens delete-signal-endpoint-token" [
  signalEndpointId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/signal-endpoints/($signalEndpointId)/tokens/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get signals originated from a specific signal endpoint.
#
# GET /api/admin/signal-endpoints/{signalEndpointId}/signals
# operationId: get-signal-endpoint-signals
export def "admin-signal-endpoints-signals get-signal-endpoint-signals" [
  signalEndpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # The number of results to return in a page. By default it is set to 50.
  --offset: string # The number of results to skip when returning a page. By default it is set to 0.
  --Authorization: string # API key needed to access this API
]: nothing -> record<signalEndpointSignals: table<id: int, payload: record, createdAt: string, source: string, sourceId: int, tokenName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/admin/signal-endpoints/($signalEndpointId)/signals" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Call a signal endpoint.
#
# POST /api/signal-endpoint/{name}
# operationId: call-signal-endpoint
export def "signal-endpoint call-signal-endpoint" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/signal-endpoint/($name)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get all signals that match the query parameter criteria.
#
# GET /api/admin/signals
# operationId: get-signals
export def "admin-signals get-signals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # The starting date of the creation date range in IS:yyyy-MM-dd format
  --qp-to: string # The ending date of the creation date range in IS:yyyy-MM-dd format
  --offset: string # The number of features to skip when returning a page. By default it is set to 0. (default: 0)
  --limit: string # The number of feature environments to return in a page. By default it is set to 50. The maximum is 1000. (default: 50)
  --Authorization: string # API key needed to access this API
]: nothing -> record<signals: table<id: int, payload: record, createdAt: string, source: string, sourceId: int, tokenName: string, sourceName: string, sourceDescription: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/admin/signals" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive project
#
# POST /api/admin/projects/archive/{projectId}
# operationId: archive-project
export def "admin-projects-archive archive-project" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/archive/($projectId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revive project
#
# POST /api/admin/projects/revive/{projectId}
# operationId: revive-project
export def "admin-projects-revive revive-project" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/revive/($projectId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] List action sets.
#
# GET /api/admin/projects/{projectId}/actions
# operationId: get-actions
export def "admin-projects-actions get-actions" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<actions: table<id: int, project: string, createdAt: string, createdByUserId: int, name: string, description: string, actorId: int, enabled: bool, actions: list, match: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/actions")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Create an action set.
#
# POST /api/admin/projects/{projectId}/actions
# operationId: create-actions
# --actions item shape: {action: string, sortOrder: int, executionParams?: record}
# --match shape: {source: "signal-endpoint", sourceId: float, payload: record}
export def "admin-projects-actions create-actions" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  name: string # The name of the action set
  --description: string # The description of the action set (nullable)
  actorId: int # The id of the service account that will execute the action
  --enabled: string@bool-completer # Whether this action set is enabled or not (default: true)
  actions: list # The list of actions to execute in sequential order when the action set is triggered — item shape: {action: string, sortOrder: int, executionParams?: record}
  --body-match: record # Defines a matching rule for the signal that will trigger the action set — shape: {source: "signal-endpoint", sourceId: float, payload: record}
]: any -> record<id: int, project: string, createdAt: string, createdByUserId: int, name: string, description: string, actorId: int, enabled: bool, actions: table<id: int, createdAt: string, createdByUserId: int, action: string, sortOrder: int, executionParams: record>, match: record<source: string, sourceId: float, payload: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/actions")
  let body = {name: $name, description: $description, actorId: $actorId, enabled: $enabled, actions: $actions, match: $body_match} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Update an action set.
#
# PUT /api/admin/projects/{projectId}/actions/{id}
# operationId: update-actions
# --actions item shape: {action: string, sortOrder: int, executionParams?: record}
# --match shape: {source: "signal-endpoint", sourceId: float, payload: record}
export def "admin-projects-actions update-actions" [
  projectId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  name: string # The name of the action set
  --description: string # The description of the action set (nullable)
  actorId: int # The id of the service account that will execute the action
  --enabled: string@bool-completer # Whether this action set is enabled or not (default: true)
  actions: list # The list of actions to execute in sequential order when the action set is triggered — item shape: {action: string, sortOrder: int, executionParams?: record}
  --body-match: record # Defines a matching rule for the signal that will trigger the action set — shape: {source: "signal-endpoint", sourceId: float, payload: record}
]: any -> record<id: int, project: string, createdAt: string, createdByUserId: int, name: string, description: string, actorId: int, enabled: bool, actions: table<id: int, createdAt: string, createdByUserId: int, action: string, sortOrder: int, executionParams: record>, match: record<source: string, sourceId: float, payload: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/actions/($id)")
  let body = {name: $name, description: $description, actorId: $actorId, enabled: $enabled, actions: $actions, match: $body_match} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Delete an action set.
#
# DELETE /api/admin/projects/{projectId}/actions/{id}
# operationId: delete-actions
export def "admin-projects-actions delete-actions" [
  projectId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/actions/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Enables an action set.
#
# POST /api/admin/projects/{projectId}/actions/{id}/on
# operationId: enable-actions
export def "admin-projects-actions-on enable-actions" [
  projectId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<id: int, project: string, createdAt: string, createdByUserId: int, name: string, description: string, actorId: int, enabled: bool, actions: table<id: int, createdAt: string, createdByUserId: int, action: string, sortOrder: int, executionParams: record>, match: record<source: string, sourceId: float, payload: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/actions/($id)/on")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Disables an action set.
#
# POST /api/admin/projects/{projectId}/actions/{id}/off
# operationId: disable-actions
export def "admin-projects-actions-off disable-actions" [
  projectId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<id: int, project: string, createdAt: string, createdByUserId: int, name: string, description: string, actorId: int, enabled: bool, actions: table<id: int, createdAt: string, createdByUserId: int, action: string, sortOrder: int, executionParams: record>, match: record<source: string, sourceId: float, payload: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/actions/($id)/off")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get action events for a specific action set.
#
# GET /api/admin/projects/{projectId}/actions/{id}/events
# operationId: get-actions-events
export def "admin-projects-actions-events get-actions-events" [
  projectId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # The number of results to return in a page. By default it is set to 50.
  --offset: string # The number of results to skip when returning a page. By default it is set to 0.
  --Authorization: string # API key needed to access this API
]: nothing -> record<actionSetEvents: table<id: int, actionSetId: int, signalId: int, createdAt: string, state: string, signal: record, actionSet: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/actions/($id)/events" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Configuration for the actions UI.
#
# GET /api/admin/projects/{projectId}/actions/config
# operationId: get-actions-config
export def "admin-projects-actions-config get-actions-config" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<TOGGLE_FEATURE_ON: record<label: string, description: string, category: string, permissions: list<string>, parameters: list<record>>, TOGGLE_FEATURE_OFF: record<label: string, description: string, category: string, permissions: list<string>, parameters: list<record>>, TOGGLE_FEATURES_ON_BY_TAG: record<label: string, description: string, category: string, permissions: list<string>, parameters: list<record>>, TOGGLE_FEATURES_OFF_BY_TAG: record<label: string, description: string, category: string, permissions: list<string>, parameters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/actions/config")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project status
#
# GET /api/admin/projects/{projectId}/status
# operationId: get-project-status
export def "admin-projects-status get-project-status" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<activityCountByDate: table<date: string, count: int>, health: record<current: int>, technicalDebt: record<current: int>, resources: record<apiTokens: int, members: int, segments: int>, staleFlags: record<total: int>, lifecycleSummary: record<initial: record<averageDays: float, currentFlags: int>, preLive: record<averageDays: float, currentFlags: int>, live: record<averageDays: float, currentFlags: int>, completed: record<averageDays: float, currentFlags: int>, archived: record<currentFlags: int, last30Days: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/status")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get personal dashboard
#
# GET /api/admin/personal-dashboard
# operationId: get-personal-dashboard
export def "admin-personal-dashboard get-personal-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<admins: table<id: int, name: string, username: string, imageUrl: string, email: string>, projectOwners: table<ownerType: string, name: string, imageUrl: string, email: string>, projects: table<id: string, name: string, health: int, technicalDebt: int, memberCount: int, featureCount: int>, flags: table<name: string, project: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/personal-dashboard")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get personal project details
#
# GET /api/admin/personal-dashboard/{projectId}
# operationId: get-personal-dashboard-project-details
export def "admin-personal-dashboard get-personal-dashboard-project-details" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<insights: record<avgHealthCurrentWindow: int, avgHealthPastWindow: int, totalFlags: int, activeFlags: int, staleFlags: int, potentiallyStaleFlags: int, health: int, technicalDebt: int>, onboardingStatus: any, latestEvents: table<id: int, summary: string, createdBy: string, createdByImageUrl: string, createdAt: string>, owners: any, roles: table<name: string, id: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/personal-dashboard/($projectId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Get strategies that use a context field
#
# GET /api/admin/projects/{projectId}/context/{contextField}/strategies
# operationId: get-strategies-by-context-field-for-project
export def "admin-projects-context-strategies get-strategies-by-context-field-for-project" [
  projectId: string
  contextField: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<strategies: table<id: string, featureName: string, projectId: string, environment: string, strategyName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/context/($contextField)/strategies")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Heartbeat for Enterprise Edge instances.
#
# POST /api/client/edge-licensing/heartbeat
# operationId: edge-instance-heartbeat
export def "client-edge-licensing-heartbeat edge-instance-heartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<edgeLicenseState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client/edge-licensing/heartbeat")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Connect to the streaming API.
#
# GET /api/client/streaming
# operationId: connect
export def "client-streaming connect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/client/streaming")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Disconnect all clients.
#
# POST /api/admin/streaming/disconnect-all
# operationId: disconnect-all
export def "admin-streaming-disconnect-all disconnect-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/streaming/disconnect-all")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get or create valid tokens for the requested environment
#
# POST /edge/issue-token
# operationId: edge-create-or-return-tokens
# --tokens item shape: {environment: string, projects: list}
export def "edge-issue-token edge-create-or-return-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tokens: list # A list of requested api tokens. — item shape: {environment: string, projects: list}
]: any -> record<tokens: table<projects: list, environment: string, type: string, token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/edge/issue-token")
  let body = {tokens: $tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves all licensed users data.
#
# GET /api/admin/licensed-users
# operationId: get-all-licensed-users
export def "admin-licensed-users get-all-licensed-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<seatCount: int, licensedUsers: record<history: list<record>, current: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/licensed-users")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all pending user access requests.
#
# GET /api/admin/user-access-requests
# operationId: get-user-access-requests
export def "admin-user-access-requests get-user-access-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<userAccessRequests: table<id: string, email: string, requestedAt: string, imageUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/user-access-requests")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Approve a user access request.
#
# POST /api/admin/user-access-requests/{id}/approve
# operationId: approve-user-access-request
export def "admin-user-access-requests-approve approve-user-access-request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  rootRole: int # The ID of the root role to assign to the new user.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/user-access-requests/($id)/approve")
  let body = {rootRole: $rootRole} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reject a user access request.
#
# DELETE /api/admin/user-access-requests/{id}
# operationId: reject-user-access-request
export def "admin-user-access-requests reject-user-access-request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/user-access-requests/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of change requests you can do something with
#
# GET /api/admin/projects/{projectId}/change-requests/actionable
# operationId: get-actionable-change-requests
export def "admin-projects-change-requests-actionable get-actionable-change-requests" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($projectId)/change-requests/actionable")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Create or update a milestone progression
#
# PUT /api/admin/projects/{project}/features/{featureName}/environments/{environment}/progressions/{id}
# operationId: change-milestone-progression
# --transitionCondition shape: {intervalMinutes: int}
export def "admin-projects-features-environments-progressions change-milestone-progression" [
  project: string
  featureName: string
  environment: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  targetMilestone: string # The ID of the target milestone
  transitionCondition: record # A transition condition for milestone progression — shape: {intervalMinutes: int}
]: any -> record<sourceMilestone: string, targetMilestone: string, transitionCondition: record<intervalMinutes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($project)/features/($featureName)/environments/($environment)/progressions/($id)")
  let body = {targetMilestone: $targetMilestone, transitionCondition: $transitionCondition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Delete a milestone progression
#
# DELETE /api/admin/projects/{project}/features/{featureName}/environments/{environment}/progressions/{id}
# operationId: delete-milestone-progression
export def "admin-projects-features-environments-progressions delete-milestone-progression" [
  project: string
  featureName: string
  environment: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($project)/features/($featureName)/environments/($environment)/progressions/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Resume paused milestone progressions
#
# POST /api/admin/projects/{project}/features/{featureName}/environments/{environment}/progressions/{planId}/resume
# operationId: resume-milestone-progressions
export def "admin-projects-features-environments-progressions-resume resume-milestone-progressions" [
  project: string
  featureName: string
  environment: string
  planId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($project)/features/($featureName)/environments/($environment)/progressions/($planId)/resume")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [BETA] Change a release plan safeguard
#
# PUT /api/admin/projects/{project}/features/{featureName}/environments/{environment}/release-plans/{planId}/safeguards
# operationId: change-release-plan-safeguard
# --impactMetric shape: {metricName: string, timeRange: "hour"|"day"|"week"|"month", aggregationMode: "rps"|"count"|"avg"|"sum"|"p95"|"p99"|"p50", labelSelectors: record, source?: "internal"|"external"}
# --triggerCondition shape: {operator: ">"|"<", threshold: float}
export def "admin-projects-features-environments-release-plans-safeguards change-release-plan-safeguard" [
  project: string
  featureName: string
  environment: string
  planId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  impactMetric: record # Metric configuration that should be evaluated for the safeguard. — shape: {metricName: string, timeRange: "hour"|"day"|"week"|"month", aggregationMode: "rps"|"count"|"avg"|"sum"|"p95"|"p99"|"p50", labelSelectors: record, source?: "internal"|"external"}
  triggerCondition: record # The condition that triggers the safeguard. — shape: {operator: ">"|"<", threshold: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($project)/features/($featureName)/environments/($environment)/release-plans/($planId)/safeguards")
  let body = {impactMetric: $impactMetric, triggerCondition: $triggerCondition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [BETA] Delete a release plan safeguard
#
# DELETE /api/admin/projects/{project}/features/{featureName}/environments/{environment}/release-plans/{planId}/safeguards/{safeguardId}
# operationId: delete-release-plan-safeguard
export def "admin-projects-features-environments-release-plans-safeguards delete-release-plan-safeguard" [
  project: string
  featureName: string
  environment: string
  planId: string
  safeguardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/admin/projects/($project)/features/($featureName)/environments/($environment)/release-plans/($planId)/safeguards/($safeguardId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get signup data
#
# GET /api/admin/signup
# operationId: get-signup-data
export def "admin-signup get-signup-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
]: nothing -> record<shouldSetPassword: bool, name: string, companyRole: string, companyName: string, companyIsNA: bool, productUpdatesEmailConsent: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/signup")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit signup data.
#
# POST /api/admin/signup
# operationId: submit-signup-data
export def "admin-signup submit-signup-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # API key needed to access this API
  --name: string # The user's name.
  --companyRole: string # The role of the user within the company.
  --companyName: string # The name of the company.
  --companyIsNA: string@bool-completer # Whether the company is based in North America.
  --productUpdatesEmailConsent: string@bool-completer # Whether the user has consented to receive product update emails.
  --password: string # The user's new password.
  --inviteEmails: list # A list of email addresses to invite.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/admin/signup")
  let body = {name: $name, companyRole: $companyRole, companyName: $companyName, companyIsNA: $companyIsNA, productUpdatesEmailConsent: $productUpdatesEmailConsent, password: $password, inviteEmails: $inviteEmails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
