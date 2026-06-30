# Auto-generated client for Azure Machine Learning Datastore Management Client v2019-09-30
# Source: https://api.apis.guru/v2/specs/azure.com/machinelearningservices-datastore/2019-09-30/swagger.json
# Auth: --token flag or $env.AZURE_MACHINE_LEARNING_DATASTORE_MANAGEMENT_CLIENT_TOKEN

const BASE_URL = "https://azure.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AZURE_MACHINE_LEARNING_DATASTORE_MANAGEMENT_CLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def data-store-type-completer [] { ["AzureBlob" "AzureDataLake" "AzureDataLakeGen2" "AzureFile" "AzurePostgreSql" "AzureSqlDatabase" "DBFS" "GlusterFs"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "datastore-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-datastores delete-data-stores-list" } } | get name | first)
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

# Delete all Datastores.
#
# DELETE /datastore/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/datastores
# operationId: DataStores_DeleteAll
export def "datastore-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-datastores delete-data-stores-list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/datastore/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/datastores") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get Datastores list.
#
# GET /datastore/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/datastores
# operationId: DataStores_List
export def "datastore-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-datastores list-data-stores" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-store-names: list<string> # List of Datastore names.
  --continuation-token: string # The Continuation Token.
  --count: int # Count of Datastores to be returned. (format: int32, default: 30)
  --include-secret: oneof<nothing, bool> # Whether to include the datastore secret in the response. (default: true)
]: nothing -> record<continuationToken: string, nextLink: string, value: table<azureDataLakeSection: record, azurePostgreSqlSection: record, azureSqlDatabaseSection: record, azureStorageSection: record, dataStoreType: string, glusterFsSection: record, hasBeenValidated: bool, name: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "dataStoreNames" $data_store_names "multi") (serialize-qp "continuationToken" $continuation_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "includeSecret" $include_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/datastore/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/datastores") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"dataStoreNames": $data_store_names, "continuationToken": $continuation_token, "count": $count, "includeSecret": $include_secret} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or update a Datastore.
#
# POST /datastore/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/datastores
# operationId: DataStores_Create
# --azureDataLakeSection shape: {authorityUrl?: string, certificate?: string, clientId?: string, clientSecret?: string, isCertAuth?: bool, resourceGroup?: string, resourceUri?: string, storeName?: string, subscriptionId?: string, tenantId?: string, thumbprint?: string}
# --azurePostgreSqlSection shape: {databaseName?: string, endpoint?: string, portNumber?: string, resourceGroup?: string, serverName?: string, subscriptionId?: string, userId?: string, userPassword?: string}
# --azureSqlDatabaseSection shape: {authorityUrl?: string, certificate?: string, clientId?: string, clientSecret?: string, databaseName?: string, endpoint?: string, isCertAuth?: bool, resourceGroup?: string, resourceUri?: string, serverName?: string, subscriptionId?: string, tenantId?: string, thumbprint?: string}
# --azureStorageSection shape: {accountKey?: string, accountName?: string, areWorkspaceManagedIdentitiesAllowed?: bool, blobCacheTimeout?: int, clientCredentials?: record, containerName?: string, credential?: string, credentialType?: "None"|"Sas"|"AccountKey"|"ClientCredentials", endpoint?: string, isSas?: bool, protocol?: string, resourceGroup?: string, sasToken?: string, subscriptionId?: string}
# --glusterFsSection shape: {serverAddress?: string, volumeName?: string}
export def "datastore-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-datastores create-data-stores" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-if-not-exists: oneof<nothing, bool> # If set to true, the call will create an Datastore if it doesn't exist. (default: false)
  --skip-validation: oneof<nothing, bool> # If set to true, the call will skip Datastore validation. (default: false)
  --azure-data-lake-section: record # shape: {authorityUrl?: string, certificate?: string, clientId?: string, clientSecret?: string, isCertAuth?: bool, resourceGroup?: string, resourceUri?: string, storeName?: string, subscriptionId?: string, tenantId?: string, thumbprint?: string}
  --azure-postgre-sql-section: record # shape: {databaseName?: string, endpoint?: string, portNumber?: string, resourceGroup?: string, serverName?: string, subscriptionId?: string, userId?: string, userPassword?: string}
  --azure-sql-database-section: record # shape: {authorityUrl?: string, certificate?: string, clientId?: string, clientSecret?: string, databaseName?: string, endpoint?: string, isCertAuth?: bool, resourceGroup?: string, resourceUri?: string, serverName?: string, subscriptionId?: string, tenantId?: string, thumbprint?: string}
  --azure-storage-section: record # shape: {accountKey?: string, accountName?: string, areWorkspaceManagedIdentitiesAllowed?: bool, blobCacheTimeout?: int, clientCredentials?: record, containerName?: string, credential?: string, credentialType?: "None"|"Sas"|"AccountKey"|"ClientCredentials", endpoint?: string, isSas?: bool, protocol?: string, resourceGroup?: string, sasToken?: string, subscriptionId?: string}
  --data-store-type: string@data-store-type-completer # The Azure storage service this datastore points to.
  --gluster-fs-section: record # shape: {serverAddress?: string, volumeName?: string}
  --has-been-validated: oneof<nothing, bool> # A read only property that denotes whether the service datastore has been validated with credentials.
  --name: string # Name of the datastore
  --tags: record # Tags to datastore
]: any -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "createIfNotExists" $create_if_not_exists "scalar") (serialize-qp "skipValidation" $skip_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/datastore/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/datastores") $qp $auth.query)
  let req_body = {"azureDataLakeSection": $azure_data_lake_section, "azurePostgreSqlSection": $azure_postgre_sql_section, "azureSqlDatabaseSection": $azure_sql_database_section, "azureStorageSection": $azure_storage_section, "dataStoreType": $data_store_type, "glusterFsSection": $gluster_fs_section, "hasBeenValidated": $has_been_validated, "name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"createIfNotExists": $create_if_not_exists, "skipValidation": $skip_validation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a Datastore.
#
# DELETE /datastore/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/datastores/{name}
# operationId: DataStores_Delete
export def "datastore-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-datastores delete-data-stores" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), name: (encode-path-segment $name)} | format pattern "/datastore/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/datastores/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get Datastore details.
#
# GET /datastore/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/datastores/{name}
# operationId: DataStores_Get
export def "datastore-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-datastores get-data-stores" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<azureDataLakeSection: record<authorityUrl: string, certificate: string, clientId: string, clientSecret: string, isCertAuth: bool, resourceGroup: string, resourceUri: string, storeName: string, subscriptionId: string, tenantId: string, thumbprint: string>, azurePostgreSqlSection: record<databaseName: string, endpoint: string, portNumber: string, resourceGroup: string, serverName: string, subscriptionId: string, userId: string, userPassword: string>, azureSqlDatabaseSection: record<authorityUrl: string, certificate: string, clientId: string, clientSecret: string, databaseName: string, endpoint: string, isCertAuth: bool, resourceGroup: string, resourceUri: string, serverName: string, subscriptionId: string, tenantId: string, thumbprint: string>, azureStorageSection: record<accountKey: string, accountName: string, areWorkspaceManagedIdentitiesAllowed: bool, blobCacheTimeout: int, clientCredentials: record<authorityUrl: string, certificate: string, clientId: string, clientSecret: string, isCertAuth: bool, resourceGroup: string, resourceUri: string, subscriptionId: string, tenantId: string, thumbprint: string>, containerName: string, credential: string, credentialType: string, endpoint: string, isSas: bool, protocol: string, resourceGroup: string, sasToken: string, subscriptionId: string>, dataStoreType: string, glusterFsSection: record<serverAddress: string, volumeName: string>, hasBeenValidated: bool, name: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), name: (encode-path-segment $name)} | format pattern "/datastore/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/datastores/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update or create a Datastore.
#
# PUT /datastore/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/datastores/{name}
# operationId: DataStores_Update
# --azureDataLakeSection shape: {authorityUrl?: string, certificate?: string, clientId?: string, clientSecret?: string, isCertAuth?: bool, resourceGroup?: string, resourceUri?: string, storeName?: string, subscriptionId?: string, tenantId?: string, thumbprint?: string}
# --azurePostgreSqlSection shape: {databaseName?: string, endpoint?: string, portNumber?: string, resourceGroup?: string, serverName?: string, subscriptionId?: string, userId?: string, userPassword?: string}
# --azureSqlDatabaseSection shape: {authorityUrl?: string, certificate?: string, clientId?: string, clientSecret?: string, databaseName?: string, endpoint?: string, isCertAuth?: bool, resourceGroup?: string, resourceUri?: string, serverName?: string, subscriptionId?: string, tenantId?: string, thumbprint?: string}
# --azureStorageSection shape: {accountKey?: string, accountName?: string, areWorkspaceManagedIdentitiesAllowed?: bool, blobCacheTimeout?: int, clientCredentials?: record, containerName?: string, credential?: string, credentialType?: "None"|"Sas"|"AccountKey"|"ClientCredentials", endpoint?: string, isSas?: bool, protocol?: string, resourceGroup?: string, sasToken?: string, subscriptionId?: string}
# --glusterFsSection shape: {serverAddress?: string, volumeName?: string}
export def "datastore-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-datastores update-data-stores" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --create-if-not-exists: oneof<nothing, bool> # If set to true, the call will create an Datastore if it doesn't exist. (default: false)
  --skip-validation: oneof<nothing, bool> # If set to true, the call will skip Datastore validation. (default: false)
  --azure-data-lake-section: record # shape: {authorityUrl?: string, certificate?: string, clientId?: string, clientSecret?: string, isCertAuth?: bool, resourceGroup?: string, resourceUri?: string, storeName?: string, subscriptionId?: string, tenantId?: string, thumbprint?: string}
  --azure-postgre-sql-section: record # shape: {databaseName?: string, endpoint?: string, portNumber?: string, resourceGroup?: string, serverName?: string, subscriptionId?: string, userId?: string, userPassword?: string}
  --azure-sql-database-section: record # shape: {authorityUrl?: string, certificate?: string, clientId?: string, clientSecret?: string, databaseName?: string, endpoint?: string, isCertAuth?: bool, resourceGroup?: string, resourceUri?: string, serverName?: string, subscriptionId?: string, tenantId?: string, thumbprint?: string}
  --azure-storage-section: record # shape: {accountKey?: string, accountName?: string, areWorkspaceManagedIdentitiesAllowed?: bool, blobCacheTimeout?: int, clientCredentials?: record, containerName?: string, credential?: string, credentialType?: "None"|"Sas"|"AccountKey"|"ClientCredentials", endpoint?: string, isSas?: bool, protocol?: string, resourceGroup?: string, sasToken?: string, subscriptionId?: string}
  --data-store-type: string@data-store-type-completer # The Azure storage service this datastore points to.
  --gluster-fs-section: record # shape: {serverAddress?: string, volumeName?: string}
  --has-been-validated: oneof<nothing, bool> # A read only property that denotes whether the service datastore has been validated with credentials.
  --body-name: string # Name of the datastore
  --tags: record # Tags to datastore
]: any -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "createIfNotExists" $create_if_not_exists "scalar") (serialize-qp "skipValidation" $skip_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), name: (encode-path-segment $name)} | format pattern "/datastore/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/datastores/{name}") $qp $auth.query)
  let req_body = {"azureDataLakeSection": $azure_data_lake_section, "azurePostgreSqlSection": $azure_postgre_sql_section, "azureSqlDatabaseSection": $azure_sql_database_section, "azureStorageSection": $azure_storage_section, "dataStoreType": $data_store_type, "glusterFsSection": $gluster_fs_section, "hasBeenValidated": $has_been_validated, "name": $body_name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"createIfNotExists": $create_if_not_exists, "skipValidation": $skip_validation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get the default Datastore.
#
# GET /datastore/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/default
# operationId: DataStores_GetDefault
export def "datastore-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-default get-data-stores" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<azureDataLakeSection: record<authorityUrl: string, certificate: string, clientId: string, clientSecret: string, isCertAuth: bool, resourceGroup: string, resourceUri: string, storeName: string, subscriptionId: string, tenantId: string, thumbprint: string>, azurePostgreSqlSection: record<databaseName: string, endpoint: string, portNumber: string, resourceGroup: string, serverName: string, subscriptionId: string, userId: string, userPassword: string>, azureSqlDatabaseSection: record<authorityUrl: string, certificate: string, clientId: string, clientSecret: string, databaseName: string, endpoint: string, isCertAuth: bool, resourceGroup: string, resourceUri: string, serverName: string, subscriptionId: string, tenantId: string, thumbprint: string>, azureStorageSection: record<accountKey: string, accountName: string, areWorkspaceManagedIdentitiesAllowed: bool, blobCacheTimeout: int, clientCredentials: record<authorityUrl: string, certificate: string, clientId: string, clientSecret: string, isCertAuth: bool, resourceGroup: string, resourceUri: string, subscriptionId: string, tenantId: string, thumbprint: string>, containerName: string, credential: string, credentialType: string, endpoint: string, isSas: bool, protocol: string, resourceGroup: string, sasToken: string, subscriptionId: string>, dataStoreType: string, glusterFsSection: record<serverAddress: string, volumeName: string>, hasBeenValidated: bool, name: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/datastore/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/default") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Set a default Datastore.
#
# PUT /datastore/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/default/{name}
# operationId: DataStores_SetDefault
export def "datastore-v1-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-default update-data-stores" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), name: (encode-path-segment $name)} | format pattern "/datastore/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/default/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}
