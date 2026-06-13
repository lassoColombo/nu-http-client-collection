# Auto-generated client for Artifact v2019-09-30
# Source: https://api.apis.guru/v2/specs/azure.com/machinelearningservices-artifact/2019-09-30/swagger.json
# Auth: --token flag or $env.ARTIFACT_TOKEN

const BASE_URL = "https://azure.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ARTIFACT_TOKEN | default "" }
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

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/octet-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch-metadata BatchGetById" } } | get name | first)
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

# Get Batch Artifacts by Ids.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/batch/metadata
# operationId: Artifacts_BatchGetById
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch-metadata BatchGetById" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  artifactIds: list # List of Artifacts Ids.
]: any -> record<artifactContentInformation: record, artifacts: record, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/batch/metadata")
  let body = {artifactIds: $artifactIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Artifact.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/metadata
# operationId: Artifacts_Create
# --dataPath shape: {dataStoreName?: string, relativePath?: string, sqlDataPath?: record}
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-metadata Create" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifactId: string # The identifier of an Artifact. Format of ArtifactId - {Origin}/{Container}/{Path}.
  container: string # The name of container. Artifacts can be grouped by container.
  --dataPath: record # shape: {dataStoreName?: string, relativePath?: string, sqlDataPath?: record}
  origin: string # The origin of the Artifact creation request. Available origins are 'ExperimentRun', 'LocalUpload', 'WebUpload', 'Dataset' and 'Unknown'.
  path: string # The path to the Artifact in a container.
]: any -> record<artifactId: string, container: string, createdTime: string, dataPath: record<dataStoreName: string, relativePath: string, sqlDataPath: record<sqlQuery: string, sqlStoredProcedureName: string, sqlStoredProcedureParams: list, sqlTableName: string>>, etag: string, origin: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/metadata")
  let body = {artifactId: $artifactId, container: $container, dataPath: $dataPath, origin: $origin, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an Artifact for an existing data location.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/register
# operationId: Artifacts_Register
# --dataPath shape: {dataStoreName?: string, relativePath?: string, sqlDataPath?: record}
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-register Register" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifactId: string # The identifier of an Artifact. Format of ArtifactId - {Origin}/{Container}/{Path}.
  container: string # The name of container. Artifacts can be grouped by container.
  --dataPath: record # shape: {dataStoreName?: string, relativePath?: string, sqlDataPath?: record}
  origin: string # The origin of the Artifact creation request. Available origins are 'ExperimentRun', 'LocalUpload', 'WebUpload', 'Dataset' and 'Unknown'.
  path: string # The path to the Artifact in a container.
]: any -> record<artifactId: string, container: string, createdTime: string, dataPath: record<dataStoreName: string, relativePath: string, sqlDataPath: record<sqlQuery: string, sqlStoredProcedureName: string, sqlStoredProcedureParams: list, sqlTableName: string>>, etag: string, origin: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/register")
  let body = {artifactId: $artifactId, container: $container, dataPath: $dataPath, origin: $origin, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Batch Artifacts storage by Ids.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/storageuri/batch/metadata
# operationId: Artifacts_BatchGetStorageById
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-storageuri-batch-metadata BatchGetStorageById" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  artifactIds: list # List of Artifacts Ids.
]: any -> record<artifactContentInformation: record, artifacts: record, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/storageuri/batch/metadata")
  let body = {artifactIds: $artifactIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Artifacts metadata in a container or path.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}
# operationId: Artifacts_ListInContainer
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts ListInContainer" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --continuationToken: string # The continuation token.
]: nothing -> record<continuationToken: string, nextLink: string, value: table<artifactId: string, container: string, createdTime: string, dataPath: record, etag: string, origin: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "continuationToken" $continuationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Artifact Metadata.
#
# DELETE /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/batch
# operationId: Artifacts_DeleteMetaDataInContainer
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch DeleteMetaDataInContainer" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hardDelete: oneof<nothing, bool> # If set to true. The delete cannot be revert at later time. (default: false)
]: nothing -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/batch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Batch ingest using shared access signature.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/batch/ingest/containersas
# operationId: Artifacts_BatchIngestFromSas
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch-ingest-containersas BatchIngestFromSas" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifactPrefix: string # The Prefix to the Artifact in the Blob.
  containerSas: string # The shared access signature of the Container.
  containerUri: string # The URI of the Container.
  --prefix: string # The Prefix to the Blobs in the Container.
]: any -> record<continuationToken: string, nextLink: string, value: table<artifactId: string, container: string, createdTime: string, dataPath: record, etag: string, origin: string, path: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/batch/ingest/containersas")
  let body = {artifactPrefix: $artifactPrefix, containerSas: $containerSas, containerUri: $containerUri, prefix: $prefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a batch of empty Artifacts.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/batch/metadata
# operationId: Artifacts_BatchCreateEmptyArtifacts
# --paths item shape: {path: string}
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch-metadata BatchCreateEmptyArtifacts" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  paths: list # List of Artifact Paths. — item shape: {path: string}
]: any -> record<artifactContentInformation: record, artifacts: record, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/batch/metadata")
  let body = {paths: $paths} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Batch of Artifact Metadata.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/batch/metadata:delete
# operationId: Artifacts_DeleteBatchMetaData
# --paths item shape: {path: string}
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch-metadata-delete DeleteBatchMetaData" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hardDelete: oneof<nothing, bool> # If set to true, the delete cannot be reverted at a later time. (default: false)
  paths: list # List of Artifact Paths. — item shape: {path: string}
]: any -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/batch/metadata:delete" $qp)
  let body = {paths: $paths} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Artifact content by Id.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/content
# operationId: Artifacts_Download
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-content Download" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --path: string # The Artifact Path.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/content" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload Artifact content.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/content
# operationId: Artifacts_Upload
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-content Upload" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --index: int # The index. (format: int32)
  --append: oneof<nothing, bool> # Whether or not to append the content or replace it. (default: false)
  --allowOverwrite: oneof<nothing, bool> # whether to allow overwrite if Artifact Content exist already. when set to true, Overwrite happens if Artifact Content already exists (default: false)
  --body: record
]: any -> record<artifactId: string, container: string, createdTime: string, dataPath: record<dataStoreName: string, relativePath: string, sqlDataPath: record<sqlQuery: string, sqlStoredProcedureName: string, sqlStoredProcedureParams: list, sqlTableName: string>>, etag: string, origin: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "index" $index "scalar") (serialize-qp "append" $append "scalar") (serialize-qp "allowOverwrite" $allowOverwrite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/content" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Artifact content information.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/contentinfo
# operationId: Artifacts_GetContentInformation
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-contentinfo GetContentInformation" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> record<container: string, contentUri: string, origin: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/contentinfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Artifact storage content information.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/contentinfo/storageuri
# operationId: Artifacts_GetStorageContentInformation
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-contentinfo-storageuri GetStorageContentInformation" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> record<container: string, contentUri: string, origin: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/contentinfo/storageuri" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Artifact Metadata.
#
# DELETE /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/metadata
# operationId: Artifacts_DeleteMetaData
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-metadata DeleteMetaData" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --hardDelete: oneof<nothing, bool> # If set to true. The delete cannot be revert at later time. (default: false)
]: nothing -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Artifact metadata by Id.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/metadata
# operationId: Artifacts_Get
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-metadata Get" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> record<artifactId: string, container: string, createdTime: string, dataPath: record<dataStoreName: string, relativePath: string, sqlDataPath: record<sqlQuery: string, sqlStoredProcedureName: string, sqlStoredProcedureParams: list, sqlTableName: string>>, etag: string, origin: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get shared access signature for an Artifact
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/prefix/contentinfo
# operationId: Artifacts_ListSasByPrefix
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-prefix-contentinfo ListSasByPrefix" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --continuationToken: string # The continuation token.
]: nothing -> record<continuationToken: string, nextLink: string, value: table<container: string, contentUri: string, origin: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "continuationToken" $continuationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/prefix/contentinfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get storage Uri for Artifacts in a path.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/prefix/contentinfo/storageuri
# operationId: Artifacts_ListStorageUriByPrefix
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-prefix-contentinfo-storageuri ListStorageUriByPrefix" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --continuationToken: string # The continuation token.
]: nothing -> record<continuationToken: string, nextLink: string, value: table<container: string, contentUri: string, origin: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "continuationToken" $continuationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/prefix/contentinfo/storageuri" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get writable shared access signature for Artifact.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/write
# operationId: Artifacts_GetSas
export def "artifact-v20-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-write GetSas" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> record<container: string, contentUri: string, origin: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/artifact/v2.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/artifacts/($origin)/($container)/write" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
