# Auto-generated client for SqlManagementClient v2017-03-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/sql-jobs/2017-03-01-preview/swagger.json
# Auth: --token flag or $env.SQLMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SQLMANAGEMENTCLIENT_TOKEN | default "" }
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


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents list" } } | get name | first)
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

# Gets a list of job agents in a server.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents
# operationId: JobAgents_ListByServer
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a job agent.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}
# operationId: JobAgents_Delete
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents delete" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a job agent.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}
# operationId: JobAgents_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents get" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<properties: record<databaseId: string, state: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates a job agent.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}
# operationId: JobAgents_Update
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents update" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
  --tags: record # Resource tags.
]: any -> record<properties: record<databaseId: string, state: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates or updates a job agent.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}
# operationId: JobAgents_CreateOrUpdate
# --properties shape: {databaseId: string}
# --sku shape: {capacity?: int, family?: string, name: string, size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents create-or-update" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
  --properties: record # Properties of a job agent. — shape: {databaseId: string}
  --sku: record # An ARM Resource SKU. — shape: {capacity?: int, family?: string, name: string, size?: string, tier?: string}
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<properties: record<databaseId: string, state: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}") $qp)
  let req_body = {"properties": $properties, "sku": $sku, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets a list of jobs credentials.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/credentials
# operationId: JobCredentials_ListByAgent
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-credentials list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/credentials") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a job credential.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/credentials/{credentialName}
# operationId: JobCredentials_Delete
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-credentials delete" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  credential_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($credential_name | is-empty) { error make --unspanned { msg: "path parameter 'credentialName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), credential_name: (encode-path-segment $credential_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/credentials/{credential_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a jobs credential.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/credentials/{credentialName}
# operationId: JobCredentials_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-credentials get" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  credential_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<properties: record<password: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($credential_name | is-empty) { error make --unspanned { msg: "path parameter 'credentialName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), credential_name: (encode-path-segment $credential_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/credentials/{credential_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a job credential.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/credentials/{credentialName}
# operationId: JobCredentials_CreateOrUpdate
# --properties shape: {password: string, username: string}
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-credentials create-or-update" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  credential_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
  --properties: record # Properties of a job credential. — shape: {password: string, username: string}
]: any -> record<properties: record<password: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($credential_name | is-empty) { error make --unspanned { msg: "path parameter 'credentialName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), credential_name: (encode-path-segment $credential_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/credentials/{credential_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all executions in a job agent.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/executions
# operationId: JobExecutions_ListByAgent
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-executions list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-time-min: string # If specified, only job executions created at or after the specified time are included. (format: date-time)
  --create-time-max: string # If specified, only job executions created before the specified time are included. (format: date-time)
  --end-time-min: string # If specified, only job executions completed at or after the specified time are included. (format: date-time)
  --end-time-max: string # If specified, only job executions completed before the specified time are included. (format: date-time)
  --is-active: oneof<nothing, bool> # If specified, only active or only completed job executions are included.
  --skip: int # The number of elements in the collection to skip.
  --top: int # The number of elements to return from the collection.
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  let qp = [(serialize-qp "createTimeMin" $create_time_min "scalar") (serialize-qp "createTimeMax" $create_time_max "scalar") (serialize-qp "endTimeMin" $end_time_min "scalar") (serialize-qp "endTimeMax" $end_time_max "scalar") (serialize-qp "isActive" $is_active "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/executions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"createTimeMin": $create_time_min, "createTimeMax": $create_time_max, "endTimeMin": $end_time_min, "endTimeMax": $end_time_max, "isActive": $is_active, "$skip": $skip, "$top": $top, "api-version": $api_version} | compact), body: null}
}

# Gets a list of jobs.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs
# operationId: Jobs_ListByAgent
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a job.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}
# operationId: Jobs_Delete
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs delete" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a job.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}
# operationId: Jobs_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs get" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<properties: record<description: string, schedule: record<enabled: bool, endTime: string, interval: string, startTime: string, type: string>, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a job.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}
# operationId: Jobs_CreateOrUpdate
# --properties shape: {description?: string, schedule?: record}
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs create-or-update" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
  --properties: record # Properties of a job. — shape: {description?: string, schedule?: record}
]: any -> record<properties: record<description: string, schedule: record<enabled: bool, endTime: string, interval: string, startTime: string, type: string>, version: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists a job's executions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/executions
# operationId: JobExecutions_ListByJob
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-executions list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-time-min: string # If specified, only job executions created at or after the specified time are included. (format: date-time)
  --create-time-max: string # If specified, only job executions created before the specified time are included. (format: date-time)
  --end-time-min: string # If specified, only job executions completed at or after the specified time are included. (format: date-time)
  --end-time-max: string # If specified, only job executions completed before the specified time are included. (format: date-time)
  --is-active: oneof<nothing, bool> # If specified, only active or only completed job executions are included.
  --skip: int # The number of elements in the collection to skip.
  --top: int # The number of elements to return from the collection.
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "createTimeMin" $create_time_min "scalar") (serialize-qp "createTimeMax" $create_time_max "scalar") (serialize-qp "endTimeMin" $end_time_min "scalar") (serialize-qp "endTimeMax" $end_time_max "scalar") (serialize-qp "isActive" $is_active "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/executions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"createTimeMin": $create_time_min, "createTimeMax": $create_time_max, "endTimeMin": $end_time_min, "endTimeMax": $end_time_max, "isActive": $is_active, "$skip": $skip, "$top": $top, "api-version": $api_version} | compact), body: null}
}

# Gets a job execution.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/executions/{jobExecutionId}
# operationId: JobExecutions_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-executions get" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  job_execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<properties: record<createTime: string, currentAttemptStartTime: string, currentAttempts: int, endTime: string, jobExecutionId: string, jobVersion: int, lastMessage: string, lifecycle: string, provisioningState: string, startTime: string, stepId: int, stepName: string, target: record<databaseName: string, serverName: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($job_execution_id | is-empty) { error make --unspanned { msg: "path parameter 'jobExecutionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), job_execution_id: (encode-path-segment $job_execution_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/executions/{job_execution_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a job execution.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/executions/{jobExecutionId}
# operationId: JobExecutions_CreateOrUpdate
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-executions create-or-update" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  job_execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<properties: record<createTime: string, currentAttemptStartTime: string, currentAttempts: int, endTime: string, jobExecutionId: string, jobVersion: int, lastMessage: string, lifecycle: string, provisioningState: string, startTime: string, stepId: int, stepName: string, target: record<databaseName: string, serverName: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($job_execution_id | is-empty) { error make --unspanned { msg: "path parameter 'jobExecutionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), job_execution_id: (encode-path-segment $job_execution_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/executions/{job_execution_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Requests cancellation of a job execution.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/executions/{jobExecutionId}/cancel
# operationId: JobExecutions_Cancel
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-executions-cancel cancel" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  job_execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($job_execution_id | is-empty) { error make --unspanned { msg: "path parameter 'jobExecutionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), job_execution_id: (encode-path-segment $job_execution_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/executions/{job_execution_id}/cancel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists the step executions of a job execution.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/executions/{jobExecutionId}/steps
# operationId: JobStepExecutions_ListByJobExecution
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-executions-steps list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  job_execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-time-min: string # If specified, only job executions created at or after the specified time are included. (format: date-time)
  --create-time-max: string # If specified, only job executions created before the specified time are included. (format: date-time)
  --end-time-min: string # If specified, only job executions completed at or after the specified time are included. (format: date-time)
  --end-time-max: string # If specified, only job executions completed before the specified time are included. (format: date-time)
  --is-active: oneof<nothing, bool> # If specified, only active or only completed job executions are included.
  --skip: int # The number of elements in the collection to skip.
  --top: int # The number of elements to return from the collection.
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($job_execution_id | is-empty) { error make --unspanned { msg: "path parameter 'jobExecutionId' must be non-empty" } }
  let qp = [(serialize-qp "createTimeMin" $create_time_min "scalar") (serialize-qp "createTimeMax" $create_time_max "scalar") (serialize-qp "endTimeMin" $end_time_min "scalar") (serialize-qp "endTimeMax" $end_time_max "scalar") (serialize-qp "isActive" $is_active "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), job_execution_id: (encode-path-segment $job_execution_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/executions/{job_execution_id}/steps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"createTimeMin": $create_time_min, "createTimeMax": $create_time_max, "endTimeMin": $end_time_min, "endTimeMax": $end_time_max, "isActive": $is_active, "$skip": $skip, "$top": $top, "api-version": $api_version} | compact), body: null}
}

# Gets a step execution of a job execution.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/executions/{jobExecutionId}/steps/{stepName}
# operationId: JobStepExecutions_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-executions-steps get" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  job_execution_id: string
  step_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<properties: record<createTime: string, currentAttemptStartTime: string, currentAttempts: int, endTime: string, jobExecutionId: string, jobVersion: int, lastMessage: string, lifecycle: string, provisioningState: string, startTime: string, stepId: int, stepName: string, target: record<databaseName: string, serverName: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($job_execution_id | is-empty) { error make --unspanned { msg: "path parameter 'jobExecutionId' must be non-empty" } }
  if ($step_name | is-empty) { error make --unspanned { msg: "path parameter 'stepName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), job_execution_id: (encode-path-segment $job_execution_id), step_name: (encode-path-segment $step_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/executions/{job_execution_id}/steps/{step_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists the target executions of a job step execution.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/executions/{jobExecutionId}/steps/{stepName}/targets
# operationId: JobTargetExecutions_ListByStep
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-executions-steps-targets list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  job_execution_id: string
  step_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-time-min: string # If specified, only job executions created at or after the specified time are included. (format: date-time)
  --create-time-max: string # If specified, only job executions created before the specified time are included. (format: date-time)
  --end-time-min: string # If specified, only job executions completed at or after the specified time are included. (format: date-time)
  --end-time-max: string # If specified, only job executions completed before the specified time are included. (format: date-time)
  --is-active: oneof<nothing, bool> # If specified, only active or only completed job executions are included.
  --skip: int # The number of elements in the collection to skip.
  --top: int # The number of elements to return from the collection.
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($job_execution_id | is-empty) { error make --unspanned { msg: "path parameter 'jobExecutionId' must be non-empty" } }
  if ($step_name | is-empty) { error make --unspanned { msg: "path parameter 'stepName' must be non-empty" } }
  let qp = [(serialize-qp "createTimeMin" $create_time_min "scalar") (serialize-qp "createTimeMax" $create_time_max "scalar") (serialize-qp "endTimeMin" $end_time_min "scalar") (serialize-qp "endTimeMax" $end_time_max "scalar") (serialize-qp "isActive" $is_active "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), job_execution_id: (encode-path-segment $job_execution_id), step_name: (encode-path-segment $step_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/executions/{job_execution_id}/steps/{step_name}/targets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"createTimeMin": $create_time_min, "createTimeMax": $create_time_max, "endTimeMin": $end_time_min, "endTimeMax": $end_time_max, "isActive": $is_active, "$skip": $skip, "$top": $top, "api-version": $api_version} | compact), body: null}
}

# Gets a target execution.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/executions/{jobExecutionId}/steps/{stepName}/targets/{targetId}
# operationId: JobTargetExecutions_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-executions-steps-targets get" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  job_execution_id: string
  step_name: string
  target_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<properties: record<createTime: string, currentAttemptStartTime: string, currentAttempts: int, endTime: string, jobExecutionId: string, jobVersion: int, lastMessage: string, lifecycle: string, provisioningState: string, startTime: string, stepId: int, stepName: string, target: record<databaseName: string, serverName: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($job_execution_id | is-empty) { error make --unspanned { msg: "path parameter 'jobExecutionId' must be non-empty" } }
  if ($step_name | is-empty) { error make --unspanned { msg: "path parameter 'stepName' must be non-empty" } }
  if ($target_id | is-empty) { error make --unspanned { msg: "path parameter 'targetId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), job_execution_id: (encode-path-segment $job_execution_id), step_name: (encode-path-segment $step_name), target_id: (encode-path-segment $target_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/executions/{job_execution_id}/steps/{step_name}/targets/{target_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists target executions for all steps of a job execution.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/executions/{jobExecutionId}/targets
# operationId: JobTargetExecutions_ListByJobExecution
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-executions-targets list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  job_execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-time-min: string # If specified, only job executions created at or after the specified time are included. (format: date-time)
  --create-time-max: string # If specified, only job executions created before the specified time are included. (format: date-time)
  --end-time-min: string # If specified, only job executions completed at or after the specified time are included. (format: date-time)
  --end-time-max: string # If specified, only job executions completed before the specified time are included. (format: date-time)
  --is-active: oneof<nothing, bool> # If specified, only active or only completed job executions are included.
  --skip: int # The number of elements in the collection to skip.
  --top: int # The number of elements to return from the collection.
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($job_execution_id | is-empty) { error make --unspanned { msg: "path parameter 'jobExecutionId' must be non-empty" } }
  let qp = [(serialize-qp "createTimeMin" $create_time_min "scalar") (serialize-qp "createTimeMax" $create_time_max "scalar") (serialize-qp "endTimeMin" $end_time_min "scalar") (serialize-qp "endTimeMax" $end_time_max "scalar") (serialize-qp "isActive" $is_active "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), job_execution_id: (encode-path-segment $job_execution_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/executions/{job_execution_id}/targets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"createTimeMin": $create_time_min, "createTimeMax": $create_time_max, "endTimeMin": $end_time_min, "endTimeMax": $end_time_max, "isActive": $is_active, "$skip": $skip, "$top": $top, "api-version": $api_version} | compact), body: null}
}

# Starts an elastic job execution.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/start
# operationId: JobExecutions_Create
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-start create-executions" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<properties: record<createTime: string, currentAttemptStartTime: string, currentAttempts: int, endTime: string, jobExecutionId: string, jobVersion: int, lastMessage: string, lifecycle: string, provisioningState: string, startTime: string, stepId: int, stepName: string, target: record<databaseName: string, serverName: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/start") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets all job steps for a job's current version.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/steps
# operationId: JobSteps_ListByJob
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-steps list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/steps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a job step. This will implicitly create a new job version.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/steps/{stepName}
# operationId: JobSteps_Delete
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-steps delete" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  step_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($step_name | is-empty) { error make --unspanned { msg: "path parameter 'stepName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), step_name: (encode-path-segment $step_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/steps/{step_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a job step in a job's current version.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/steps/{stepName}
# operationId: JobSteps_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-steps get" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  step_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<properties: record<action: record<source: string, type: string, value: string>, credential: string, executionOptions: record<initialRetryIntervalSeconds: int, maximumRetryIntervalSeconds: int, retryAttempts: int, retryIntervalBackoffMultiplier: float, timeoutSeconds: int>, output: record<credential: string, databaseName: string, resourceGroupName: string, schemaName: string, serverName: string, subscriptionId: string, tableName: string, type: string>, stepId: int, targetGroup: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($step_name | is-empty) { error make --unspanned { msg: "path parameter 'stepName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), step_name: (encode-path-segment $step_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/steps/{step_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a job step. This will implicitly create a new job version.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/steps/{stepName}
# operationId: JobSteps_CreateOrUpdate
# --properties shape: {action: record, credential: string, executionOptions?: record, output?: record, stepId?: int, targetGroup: string}
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-steps create-or-update" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  step_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
  --properties: record # Properties of a job step. — shape: {action: record, credential: string, executionOptions?: record, output?: record, stepId?: int, targetGroup: string}
]: any -> record<properties: record<action: record<source: string, type: string, value: string>, credential: string, executionOptions: record<initialRetryIntervalSeconds: int, maximumRetryIntervalSeconds: int, retryAttempts: int, retryIntervalBackoffMultiplier: float, timeoutSeconds: int>, output: record<credential: string, databaseName: string, resourceGroupName: string, schemaName: string, serverName: string, subscriptionId: string, tableName: string, type: string>, stepId: int, targetGroup: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($step_name | is-empty) { error make --unspanned { msg: "path parameter 'stepName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), step_name: (encode-path-segment $step_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/steps/{step_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets all versions of a job.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/versions
# operationId: JobVersions_ListByJob
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-versions list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a job version.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/versions/{jobVersion}
# operationId: JobVersions_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-versions get" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  job_version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($job_version | is-empty) { error make --unspanned { msg: "path parameter 'jobVersion' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), job_version: (encode-path-segment $job_version)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/versions/{job_version}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets all job steps in the specified job version.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/versions/{jobVersion}/steps
# operationId: JobSteps_ListByVersion
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-versions-steps list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  job_version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($job_version | is-empty) { error make --unspanned { msg: "path parameter 'jobVersion' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), job_version: (encode-path-segment $job_version)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/versions/{job_version}/steps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the specified version of a job step.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/jobs/{jobName}/versions/{jobVersion}/steps/{stepName}
# operationId: JobSteps_GetByVersion
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-jobs-versions-steps get" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  job_name: string
  job_version: int
  step_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<properties: record<action: record<source: string, type: string, value: string>, credential: string, executionOptions: record<initialRetryIntervalSeconds: int, maximumRetryIntervalSeconds: int, retryAttempts: int, retryIntervalBackoffMultiplier: float, timeoutSeconds: int>, output: record<credential: string, databaseName: string, resourceGroupName: string, schemaName: string, serverName: string, subscriptionId: string, tableName: string, type: string>, stepId: int, targetGroup: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($job_version | is-empty) { error make --unspanned { msg: "path parameter 'jobVersion' must be non-empty" } }
  if ($step_name | is-empty) { error make --unspanned { msg: "path parameter 'stepName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), job_name: (encode-path-segment $job_name), job_version: (encode-path-segment $job_version), step_name: (encode-path-segment $step_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/jobs/{job_name}/versions/{job_version}/steps/{step_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets all target groups in an agent.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/targetGroups
# operationId: JobTargetGroups_ListByAgent
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-target-groups list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/targetGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a target group.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/targetGroups/{targetGroupName}
# operationId: JobTargetGroups_Delete
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-target-groups delete" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  target_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($target_group_name | is-empty) { error make --unspanned { msg: "path parameter 'targetGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), target_group_name: (encode-path-segment $target_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/targetGroups/{target_group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a target group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/targetGroups/{targetGroupName}
# operationId: JobTargetGroups_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-target-groups get" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  target_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
]: nothing -> record<properties: record<members: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($target_group_name | is-empty) { error make --unspanned { msg: "path parameter 'targetGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), target_group_name: (encode-path-segment $target_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/targetGroups/{target_group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a target group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/jobAgents/{jobAgentName}/targetGroups/{targetGroupName}
# operationId: JobTargetGroups_CreateOrUpdate
# --properties shape: {members: list}
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-job-agents-target-groups create-or-update" [
  subscription_id: string
  resource_group_name: string
  server_name: string
  job_agent_name: string
  target_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
  --properties: record # Properties of job target group. — shape: {members: list}
]: any -> record<properties: record<members: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  if ($job_agent_name | is-empty) { error make --unspanned { msg: "path parameter 'jobAgentName' must be non-empty" } }
  if ($target_group_name | is-empty) { error make --unspanned { msg: "path parameter 'targetGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name), job_agent_name: (encode-path-segment $job_agent_name), target_group_name: (encode-path-segment $target_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Sql/servers/{server_name}/jobAgents/{job_agent_name}/targetGroups/{target_group_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}
