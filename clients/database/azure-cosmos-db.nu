# Auto-generated client for Cosmos DB v2019-08-01
# Source: https://api.apis.guru/v2/specs/azure.com/cosmos-db/2019-08-01/swagger.json
# Auth: --token flag or $env.COSMOS_DB_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o COSMOS_DB_TOKEN | default "" }
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
def kind-completer [] { ["GlobalDocumentDB" "MongoDB" "Parse"] }
def keyKind-completer [] { ["primary" "primaryReadonly" "secondary" "secondaryReadonly"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-document-db-database-account-names CheckNameExists" } } | get name | first)
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

# Checks that the Azure Cosmos DB account name already exists. A valid account name may contain only lowercase letters, numbers, and the '-' character, and must be between 3 and 50 characters.
#
# HEAD /providers/Microsoft.DocumentDB/databaseAccountNames/{accountName}
# operationId: DatabaseAccounts_CheckNameExists
export def "providers-microsoft-document-db-database-account-names CheckNameExists" [
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.DocumentDB/databaseAccountNames/($accountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all of the available Cosmos DB Resource Provider operations.
#
# GET /providers/Microsoft.DocumentDB/operations
# operationId: Operations_List
export def "providers-microsoft-document-db-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.DocumentDB/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the Azure Cosmos DB database accounts available under the subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DocumentDB/databaseAccounts
# operationId: DatabaseAccounts_List
export def "subscriptions-providers-microsoft-document-db-database-accounts List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<kind: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DocumentDB/databaseAccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the Azure Cosmos DB database accounts available under the given resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts
# operationId: DatabaseAccounts_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts ListByResourceGroup" [
  resourceGroupName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<kind: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB database account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}
# operationId: DatabaseAccounts_Delete
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts Delete" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the properties of an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}
# operationId: DatabaseAccounts_Get
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts Get" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<kind: string, properties: record<capabilities: list<record>, connectorOffer: string, consistencyPolicy: record<defaultConsistencyLevel: string, maxIntervalInSeconds: int, maxStalenessPrefix: int>, databaseAccountOfferType: string, disableKeyBasedMetadataWriteAccess: bool, documentEndpoint: string, enableAutomaticFailover: bool, enableCassandraConnector: bool, enableMultipleWriteLocations: bool, failoverPolicies: list<record>, ipRangeFilter: string, isVirtualNetworkFilterEnabled: bool, locations: list<record>, provisioningState: string, readLocations: list<record>, virtualNetworkRules: list<record>, writeLocations: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the properties of an existing Azure Cosmos DB database account.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}
# operationId: DatabaseAccounts_Update
# --properties shape: {capabilities?: list, connectorOffer?: "Small", consistencyPolicy?: record, disableKeyBasedMetadataWriteAccess?: bool, enableAutomaticFailover?: bool, enableCassandraConnector?: bool, enableMultipleWriteLocations?: bool, ipRangeFilter?: string, isVirtualNetworkFilterEnabled?: bool, locations?: list, virtualNetworkRules?: list}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts Update" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --location: string # The location of the resource group to which the resource belongs.
  --properties: record # Properties to update Azure Cosmos DB database accounts. — shape: {capabilities?: list, connectorOffer?: "Small", consistencyPolicy?: record, disableKeyBasedMetadataWriteAccess?: bool, enableAutomaticFailover?: bool, enableCassandraConnector?: bool, enableMultipleWriteLocations?: bool, ipRangeFilter?: string, isVirtualNetworkFilterEnabled?: bool, locations?: list, virtualNetworkRules?: list}
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<kind: string, properties: record<capabilities: list<record>, connectorOffer: string, consistencyPolicy: record<defaultConsistencyLevel: string, maxIntervalInSeconds: int, maxStalenessPrefix: int>, databaseAccountOfferType: string, disableKeyBasedMetadataWriteAccess: bool, documentEndpoint: string, enableAutomaticFailover: bool, enableCassandraConnector: bool, enableMultipleWriteLocations: bool, failoverPolicies: list<record>, ipRangeFilter: string, isVirtualNetworkFilterEnabled: bool, locations: list<record>, provisioningState: string, readLocations: list<record>, virtualNetworkRules: list<record>, writeLocations: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)" $qp)
  let body = {location: $location, properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates an Azure Cosmos DB database account. The "Update" method is preferred when performing updates on an account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}
# operationId: DatabaseAccounts_CreateOrUpdate
# --properties shape: {capabilities?: list, connectorOffer?: "Small", consistencyPolicy?: record, databaseAccountOfferType: "Standard", disableKeyBasedMetadataWriteAccess?: bool, enableAutomaticFailover?: bool, enableCassandraConnector?: bool, enableMultipleWriteLocations?: bool, ipRangeFilter?: string, isVirtualNetworkFilterEnabled?: bool, locations: list, virtualNetworkRules?: list}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --kind: string@kind-completer # Indicates the type of database account. This can only be set at database account creation. (default: GlobalDocumentDB)
  properties: record # Properties to create and update Azure Cosmos DB database accounts. — shape: {capabilities?: list, connectorOffer?: "Small", consistencyPolicy?: record, databaseAccountOfferType: "Standard", disableKeyBasedMetadataWriteAccess?: bool, enableAutomaticFailover?: bool, enableCassandraConnector?: bool, enableMultipleWriteLocations?: bool, ipRangeFilter?: string, isVirtualNetworkFilterEnabled?: bool, locations: list, virtualNetworkRules?: list}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<kind: string, properties: record<capabilities: list<record>, connectorOffer: string, consistencyPolicy: record<defaultConsistencyLevel: string, maxIntervalInSeconds: int, maxStalenessPrefix: int>, databaseAccountOfferType: string, disableKeyBasedMetadataWriteAccess: bool, documentEndpoint: string, enableAutomaticFailover: bool, enableCassandraConnector: bool, enableMultipleWriteLocations: bool, failoverPolicies: list<record>, ipRangeFilter: string, isVirtualNetworkFilterEnabled: bool, locations: list<record>, provisioningState: string, readLocations: list<record>, virtualNetworkRules: list<record>, writeLocations: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)" $qp)
  let body = {kind: $kind, properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the Cassandra keyspaces under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces
# operationId: CassandraResources_ListCassandraKeyspaces
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces ListCassandraKeyspaces" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB Cassandra keyspace.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces/{keyspaceName}
# operationId: CassandraResources_DeleteCassandraKeyspace
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces DeleteCassandraKeyspace" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  keyspaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces/($keyspaceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Cassandra keyspaces under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces/{keyspaceName}
# operationId: CassandraResources_GetCassandraKeyspace
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces GetCassandraKeyspace" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  keyspaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<id: string, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces/($keyspaceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an Azure Cosmos DB Cassandra keyspace
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces/{keyspaceName}
# operationId: CassandraResources_CreateUpdateCassandraKeyspace
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces CreateUpdateCassandraKeyspace" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  keyspaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB Cassandra keyspace. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<id: string, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces/($keyspaceName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the Cassandra table under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces/{keyspaceName}/tables
# operationId: CassandraResources_ListCassandraTables
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces-tables ListCassandraTables" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  keyspaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces/($keyspaceName)/tables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB Cassandra table.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces/{keyspaceName}/tables/{tableName}
# operationId: CassandraResources_DeleteCassandraTable
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces-tables DeleteCassandraTable" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  keyspaceName: string
  tableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces/($keyspaceName)/tables/($tableName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Cassandra table under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces/{keyspaceName}/tables/{tableName}
# operationId: CassandraResources_GetCassandraTable
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces-tables GetCassandraTable" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  keyspaceName: string
  tableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<defaultTtl: int, id: string, schema: record, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces/($keyspaceName)/tables/($tableName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an Azure Cosmos DB Cassandra Table
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces/{keyspaceName}/tables/{tableName}
# operationId: CassandraResources_CreateUpdateCassandraTable
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces-tables CreateUpdateCassandraTable" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  keyspaceName: string
  tableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB Cassandra table. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<defaultTtl: int, id: string, schema: record, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces/($keyspaceName)/tables/($tableName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the RUs per second of the Cassandra table under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces/{keyspaceName}/tables/{tableName}/throughputSettings/default
# operationId: CassandraResources_GetCassandraTableThroughput
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces-tables-throughput-settings-default GetCassandraTableThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  keyspaceName: string
  tableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces/($keyspaceName)/tables/($tableName)/throughputSettings/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update RUs per second of an Azure Cosmos DB Cassandra table
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces/{keyspaceName}/tables/{tableName}/throughputSettings/default
# operationId: CassandraResources_UpdateCassandraTableThroughput
# --properties shape: {resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces-tables-throughput-settings-default UpdateCassandraTableThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  keyspaceName: string
  tableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to update Azure Cosmos DB resource throughput. — shape: {resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces/($keyspaceName)/tables/($tableName)/throughputSettings/default" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the RUs per second of the Cassandra Keyspace under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces/{keyspaceName}/throughputSettings/default
# operationId: CassandraResources_GetCassandraKeyspaceThroughput
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces-throughput-settings-default GetCassandraKeyspaceThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  keyspaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces/($keyspaceName)/throughputSettings/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update RUs per second of an Azure Cosmos DB Cassandra Keyspace
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/cassandraKeyspaces/{keyspaceName}/throughputSettings/default
# operationId: CassandraResources_UpdateCassandraKeyspaceThroughput
# --properties shape: {resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-cassandra-keyspaces-throughput-settings-default UpdateCassandraKeyspaceThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  keyspaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to update Azure Cosmos DB resource throughput. — shape: {resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/cassandraKeyspaces/($keyspaceName)/throughputSettings/default" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves metric definitions for the given collection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/databases/{databaseRid}/collections/{collectionRid}/metricDefinitions
# operationId: Collection_ListMetricDefinitions
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-databases-collections-metric-definitions ListMetricDefinitions" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseRid: string
  collectionRid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<metricAvailabilities: list, name: record, primaryAggregationType: string, resourceUri: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/databases/($databaseRid)/collections/($collectionRid)/metricDefinitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the metrics determined by the given filter for the given database account and collection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/databases/{databaseRid}/collections/{collectionRid}/metrics
# operationId: Collection_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-databases-collections-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseRid: string
  collectionRid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/databases/($databaseRid)/collections/($collectionRid)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the metrics determined by the given filter for the given partition key range id.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/databases/{databaseRid}/collections/{collectionRid}/partitionKeyRangeId/{partitionKeyRangeId}/metrics
# operationId: PartitionKeyRangeId_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-databases-collections-partition-key-range-id-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseRid: string
  collectionRid: string
  partitionKeyRangeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<partitionId: string, partitionKeyRangeId: string, endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/databases/($databaseRid)/collections/($collectionRid)/partitionKeyRangeId/($partitionKeyRangeId)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the metrics determined by the given filter for the given collection, split by partition.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/databases/{databaseRid}/collections/{collectionRid}/partitions/metrics
# operationId: CollectionPartition_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-databases-collections-partitions-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseRid: string
  collectionRid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<partitionId: string, partitionKeyRangeId: string, endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/databases/($databaseRid)/collections/($collectionRid)/partitions/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the usages (most recent storage data) for the given collection, split by partition.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/databases/{databaseRid}/collections/{collectionRid}/partitions/usages
# operationId: CollectionPartition_ListUsages
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-databases-collections-partitions-usages ListUsages" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseRid: string
  collectionRid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of usages to return. The supported parameter is name.value (name of the metric, can have an or of multiple names).
]: nothing -> record<value: table<partitionId: string, partitionKeyRangeId: string, currentValue: int, limit: int, name: record, quotaPeriod: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/databases/($databaseRid)/collections/($collectionRid)/partitions/usages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the usages (most recent storage data) for the given collection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/databases/{databaseRid}/collections/{collectionRid}/usages
# operationId: Collection_ListUsages
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-databases-collections-usages ListUsages" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseRid: string
  collectionRid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of usages to return. The supported parameter is name.value (name of the metric, can have an or of multiple names).
]: nothing -> record<value: table<currentValue: int, limit: int, name: record, quotaPeriod: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/databases/($databaseRid)/collections/($collectionRid)/usages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves metric definitions for the given database.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/databases/{databaseRid}/metricDefinitions
# operationId: Database_ListMetricDefinitions
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-databases-metric-definitions ListMetricDefinitions" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseRid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<metricAvailabilities: list, name: record, primaryAggregationType: string, resourceUri: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/databases/($databaseRid)/metricDefinitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the metrics determined by the given filter for the given database account and database.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/databases/{databaseRid}/metrics
# operationId: Database_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-databases-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseRid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/databases/($databaseRid)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the usages (most recent data) for the given database.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/databases/{databaseRid}/usages
# operationId: Database_ListUsages
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-databases-usages ListUsages" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseRid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of usages to return. The supported parameter is name.value (name of the metric, can have an or of multiple names).
]: nothing -> record<value: table<currentValue: int, limit: int, name: record, quotaPeriod: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/databases/($databaseRid)/usages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Changes the failover priority for the Azure Cosmos DB database account. A failover priority of 0 indicates a write region. The maximum value for a failover priority = (total number of regions - 1). Failover priority values must be unique for each of the regions in which the database account exists.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/failoverPriorityChange
# operationId: DatabaseAccounts_FailoverPriorityChange
# --failoverPolicies item shape: {failoverPriority?: int, locationName?: string}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-failover-priority-change FailoverPriorityChange" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  failoverPolicies: list # List of failover policies. — item shape: {failoverPriority?: int, locationName?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/failoverPriorityChange" $qp)
  let body = {failoverPolicies: $failoverPolicies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the Gremlin databases under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases
# operationId: GremlinResources_ListGremlinDatabases
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases ListGremlinDatabases" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB Gremlin database.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases/{databaseName}
# operationId: GremlinResources_DeleteGremlinDatabase
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases DeleteGremlinDatabase" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases/($databaseName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Gremlin databases under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases/{databaseName}
# operationId: GremlinResources_GetGremlinDatabase
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases GetGremlinDatabase" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<id: string, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases/($databaseName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an Azure Cosmos DB Gremlin database
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases/{databaseName}
# operationId: GremlinResources_CreateUpdateGremlinDatabase
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases CreateUpdateGremlinDatabase" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB Gremlin database. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<id: string, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases/($databaseName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the Gremlin graph under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases/{databaseName}/graphs
# operationId: GremlinResources_ListGremlinGraphs
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases-graphs ListGremlinGraphs" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases/($databaseName)/graphs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB Gremlin graph.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases/{databaseName}/graphs/{graphName}
# operationId: GremlinResources_DeleteGremlinGraph
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases-graphs DeleteGremlinGraph" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  graphName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases/($databaseName)/graphs/($graphName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Gremlin graph under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases/{databaseName}/graphs/{graphName}
# operationId: GremlinResources_GetGremlinGraph
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases-graphs GetGremlinGraph" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  graphName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<conflictResolutionPolicy: record, defaultTtl: int, id: string, indexingPolicy: record, partitionKey: record, uniqueKeyPolicy: record, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases/($databaseName)/graphs/($graphName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an Azure Cosmos DB Gremlin graph
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases/{databaseName}/graphs/{graphName}
# operationId: GremlinResources_CreateUpdateGremlinGraph
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases-graphs CreateUpdateGremlinGraph" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  graphName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB Gremlin graph. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<conflictResolutionPolicy: record, defaultTtl: int, id: string, indexingPolicy: record, partitionKey: record, uniqueKeyPolicy: record, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases/($databaseName)/graphs/($graphName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the Gremlin graph throughput under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases/{databaseName}/graphs/{graphName}/throughputSettings/default
# operationId: GremlinResources_GetGremlinGraphThroughput
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases-graphs-throughput-settings-default GetGremlinGraphThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  graphName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases/($databaseName)/graphs/($graphName)/throughputSettings/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update RUs per second of an Azure Cosmos DB Gremlin graph
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases/{databaseName}/graphs/{graphName}/throughputSettings/default
# operationId: GremlinResources_UpdateGremlinGraphThroughput
# --properties shape: {resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases-graphs-throughput-settings-default UpdateGremlinGraphThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  graphName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to update Azure Cosmos DB resource throughput. — shape: {resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases/($databaseName)/graphs/($graphName)/throughputSettings/default" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the RUs per second of the Gremlin database under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases/{databaseName}/throughputSettings/default
# operationId: GremlinResources_GetGremlinDatabaseThroughput
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases-throughput-settings-default GetGremlinDatabaseThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases/($databaseName)/throughputSettings/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update RUs per second of an Azure Cosmos DB Gremlin database
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/gremlinDatabases/{databaseName}/throughputSettings/default
# operationId: GremlinResources_UpdateGremlinDatabaseThroughput
# --properties shape: {resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-gremlin-databases-throughput-settings-default UpdateGremlinDatabaseThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to update Azure Cosmos DB resource throughput. — shape: {resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/gremlinDatabases/($databaseName)/throughputSettings/default" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the connection strings for the specified Azure Cosmos DB database account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/listConnectionStrings
# operationId: DatabaseAccounts_ListConnectionStrings
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-list-connection-strings ListConnectionStrings" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<connectionStrings: table<connectionString: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/listConnectionStrings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the access keys for the specified Azure Cosmos DB database account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/listKeys
# operationId: DatabaseAccounts_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-list-keys ListKeys" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<primaryMasterKey: string, secondaryMasterKey: string, primaryReadonlyMasterKey: string, secondaryReadonlyMasterKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/listKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves metric definitions for the given database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/metricDefinitions
# operationId: DatabaseAccounts_ListMetricDefinitions
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-metric-definitions ListMetricDefinitions" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<metricAvailabilities: list, name: record, primaryAggregationType: string, resourceUri: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/metricDefinitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the metrics determined by the given filter for the given database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/metrics
# operationId: DatabaseAccounts_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the MongoDB databases under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases
# operationId: MongoDBResources_ListMongoDBDatabases
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases ListMongoDBDatabases" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB MongoDB database.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases/{databaseName}
# operationId: MongoDBResources_DeleteMongoDBDatabase
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases DeleteMongoDBDatabase" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases/($databaseName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the MongoDB databases under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases/{databaseName}
# operationId: MongoDBResources_GetMongoDBDatabase
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases GetMongoDBDatabase" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<id: string, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases/($databaseName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or updates Azure Cosmos DB MongoDB database
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases/{databaseName}
# operationId: MongoDBResources_CreateUpdateMongoDBDatabase
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases CreateUpdateMongoDBDatabase" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB MongoDB database. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<id: string, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases/($databaseName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the MongoDB collection under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases/{databaseName}/collections
# operationId: MongoDBResources_ListMongoDBCollections
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases-collections ListMongoDBCollections" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases/($databaseName)/collections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB MongoDB Collection.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases/{databaseName}/collections/{collectionName}
# operationId: MongoDBResources_DeleteMongoDBCollection
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases-collections DeleteMongoDBCollection" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases/($databaseName)/collections/($collectionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the MongoDB collection under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases/{databaseName}/collections/{collectionName}
# operationId: MongoDBResources_GetMongoDBCollection
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases-collections GetMongoDBCollection" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<id: string, indexes: list, shardKey: record, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases/($databaseName)/collections/($collectionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an Azure Cosmos DB MongoDB Collection
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases/{databaseName}/collections/{collectionName}
# operationId: MongoDBResources_CreateUpdateMongoDBCollection
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases-collections CreateUpdateMongoDBCollection" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB MongoDB collection. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<id: string, indexes: list, shardKey: record, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases/($databaseName)/collections/($collectionName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the RUs per second of the MongoDB collection under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases/{databaseName}/collections/{collectionName}/throughputSettings/default
# operationId: MongoDBResources_GetMongoDBCollectionThroughput
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases-collections-throughput-settings-default GetMongoDBCollectionThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases/($databaseName)/collections/($collectionName)/throughputSettings/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the RUs per second of an Azure Cosmos DB MongoDB collection
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases/{databaseName}/collections/{collectionName}/throughputSettings/default
# operationId: MongoDBResources_UpdateMongoDBCollectionThroughput
# --properties shape: {resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases-collections-throughput-settings-default UpdateMongoDBCollectionThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to update Azure Cosmos DB resource throughput. — shape: {resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases/($databaseName)/collections/($collectionName)/throughputSettings/default" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the RUs per second of the MongoDB database under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases/{databaseName}/throughputSettings/default
# operationId: MongoDBResources_GetMongoDBDatabaseThroughput
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases-throughput-settings-default GetMongoDBDatabaseThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases/($databaseName)/throughputSettings/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update RUs per second of the an Azure Cosmos DB MongoDB database
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/mongodbDatabases/{databaseName}/throughputSettings/default
# operationId: MongoDBResources_UpdateMongoDBDatabaseThroughput
# --properties shape: {resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-mongodb-databases-throughput-settings-default UpdateMongoDBDatabaseThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to update Azure Cosmos DB resource throughput. — shape: {resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/mongodbDatabases/($databaseName)/throughputSettings/default" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Offline the specified region for the specified Azure Cosmos DB database account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/offlineRegion
# operationId: DatabaseAccounts_OfflineRegion
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-offline-region OfflineRegion" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  region: string # Cosmos DB region, with spaces between words and each word capitalized.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/offlineRegion" $qp)
  let body = {region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Online the specified region for the specified Azure Cosmos DB database account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/onlineRegion
# operationId: DatabaseAccounts_OnlineRegion
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-online-region OnlineRegion" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  region: string # Cosmos DB region, with spaces between words and each word capitalized.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/onlineRegion" $qp)
  let body = {region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the metrics determined by the given filter for the given database account. This url is only for PBS and Replication Latency data
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/percentile/metrics
# operationId: Percentile_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-percentile-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/percentile/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the read-only access keys for the specified Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/readonlykeys
# operationId: DatabaseAccounts_GetReadOnlyKeys
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-readonlykeys GetReadOnlyKeys" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<primaryReadonlyMasterKey: string, secondaryReadonlyMasterKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/readonlykeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the read-only access keys for the specified Azure Cosmos DB database account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/readonlykeys
# operationId: DatabaseAccounts_ListReadOnlyKeys
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-readonlykeys ListReadOnlyKeys" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<primaryReadonlyMasterKey: string, secondaryReadonlyMasterKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/readonlykeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerates an access key for the specified Azure Cosmos DB database account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/regenerateKey
# operationId: DatabaseAccounts_RegenerateKey
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-regenerate-key RegenerateKey" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  keyKind: string@keyKind-completer # The access key to regenerate.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/regenerateKey" $qp)
  let body = {keyKind: $keyKind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the metrics determined by the given filter for the given database account, collection and region.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/region/{region}/databases/{databaseRid}/collections/{collectionRid}/metrics
# operationId: CollectionRegion_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-region-databases-collections-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  region: string
  databaseRid: string
  collectionRid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/region/($region)/databases/($databaseRid)/collections/($collectionRid)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the metrics determined by the given filter for the given partition key range id and region.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/region/{region}/databases/{databaseRid}/collections/{collectionRid}/partitionKeyRangeId/{partitionKeyRangeId}/metrics
# operationId: PartitionKeyRangeIdRegion_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-region-databases-collections-partition-key-range-id-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  region: string
  databaseRid: string
  collectionRid: string
  partitionKeyRangeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<partitionId: string, partitionKeyRangeId: string, endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/region/($region)/databases/($databaseRid)/collections/($collectionRid)/partitionKeyRangeId/($partitionKeyRangeId)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the metrics determined by the given filter for the given collection and region, split by partition.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/region/{region}/databases/{databaseRid}/collections/{collectionRid}/partitions/metrics
# operationId: CollectionPartitionRegion_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-region-databases-collections-partitions-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  region: string
  databaseRid: string
  collectionRid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<partitionId: string, partitionKeyRangeId: string, endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/region/($region)/databases/($databaseRid)/collections/($collectionRid)/partitions/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the metrics determined by the given filter for the given database account and region.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/region/{region}/metrics
# operationId: DatabaseAccountRegion_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-region-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  region: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/region/($region)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the metrics determined by the given filter for the given account, source and target region. This url is only for PBS and Replication Latency data
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sourceRegion/{sourceRegion}/targetRegion/{targetRegion}/percentile/metrics
# operationId: PercentileSourceTarget_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-source-region-target-region-percentile-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  sourceRegion: string
  targetRegion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sourceRegion/($sourceRegion)/targetRegion/($targetRegion)/percentile/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the SQL databases under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases
# operationId: SqlResources_ListSqlDatabases
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases ListSqlDatabases" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB SQL database.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}
# operationId: SqlResources_DeleteSqlDatabase
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases DeleteSqlDatabase" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the SQL database under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}
# operationId: SqlResources_GetSqlDatabase
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases GetSqlDatabase" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<_colls: string, _users: string, id: string, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an Azure Cosmos DB SQL database
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}
# operationId: SqlResources_CreateUpdateSqlDatabase
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases CreateUpdateSqlDatabase" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB SQL database. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<_colls: string, _users: string, id: string, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the SQL container under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers
# operationId: SqlResources_ListSqlContainers
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers ListSqlContainers" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB SQL container.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}
# operationId: SqlResources_DeleteSqlContainer
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers DeleteSqlContainer" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the SQL container under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}
# operationId: SqlResources_GetSqlContainer
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers GetSqlContainer" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<conflictResolutionPolicy: record, defaultTtl: int, id: string, indexingPolicy: record, partitionKey: record, uniqueKeyPolicy: record, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an Azure Cosmos DB SQL container
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}
# operationId: SqlResources_CreateUpdateSqlContainer
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers CreateUpdateSqlContainer" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB container. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<conflictResolutionPolicy: record, defaultTtl: int, id: string, indexingPolicy: record, partitionKey: record, uniqueKeyPolicy: record, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the SQL storedProcedure under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/storedProcedures
# operationId: SqlResources_ListSqlStoredProcedures
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-stored-procedures ListSqlStoredProcedures" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/storedProcedures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB SQL storedProcedure.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/storedProcedures/{storedProcedureName}
# operationId: SqlResources_DeleteSqlStoredProcedure
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-stored-procedures DeleteSqlStoredProcedure" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  storedProcedureName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/storedProcedures/($storedProcedureName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the SQL storedProcedure under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/storedProcedures/{storedProcedureName}
# operationId: SqlResources_GetSqlStoredProcedure
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-stored-procedures GetSqlStoredProcedure" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  storedProcedureName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<body: string, id: string, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/storedProcedures/($storedProcedureName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an Azure Cosmos DB SQL storedProcedure
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/storedProcedures/{storedProcedureName}
# operationId: SqlResources_CreateUpdateSqlStoredProcedure
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-stored-procedures CreateUpdateSqlStoredProcedure" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  storedProcedureName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB storedProcedure. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<body: string, id: string, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/storedProcedures/($storedProcedureName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the RUs per second of the SQL container under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/throughputSettings/default
# operationId: SqlResources_GetSqlContainerThroughput
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-throughput-settings-default GetSqlContainerThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/throughputSettings/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update RUs per second of an Azure Cosmos DB SQL container
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/throughputSettings/default
# operationId: SqlResources_UpdateSqlContainerThroughput
# --properties shape: {resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-throughput-settings-default UpdateSqlContainerThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to update Azure Cosmos DB resource throughput. — shape: {resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/throughputSettings/default" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the SQL trigger under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/triggers
# operationId: SqlResources_ListSqlTriggers
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-triggers ListSqlTriggers" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/triggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB SQL trigger.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/triggers/{triggerName}
# operationId: SqlResources_DeleteSqlTrigger
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-triggers DeleteSqlTrigger" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/triggers/($triggerName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the SQL trigger under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/triggers/{triggerName}
# operationId: SqlResources_GetSqlTrigger
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-triggers GetSqlTrigger" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<body: string, id: string, triggerOperation: string, triggerType: string, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/triggers/($triggerName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an Azure Cosmos DB SQL trigger
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/triggers/{triggerName}
# operationId: SqlResources_CreateUpdateSqlTrigger
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-triggers CreateUpdateSqlTrigger" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB trigger. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<body: string, id: string, triggerOperation: string, triggerType: string, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/triggers/($triggerName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the SQL userDefinedFunction under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/userDefinedFunctions
# operationId: SqlResources_ListSqlUserDefinedFunctions
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-user-defined-functions ListSqlUserDefinedFunctions" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/userDefinedFunctions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB SQL userDefinedFunction.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/userDefinedFunctions/{userDefinedFunctionName}
# operationId: SqlResources_DeleteSqlUserDefinedFunction
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-user-defined-functions DeleteSqlUserDefinedFunction" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  userDefinedFunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/userDefinedFunctions/($userDefinedFunctionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the SQL userDefinedFunction under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/userDefinedFunctions/{userDefinedFunctionName}
# operationId: SqlResources_GetSqlUserDefinedFunction
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-user-defined-functions GetSqlUserDefinedFunction" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  userDefinedFunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<body: string, id: string, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/userDefinedFunctions/($userDefinedFunctionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an Azure Cosmos DB SQL userDefinedFunction
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/containers/{containerName}/userDefinedFunctions/{userDefinedFunctionName}
# operationId: SqlResources_CreateUpdateSqlUserDefinedFunction
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-containers-user-defined-functions CreateUpdateSqlUserDefinedFunction" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  containerName: string
  userDefinedFunctionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB userDefinedFunction. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<body: string, id: string, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/containers/($containerName)/userDefinedFunctions/($userDefinedFunctionName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the RUs per second of the SQL database under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/throughputSettings/default
# operationId: SqlResources_GetSqlDatabaseThroughput
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-throughput-settings-default GetSqlDatabaseThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/throughputSettings/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update RUs per second of an Azure Cosmos DB SQL database
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/sqlDatabases/{databaseName}/throughputSettings/default
# operationId: SqlResources_UpdateSqlDatabaseThroughput
# --properties shape: {resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-sql-databases-throughput-settings-default UpdateSqlDatabaseThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  databaseName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to update Azure Cosmos DB resource throughput. — shape: {resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/sqlDatabases/($databaseName)/throughputSettings/default" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the Tables under an existing Azure Cosmos DB database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/tables
# operationId: TableResources_ListTables
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-tables ListTables" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/tables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing Azure Cosmos DB Table.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/tables/{tableName}
# operationId: TableResources_DeleteTable
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-tables DeleteTable" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  tableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/tables/($tableName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Tables under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/tables/{tableName}
# operationId: TableResources_GetTable
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-tables GetTable" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  tableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<id: string, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/tables/($tableName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an Azure Cosmos DB Table
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/tables/{tableName}
# operationId: TableResources_CreateUpdateTable
# --properties shape: {options: record, resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-tables CreateUpdateTable" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  tableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to create and update Azure Cosmos DB Table. — shape: {options: record, resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<id: string, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/tables/($tableName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the RUs per second of the Table under an existing Azure Cosmos DB database account with the provided name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/tables/{tableName}/throughputSettings/default
# operationId: TableResources_GetTableThroughput
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-tables-throughput-settings-default GetTableThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  tableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
]: nothing -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/tables/($tableName)/throughputSettings/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update RUs per second of an Azure Cosmos DB Table
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/tables/{tableName}/throughputSettings/default
# operationId: TableResources_UpdateTableThroughput
# --properties shape: {resource: record}
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-tables-throughput-settings-default UpdateTableThroughput" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  tableName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  properties: record # Properties to update Azure Cosmos DB resource throughput. — shape: {resource: record}
  --location: string # The location of the resource group to which the resource belongs.
  --tags: record # Tags are a list of key-value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater than 128 characters and value no greater than 256 characters. For example, the default experience for a template type is set with "defaultExperience": "Cassandra". Current "defaultExperience" values also include "Table", "Graph", "DocumentDB", and "MongoDB".
]: any -> record<properties: record<resource: record<minimumThroughput: string, offerReplacePending: string, throughput: int, _etag: string, _rid: string, _ts: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/tables/($tableName)/throughputSettings/default" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the metrics determined by the given filter for the given account target region. This url is only for PBS and Replication Latency data
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/targetRegion/{targetRegion}/percentile/metrics
# operationId: PercentileTarget_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-target-region-percentile-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  targetRegion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of metrics to return. The parameters that can be filtered are name.value (name of the metric, can have an or of multiple names), startTime, endTime, and timeGrain. The supported operator is eq.
]: nothing -> record<value: table<endTime: string, metricValues: list, name: record, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/targetRegion/($targetRegion)/percentile/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the usages (most recent data) for the given database account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DocumentDB/databaseAccounts/{accountName}/usages
# operationId: DatabaseAccounts_ListUsages
export def "subscriptions-resource-groups-providers-microsoft-document-db-database-accounts-usages ListUsages" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-08-01.
  --filter: string # An OData filter expression that describes a subset of usages to return. The supported parameter is name.value (name of the metric, can have an or of multiple names).
]: nothing -> record<value: table<currentValue: int, limit: int, name: record, quotaPeriod: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DocumentDB/databaseAccounts/($accountName)/usages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
