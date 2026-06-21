# Auto-generated client for Artifact v2019-09-30
# Source: https://api.apis.guru/v2/specs/azure.com/machinelearningservices-artifact/2019-09-30/swagger.json
# Auth: --token flag or $env.ARTIFACT_TOKEN

const BASE_URL = "https://azure.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ARTIFACT_TOKEN | default "" }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/octet-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch-metadata get" } } | get name | first)
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
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch-metadata get" [
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
  artifact_ids: list<string> # List of Artifacts Ids.
]: any -> record<artifactContentInformation: record, artifacts: record, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/batch/metadata"))
  let req_body = {"artifactIds": $artifact_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Artifact.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/metadata
# operationId: Artifacts_Create
# --dataPath shape: {dataStoreName?: string, relativePath?: string, sqlDataPath?: record}
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-metadata create" [
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
  --artifact-id: string # The identifier of an Artifact. Format of ArtifactId - {Origin}/{Container}/{Path}.
  container: string # The name of container. Artifacts can be grouped by container.
  --data-path: record # shape: {dataStoreName?: string, relativePath?: string, sqlDataPath?: record}
  origin: string # The origin of the Artifact creation request. Available origins are 'ExperimentRun', 'LocalUpload', 'WebUpload', 'Dataset' and 'Unknown'.
  path: string # The path to the Artifact in a container.
]: any -> record<artifactId: string, container: string, createdTime: string, dataPath: record<dataStoreName: string, relativePath: string, sqlDataPath: record<sqlQuery: string, sqlStoredProcedureName: string, sqlStoredProcedureParams: list, sqlTableName: string>>, etag: string, origin: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/metadata"))
  let req_body = {"artifactId": $artifact_id, "container": $container, "dataPath": $data_path, "origin": $origin, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create an Artifact for an existing data location.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/register
# operationId: Artifacts_Register
# --dataPath shape: {dataStoreName?: string, relativePath?: string, sqlDataPath?: record}
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-register create" [
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
  --artifact-id: string # The identifier of an Artifact. Format of ArtifactId - {Origin}/{Container}/{Path}.
  container: string # The name of container. Artifacts can be grouped by container.
  --data-path: record # shape: {dataStoreName?: string, relativePath?: string, sqlDataPath?: record}
  origin: string # The origin of the Artifact creation request. Available origins are 'ExperimentRun', 'LocalUpload', 'WebUpload', 'Dataset' and 'Unknown'.
  path: string # The path to the Artifact in a container.
]: any -> record<artifactId: string, container: string, createdTime: string, dataPath: record<dataStoreName: string, relativePath: string, sqlDataPath: record<sqlQuery: string, sqlStoredProcedureName: string, sqlStoredProcedureParams: list, sqlTableName: string>>, etag: string, origin: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/register"))
  let req_body = {"artifactId": $artifact_id, "container": $container, "dataPath": $data_path, "origin": $origin, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Batch Artifacts storage by Ids.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/storageuri/batch/metadata
# operationId: Artifacts_BatchGetStorageById
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-storageuri-batch-metadata get-storage" [
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
  artifact_ids: list<string> # List of Artifacts Ids.
]: any -> record<artifactContentInformation: record, artifacts: record, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/storageuri/batch/metadata"))
  let req_body = {"artifactIds": $artifact_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Artifacts metadata in a container or path.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}
# operationId: Artifacts_ListInContainer
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --continuation-token: string # The continuation token.
]: nothing -> record<continuationToken: string, nextLink: string, value: table<artifactId: string, container: string, createdTime: string, dataPath: record, etag: string, origin: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "continuationToken" $continuation_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"path": $path, "continuationToken": $continuation_token} | compact), body: null}
}

# Delete Artifact Metadata.
#
# DELETE /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/batch
# operationId: Artifacts_DeleteMetaDataInContainer
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch delete-meta-data" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard-delete: oneof<nothing, bool> # If set to true. The delete cannot be revert at later time. (default: false)
]: nothing -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "hardDelete" $hard_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hardDelete": $hard_delete} | compact), body: null}
}

# Batch ingest using shared access signature.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/batch/ingest/containersas
# operationId: Artifacts_BatchIngestFromSas
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch-ingest-containersas create-from-sas" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifact-prefix: string # The Prefix to the Artifact in the Blob.
  container_sas: string # The shared access signature of the Container.
  container_uri: string # The URI of the Container.
  --prefix: string # The Prefix to the Blobs in the Container.
]: any -> record<continuationToken: string, nextLink: string, value: table<artifactId: string, container: string, createdTime: string, dataPath: record, etag: string, origin: string, path: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/batch/ingest/containersas"))
  let req_body = {"artifactPrefix": $artifact_prefix, "containerSas": $container_sas, "containerUri": $container_uri, "prefix": $prefix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a batch of empty Artifacts.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/batch/metadata
# operationId: Artifacts_BatchCreateEmptyArtifacts
# --paths item shape: {path: string}
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch-metadata create-empty" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  paths: list # List of Artifact Paths. — item shape: {path: string}
]: any -> record<artifactContentInformation: record, artifacts: record, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/batch/metadata"))
  let req_body = {"paths": $paths} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Batch of Artifact Metadata.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/batch/metadata:delete
# operationId: Artifacts_DeleteBatchMetaData
# --paths item shape: {path: string}
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-batch-metadata-delete delete-meta-data" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard-delete: oneof<nothing, bool> # If set to true, the delete cannot be reverted at a later time. (default: false)
  paths: list # List of Artifact Paths. — item shape: {path: string}
]: any -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "hardDelete" $hard_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/batch/metadata:delete") $qp)
  let req_body = {"paths": $paths} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"hardDelete": $hard_delete} | compact), body: $req_body}
}

# Get Artifact content by Id.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/content
# operationId: Artifacts_Download
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-content download" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --path: string # The Artifact Path.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/content") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"path": $path} | compact), body: null}
}

# Upload Artifact content.
#
# POST /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/content
# operationId: Artifacts_Upload
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-content upload" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --index: int # The index. (format: int32)
  --append: oneof<nothing, bool> # Whether or not to append the content or replace it. (default: false)
  --allow-overwrite: oneof<nothing, bool> # whether to allow overwrite if Artifact Content exist already. when set to true, Overwrite happens if Artifact Content already exists (default: false)
  --body: string
]: any -> record<artifactId: string, container: string, createdTime: string, dataPath: record<dataStoreName: string, relativePath: string, sqlDataPath: record<sqlQuery: string, sqlStoredProcedureName: string, sqlStoredProcedureParams: list, sqlTableName: string>>, etag: string, origin: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "index" $index "scalar") (serialize-qp "append" $append "scalar") (serialize-qp "allowOverwrite" $allow_overwrite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/content") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body {query: ({"path": $path, "index": $index, "append": $append, "allowOverwrite": $allow_overwrite} | compact), body: $req_body}
}

# Get Artifact content information.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/contentinfo
# operationId: Artifacts_GetContentInformation
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-contentinfo get-content-information" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> record<container: string, contentUri: string, origin: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/contentinfo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"path": $path} | compact), body: null}
}

# Get Artifact storage content information.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/contentinfo/storageuri
# operationId: Artifacts_GetStorageContentInformation
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-contentinfo-storageuri get-storage-content-information" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> record<container: string, contentUri: string, origin: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/contentinfo/storageuri") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"path": $path} | compact), body: null}
}

# Delete Artifact Metadata.
#
# DELETE /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/metadata
# operationId: Artifacts_DeleteMetaData
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-metadata delete-meta-data" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --hard-delete: oneof<nothing, bool> # If set to true. The delete cannot be revert at later time. (default: false)
]: nothing -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "hardDelete" $hard_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/metadata") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"path": $path, "hardDelete": $hard_delete} | compact), body: null}
}

# Get Artifact metadata by Id.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/metadata
# operationId: Artifacts_Get
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-metadata get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> record<artifactId: string, container: string, createdTime: string, dataPath: record<dataStoreName: string, relativePath: string, sqlDataPath: record<sqlQuery: string, sqlStoredProcedureName: string, sqlStoredProcedureParams: list, sqlTableName: string>>, etag: string, origin: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/metadata") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"path": $path} | compact), body: null}
}

# Get shared access signature for an Artifact
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/prefix/contentinfo
# operationId: Artifacts_ListSasByPrefix
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-prefix-contentinfo list-sas" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --continuation-token: string # The continuation token.
]: nothing -> record<continuationToken: string, nextLink: string, value: table<container: string, contentUri: string, origin: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "continuationToken" $continuation_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/prefix/contentinfo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"path": $path, "continuationToken": $continuation_token} | compact), body: null}
}

# Get storage Uri for Artifacts in a path.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/prefix/contentinfo/storageuri
# operationId: Artifacts_ListStorageUriByPrefix
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-prefix-contentinfo-storageuri list-storage-uri" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --continuation-token: string # The continuation token.
]: nothing -> record<continuationToken: string, nextLink: string, value: table<container: string, contentUri: string, origin: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "continuationToken" $continuation_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/prefix/contentinfo/storageuri") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"path": $path, "continuationToken": $continuation_token} | compact), body: null}
}

# Get writable shared access signature for Artifact.
#
# GET /artifact/v2.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/artifacts/{origin}/{container}/write
# operationId: Artifacts_GetSas
export def "artifact-v2-0-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-artifacts-write get-sas" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  origin: string
  container: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> record<container: string, contentUri: string, origin: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($container | is-empty) { error make --unspanned { msg: "path parameter 'container' must be non-empty" } }
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), origin: (encode-path-segment $origin), container: (encode-path-segment $container)} | format pattern "/artifact/v2.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/artifacts/{origin}/{container}/write") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"path": $path} | compact), body: null}
}
