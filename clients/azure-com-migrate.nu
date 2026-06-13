# Auto-generated client for Azure Migrate v2018-02-02
# Source: https://api.apis.guru/v2/specs/azure.com/migrate/2018-02-02/swagger.json
# Auth: --token flag or $env.AZURE_MIGRATE_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AZURE_MIGRATE_TOKEN | default "" }
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

# Completers for enum parameters
def api-version-completer [] { ["2018-02-02"] }
def type-completer [] { ["Microsoft.Migrate/projects"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-migrate-operations List" } } | get name | first)
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
export def "providers-microsoft-migrate-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: table<display: record, name: string, origin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/providers/Microsoft.Migrate/operations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the assessment options.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Migrate/locations/{locationName}/assessmentOptions
# operationId: AssessmentOptions_Get
export def "subscriptions-providers-microsoft-migrate-locations-assessment-options Get" [
  subscriptionId: string
  locationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<reservedInstanceVmFamilies: list<string>, vmFamilies: table<category: list, familyName: string, targetLocations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Migrate/locations/($locationName)/assessmentOptions" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether the project name is available in the specified region.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Migrate/locations/{locationName}/checkNameAvailability
# operationId: Location_CheckNameAvailability
export def "subscriptions-providers-microsoft-migrate-locations-check-name-availability CheckNameAvailability" [
  locationName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  name: string # The name to check for availability
  type: string@type-completer # The resource type. Must be set to Microsoft.Migrate/projects
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Migrate/locations/($locationName)/checkNameAvailability" $qp)
  let body = {name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all projects.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Migrate/projects
# operationId: Projects_ListBySubscription
export def "subscriptions-providers-microsoft-migrate-projects ListBySubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, location: string, name: string, properties: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Migrate/projects" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all assessments created in the project.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/assessments
# operationId: Assessments_ListByProject
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-assessments ListByProject" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/assessments" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all groups
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups
# operationId: Groups_ListByProject
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups ListByProject" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/groups" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the group
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}
# operationId: Groups_Delete
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups Delete" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  groupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/groups/($groupName)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}
# operationId: Groups_Get
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups Get" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  groupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<eTag: string, id: string, name: string, properties: record<assessments: list<string>, createdTimestamp: string, machines: list<string>, updatedTimestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/groups/($groupName)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new group with specified settings. If group with the name provided already exists, then the existing group is updated.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}
# operationId: Groups_Create
# --properties shape: {machines: list}
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups Create" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  groupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
  --eTag: string # For optimistic concurrency control.
  properties: record # Properties of group resource. — shape: {machines: list}
]: any -> record<eTag: string, id: string, name: string, properties: record<assessments: list<string>, createdTimestamp: string, machines: list<string>, updatedTimestamp: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/groups/($groupName)" $qp)
  let body = {eTag: $eTag, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all assessments created for the specified group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments
# operationId: Assessments_ListByGroup
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments ListByGroup" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  groupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/groups/($groupName)/assessments" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an assessment from the project.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}
# operationId: Assessments_Delete
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments Delete" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  groupName: string
  assessmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/groups/($groupName)/assessments/($assessmentName)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an assessment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}
# operationId: Assessments_Get
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments Get" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  groupName: string
  assessmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<eTag: string, id: string, name: string, properties: record<azureHybridUseBenefit: string, azureLocation: string, azureOfferCode: string, azurePricingTier: string, azureStorageRedundancy: string, confidenceRatingInPercentage: float, createdTimestamp: string, currency: string, discountPercentage: float, monthlyBandwidthCost: float, monthlyComputeCost: float, monthlyStorageCost: float, numberOfMachines: int, percentile: string, pricesTimestamp: string, scalingFactor: float, sizingCriterion: string, stage: string, status: string, timeRange: string, updatedTimestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/groups/($groupName)/assessments/($assessmentName)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or Update assessment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}
# operationId: Assessments_Create
# --properties shape: {azureHybridUseBenefit: "Unknown"|"Yes"|"No", azureLocation: "Unknown"|"EastAsia"|"SoutheastAsia"|"AustraliaEast"|"AustraliaSoutheast"|"BrazilSouth"|"CanadaCentral"|"CanadaEast"|"WestEurope"|"NorthEurope"|"CentralIndia"|"SouthIndia"|"WestIndia"|"JapanEast"|"JapanWest"|"KoreaCentral"|"KoreaSouth"|"UkWest"|"UkSouth"|"NorthCentralUs"|"EastUs"|"WestUs2"|"SouthCentralUs"|"CentralUs"|"EastUs2"|"WestUs"|"WestCentralUs"|"GermanyCentral"|"GermanyNortheast"|"ChinaNorth"|"ChinaEast", azureOfferCode: "Unknown"|"MSAZR0003P"|"MSAZR0044P"|"MSAZR0059P"|"MSAZR0060P"|"MSAZR0062P"|"MSAZR0063P"|"MSAZR0064P"|"MSAZR0029P"|"MSAZR0022P"|"MSAZR0023P"|"MSAZR0148P"|"MSAZR0025P"|"MSAZR0036P"|"MSAZR0120P"|"MSAZR0121P"|"MSAZR0122P"|"MSAZR0123P"|"MSAZR0124P"|"MSAZR0125P"|"MSAZR0126P"|"MSAZR0127P"|"MSAZR0128P"|"MSAZR0129P"|"MSAZR0130P"|"MSAZR0111P"|"MSAZR0144P"|"MSAZR0149P"|"MSMCAZR0044P"|"MSMCAZR0059P"|"MSMCAZR0060P"|"MSMCAZR0063P"|"MSMCAZR0120P"|"MSMCAZR0121P"|"MSMCAZR0125P"|"MSMCAZR0128P"|"MSAZRDE0003P"|"MSAZRDE0044P", azurePricingTier: "Standard"|"Basic", azureStorageRedundancy: "Unknown"|"LocallyRedundant"|"ZoneRedundant"|"GeoRedundant"|"ReadAccessGeoRedundant", currency: "Unknown"|"USD"|"DKK"|"CAD"|"IDR"|"JPY"|"KRW"|"NZD"|"NOK"|"RUB"|"SAR"|"ZAR"|"SEK"|"TRY"|"GBP"|"MXN"|"MYR"|"INR"|"HKD"|"BRL"|"TWD"|"EUR"|"CHF"|"ARS"|"AUD"|"CNY", discountPercentage: float, percentile: "Percentile50"|"Percentile90"|"Percentile95"|"Percentile99", scalingFactor: float, sizingCriterion: "PerformanceBased"|"AsOnPremises", stage: "InProgress"|"UnderReview"|"Approved", timeRange: "Day"|"Week"|"Month"}
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments Create" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  groupName: string
  assessmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
  --eTag: string # For optimistic concurrency control.
  properties: record # Properties of an assessment. — shape: {azureHybridUseBenefit: "Unknown"|"Yes"|"No", azureLocation: "Unknown"|"EastAsia"|"SoutheastAsia"|"AustraliaEast"|"AustraliaSoutheast"|"BrazilSouth"|"CanadaCentral"|"CanadaEast"|"WestEurope"|"NorthEurope"|"CentralIndia"|"SouthIndia"|"WestIndia"|"JapanEast"|"JapanWest"|"KoreaCentral"|"KoreaSouth"|"UkWest"|"UkSouth"|"NorthCentralUs"|"EastUs"|"WestUs2"|"SouthCentralUs"|"CentralUs"|"EastUs2"|"WestUs"|"WestCentralUs"|"GermanyCentral"|"GermanyNortheast"|"ChinaNorth"|"ChinaEast", azureOfferCode: "Unknown"|"MSAZR0003P"|"MSAZR0044P"|"MSAZR0059P"|"MSAZR0060P"|"MSAZR0062P"|"MSAZR0063P"|"MSAZR0064P"|"MSAZR0029P"|"MSAZR0022P"|"MSAZR0023P"|"MSAZR0148P"|"MSAZR0025P"|"MSAZR0036P"|"MSAZR0120P"|"MSAZR0121P"|"MSAZR0122P"|"MSAZR0123P"|"MSAZR0124P"|"MSAZR0125P"|"MSAZR0126P"|"MSAZR0127P"|"MSAZR0128P"|"MSAZR0129P"|"MSAZR0130P"|"MSAZR0111P"|"MSAZR0144P"|"MSAZR0149P"|"MSMCAZR0044P"|"MSMCAZR0059P"|"MSMCAZR0060P"|"MSMCAZR0063P"|"MSMCAZR0120P"|"MSMCAZR0121P"|"MSMCAZR0125P"|"MSMCAZR0128P"|"MSAZRDE0003P"|"MSAZRDE0044P", azurePricingTier: "Standard"|"Basic", azureStorageRedundancy: "Unknown"|"LocallyRedundant"|"ZoneRedundant"|"GeoRedundant"|"ReadAccessGeoRedundant", currency: "Unknown"|"USD"|"DKK"|"CAD"|"IDR"|"JPY"|"KRW"|"NZD"|"NOK"|"RUB"|"SAR"|"ZAR"|"SEK"|"TRY"|"GBP"|"MXN"|"MYR"|"INR"|"HKD"|"BRL"|"TWD"|"EUR"|"CHF"|"ARS"|"AUD"|"CNY", discountPercentage: float, percentile: "Percentile50"|"Percentile90"|"Percentile95"|"Percentile99", scalingFactor: float, sizingCriterion: "PerformanceBased"|"AsOnPremises", stage: "InProgress"|"UnderReview"|"Approved", timeRange: "Day"|"Week"|"Month"}
]: any -> record<eTag: string, id: string, name: string, properties: record<azureHybridUseBenefit: string, azureLocation: string, azureOfferCode: string, azurePricingTier: string, azureStorageRedundancy: string, confidenceRatingInPercentage: float, createdTimestamp: string, currency: string, discountPercentage: float, monthlyBandwidthCost: float, monthlyComputeCost: float, monthlyStorageCost: float, numberOfMachines: int, percentile: string, pricesTimestamp: string, scalingFactor: float, sizingCriterion: string, stage: string, status: string, timeRange: string, updatedTimestamp: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/groups/($groupName)/assessments/($assessmentName)" $qp)
  let body = {eTag: $eTag, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get assessed machines for assessment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}/assessedMachines
# operationId: AssessedMachines_ListByAssessment
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments-assessed-machines ListByAssessment" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  groupName: string
  assessmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/groups/($groupName)/assessments/($assessmentName)/assessedMachines" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an assessed machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}/assessedMachines/{assessedMachineName}
# operationId: AssessedMachines_Get
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments-assessed-machines Get" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  groupName: string
  assessmentName: string
  assessedMachineName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<eTag: string, id: string, name: string, properties: record<bootType: string, createdTimestamp: string, datacenterContainer: string, datacenterMachineId: string, datacenterManagementServer: string, datacenterManagementServerId: string, description: string, discoveredTimestamp: string, disks: record, displayName: string, groups: list<string>, megabytesOfMemory: float, megabytesOfMemoryForRecommendedSize: float, monthlyBandwidthCost: float, monthlyComputeCostForRecommendedSize: float, monthlyStorageCost: float, networkAdapters: record, numberOfCores: int, numberOfCoresForRecommendedSize: int, operatingSystem: string, percentageCoresUtilization: float, percentageCoresUtilizationDataPointsExpected: int, percentageCoresUtilizationDataPointsReceived: int, percentageMemoryUtilization: float, percentageMemoryUtilizationDataPointsExpected: int, percentageMemoryUtilizationDataPointsReceived: int, recommendedSize: string, suitability: string, suitabilityExplanation: string, updatedTimestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/groups/($groupName)/assessments/($assessmentName)/assessedMachines/($assessedMachineName)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get download URL for the assessment report.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/groups/{groupName}/assessments/{assessmentName}/downloadUrl
# operationId: Assessments_GetReportDownloadUrl
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-groups-assessments-download-url GetReportDownloadUrl" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  groupName: string
  assessmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<assessmentReportUrl: string, expirationTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/groups/($groupName)/assessments/($assessmentName)/downloadUrl" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all machines in the project
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/machines
# operationId: Machines_ListByProject
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-machines ListByProject" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/machines" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/machines/{machineName}
# operationId: Machines_Get
export def "subscriptions-resource-groups-providers-microsoft-migrate-projects-machines Get" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  machineName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<eTag: string, id: string, name: string, properties: record<bootType: string, createdTimestamp: string, datacenterContainer: string, datacenterMachineId: string, datacenterManagementServer: string, datacenterManagementServerId: string, description: string, discoveredTimestamp: string, disks: record, displayName: string, groups: list<string>, megabytesOfMemory: float, networkAdapters: record, numberOfCores: int, operatingSystem: string, updatedTimestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/machines/($machineName)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all projects.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects
# operationId: Projects_ListByResourceGroup
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects ListByResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<value: table<eTag: string, id: string, location: string, name: string, properties: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Migrate/projects" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the project
#
# DELETE /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}
# operationId: Projects_Delete
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects Delete" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the specified project.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}
# operationId: Projects_Get
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects Get" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<eTag: string, id: string, location: string, name: string, properties: record<createdTimestamp: string, customerWorkspaceId: string, customerWorkspaceLocation: string, discoveryStatus: string, lastAssessmentTimestamp: string, lastDiscoverySessionId: string, lastDiscoveryTimestamp: string, numberOfAssessments: int, numberOfGroups: int, numberOfMachines: int, provisioningState: string, updatedTimestamp: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project.
#
# PATCH /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}
# operationId: Projects_Update
# --properties shape: {customerWorkspaceId?: string, customerWorkspaceLocation?: string, provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded"}
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects Update" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
  --eTag: string # For optimistic concurrency control.
  --location: string # Azure location in which project is created.
  --properties: record # Properties of a project. — shape: {customerWorkspaceId?: string, customerWorkspaceLocation?: string, provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded"}
  --tags: record # Tags provided by Azure Tagging service.
]: any -> record<eTag: string, id: string, location: string, name: string, properties: record<createdTimestamp: string, customerWorkspaceId: string, customerWorkspaceLocation: string, discoveryStatus: string, lastAssessmentTimestamp: string, lastDiscoverySessionId: string, lastDiscoveryTimestamp: string, numberOfAssessments: int, numberOfGroups: int, numberOfMachines: int, provisioningState: string, updatedTimestamp: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)" $qp)
  let body = {eTag: $eTag, location: $location, properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or update project.
#
# PUT /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}
# operationId: Projects_Create
# --properties shape: {customerWorkspaceId?: string, customerWorkspaceLocation?: string, provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded"}
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects Create" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
  --eTag: string # For optimistic concurrency control.
  --location: string # Azure location in which project is created.
  --properties: record # Properties of a project. — shape: {customerWorkspaceId?: string, customerWorkspaceLocation?: string, provisioningState?: "Accepted"|"Creating"|"Deleting"|"Failed"|"Moving"|"Succeeded"}
  --tags: record # Tags provided by Azure Tagging service.
]: any -> record<eTag: string, id: string, location: string, name: string, properties: record<createdTimestamp: string, customerWorkspaceId: string, customerWorkspaceLocation: string, discoveryStatus: string, lastAssessmentTimestamp: string, lastDiscoverySessionId: string, lastDiscoveryTimestamp: string, numberOfAssessments: int, numberOfGroups: int, numberOfMachines: int, provisioningState: string, updatedTimestamp: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)" $qp)
  let body = {eTag: $eTag, location: $location, properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get shared keys for the project.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Migrate/projects/{projectName}/keys
# operationId: Projects_GetKeys
export def "subscriptions-resourcegroups-providers-microsoft-migrate-projects-keys GetKeys" [
  subscriptionId: string
  resourceGroupName: string
  projectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # Standard request header. Used by service to identify API version used by client.
  --Accept-Language: string # Standard request header. Used by service to respond to client in appropriate language.
]: nothing -> record<workspaceId: string, workspaceKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Migrate/projects/($projectName)/keys" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
