# Auto-generated client for CostManagementClient v2019-04-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/cost-management-costmanagement/2019-04-01-preview/swagger.json
# Auth: --token flag or $env.COSTMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o COSTMANAGEMENTCLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-cost-management-operations list" } } | get name | first)
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

# Lists all of the available consumption REST API operations.
#
# GET /providers/Microsoft.CostManagement/operations
# operationId: Operations_List
export def "providers-microsoft-cost-management-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.CostManagement/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all views by tenant and object.
#
# GET /providers/Microsoft.CostManagement/views
# Docs: https://docs.microsoft.com/en-us/rest/api/costmanagement/
# operationId: Views_List
export def "providers-microsoft-cost-management-views list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.CostManagement/views" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The operation to delete a view.
#
# DELETE /providers/Microsoft.CostManagement/views/{viewName}
# Docs: https://docs.microsoft.com/en-us/rest/api/costmanagement/
# operationId: Views_Delete
export def "providers-microsoft-cost-management-views delete" [
  view_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
]: nothing -> record<error: record<code: string, details: list<record>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({view_name: $view_name} | format pattern "/providers/Microsoft.CostManagement/views/{view_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the view by view name.
#
# GET /providers/Microsoft.CostManagement/views/{viewName}
# Docs: https://docs.microsoft.com/en-us/rest/api/costmanagement/
# operationId: Views_Get
export def "providers-microsoft-cost-management-views get" [
  view_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
]: nothing -> record<properties: record<accumulated: string, chart: string, createdOn: string, displayName: string, kpis: list<record>, metric: string, modifiedOn: string, pivots: list<record>, query: record<dataset: record, timePeriod: record, timeframe: string, type: string>, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({view_name: $view_name} | format pattern "/providers/Microsoft.CostManagement/views/{view_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The operation to create or update a view. Update operation requires latest eTag to be set in the request. You may obtain the latest eTag by performing a get operation. Create operation does not require eTag.
#
# PUT /providers/Microsoft.CostManagement/views/{viewName}
# Docs: https://docs.microsoft.com/en-us/rest/api/costmanagement/
# operationId: Views_CreateOrUpdate
# --properties shape: {accumulated?: "true"|"false", chart?: "Area"|"Line"|"StackedColumn"|"GroupedColumn"|"Table", displayName?: string, kpis?: list, metric?: "ActualCost"|"AmortizedCost"|"AHUB", pivots?: list, query?: any, scope?: string}
export def "providers-microsoft-cost-management-views create-or-update-by-viewName" [
  view_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
  --properties: record # The properties of the view. — shape: {accumulated?: "true"|"false", chart?: "Area"|"Line"|"StackedColumn"|"GroupedColumn"|"Table", displayName?: string, kpis?: list, metric?: "ActualCost"|"AmortizedCost"|"AHUB", pivots?: list, query?: any, scope?: string}
  --e-tag: string # eTag of the resource. To handle concurrent update scenario, this field will be used to determine whether the user is updating the latest version or not.
]: any -> record<properties: record<accumulated: string, chart: string, createdOn: string, displayName: string, kpis: list<record>, metric: string, modifiedOn: string, pivots: list<record>, query: record<dataset: record, timePeriod: record, timeframe: string, type: string>, scope: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({view_name: $view_name} | format pattern "/providers/Microsoft.CostManagement/views/{view_name}") $qp)
  let body = {"properties": $properties, "eTag": $e_tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all budgets for the defined scope.
#
# GET /{scope}/providers/Microsoft.CostManagement/budgets
# Docs: https://docs.microsoft.com/en-us/rest/api/cost-management/
# operationId: Budgets_List
export def "providers-microsoft-cost-management-budgets list" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
]: nothing -> record<nextLink: string, value: table<properties: record, eTag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: $scope} | format pattern "/{scope}/providers/Microsoft.CostManagement/budgets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The operation to delete a budget.
#
# DELETE /{scope}/providers/Microsoft.CostManagement/budgets/{budgetName}
# Docs: https://docs.microsoft.com/en-us/rest/api/cost-management/
# operationId: Budget_Delete
export def "providers-microsoft-cost-management-budgets delete" [
  scope: string
  budget_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
]: nothing -> record<error: record<code: string, details: list<record>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: $scope, budget_name: $budget_name} | format pattern "/{scope}/providers/Microsoft.CostManagement/budgets/{budget_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the budget for the scope by budget name.
#
# GET /{scope}/providers/Microsoft.CostManagement/budgets/{budgetName}
# Docs: https://docs.microsoft.com/en-us/rest/api/cost-management/
# operationId: Budget_Get
export def "providers-microsoft-cost-management-budgets get" [
  scope: string
  budget_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
]: nothing -> record<properties: record<amount: float, category: string, currentSpend: record<amount: float, unit: string>, filter: record<and: list, dimension: record, not: any, or: list, tag: record>, notifications: record, timeGrain: string, timePeriod: record<endDate: string, startDate: string>>, eTag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: $scope, budget_name: $budget_name} | format pattern "/{scope}/providers/Microsoft.CostManagement/budgets/{budget_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The operation to create or update a budget. Update operation requires latest eTag to be set in the request mandatorily. You may obtain the latest eTag by performing a get operation. Create operation does not require eTag.
#
# PUT /{scope}/providers/Microsoft.CostManagement/budgets/{budgetName}
# Docs: https://docs.microsoft.com/en-us/rest/api/cost-management/
# operationId: Budget_CreateOrUpdate
# --properties shape: {amount: float, category: "Cost"|"Usage", currentSpend?: any, filter?: any, notifications?: record, timeGrain: "Monthly"|"Quarterly"|"Annually", timePeriod: any}
export def "providers-microsoft-cost-management-budgets create-or-update" [
  scope: string
  budget_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
  --properties: any # The properties of the budget. — shape: {amount: float, category: "Cost"|"Usage", currentSpend?: any, filter?: any, notifications?: record, timeGrain: "Monthly"|"Quarterly"|"Annually", timePeriod: any}
  --e-tag: string # eTag of the resource. To handle concurrent update scenario, this field will be used to determine whether the user is updating the latest version or not.
]: any -> record<properties: record<amount: float, category: string, currentSpend: record<amount: float, unit: string>, filter: record<and: list, dimension: record, not: any, or: list, tag: record>, notifications: record, timeGrain: string, timePeriod: record<endDate: string, startDate: string>>, eTag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: $scope, budget_name: $budget_name} | format pattern "/{scope}/providers/Microsoft.CostManagement/budgets/{budget_name}") $qp)
  let body = {"properties": $properties, "eTag": $e_tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all views at the given scope.
#
# GET /{scope}/providers/Microsoft.CostManagement/views
# Docs: https://docs.microsoft.com/en-us/rest/api/costmanagement/
# operationId: Views_ListByScope
export def "providers-microsoft-cost-management-views list-by" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: $scope} | format pattern "/{scope}/providers/Microsoft.CostManagement/views") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The operation to delete a view.
#
# DELETE /{scope}/providers/Microsoft.CostManagement/views/{viewName}
# Docs: https://docs.microsoft.com/en-us/rest/api/costmanagement/
# operationId: Views_DeleteByScope
export def "providers-microsoft-cost-management-views delete-by" [
  scope: string
  view_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
]: nothing -> record<error: record<code: string, details: list<record>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: $scope, view_name: $view_name} | format pattern "/{scope}/providers/Microsoft.CostManagement/views/{view_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the view for the defined scope by view name.
#
# GET /{scope}/providers/Microsoft.CostManagement/views/{viewName}
# Docs: https://docs.microsoft.com/en-us/rest/api/costmanagement/
# operationId: Views_GetByScope
export def "providers-microsoft-cost-management-views get-by" [
  scope: string
  view_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
]: nothing -> record<properties: record<accumulated: string, chart: string, createdOn: string, displayName: string, kpis: list<record>, metric: string, modifiedOn: string, pivots: list<record>, query: record<dataset: record, timePeriod: record, timeframe: string, type: string>, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: $scope, view_name: $view_name} | format pattern "/{scope}/providers/Microsoft.CostManagement/views/{view_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The operation to create or update a view. Update operation requires latest eTag to be set in the request. You may obtain the latest eTag by performing a get operation. Create operation does not require eTag.
#
# PUT /{scope}/providers/Microsoft.CostManagement/views/{viewName}
# Docs: https://docs.microsoft.com/en-us/rest/api/costmanagement/
# operationId: Views_CreateOrUpdateByScope
# --properties shape: {accumulated?: "true"|"false", chart?: "Area"|"Line"|"StackedColumn"|"GroupedColumn"|"Table", displayName?: string, kpis?: list, metric?: "ActualCost"|"AmortizedCost"|"AHUB", pivots?: list, query?: any, scope?: string}
export def "providers-microsoft-cost-management-views create-or-update-by-scope-viewName" [
  scope: string
  view_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-04-01-preview
  --properties: record # The properties of the view. — shape: {accumulated?: "true"|"false", chart?: "Area"|"Line"|"StackedColumn"|"GroupedColumn"|"Table", displayName?: string, kpis?: list, metric?: "ActualCost"|"AmortizedCost"|"AHUB", pivots?: list, query?: any, scope?: string}
  --e-tag: string # eTag of the resource. To handle concurrent update scenario, this field will be used to determine whether the user is updating the latest version or not.
]: any -> record<properties: record<accumulated: string, chart: string, createdOn: string, displayName: string, kpis: list<record>, metric: string, modifiedOn: string, pivots: list<record>, query: record<dataset: record, timePeriod: record, timeframe: string, type: string>, scope: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: $scope, view_name: $view_name} | format pattern "/{scope}/providers/Microsoft.CostManagement/views/{view_name}") $qp)
  let body = {"properties": $properties, "eTag": $e_tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
