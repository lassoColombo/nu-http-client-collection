# Auto-generated client for Azure Migrate Hub v2018-09-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/migrateprojects-migrate/2018-09-01-preview/swagger.json
# Auth: --token flag or $env.AZURE_MIGRATE_HUB_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AZURE_MIGRATE_HUB_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def api-version-completer [] { ["2018-09-01-preview"] }
def goal-completer [] { ["Databases" "Servers"] }
def tool-completer [] { ["Carbonite" "Cloudamize" "CorentTech" "DataMigrationAssistant" "DatabaseMigrationService" "ServerAssessment" "ServerAssessmentV1" "ServerDiscovery" "ServerMigration" "ServerMigration_Replication" "Turbonomic" "Zerto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-migrate-operations list" } } | get name | first)
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

# Get list of operations supported in the API.
#
# GET /providers/Microsoft.Migrate/operations
# operationId: Operations_List
export def "providers-microsoft-migrate-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: table<display: record, name: string, origin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/providers/Microsoft.Migrate/operations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete the migrate project
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}
# operationId: MigrateProjects_DeleteMigrateProject
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects delete" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Method to get a migrate project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}
# operationId: MigrateProjects_GetMigrateProject
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects get" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
]: nothing -> record<eTag: string, id: string, location: string, name: string, properties: record<lastSummaryRefreshedTime: string, provisioningState: string, refreshSummaryState: string, registeredTools: list<string>, summary: record>, tags: record<additionalProperties: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Update migrate project.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}
# operationId: MigrateProjects_PatchMigrateProject
# --properties shape: {provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded", registeredTools?: list<string>}
# --tags shape: {additionalProperties?: string}
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects update-by-subscription-id-resource-group-name-migrate-project-name" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
  --e-tag: string # Gets or sets the eTag for concurrency control.
  --location: string # Gets or sets the Azure location in which migrate project is created.
  --properties: record # Class for migrate project properties. — shape: {provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded", registeredTools?: list<string>}
  --tags: record # Gets or sets the tags. — shape: {additionalProperties?: string}
]: any -> record<eTag: string, id: string, location: string, name: string, properties: record<lastSummaryRefreshedTime: string, provisioningState: string, refreshSummaryState: string, registeredTools: list<string>, summary: record>, tags: record<additionalProperties: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}") $qp)
  let req_body = {"eTag": $e_tag, "location": $location, "properties": $properties, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Method to create or update a migrate project.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}
# operationId: MigrateProjects_PutMigrateProject
# --properties shape: {provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded", registeredTools?: list<string>}
# --tags shape: {additionalProperties?: string}
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects update-by-subscription-id-resource-group-name-migrate-project-name-1" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
  --e-tag: string # Gets or sets the eTag for concurrency control.
  --location: string # Gets or sets the Azure location in which migrate project is created.
  --properties: record # Class for migrate project properties. — shape: {provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded", registeredTools?: list<string>}
  --tags: record # Gets or sets the tags. — shape: {additionalProperties?: string}
]: any -> record<eTag: string, id: string, location: string, name: string, properties: record<lastSummaryRefreshedTime: string, provisioningState: string, refreshSummaryState: string, registeredTools: list<string>, summary: record>, tags: record<additionalProperties: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}") $qp)
  let req_body = {"eTag": $e_tag, "location": $location, "properties": $properties, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets a list of database instances in the migrate project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/databaseInstances
# operationId: DatabaseInstances_EnumerateDatabaseInstances
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-database-instances get-enumerate" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --continuation-token: string # The continuation token.
  --page-size: int # The number of items to be returned in a single page. This value is honored only if it is less than the 100.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "continuationToken" $continuation_token "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/databaseInstances") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "continuationToken": $continuation_token, "pageSize": $page_size} | compact), body: null}
}

# Gets a database instance in the migrate project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/databaseInstances/{databaseInstanceName}
# operationId: DatabaseInstances_GetDatabaseInstance
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-database-instances get" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  database_instance_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<id: string, name: string, properties: record<discoveryData: list<record>, lastUpdatedTime: string, summary: record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  if ($database_instance_name | is-empty) { error make --unspanned { msg: "path parameter 'databaseInstanceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name), database_instance_name: (encode-path-segment $database_instance_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/databaseInstances/{database_instance_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a list of databases in the migrate project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/databases
# operationId: Databases_EnumerateDatabases
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-databases get-enumerate" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --continuation-token: string # The continuation token.
  --page-size: int # The number of items to be returned in a single page. This value is honored only if it is less than the 100.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "continuationToken" $continuation_token "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/databases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "continuationToken": $continuation_token, "pageSize": $page_size} | compact), body: null}
}

# Gets a database in the migrate project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/databases/{databaseName}
# operationId: Databases_GetDatabase
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-databases get" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<id: string, name: string, properties: record<assessmentData: list<record>, lastUpdatedTime: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  if ($database_name | is-empty) { error make --unspanned { msg: "path parameter 'databaseName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name), database_name: (encode-path-segment $database_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/databases/{database_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a list of machines in the migrate project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/machines
# operationId: Machines_EnumerateMachines
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-machines get-enumerate" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --continuation-token: string # The continuation token.
  --page-size: int # The number of items to be returned in a single page. This value is honored only if it is less than the 100.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "continuationToken" $continuation_token "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/machines") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "continuationToken": $continuation_token, "pageSize": $page_size} | compact), body: null}
}

# Gets a machine in the migrate project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/machines/{machineName}
# operationId: Machines_GetMachine
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-machines get" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
]: nothing -> record<id: string, name: string, properties: record<assessmentData: list<record>, discoveryData: list<record>, lastUpdatedTime: string, migrationData: list<record>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/machines/{machine_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a list of events in the migrate project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/migrateEvents
# operationId: Events_EnumerateEvents
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-migrate-events get-enumerate" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --continuation-token: string # The continuation token.
  --page-size: int # The number of items to be returned in a single page. This value is honored only if it is less than the 100.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "continuationToken" $continuation_token "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/migrateEvents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "continuationToken": $continuation_token, "pageSize": $page_size} | compact), body: null}
}

# Delete the migrate event
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/migrateEvents/{eventName}
# operationId: Events_DeleteEvent
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-migrate-events delete" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'eventName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name), event_name: (encode-path-segment $event_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/migrateEvents/{event_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets an event in the migrate project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/migrateEvents/{eventName}
# operationId: Events_GetEvent
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-migrate-events get" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
]: nothing -> record<id: string, name: string, properties: record<clientRequestId: string, errorCode: string, errorMessage: string, instanceType: string, possibleCauses: string, recommendation: string, solution: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'eventName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name), event_name: (encode-path-segment $event_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/migrateEvents/{event_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Refresh the summary of the migrate project.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/refreshSummary
# operationId: MigrateProjects_RefreshMigrateProjectSummary
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-refresh-summary refresh" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --goal: string@goal-completer # Gets or sets the goal for which summary needs to be refreshed.
]: any -> record<isRefreshed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/refreshSummary") $qp)
  let req_body = {"goal": $goal} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Registers a tool with the migrate project.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/registerTool
# operationId: MigrateProjects_RegisterTool
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-register-tool create" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
  --tool: string@tool-completer # Gets or sets the tool to be registered.
]: any -> record<isRegistered: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/registerTool") $qp)
  let req_body = {"tool": $tool} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of solutions in the migrate project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/solutions
# operationId: Solutions_EnumerateSolutions
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-solutions get-enumerate" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
]: nothing -> record<nextLink: string, value: table<etag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/solutions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Delete the solution
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/solutions/{solutionName}
# operationId: Solutions_DeleteSolution
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-solutions delete" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  solution_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --accept-language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  if ($solution_name | is-empty) { error make --unspanned { msg: "path parameter 'solutionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name), solution_name: (encode-path-segment $solution_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/solutions/{solution_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a solution in the migrate project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/solutions/{solutionName}
# operationId: Solutions_GetSolution
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-solutions get" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  solution_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
]: nothing -> record<etag: string, id: string, name: string, properties: record<cleanupState: string, details: record<assessmentCount: int, extendedDetails: record, groupCount: int>, goal: string, purpose: string, status: string, summary: record<instanceType: string>, tool: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  if ($solution_name | is-empty) { error make --unspanned { msg: "path parameter 'solutionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name), solution_name: (encode-path-segment $solution_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/solutions/{solution_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Update solution.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/solutions/{solutionName}
# operationId: Solutions_PatchSolution
# --properties shape: {cleanupState?: "None"|"Started"|"InProgress"|"Completed"|"Failed", details?: record, goal?: "Servers"|"Databases", purpose?: "Discovery"|"Assessment"|"Migration", status?: "Inactive"|"Active", summary?: record, tool?: "ServerDiscovery"|"ServerAssessment"|"ServerMigration"|"Cloudamize"|"Turbonomic"|"Zerto"|"CorentTech"|"ServerAssessmentV1"|"ServerMigration_Replication"|"Carbonite"|"DataMigrationAssistant"|"DatabaseMigrationService"}
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-solutions update-by-subscription-id-resource-group-name-migrate-project-name-solution-name" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  solution_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --etag: string # Gets or sets the ETAG for optimistic concurrency control.
  --properties: record # Class for solution properties. — shape: {cleanupState?: "None"|"Started"|"InProgress"|"Completed"|"Failed", details?: record, goal?: "Servers"|"Databases", purpose?: "Discovery"|"Assessment"|"Migration", status?: "Inactive"|"Active", summary?: record, tool?: "ServerDiscovery"|"ServerAssessment"|"ServerMigration"|"Cloudamize"|"Turbonomic"|"Zerto"|"CorentTech"|"ServerAssessmentV1"|"ServerMigration_Replication"|"Carbonite"|"DataMigrationAssistant"|"DatabaseMigrationService"}
]: any -> record<etag: string, id: string, name: string, properties: record<cleanupState: string, details: record<assessmentCount: int, extendedDetails: record, groupCount: int>, goal: string, purpose: string, status: string, summary: record<instanceType: string>, tool: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  if ($solution_name | is-empty) { error make --unspanned { msg: "path parameter 'solutionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name), solution_name: (encode-path-segment $solution_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/solutions/{solution_name}") $qp)
  let req_body = {"etag": $etag, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a solution in the migrate project.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/solutions/{solutionName}
# operationId: Solutions_PutSolution
# --properties shape: {cleanupState?: "None"|"Started"|"InProgress"|"Completed"|"Failed", details?: record, goal?: "Servers"|"Databases", purpose?: "Discovery"|"Assessment"|"Migration", status?: "Inactive"|"Active", summary?: record, tool?: "ServerDiscovery"|"ServerAssessment"|"ServerMigration"|"Cloudamize"|"Turbonomic"|"Zerto"|"CorentTech"|"ServerAssessmentV1"|"ServerMigration_Replication"|"Carbonite"|"DataMigrationAssistant"|"DatabaseMigrationService"}
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-solutions update-by-subscription-id-resource-group-name-migrate-project-name-solution-name-1" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  solution_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --etag: string # Gets or sets the ETAG for optimistic concurrency control.
  --properties: record # Class for solution properties. — shape: {cleanupState?: "None"|"Started"|"InProgress"|"Completed"|"Failed", details?: record, goal?: "Servers"|"Databases", purpose?: "Discovery"|"Assessment"|"Migration", status?: "Inactive"|"Active", summary?: record, tool?: "ServerDiscovery"|"ServerAssessment"|"ServerMigration"|"Cloudamize"|"Turbonomic"|"Zerto"|"CorentTech"|"ServerAssessmentV1"|"ServerMigration_Replication"|"Carbonite"|"DataMigrationAssistant"|"DatabaseMigrationService"}
]: any -> record<etag: string, id: string, name: string, properties: record<cleanupState: string, details: record<assessmentCount: int, extendedDetails: record, groupCount: int>, goal: string, purpose: string, status: string, summary: record<instanceType: string>, tool: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  if ($solution_name | is-empty) { error make --unspanned { msg: "path parameter 'solutionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name), solution_name: (encode-path-segment $solution_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/solutions/{solution_name}") $qp)
  let req_body = {"etag": $etag, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Cleanup the solution data in the migrate project.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/solutions/{solutionName}/cleanupData
# operationId: Solutions_CleanupSolutionData
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-solutions-cleanup-data create" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  solution_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  if ($solution_name | is-empty) { error make --unspanned { msg: "path parameter 'solutionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name), solution_name: (encode-path-segment $solution_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/solutions/{solution_name}/cleanupData") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the config for the solution in the migrate project.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/migrateProjects/{migrateProjectName}/solutions/{solutionName}/getConfig
# operationId: Solutions_GetConfig
export def "subscriptions-resource-groups-providers-microsoft-migrate-migrate-projects-solutions-get-config get" [
  subscription_id: string
  resource_group_name: string
  migrate_project_name: string
  solution_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
]: nothing -> record<publisherSasUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($migrate_project_name | is-empty) { error make --unspanned { msg: "path parameter 'migrateProjectName' must be non-empty" } }
  if ($solution_name | is-empty) { error make --unspanned { msg: "path parameter 'solutionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), migrate_project_name: (encode-path-segment $migrate_project_name), solution_name: (encode-path-segment $solution_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Migrate/migrateProjects/{migrate_project_name}/solutions/{solution_name}/getConfig") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}
