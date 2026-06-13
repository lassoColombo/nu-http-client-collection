# Auto-generated client for Azure SQL Database Import/Export spec v2014-04-01
# Source: https://api.apis.guru/v2/specs/azure.com/sql-importExport/2014-04-01/swagger.json
# Auth: --token flag or $env.AZURE_SQL_DATABASE_IMPORT_EXPORT_SPEC_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AZURE_SQL_DATABASE_IMPORT_EXPORT_SPEC_TOKEN | default "" }
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
def authenticationType-completer [] { ["ADPassword" "SQL"] }
def storageKeyType-completer [] { ["SharedAccessKey" "StorageAccessKey"] }
def edition-completer [] { ["Basic" "Business" "BusinessCritical" "DataWarehouse" "Free" "GeneralPurpose" "Hyperscale" "Premium" "PremiumRS" "Standard" "Stretch" "System" "System2" "Web"] }
def serviceObjectiveName-completer [] { ["Basic" "DS100" "DS1000" "DS1200" "DS1500" "DS200" "DS2000" "DS300" "DS400" "DS500" "DS600" "DW100" "DW1000" "DW10000c" "DW1000c" "DW1200" "DW1500" "DW15000c" "DW1500c" "DW200" "DW2000" "DW2000c" "DW2500c" "DW300" "DW3000" "DW30000c" "DW3000c" "DW400" "DW500" "DW5000c" "DW600" "DW6000" "DW6000c" "DW7500c" "ElasticPool" "Free" "P1" "P11" "P15" "P2" "P3" "P4" "P6" "PRS1" "PRS2" "PRS4" "PRS6" "S0" "S1" "S12" "S2" "S3" "S4" "S6" "S7" "S9" "System" "System0" "System1" "System2" "System2L" "System3" "System3L" "System4" "System4L"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resource-groups-providers-microsoft-sql-servers-databases-export Export" } } | get name | first)
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

# Exports a database to a bacpac.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/databases/{databaseName}/export
# operationId: Databases_Export
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-databases-export Export" [
  subscriptionId: string
  resourceGroupName: string
  serverName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
  administratorLogin: string # The name of the SQL administrator.
  administratorLoginPassword: string # The password of the SQL administrator.
  --authenticationType: string@authenticationType-completer # The authentication type. (default: SQL)
  storageKey: string # The storage key to use.  If storage key type is SharedAccessKey, it must be preceded with a "?."
  storageKeyType: string@storageKeyType-completer # The type of the storage key to use.
  storageUri: string # The storage uri to use.
]: any -> record<properties: record<blobUri: string, databaseName: string, errorMessage: string, lastModifiedTime: string, queuedTime: string, requestId: string, requestType: string, serverName: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Sql/servers/($serverName)/databases/($databaseName)/export" $qp)
  let body = {administratorLogin: $administratorLogin, administratorLoginPassword: $administratorLoginPassword, authenticationType: $authenticationType, storageKey: $storageKey, storageKeyType: $storageKeyType, storageUri: $storageUri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an import operation that imports a bacpac into an existing database. The existing database must be empty.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/databases/{databaseName}/extensions/{extensionName}
# operationId: Databases_CreateImportOperation
# --properties shape: {operationMode: "Import", administratorLogin: string, administratorLoginPassword: string, authenticationType?: "SQL"|"ADPassword", storageKey: string, storageKeyType: "StorageAccessKey"|"SharedAccessKey", storageUri: string}
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-databases-extensions CreateImportOperation" [
  subscriptionId: string
  resourceGroupName: string
  serverName: string
  databaseName: string
  extensionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
  --name: string # The name of the extension.
  --properties: any # Represents the properties for an import operation — shape: {operationMode: "Import", administratorLogin: string, administratorLoginPassword: string, authenticationType?: "SQL"|"ADPassword", storageKey: string, storageKeyType: "StorageAccessKey"|"SharedAccessKey", storageUri: string}
  --type: string # The type of the extension.
]: any -> record<properties: record<blobUri: string, databaseName: string, errorMessage: string, lastModifiedTime: string, queuedTime: string, requestId: string, requestType: string, serverName: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Sql/servers/($serverName)/databases/($databaseName)/extensions/($extensionName)" $qp)
  let body = {name: $name, properties: $properties, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Imports a bacpac into a new database. 
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Sql/servers/{serverName}/import
# operationId: Databases_Import
export def "subscriptions-resource-groups-providers-microsoft-sql-servers-import Import" [
  subscriptionId: string
  resourceGroupName: string
  serverName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for the request.
  databaseName: string # The name of the database to import.
  edition: string@edition-completer # The edition for the database being created.  The list of SKUs may vary by region and support offer. To determine the SKUs (including the SKU name, tier/edition, family, and capacity) that are available to your subscription in an Azure region, use the `Capabilities_ListByLocation` REST API or one of the following commands:  ```azurecli az sql db list-editions -l <location> -o table ````  ```powershell Get-AzSqlServerServiceObjective -Location <location> ````
  maxSizeBytes: string # The maximum size for the newly imported database.
  serviceObjectiveName: string@serviceObjectiveName-completer # The name of the service objective to assign to the database.
  administratorLogin: string # The name of the SQL administrator.
  administratorLoginPassword: string # The password of the SQL administrator.
  --authenticationType: string@authenticationType-completer # The authentication type. (default: SQL)
  storageKey: string # The storage key to use.  If storage key type is SharedAccessKey, it must be preceded with a "?."
  storageKeyType: string@storageKeyType-completer # The type of the storage key to use.
  storageUri: string # The storage uri to use.
]: any -> record<properties: record<blobUri: string, databaseName: string, errorMessage: string, lastModifiedTime: string, queuedTime: string, requestId: string, requestType: string, serverName: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Sql/servers/($serverName)/import" $qp)
  let body = {databaseName: $databaseName, edition: $edition, maxSizeBytes: $maxSizeBytes, serviceObjectiveName: $serviceObjectiveName, administratorLogin: $administratorLogin, administratorLoginPassword: $administratorLoginPassword, authenticationType: $authenticationType, storageKey: $storageKey, storageKeyType: $storageKeyType, storageUri: $storageUri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
