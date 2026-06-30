# Auto-generated client for SqlVirtualMachineManagementClient v2017-03-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/sqlvirtualmachine-sqlvm/2017-03-01-preview/swagger.json
# Auth: --token flag or $env.SQLVIRTUALMACHINEMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SQLVIRTUALMACHINEMANAGEMENTCLIENT_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-sql-virtual-machine-operations list" } } | get name | first)
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

# Lists all of the available SQL Rest API operations.
#
# GET /providers/Microsoft.SqlVirtualMachine/operations
# operationId: Operations_List
export def "providers-microsoft-sql-virtual-machine-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.SqlVirtualMachine/operations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets all SQL virtual machine groups in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups
# operationId: SqlVirtualMachineGroups_List
export def "subscriptions-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets all SQL virtual machines in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines
# operationId: SqlVirtualMachines_List
export def "subscriptions-providers-microsoft-sql-virtual-machine-sql-virtual-machines list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets all SQL virtual machine groups in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups
# operationId: SqlVirtualMachineGroups_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a SQL virtual machine group.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}
# operationId: SqlVirtualMachineGroups_Delete
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups delete" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_group_name: (encode-path-segment $sql_virtual_machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 202 204]
}

# Gets a SQL virtual machine group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}
# operationId: SqlVirtualMachineGroups_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups get" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<properties: record<clusterConfiguration: string, clusterManagerType: string, provisioningState: string, scaleType: string, sqlImageOffer: string, sqlImageSku: string, wsfcDomainProfile: record<clusterBootstrapAccount: string, clusterOperatorAccount: string, domainFqdn: string, fileShareWitnessPath: string, ouPath: string, sqlServiceAccount: string, storageAccountPrimaryKey: string, storageAccountUrl: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_group_name: (encode-path-segment $sql_virtual_machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates SQL virtual machine group tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}
# operationId: SqlVirtualMachineGroups_Update
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups update" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
  --tags: record # Resource tags.
]: any -> record<properties: record<clusterConfiguration: string, clusterManagerType: string, provisioningState: string, scaleType: string, sqlImageOffer: string, sqlImageSku: string, wsfcDomainProfile: record<clusterBootstrapAccount: string, clusterOperatorAccount: string, domainFqdn: string, fileShareWitnessPath: string, ouPath: string, sqlServiceAccount: string, storageAccountPrimaryKey: string, storageAccountUrl: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_group_name: (encode-path-segment $sql_virtual_machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}") $qp $auth.query)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates or updates a SQL virtual machine group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}
# operationId: SqlVirtualMachineGroups_CreateOrUpdate
# --properties shape: {sqlImageOffer?: string, sqlImageSku?: "Developer"|"Enterprise", wsfcDomainProfile?: record}
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups create-or-update" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
  --properties: record # The properties of a SQL virtual machine group. — shape: {sqlImageOffer?: string, sqlImageSku?: "Developer"|"Enterprise", wsfcDomainProfile?: record}
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<properties: record<clusterConfiguration: string, clusterManagerType: string, provisioningState: string, scaleType: string, sqlImageOffer: string, sqlImageSku: string, wsfcDomainProfile: record<clusterBootstrapAccount: string, clusterOperatorAccount: string, domainFqdn: string, fileShareWitnessPath: string, ouPath: string, sqlServiceAccount: string, storageAccountPrimaryKey: string, storageAccountUrl: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_group_name: (encode-path-segment $sql_virtual_machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Lists all availability group listeners in a SQL virtual machine group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}/availabilityGroupListeners
# operationId: AvailabilityGroupListeners_ListByGroup
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups-availability-group-list-eners list" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_group_name: (encode-path-segment $sql_virtual_machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}/availabilityGroupListeners") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an availability group listener.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}/availabilityGroupListeners/{availabilityGroupListenerName}
# operationId: AvailabilityGroupListeners_Delete
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups-availability-group-list-eners delete" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  availability_group_listener_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineGroupName' must be non-empty" } }
  if ($availability_group_listener_name | is-empty) { error make --unspanned { msg: "path parameter 'availabilityGroupListenerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_group_name: (encode-path-segment $sql_virtual_machine_group_name), availability_group_listener_name: (encode-path-segment $availability_group_listener_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}/availabilityGroupListeners/{availability_group_listener_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 202 204]
}

# Gets an availability group listener.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}/availabilityGroupListeners/{availabilityGroupListenerName}
# operationId: AvailabilityGroupListeners_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups-availability-group-list-eners get" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  availability_group_listener_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<properties: record<availabilityGroupName: string, createDefaultAvailabilityGroupIfNotExist: bool, loadBalancerConfigurations: list<record>, port: int, provisioningState: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineGroupName' must be non-empty" } }
  if ($availability_group_listener_name | is-empty) { error make --unspanned { msg: "path parameter 'availabilityGroupListenerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_group_name: (encode-path-segment $sql_virtual_machine_group_name), availability_group_listener_name: (encode-path-segment $availability_group_listener_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}/availabilityGroupListeners/{availability_group_listener_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates or updates an availability group listener.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}/availabilityGroupListeners/{availabilityGroupListenerName}
# operationId: AvailabilityGroupListeners_CreateOrUpdate
# --properties shape: {availabilityGroupName?: string, createDefaultAvailabilityGroupIfNotExist?: bool, loadBalancerConfigurations?: list, port?: int}
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups-availability-group-list-eners create-or-update" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  availability_group_listener_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
  --properties: record # The properties of an availability group listener. — shape: {availabilityGroupName?: string, createDefaultAvailabilityGroupIfNotExist?: bool, loadBalancerConfigurations?: list, port?: int}
]: any -> record<properties: record<availabilityGroupName: string, createDefaultAvailabilityGroupIfNotExist: bool, loadBalancerConfigurations: list<record>, port: int, provisioningState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineGroupName' must be non-empty" } }
  if ($availability_group_listener_name | is-empty) { error make --unspanned { msg: "path parameter 'availabilityGroupListenerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_group_name: (encode-path-segment $sql_virtual_machine_group_name), availability_group_listener_name: (encode-path-segment $availability_group_listener_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}/availabilityGroupListeners/{availability_group_listener_name}") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Gets the list of sql virtual machines in a SQL virtual machine group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}/sqlVirtualMachines
# operationId: SqlVirtualMachines_ListBySqlVmGroup
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups-sql-virtual-machines list-by-vm" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_group_name: (encode-path-segment $sql_virtual_machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}/sqlVirtualMachines") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets all SQL virtual machines in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines
# operationId: SqlVirtualMachines_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machines list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a SQL virtual machine.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sqlVirtualMachineName}
# operationId: SqlVirtualMachines_Delete
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machines delete" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_name: (encode-path-segment $sql_virtual_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sql_virtual_machine_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 202 204]
}

# Gets a SQL virtual machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sqlVirtualMachineName}
# operationId: SqlVirtualMachines_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machines get" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # The child resources to include in the response.
  --api-version: string # API version to use for the request.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<autoBackupSettings: record<backupScheduleType: string, backupSystemDbs: bool, enable: bool, enableEncryption: bool, fullBackupFrequency: string, fullBackupStartTime: int, fullBackupWindowHours: int, logBackupFrequency: int, password: string, retentionPeriod: int, storageAccessKey: string, storageAccountUrl: string>, autoPatchingSettings: record<dayOfWeek: string, enable: bool, maintenanceWindowDuration: int, maintenanceWindowStartingHour: int>, keyVaultCredentialSettings: record<azureKeyVaultUrl: string, credentialName: string, enable: bool, servicePrincipalName: string, servicePrincipalSecret: string>, provisioningState: string, serverConfigurationsManagementSettings: record<additionalFeaturesServerConfigurations: record, sqlConnectivityUpdateSettings: record, sqlStorageUpdateSettings: record, sqlWorkloadTypeUpdateSettings: record>, sqlImageOffer: string, sqlImageSku: string, sqlManagement: string, sqlServerLicenseType: string, sqlVirtualMachineGroupResourceId: string, storageConfigurationSettings: record<diskConfigurationType: string, sqlDataSettings: record, sqlLogSettings: record, sqlTempDbSettings: record, storageWorkloadType: string>, virtualMachineResourceId: string, wsfcDomainCredentials: record<clusterBootstrapAccountPassword: string, clusterOperatorAccountPassword: string, sqlServiceAccountPassword: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_name: (encode-path-segment $sql_virtual_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sql_virtual_machine_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a SQL virtual machine.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sqlVirtualMachineName}
# operationId: SqlVirtualMachines_Update
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machines update" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
  --tags: record # Resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<autoBackupSettings: record<backupScheduleType: string, backupSystemDbs: bool, enable: bool, enableEncryption: bool, fullBackupFrequency: string, fullBackupStartTime: int, fullBackupWindowHours: int, logBackupFrequency: int, password: string, retentionPeriod: int, storageAccessKey: string, storageAccountUrl: string>, autoPatchingSettings: record<dayOfWeek: string, enable: bool, maintenanceWindowDuration: int, maintenanceWindowStartingHour: int>, keyVaultCredentialSettings: record<azureKeyVaultUrl: string, credentialName: string, enable: bool, servicePrincipalName: string, servicePrincipalSecret: string>, provisioningState: string, serverConfigurationsManagementSettings: record<additionalFeaturesServerConfigurations: record, sqlConnectivityUpdateSettings: record, sqlStorageUpdateSettings: record, sqlWorkloadTypeUpdateSettings: record>, sqlImageOffer: string, sqlImageSku: string, sqlManagement: string, sqlServerLicenseType: string, sqlVirtualMachineGroupResourceId: string, storageConfigurationSettings: record<diskConfigurationType: string, sqlDataSettings: record, sqlLogSettings: record, sqlTempDbSettings: record, storageWorkloadType: string>, virtualMachineResourceId: string, wsfcDomainCredentials: record<clusterBootstrapAccountPassword: string, clusterOperatorAccountPassword: string, sqlServiceAccountPassword: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_name: (encode-path-segment $sql_virtual_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sql_virtual_machine_name}") $qp $auth.query)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates or updates a SQL virtual machine.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sqlVirtualMachineName}
# operationId: SqlVirtualMachines_CreateOrUpdate
# --identity shape: {type?: "SystemAssigned"}
# --properties shape: {autoBackupSettings?: record, autoPatchingSettings?: record, keyVaultCredentialSettings?: record, serverConfigurationsManagementSettings?: record, sqlImageOffer?: string, sqlImageSku?: "Developer"|"Express"|"Standard"|"Enterprise"|"Web", sqlManagement?: "Full"|"LightWeight"|"NoAgent", sqlServerLicenseType?: "PAYG"|"AHUB"|"DR", sqlVirtualMachineGroupResourceId?: string, storageConfigurationSettings?: record, virtualMachineResourceId?: string, wsfcDomainCredentials?: record}
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machines create-or-update" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
  --identity: record # Azure Active Directory identity configuration for a resource. — shape: {type?: "SystemAssigned"}
  --properties: record # The SQL virtual machine properties. — shape: {autoBackupSettings?: record, autoPatchingSettings?: record, keyVaultCredentialSettings?: record, serverConfigurationsManagementSettings?: record, sqlImageOffer?: string, sqlImageSku?: "Developer"|"Express"|"Standard"|"Enterprise"|"Web", sqlManagement?: "Full"|"LightWeight"|"NoAgent", sqlServerLicenseType?: "PAYG"|"AHUB"|"DR", sqlVirtualMachineGroupResourceId?: string, storageConfigurationSettings?: record, virtualMachineResourceId?: string, wsfcDomainCredentials?: record}
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<autoBackupSettings: record<backupScheduleType: string, backupSystemDbs: bool, enable: bool, enableEncryption: bool, fullBackupFrequency: string, fullBackupStartTime: int, fullBackupWindowHours: int, logBackupFrequency: int, password: string, retentionPeriod: int, storageAccessKey: string, storageAccountUrl: string>, autoPatchingSettings: record<dayOfWeek: string, enable: bool, maintenanceWindowDuration: int, maintenanceWindowStartingHour: int>, keyVaultCredentialSettings: record<azureKeyVaultUrl: string, credentialName: string, enable: bool, servicePrincipalName: string, servicePrincipalSecret: string>, provisioningState: string, serverConfigurationsManagementSettings: record<additionalFeaturesServerConfigurations: record, sqlConnectivityUpdateSettings: record, sqlStorageUpdateSettings: record, sqlWorkloadTypeUpdateSettings: record>, sqlImageOffer: string, sqlImageSku: string, sqlManagement: string, sqlServerLicenseType: string, sqlVirtualMachineGroupResourceId: string, storageConfigurationSettings: record<diskConfigurationType: string, sqlDataSettings: record, sqlLogSettings: record, sqlTempDbSettings: record, storageWorkloadType: string>, virtualMachineResourceId: string, wsfcDomainCredentials: record<clusterBootstrapAccountPassword: string, clusterOperatorAccountPassword: string, sqlServiceAccountPassword: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($sql_virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'sqlVirtualMachineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), sql_virtual_machine_name: (encode-path-segment $sql_virtual_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sql_virtual_machine_name}") $qp $auth.query)
  let req_body = {"identity": $identity, "properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}
