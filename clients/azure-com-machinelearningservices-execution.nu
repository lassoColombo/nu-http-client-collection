# Auto-generated client for Execution Service v2019-09-30
# Source: https://api.apis.guru/v2/specs/azure.com/machinelearningservices-execution/2019-09-30/swagger.json
# Auth: --token flag or $env.EXECUTION_SERVICE_TOKEN

const BASE_URL = "https://azure.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EXECUTION_SERVICE_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "execution-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-run-id-cancel cancel-run-with-uri" } } | get name | first)
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

# Cancel a run.
#
# POST /execution/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runId/{runId}/cancel
# operationId: Runs_CancelRunWithUri
export def "execution-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-run-id-cancel cancel-run-with-uri" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<runId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id} | format pattern "/execution/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/experiments/{experiment_name}/runId/{run_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start a run from a snapshot on a remote compute target.
#
# POST /execution/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/snapshotrun
# operationId: Runs_StartSnapshotRun
# --configuration shape: {arguments?: list, communicator?: "None"|"ParameterServer"|"Gloo"|"Mpi"|"Nccl", dataReferences?: record, environment?: record, framework?: "Python"|"PySpark"|"Cntk"|"TensorFlow"|"PyTorch", hdi?: record, history?: record, jobName?: string, maxRunDurationSeconds?: int, mpi?: record, nodeCount?: int, script?: string, spark?: record, target?: string, tensorflow?: record}
export def "execution-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-snapshotrun start" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --run-id: string # A run id. If not supplied a run id will be created automatically.
  --configuration: record # shape: {arguments?: list, communicator?: "None"|"ParameterServer"|"Gloo"|"Mpi"|"Nccl", dataReferences?: record, environment?: record, framework?: "Python"|"PySpark"|"Cntk"|"TensorFlow"|"PyTorch", hdi?: record, history?: record, jobName?: string, maxRunDurationSeconds?: int, mpi?: record, nodeCount?: int, script?: string, spark?: record, target?: string, tensorflow?: record}
  --parent-run-id: string # Specifies that the run history entry for this execution should be scoped within an existing run as a child. Defaults to null, meaning the run has no parent. This is intended for first-party service integration, not third-party API users. (e.g. myexperiment_155000000001_0)
  --run-type: string # Specifies the runsource property for this run. The default value is "experiment" if not specified. (e.g. experiment)
  --snapshot-id: string # Snapshots are user project folders that have been uploaded to the cloud for subsequent execution. This field is required when executing against cloud-based compute targets unless the run submission was against the API endpoint that takes a zipped project folder inline with the request. (format: uuid)
]: any -> record<runId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $run_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name} | format pattern "/execution/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/experiments/{experiment_name}/snapshotrun") $qp)
  let body = {"configuration": $configuration, "parentRunId": $parent_run_id, "runType": $run_type, "snapshotId": $snapshot_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start a run on a local machine.
#
# POST /execution/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/startlocalrun
# operationId: Runs_StartLocalRun
# --configuration shape: {arguments?: list, communicator?: "None"|"ParameterServer"|"Gloo"|"Mpi"|"Nccl", dataReferences?: record, environment?: record, framework?: "Python"|"PySpark"|"Cntk"|"TensorFlow"|"PyTorch", hdi?: record, history?: record, jobName?: string, maxRunDurationSeconds?: int, mpi?: record, nodeCount?: int, script?: string, spark?: record, target?: string, tensorflow?: record}
export def "execution-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-startlocalrun start-local-run" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --run-id: string # A run id. If not supplied a run id will be created automatically.
  --configuration: record # shape: {arguments?: list, communicator?: "None"|"ParameterServer"|"Gloo"|"Mpi"|"Nccl", dataReferences?: record, environment?: record, framework?: "Python"|"PySpark"|"Cntk"|"TensorFlow"|"PyTorch", hdi?: record, history?: record, jobName?: string, maxRunDurationSeconds?: int, mpi?: record, nodeCount?: int, script?: string, spark?: record, target?: string, tensorflow?: record}
  --parent-run-id: string # Specifies that the run history entry for this execution should be scoped within an existing run as a child. Defaults to null, meaning the run has no parent. This is intended for first-party service integration, not third-party API users. (e.g. myexperiment_155000000001_0)
  --run-type: string # Specifies the runsource property for this run. The default value is "experiment" if not specified. (e.g. experiment)
  --snapshot-id: string # Snapshots are user project folders that have been uploaded to the cloud for subsequent execution. This field is required when executing against cloud-based compute targets unless the run submission was against the API endpoint that takes a zipped project folder inline with the request. (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $run_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name} | format pattern "/execution/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/experiments/{experiment_name}/startlocalrun") $qp)
  let body = {"configuration": $configuration, "parentRunId": $parent_run_id, "runType": $run_type, "snapshotId": $snapshot_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start a run on a remote compute target.
#
# POST /execution/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/startrun
# operationId: Runs_StartRun
export def "execution-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-startrun start-run" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --run-id: string # A run id. If not supplied a run id will be created automatically.
  run_definition_file: path # The JSON file containing the RunDefinition
  project_zip_file: path # The zip archive of the project folder containing the source code to use for the run.
]: any -> record<runId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $run_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name} | format pattern "/execution/v1.0/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.MachineLearningServices/workspaces/{workspace_name}/experiments/{experiment_name}/startrun") $qp)
  let body = {"runDefinitionFile": $run_definition_file, "projectZipFile": $project_zip_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($run_definition_file | is-not-empty) { $body | upsert runDefinitionFile (open -r $run_definition_file) } else { $body }
  let body = if ($project_zip_file | is-not-empty) { $body | upsert projectZipFile (open -r $project_zip_file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}
