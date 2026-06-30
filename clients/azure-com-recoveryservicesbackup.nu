# Auto-generated client for RecoveryServicesBackupClient v2016-06-01
# Source: https://api.apis.guru/v2/specs/azure.com/recoveryservicesbackup/2016-06-01/swagger.json
# Auth: --token flag or $env.RECOVERYSERVICESBACKUPCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o RECOVERYSERVICESBACKUPCLIENT_TOKEN | default "" }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-engines get" } } | get name | first)
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

# The backup management servers registered to a Recovery Services vault. This returns a pageable list of servers.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupEngines
# operationId: BackupEngines_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-engines get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # Use this filter to choose the specific backup management server. backupManagementType { AzureIaasVM, MAB, DPM, AzureBackupServer, AzureSql }.
  --skip-token: string # The Skip Token filter.
]: nothing -> record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupEngines") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$skipToken": $skip_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Provides the result of the refresh operation triggered by the BeginRefresh operation.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/operationResults/{operationId}
# operationId: ProtectionContainerRefreshOperationResults_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-operation-results refresh-protection-container-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/operationResults/{operation_id}") $qp $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [202 204]
}

# Gets details of the specific container registered to your Recovery Services vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}
# operationId: ProtectionContainers_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<backupManagementType: string, containerType: string, friendlyName: string, healthStatus: string, protectableObjectType: string, registrationStatus: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}") $qp $auth.query)
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

# Gets the result of any operation on the container.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/operationResults/{operationId}
# operationId: ProtectionContainerOperationResults_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-operation-results get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<backupManagementType: string, containerType: string, friendlyName: string, healthStatus: string, protectableObjectType: string, registrationStatus: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/operationResults/{operation_id}") $qp $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [200 202 204]
}

# Used to disable the backup job for an item within a container. This is an asynchronous operation. To learn the status of the request, call the GetItemOperationResult API.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}
# operationId: ProtectedItems_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-protected-items delete" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), protected_item_name: (encode-path-segment $protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/protectedItems/{protected_item_name}") $qp $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [202 204]
}

# Provides the details of the backup item. This is an asynchronous operation. To know the status of the operation, call the GetItemOperationResult API.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}
# operationId: ProtectedItems_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-protected-items get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # expand eq {extendedInfo}. This filter enables you to choose (or filter) specific items in the list of backup items.
]: nothing -> record<properties: record<backupManagementType: string, lastRecoveryPoint: string, policyId: string, protectedItemType: string, sourceResourceId: string, workloadType: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), protected_item_name: (encode-path-segment $protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/protectedItems/{protected_item_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This operation enables an item to be backed up, or modifies the existing backup policy information for an item that has been backed up. This is an asynchronous operation. To learn the status of the operation, call the GetItemOperationResult API.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}
# operationId: ProtectedItems_CreateOrUpdate
# --properties shape: {backupManagementType?: "Invalid"|"AzureIaasVM"|"MAB"|"DPM"|"AzureBackupServer"|"AzureSql", lastRecoveryPoint?: string, policyId?: string, protectedItemType: string, sourceResourceId?: string, workloadType?: "Invalid"|"VM"|"FileFolder"|"AzureSqlDb"|"SQLDB"|"Exchange"|"Sharepoint"|"DPMUnknown"}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-protected-items create-or-update" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: record # The base class for backup items. — shape: {backupManagementType?: "Invalid"|"AzureIaasVM"|"MAB"|"DPM"|"AzureBackupServer"|"AzureSql", lastRecoveryPoint?: string, policyId?: string, protectedItemType: string, sourceResourceId?: string, workloadType?: "Invalid"|"VM"|"FileFolder"|"AzureSqlDb"|"SQLDB"|"Exchange"|"Sharepoint"|"DPMUnknown"}
  --e-tag: string # Optional ETag.
  --id: string # Resource ID represents the complete path to the resource.
  --location: string # Resource location.
  --name: string # Resource name associated with the resource.
  --tags: record # Resource tags.
  --type: string # Resource type represents the complete path of the form Namespace/ResourceType/ResourceType/...
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), protected_item_name: (encode-path-segment $protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/protectedItems/{protected_item_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "eTag": $e_tag, "id": $id, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Triggers the backup job for the specified backup item. This is an asynchronous operation. To know the status of the operation, call GetProtectedItemOperationResult API.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/backup
# operationId: Backups_Trigger
# --properties shape: {objectType: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-protected-items-backup trigger" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: record # The base class for a backup request. Workload-specific backup requests are derived from this class. — shape: {objectType: string}
  --e-tag: string # Optional ETag.
  --id: string # Resource ID represents the complete path to the resource.
  --location: string # Resource location.
  --name: string # Resource name associated with the resource.
  --tags: record # Resource tags.
  --type: string # Resource type represents the complete path of the form Namespace/ResourceType/ResourceType/...
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), protected_item_name: (encode-path-segment $protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/protectedItems/{protected_item_name}/backup") $qp $auth.query)
  let req_body = {"properties": $properties, "eTag": $e_tag, "id": $id, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets the result of any operation on the backup item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/operationResults/{operationId}
# operationId: ProtectedItemOperationResults_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-protected-items-operation-results get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<backupManagementType: string, lastRecoveryPoint: string, policyId: string, protectedItemType: string, sourceResourceId: string, workloadType: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectedItemName' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), protected_item_name: (encode-path-segment $protected_item_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/protectedItems/{protected_item_name}/operationResults/{operation_id}") $qp $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [200 202 204]
}

# Gets the status of an operation such as triggering a backup or restore. The status can be: In progress, Completed, or Failed. You can refer to the OperationStatus enum for all the possible states of the operation. Some operations create jobs. This method returns the list of jobs associated with the operation.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/operationsStatus/{operationId}
# operationId: ProtectedItemOperationStatuses_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-protected-items-operations-status get-statuses" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<endTime: string, error: record<code: string, message: string>, id: string, name: string, properties: record<objectType: string>, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectedItemName' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), protected_item_name: (encode-path-segment $protected_item_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/protectedItems/{protected_item_name}/operationsStatus/{operation_id}") $qp $auth.query)
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

# Lists the recovery points, or backup copies, for the specified backup item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints
# operationId: RecoveryPoints_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-protected-items-recovery-points list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # startDate eq {yyyy-mm-dd hh:mm:ss PM} and endDate { yyyy-mm-dd hh:mm:ss PM}.
]: nothing -> record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), protected_item_name: (encode-path-segment $protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/protectedItems/{protected_item_name}/recoveryPoints") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Provides the backup data for the RecoveryPointID. This is an asynchronous operation. To learn the status of the operation, call the GetProtectedItemOperationResult API.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}
# operationId: RecoveryPoints_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-protected-items-recovery-points get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  recovery_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<objectType: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectedItemName' must be non-empty" } }
  if ($recovery_point_id | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPointId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), protected_item_name: (encode-path-segment $protected_item_name), recovery_point_id: (encode-path-segment $recovery_point_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/protectedItems/{protected_item_name}/recoveryPoints/{recovery_point_id}") $qp $auth.query)
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

# Provisions a script which invokes an iSCSI connection to the backup data. Executing this script opens File Explorer which displays the recoverable files and folders. This is an asynchronous operation. To get the provisioning status, call GetProtectedItemOperationResult API.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}/provisionInstantItemRecovery
# operationId: ItemLevelRecoveryConnections_Provision
# --properties shape: {objectType: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-protected-items-recovery-points-provision-instant-item-recovery create-level-connections" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  recovery_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: record # Parameters to restore file or folders API. — shape: {objectType: string}
  --e-tag: string # Optional ETag.
  --id: string # Resource ID represents the complete path to the resource.
  --location: string # Resource location.
  --name: string # Resource name associated with the resource.
  --tags: record # Resource tags.
  --type: string # Resource type represents the complete path of the form Namespace/ResourceType/ResourceType/...
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectedItemName' must be non-empty" } }
  if ($recovery_point_id | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPointId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), protected_item_name: (encode-path-segment $protected_item_name), recovery_point_id: (encode-path-segment $recovery_point_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/protectedItems/{protected_item_name}/recoveryPoints/{recovery_point_id}/provisionInstantItemRecovery") $qp $auth.query)
  let req_body = {"properties": $properties, "eTag": $e_tag, "id": $id, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Restores the specified backup data. This is an asynchronous operation. To know the status of this API call, use GetProtectedItemOperationResult API.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}/restore
# operationId: Restores_Trigger
# --properties shape: {objectType: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-protected-items-recovery-points-restore trigger" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  recovery_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: record # The base class for restore requests. Workload-specific restore requests are derived from this class. — shape: {objectType: string}
  --e-tag: string # Optional ETag.
  --id: string # Resource ID represents the complete path to the resource.
  --location: string # Resource location.
  --name: string # Resource name associated with the resource.
  --tags: record # Resource tags.
  --type: string # Resource type represents the complete path of the form Namespace/ResourceType/ResourceType/...
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectedItemName' must be non-empty" } }
  if ($recovery_point_id | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPointId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), protected_item_name: (encode-path-segment $protected_item_name), recovery_point_id: (encode-path-segment $recovery_point_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/protectedItems/{protected_item_name}/recoveryPoints/{recovery_point_id}/restore") $qp $auth.query)
  let req_body = {"properties": $properties, "eTag": $e_tag, "id": $id, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Revokes an iSCSI connection which can be used to download a script. Executing this script opens a file explorer displaying all recoverable files and folders. This is an asynchronous operation.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/protectionContainers/{containerName}/protectedItems/{protectedItemName}/recoveryPoints/{recoveryPointId}/revokeInstantItemRecovery
# operationId: ItemLevelRecoveryConnections_Revoke
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-protection-containers-protected-items-recovery-points-revoke-instant-item-recovery delete-level-connections" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  container_name: string
  protected_item_name: string
  recovery_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($container_name | is-empty) { error make --unspanned { msg: "path parameter 'containerName' must be non-empty" } }
  if ($protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectedItemName' must be non-empty" } }
  if ($recovery_point_id | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPointId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name), container_name: (encode-path-segment $container_name), protected_item_name: (encode-path-segment $protected_item_name), recovery_point_id: (encode-path-segment $recovery_point_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/protectionContainers/{container_name}/protectedItems/{protected_item_name}/recoveryPoints/{recovery_point_id}/revokeInstantItemRecovery") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Discovers the containers in the subscription that can be protected in a Recovery Services vault. This is an asynchronous operation. To learn the status of the operation, use the GetRefreshOperationResult API.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupFabrics/{fabricName}/refreshContainers
# operationId: ProtectionContainers_Refresh
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-fabrics-refresh-containers refresh-protection" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupFabrics/{fabric_name}/refreshContainers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Provides a pageable list of jobs.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobs
# operationId: Jobs_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-jobs list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # The following equation can be used to filter the list of jobs based on status, type, start date, and end date. status eq { InProgress , Completed , Failed , CompletedWithWarnings , Cancelled , Cancelling } and backupManagementType eq {AzureIaasVM, MAB, DPM, AzureBackupServer, AzureSql } and operation eq { ConfigureBackup , Backup , Restore , DisableBackup , DeleteBackupData } and jobId eq {guid} and startTime eq { yyyy-mm-dd hh:mm:ss PM } and endTime eq { yyyy-mm-dd hh:mm:ss PM }.
  --skip-token: string # The Skip Token filter.
]: nothing -> record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupJobs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$skipToken": $skip_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the result of the operation triggered by the ExportJob API.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobs/operationResults/{operationId}
# operationId: ExportJobsOperationResults_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-jobs-operation-results export-get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<objectType: string>, Headers: record, statusCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupJobs/operationResults/{operation_id}") $qp $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Gets extended information associated with the job.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobs/{jobName}
# operationId: JobDetails_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-jobs get-details" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
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
  --api-version: string # Client API version.
]: nothing -> record<properties: record<activityId: string, backupManagementType: string, endTime: string, entityFriendlyName: string, jobType: string, operation: string, startTime: string, status: string>, eTag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), job_name: (encode-path-segment $job_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupJobs/{job_name}") $qp $auth.query)
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

# Cancels the job. This is an asynchronous operation. To know the status of the cancellation, call the GetCancelOperationResult API.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobs/{jobName}/cancel
# operationId: JobCancellations_Trigger
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-jobs-cancel trigger-cancellations" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
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
  --api-version: string # Client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), job_name: (encode-path-segment $job_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupJobs/{job_name}/cancel") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Gets the result of the operation.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobs/{jobName}/operationResults/{operationId}
# operationId: JobOperationResults_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-jobs-operation-results get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  job_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), job_name: (encode-path-segment $job_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupJobs/{job_name}/operationResults/{operation_id}") $qp $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [200 202 204]
}

# Exports all jobs for a given Shared Access Signatures (SAS) URL. The SAS URL expires within 15 minutes of its creation.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupJobsExport
# operationId: Jobs_Export
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-jobs-export export" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # The OData filter options. status eq { InProgress , Completed , Failed , CompletedWithWarnings , Cancelled , Cancelling } and backupManagementType eq {AzureIaasVM, MAB, DPM, AzureBackupServer, AzureSql } and operation eq { ConfigureBackup , Backup , Restore , DisableBackup , DeleteBackupData } and jobId eq {guid} and startTime eq { yyyy-mm-dd hh:mm:ss PM } and endTime eq { yyyy-mm-dd hh:mm:ss PM }.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupJobsExport") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Provides the status of the delete operations, for example, deleting a backup item. Once the operation starts, the response status code is Accepted. The response status code remains in this state until the operation reaches completion. On successful completion, the status code changes to OK. This method expects OperationID as an argument. OperationID is part of the Location header of the operation response.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupOperationResults/{operationId}
# operationId: BackupOperationResults_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-operation-results get" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupOperationResults/{operation_id}") $qp $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [200 202 204]
}

# Gets the status of an operation such as triggering a backup or restore. The status can be In progress, Completed or Failed. You can refer to the OperationStatus enum for all the possible states of an operation. Some operations create jobs. This method returns the list of jobs when the operation is complete.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupOperations/{operationId}
# operationId: BackupOperationStatuses_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-operations get-statuses" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<endTime: string, error: record<code: string, message: string>, id: string, name: string, properties: record<objectType: string>, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupOperations/{operation_id}") $qp $auth.query)
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

# Lists the backup policies associated with the Recovery Services vault. The API provides parameters to Get scoped results.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies
# operationId: ProtectionPolicies_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-policies list-protection" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # The following equation can be used to filter the list of backup policies. backupManagementType eq {AzureIaasVM, MAB, DPM, AzureBackupServer, AzureSql}.
]: nothing -> record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupPolicies") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes the specified backup policy from your Recovery Services vault. This is an asynchronous operation. Use the GetPolicyOperationResult API to Get the operation status.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}
# operationId: ProtectionPolicies_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-policies delete-protection" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupPolicies/{policy_name}") $qp $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Gets the details of the backup policy associated with the Recovery Services vault. This is an asynchronous operation. Use the GetPolicyOperationResult API to Get the operation status.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}
# operationId: ProtectionPolicies_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-policies get-protection" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<backupManagementType: string, protectedItemsCount: int>, eTag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupPolicies/{policy_name}") $qp $auth.query)
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

# Creates or modifies a backup policy. This is an asynchronous operation. Use the GetPolicyOperationResult API to Get the operation status.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}
# operationId: ProtectionPolicies_CreateOrUpdate
# --properties shape: {backupManagementType: string, protectedItemsCount?: int}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-policies create-protection-or-update" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: record # The base class for a backup policy. Workload-specific backup policies are derived from this class. — shape: {backupManagementType: string, protectedItemsCount?: int}
  --e-tag: string # Optional ETag.
  --id: string # Resource ID represents the complete path to the resource.
  --location: string # Resource location.
  --name: string # Resource name associated with the resource.
  --tags: record # Resource tags.
  --type: string # Resource type represents the complete path of the form Namespace/ResourceType/ResourceType/...
]: any -> record<properties: record<backupManagementType: string, protectedItemsCount: int>, eTag: string, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupPolicies/{policy_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "eTag": $e_tag, "id": $id, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Provides the result of an operation.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}/operationResults/{operationId}
# operationId: ProtectionPolicyOperationResults_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-policies-operation-results get-protection-policy" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  policy_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<backupManagementType: string, protectedItemsCount: int>, eTag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), policy_name: (encode-path-segment $policy_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupPolicies/{policy_name}/operationResults/{operation_id}") $qp $auth.query)
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

# Provides the status of the asynchronous operations like backup or restore. The status can be: in progress, completed, or failed. You can refer to the Operation Status enumeration for the possible states of an operation. Some operations create jobs. This method returns the list of jobs associated with the operation.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupPolicies/{policyName}/operations/{operationId}
# operationId: ProtectionPolicyOperationStatuses_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-policies-operations get-protection-policy-statuses" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  policy_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<endTime: string, error: record<code: string, message: string>, id: string, name: string, properties: record<objectType: string>, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name), policy_name: (encode-path-segment $policy_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupPolicies/{policy_name}/operations/{operation_id}") $qp $auth.query)
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

# Based on the query filter and the pagination parameters, this operation provides a pageable list of objects within the subscription that can be protected.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupProtectableItems
# operationId: ProtectableItems_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-protectable-items list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # Using the following query filters, you can sort a specific backup item based on: type of backup item, status, name of the item, and more. providerType eq { AzureIaasVM, MAB, DPM, AzureBackupServer, AzureSql } and status eq { NotProtected , Protecting , Protected } and friendlyName {name} and skipToken eq {string which provides the next set of list} and topToken eq {int} and backupManagementType eq { AzureIaasVM, MAB, DPM, AzureBackupServer, AzureSql }.
  --skip-token: string # The Skip Token filter.
]: nothing -> record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupProtectableItems") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$skipToken": $skip_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Provides a pageable list of all items in a subscription, that can be protected.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupProtectedItems
# operationId: ProtectedItems_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-protected-items list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # itemType eq { VM , FileFolder , AzureSqlDb , SQLDB , Exchange , Sharepoint , DPMUnknown } and providerType eq { AzureIaasVM, MAB, DPM, AzureBackupServer, AzureSql } and policyName eq {policyName} and containerName eq {containername} and backupManagementType eq { AzureIaasVM, MAB, DPM, AzureBackupServer, AzureSql }.
  --skip-token: string # The Skip Token filter.
]: nothing -> record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupProtectedItems") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$skipToken": $skip_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists the containers registered to the Recovery Services vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{vaultName}/backupProtectionContainers
# operationId: ProtectionContainers_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-backup-protection-containers list" [
  subscription_id: string
  resource_group_name: string
  vault_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # The following equation is used to sort or filter the containers registered to the vault. providerType eq {AzureIaasVM, MAB, DPM, AzureBackupServer, AzureSql} and status eq {Unknown, NotRegistered, Registered, Registering} and friendlyName eq {containername} and backupManagementType eq {AzureIaasVM, MAB, DPM, AzureBackupServer, AzureSql}.
]: nothing -> record<value: table<properties: record, eTag: string, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($vault_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), vault_name: (encode-path-segment $vault_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{vault_name}/backupProtectionContainers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
