# Auto-generated client for Kubeflow Pipelines API v2.16.1
# Source: https://raw.githubusercontent.com/kubeflow/pipelines/master/backend/api/v2beta1/swagger/kfp_api_single_file.swagger.json
# Auth: --token flag or $env.KUBEFLOW_PIPELINES_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KUBEFLOW_PIPELINES_API_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def base-url-completer [] { ["http://localhost" "https://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resources-completer [] { ["UNASSIGNED_RESOURCES" "VIEWERS"] }
def verb-completer [] { ["CREATE" "DELETE" "GET" "UNASSIGNED_VERB"] }
def storage-state-completer [] { ["ARCHIVED" "AVAILABLE" "STORAGE_STATE_UNSPECIFIED"] }
def mode-completer [] { ["DISABLE" "ENABLE" "MODE_UNSPECIFIED"] }
def status-completer [] { ["DISABLED" "ENABLED" "STATUS_UNSPECIFIED"] }
def propagation-policy-completer [] { ["BACKGROUND" "DELETE_PROPAGATION_POLICY_UNSPECIFIED" "FOREGROUND" "ORPHAN"] }
def state-completer [] { ["CANCELED" "CANCELING" "FAILED" "PAUSED" "PENDING" "RUNNING" "RUNTIME_STATE_UNSPECIFIED" "SKIPPED" "SUCCEEDED"] }
def type-completer [] { ["CUSTOM" "ROC_CURVE" "TABLE" "TFDV" "TFMA"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apis-v2beta1-auth Authorize" } } | get name | first)
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

# GET /apis/v2beta1/auth
#
# operationId: AuthService_Authorize
export def "apis-v2beta1-auth Authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # Namespace the resource belongs to.
  --resources: string@resources-completer # Resource type asking for authorization. (default: UNASSIGNED_RESOURCES)
  --verb: string@verb-completer # Verb on the resource asking for authorization. (default: UNASSIGNED_VERB)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "resources" $resources "scalar") (serialize-qp "verb" $verb "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apis/v2beta1/auth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Finds all experiments. Supports pagination, and sorting on certain fields.
#
# GET /apis/v2beta1/experiments
# operationId: ExperimentService_ListExperiments
export def "apis-v2beta1-experiments ListExperiments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-token: string # A page token to request the next page of results. The token is acquried from the nextPageToken field of the response from the previous ListExperiments call or can be omitted when fetching the first page.
  --page-size: int # The number of experiments to be listed per page. If there are more experiments than this number, the response message will contain a nextPageToken field you can use to fetch the next page. (format: int32)
  --sort-by: string # Can be format of "field_name", "field_name asc" or "field_name desc" Ascending by default.
  --filter: string # A url-encoded, JSON-serialized Filter protocol buffer (see [filter.proto](https://github.com/kubeflow/pipelines/blob/master/backend/api/v2beta1/api/filter.proto)).
  --namespace: string # Which namespace to filter the experiments on.
]: nothing -> record<experiments: table<experiment_id: string, display_name: string, description: string, created_at: string, namespace: string, storage_state: string, last_run_created_at: string>, total_size: int, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_token" $page_token "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apis/v2beta1/experiments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new experiment.
#
# POST /apis/v2beta1/experiments
# operationId: ExperimentService_CreateExperiment
export def "apis-v2beta1-experiments CreateExperiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --experiment-id: string # Output. Unique experiment ID. Generated by API server.
  --display-name: string # Required input field. Unique experiment name provided by user.
  --description: string # Optional input field. Describes the purpose of the experiment.
  --created-at: string # Output. The time that the experiment was created. (format: date-time)
  --namespace: string # Optional input field. Specify the namespace this experiment belongs to.
  --storage-state: string@storage-state-completer # Describes whether an entity is available or archived.   - STORAGE_STATE_UNSPECIFIED: Default state. This state in not used  - AVAILABLE: Entity is available.  - ARCHIVED: Entity is archived. (default: STORAGE_STATE_UNSPECIFIED)
  --last-run-created-at: string # Output. The creation time of the last run in this experiment. (format: date-time)
]: any -> record<experiment_id: string, display_name: string, description: string, created_at: string, namespace: string, storage_state: string, last_run_created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apis/v2beta1/experiments")
  let body = {experiment_id: $experiment_id, display_name: $display_name, description: $description, created_at: $created_at, namespace: $namespace, storage_state: $storage_state, last_run_created_at: $last_run_created_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finds a specific experiment by ID.
#
# GET /apis/v2beta1/experiments/{experiment_id}
# operationId: ExperimentService_GetExperiment
export def "apis-v2beta1-experiments GetExperiment" [
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<experiment_id: string, display_name: string, description: string, created_at: string, namespace: string, storage_state: string, last_run_created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/experiments/($experiment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an experiment without deleting the experiment's runs and recurring  runs. To avoid unexpected behaviors, delete an experiment's runs and recurring  runs before deleting the experiment.
#
# DELETE /apis/v2beta1/experiments/{experiment_id}
# operationId: ExperimentService_DeleteExperiment
export def "apis-v2beta1-experiments DeleteExperiment" [
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/experiments/($experiment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archives an experiment and the experiment's runs and recurring runs.
#
# POST /apis/v2beta1/experiments/{experiment_id}:archive
# operationId: ExperimentService_ArchiveExperiment
export def "apis-v2beta1-experiments ArchiveExperiment" [
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/experiments/($experiment_id):archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restores an archived experiment. The experiment's archived runs and recurring runs will stay archived.
#
# POST /apis/v2beta1/experiments/{experiment_id}:unarchive
# operationId: ExperimentService_UnarchiveExperiment
export def "apis-v2beta1-experiments UnarchiveExperiment" [
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/experiments/($experiment_id):unarchive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get healthz data.
#
# GET /apis/v2beta1/healthz
# operationId: HealthzService_GetHealthz
export def "apis-v2beta1-healthz GetHealthz" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<multi_user: bool, pipeline_store: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apis/v2beta1/healthz")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Finds all pipelines within a namespace.
#
# GET /apis/v2beta1/pipelines
# operationId: PipelineService_ListPipelines
export def "apis-v2beta1-pipelines ListPipelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # Optional input. Namespace for the pipelines.
  --page-token: string # A page token to request the results page.
  --page-size: int # The number of pipelines to be listed per page. If there are more pipelines than this number, the response message will contain a valid value in the nextPageToken field. (format: int32)
  --sort-by: string # Sorting order in form of "field_name", "field_name asc" or "field_name desc". Ascending by default.
  --filter: string # A url-encoded, JSON-serialized filter protocol buffer (see [filter.proto](https://github.com/kubeflow/pipelines/blob/master/backend/api/filter.proto)).
]: nothing -> record<pipelines: table<pipeline_id: string, display_name: string, name: string, description: string, created_at: string, namespace: string, error: record, tags: record>, total_size: int, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apis/v2beta1/pipelines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a pipeline.
#
# POST /apis/v2beta1/pipelines
# operationId: PipelineService_CreatePipeline
# --error shape: {code?: int, message?: string, details?: list}
export def "apis-v2beta1-pipelines CreatePipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pipeline-id: string # Output. Unique pipeline ID. Generated by API server.
  --display-name: string # Optional input field. Pipeline display name provided by user.
  --name: string # Required input field. Pipeline name provided by user.
  --description: string # Optional input field. A short description of the pipeline.
  --created-at: string # Output. Creation time of the pipeline. (format: date-time)
  --namespace: string # Input. A namespace this pipeline belongs to. Causes error if user is not authorized to access the specified namespace. If not specified in CreatePipeline, default namespace is used.
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details.  You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, message?: string, details?: list}
  --tags: record # Optional. User-defined tags as key-value pairs associated with the pipeline. Both keys and values are limited to 63 characters.
]: any -> record<pipeline_id: string, display_name: string, name: string, description: string, created_at: string, namespace: string, error: record<code: int, message: string, details: list<record>>, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apis/v2beta1/pipelines")
  let body = {pipeline_id: $pipeline_id, display_name: $display_name, name: $name, description: $description, created_at: $created_at, namespace: $namespace, error: $body_error, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new pipeline and a new pipeline version in a single transaction.
#
# POST /apis/v2beta1/pipelines/create
# operationId: PipelineService_CreatePipelineAndVersion
# --pipeline shape: {pipeline_id?: string, display_name?: string, name?: string, description?: string, created_at?: string, namespace?: string, error?: record, tags?: record}
# --pipeline_version shape: {pipeline_id?: string, pipeline_version_id?: string, display_name?: string, name?: string, description?: string, created_at?: string, package_url?: record, code_source_url?: string, pipeline_spec?: record, error?: record, tags?: record}
export def "apis-v2beta1-pipelines-create CreatePipelineAndVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pipeline: record # shape: {pipeline_id?: string, display_name?: string, name?: string, description?: string, created_at?: string, namespace?: string, error?: record, tags?: record}
  --pipeline-version: record # shape: {pipeline_id?: string, pipeline_version_id?: string, display_name?: string, name?: string, description?: string, created_at?: string, package_url?: record, code_source_url?: string, pipeline_spec?: record, error?: record, tags?: record}
]: any -> record<pipeline_id: string, display_name: string, name: string, description: string, created_at: string, namespace: string, error: record<code: int, message: string, details: list<record>>, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apis/v2beta1/pipelines/create")
  let body = {pipeline: $pipeline, pipeline_version: $pipeline_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finds a specific pipeline by name and namespace.
#
# GET /apis/v2beta1/pipelines/names/{name}
# operationId: PipelineService_GetPipelineByName
export def "apis-v2beta1-pipelines-names GetPipelineByName" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # Optional input. Namespace of the pipeline.  It could be empty if default namespaces needs to be used or if multi-user  support is turned off.
]: nothing -> record<pipeline_id: string, display_name: string, name: string, description: string, created_at: string, namespace: string, error: record<code: int, message: string, details: list<record>>, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apis/v2beta1/pipelines/names/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a pipeline's mutable fields (display_name, tags).
#
# PATCH /apis/v2beta1/pipelines/{pipeline.pipeline_id}
# operationId: PipelineService_UpdatePipeline
# --error shape: {code?: int, message?: string, details?: list}
export def "apis-v2beta1-pipelines UpdatePipeline" [
  pipeline.pipeline_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --display-name: string # Required if name is not provided. Pipeline display name provided by user.
  --name: string # Required if display_name is not provided. Pipeline name provided by user.
  --description: string # Optional input field. A short description of the pipeline.
  --created-at: string # Output. Creation time of the pipeline. (format: date-time)
  --namespace: string # Input. A namespace this pipeline belongs to. Causes error if user is not authorized to access the specified namespace. If not specified in CreatePipeline, default namespace is used.
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details.  You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, message?: string, details?: list}
  --tags: record # Optional. User-defined tags as key-value pairs associated with the pipeline. Tags can be used to label and categorize pipelines. Constraints:   - Maximum 20 tags per pipeline.   - Both key and value are limited to 63 characters.   - Keys cannot be empty and must not contain the '.' character. Tags can be filtered on when listing pipelines using the filter parameter with keys prefixed by "tags." (e.g., filter predicate key "tags.team" with string_value "ml-ops").
]: any -> record<pipeline_id: string, display_name: string, name: string, description: string, created_at: string, namespace: string, error: record<code: int, message: string, details: list<record>>, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/pipelines/($pipeline.pipeline_id)")
  let body = {display_name: $display_name, name: $name, description: $description, created_at: $created_at, namespace: $namespace, error: $body_error, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finds a specific pipeline by ID.
#
# GET /apis/v2beta1/pipelines/{pipeline_id}
# operationId: PipelineService_GetPipeline
export def "apis-v2beta1-pipelines GetPipeline" [
  pipeline_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pipeline_id: string, display_name: string, name: string, description: string, created_at: string, namespace: string, error: record<code: int, message: string, details: list<record>>, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/pipelines/($pipeline_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a pipeline by ID. If cascade is false (default), it returns an error if the pipeline has any versions. If cascade is true, it will also delete all pipeline versions.
#
# DELETE /apis/v2beta1/pipelines/{pipeline_id}
# operationId: PipelineService_DeletePipeline
export def "apis-v2beta1-pipelines DeletePipeline" [
  pipeline_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cascade: oneof<nothing, bool> # Optional. If true, the pipeline and all its versions will be deleted. If false (default), only the pipeline will be deleted if it has no versions.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cascade" $cascade "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apis/v2beta1/pipelines/($pipeline_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all pipeline versions of a given pipeline ID.
#
# GET /apis/v2beta1/pipelines/{pipeline_id}/versions
# operationId: PipelineService_ListPipelineVersions
export def "apis-v2beta1-pipelines-versions ListPipelineVersions" [
  pipeline_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-token: string # A page token to request the results page.
  --page-size: int # The number of pipeline versions to be listed per page. If there are more pipeline versions than this number, the response message will contain a valid value in the nextPageToken field. (format: int32)
  --sort-by: string # Sorting order in form of "field_name", "field_name asc" or "field_name desc". Ascending by default.
  --filter: string # A url-encoded, JSON-serialized filter protocol buffer (see [filter.proto](https://github.com/kubeflow/pipelines/blob/master/backend/api/filter.proto)).
]: nothing -> record<pipeline_versions: table<pipeline_id: string, pipeline_version_id: string, display_name: string, name: string, description: string, created_at: string, package_url: record, code_source_url: string, pipeline_spec: record, error: record, tags: record>, next_page_token: string, total_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_token" $page_token "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apis/v2beta1/pipelines/($pipeline_id)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a pipeline version to the specified pipeline ID.
#
# POST /apis/v2beta1/pipelines/{pipeline_id}/versions
# operationId: PipelineService_CreatePipelineVersion
# --package_url shape: {pipeline_url?: string}
# --error shape: {code?: int, message?: string, details?: list}
export def "apis-v2beta1-pipelines-versions CreatePipelineVersion" [
  pipeline_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-pipeline-id: string # Required input field. Unique ID of the parent pipeline.
  --pipeline-version-id: string # Output. Unique pipeline version ID. Generated by API server.
  --display-name: string # Optional input field. Pipeline version display name provided by user.
  --name: string # Required input field. Pipeline version name provided by user.
  --description: string # Optional input field. Short description of the pipeline version.
  --created-at: string # Output. Creation time of the pipeline version. (format: date-time)
  --package-url: record # shape: {pipeline_url?: string}
  --code-source-url: string # Input. Optional. The URL to the code source of the pipeline version. The code is usually the Python definition of the pipeline and potentially related the component definitions. This allows users to trace back to how the pipeline YAML was created.
  --pipeline-spec: record # Output. The pipeline spec for the pipeline version.
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details.  You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, message?: string, details?: list}
  --tags: record # Optional input field. User-defined tags (key-value pairs) for the pipeline version. Both keys and values are limited to 63 characters.
]: any -> record<pipeline_id: string, pipeline_version_id: string, display_name: string, name: string, description: string, created_at: string, package_url: record<pipeline_url: string>, code_source_url: string, pipeline_spec: record, error: record<code: int, message: string, details: list<record>>, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/pipelines/($pipeline_id)/versions")
  let body = {pipeline_id: $body_pipeline_id, pipeline_version_id: $pipeline_version_id, display_name: $display_name, name: $name, description: $description, created_at: $created_at, package_url: $package_url, code_source_url: $code_source_url, pipeline_spec: $pipeline_spec, error: $body_error, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a pipeline version by pipeline version ID and pipeline ID.
#
# GET /apis/v2beta1/pipelines/{pipeline_id}/versions/{pipeline_version_id}
# operationId: PipelineService_GetPipelineVersion
export def "apis-v2beta1-pipelines-versions GetPipelineVersion" [
  pipeline_id: string
  pipeline_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pipeline_id: string, pipeline_version_id: string, display_name: string, name: string, description: string, created_at: string, package_url: record<pipeline_url: string>, code_source_url: string, pipeline_spec: record, error: record<code: int, message: string, details: list<record>>, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/pipelines/($pipeline_id)/versions/($pipeline_version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a specific pipeline version by pipeline version ID and pipeline ID.
#
# DELETE /apis/v2beta1/pipelines/{pipeline_id}/versions/{pipeline_version_id}
# operationId: PipelineService_DeletePipelineVersion
export def "apis-v2beta1-pipelines-versions DeletePipelineVersion" [
  pipeline_id: string
  pipeline_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/pipelines/($pipeline_id)/versions/($pipeline_version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a pipeline version's mutable fields (display_name, tags).
#
# PATCH /apis/v2beta1/pipelines/{pipeline_version.pipeline_id}/versions/{pipeline_version.pipeline_version_id}
# operationId: PipelineService_UpdatePipelineVersion
# --package_url shape: {pipeline_url?: string}
# --error shape: {code?: int, message?: string, details?: list}
export def "apis-v2beta1-pipelines-versions UpdatePipelineVersion" [
  pipeline_version.pipeline_id: string
  pipeline_version.pipeline_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --display-name: string # Required if name is not provided. Pipeline version display name provided by user. This is ignored in CreatePipelineAndVersion API.
  --name: string # Required if display_name is not provided. Pipeline version name provided by user. This is ignored in CreatePipelineAndVersion API.
  --description: string # Optional input field. Short description of the pipeline version. This is ignored in CreatePipelineAndVersion API.
  --created-at: string # Output. Creation time of the pipeline version. (format: date-time)
  --package-url: record # shape: {pipeline_url?: string}
  --code-source-url: string # Input. Optional. The URL to the code source of the pipeline version. The code is usually the Python definition of the pipeline and potentially related the component definitions. This allows users to trace back to how the pipeline YAML was created.
  --pipeline-spec: record # Output. The pipeline spec for the pipeline version.
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details.  You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, message?: string, details?: list}
  --tags: record # Optional input field. User-defined tags (key-value pairs) for the pipeline version. Constraints:   - Maximum 20 tags per pipeline version.   - Both keys and values are limited to 63 characters.   - Keys cannot be empty and must not contain the '.' character. Tags are stored in a separate table and can be retrieved via Get and List APIs.
]: any -> record<pipeline_id: string, pipeline_version_id: string, display_name: string, name: string, description: string, created_at: string, package_url: record<pipeline_url: string>, code_source_url: string, pipeline_spec: record, error: record<code: int, message: string, details: list<record>>, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/pipelines/($pipeline_version.pipeline_id)/versions/($pipeline_version.pipeline_version_id)")
  let body = {display_name: $display_name, name: $name, description: $description, created_at: $created_at, package_url: $package_url, code_source_url: $code_source_url, pipeline_spec: $pipeline_spec, error: $body_error, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /apis/v2beta1/pipelines/upload
#
# operationId: UploadPipeline
export def "apis-v2beta1-pipelines-upload UploadPipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --display-name: string
  --description: string
  --namespace: string
  --tags: string # JSON-encoded map of key-value pairs for pipeline tags.
  uploadfile: path # The pipeline to upload. Maximum size of 32MB is supported.
]: any -> record<pipeline_id: string, display_name: string, name: string, description: string, created_at: string, namespace: string, error: record<code: int, message: string, details: list<record>>, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "display_name" $display_name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apis/v2beta1/pipelines/upload" $qp)
  let body = {uploadfile: $uploadfile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($uploadfile | is-not-empty) { $body | upsert uploadfile (open -r $uploadfile) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# POST /apis/v2beta1/pipelines/upload_version
#
# operationId: UploadPipelineVersion
export def "apis-v2beta1-pipelines-upload-version UploadPipelineVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --display-name: string
  --pipelineid: string
  --description: string
  --tags: string # JSON-encoded map of key-value pairs for pipeline version tags.
  uploadfile: path # The pipeline to upload. Maximum size of 32MB is supported.
]: any -> record<pipeline_id: string, pipeline_version_id: string, display_name: string, name: string, description: string, created_at: string, package_url: record<pipeline_url: string>, code_source_url: string, pipeline_spec: record, error: record<code: int, message: string, details: list<record>>, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "display_name" $display_name "scalar") (serialize-qp "pipelineid" $pipelineid "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apis/v2beta1/pipelines/upload_version" $qp)
  let body = {uploadfile: $uploadfile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($uploadfile | is-not-empty) { $body | upsert uploadfile (open -r $uploadfile) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Finds all recurring runs given experiment and namespace. If experiment ID is not specified, find all recurring runs across all experiments.
#
# GET /apis/v2beta1/recurringruns
# operationId: RecurringRunService_ListRecurringRuns
export def "apis-v2beta1-recurringruns ListRecurringRuns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-token: string # A page token to request the next page of results. The token is acquired from the nextPageToken field of the response from the previous ListRecurringRuns call or can be omitted when fetching the first page.
  --page-size: int # The number of recurring runs to be listed per page. If there are more recurring runs than this number, the response message will contain a nextPageToken field you can use to fetch the next page. (format: int32)
  --sort-by: string # Can be formatted as "field_name", "field_name asc" or "field_name desc". Ascending by default.
  --namespace: string # Optional input. The namespace the recurring runs belong to.
  --filter: string # A url-encoded, JSON-serialized Filter protocol buffer (see [filter.proto](https://github.com/kubeflow/pipelines/blob/master/backend/api/filter.proto)).
  --experiment-id: string # The ID of the experiment to be retrieved. If empty, list recurring runs across all experiments.
]: nothing -> record<recurringRuns: table<recurring_run_id: string, display_name: string, description: string, pipeline_version_id: string, pipeline_spec: record, pipeline_version_reference: record, runtime_config: record, service_account: string, max_concurrency: string, trigger: record, mode: string, created_at: string, updated_at: string, status: string, error: record, no_catchup: bool, namespace: string, experiment_id: string, plugins_input: record>, total_size: int, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_token" $page_token "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "experiment_id" $experiment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apis/v2beta1/recurringruns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new recurring run in an experiment, given the experiment ID.
#
# POST /apis/v2beta1/recurringruns
# operationId: RecurringRunService_CreateRecurringRun
# --pipeline_version_reference shape: {pipeline_id?: string, pipeline_version_id?: string}
# --runtime_config shape: {parameters?: record, pipeline_root?: string}
# --trigger shape: {cron_schedule?: record, periodic_schedule?: record}
# --error shape: {code?: int, message?: string, details?: list}
export def "apis-v2beta1-recurringruns CreateRecurringRun" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recurring-run-id: string # Output. Unique run ID generated by API server.
  --display-name: string # Required input field. Recurring run name provided by user. Not unique.
  --description: string # Optional input field. Describes the purpose of the recurring run.
  --pipeline-version-id: string # This field is Deprecated. The pipeline version id is under pipeline_version_reference for v2.
  --pipeline-spec: record # The pipeline spec.
  --pipeline-version-reference: record # Reference to an existing pipeline version. — shape: {pipeline_id?: string, pipeline_version_id?: string}
  --runtime-config: record # The runtime config. — shape: {parameters?: record, pipeline_root?: string}
  --service-account: string # Optional input field. Specifies which Kubernetes service account this recurring run uses.
  --max-concurrency: string # Required input field. Specifies how many runs can be executed concurrently. Range [1-10]. (format: int64)
  --trigger: record # Trigger defines what starts a pipeline run. — shape: {cron_schedule?: record, periodic_schedule?: record}
  --mode: string@mode-completer # Required input. User setting to enable or disable the recurring run. Only used for creation of recurring runs. Later updates use enable/disable API.   - DISABLE: The recurring run won't schedule any run if disabled. (default: MODE_UNSPECIFIED)
  --created-at: string # Output. The time this recurring run was created. (format: date-time)
  --updated-at: string # Output. The last time this recurring run was updated. (format: date-time)
  --status: string@status-completer # Output. The status of the recurring run. (default: STATUS_UNSPECIFIED)
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details.  You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, message?: string, details?: list}
  --no-catchup: oneof<nothing, bool> # Optional input field. Whether the recurring run should catch up if behind schedule. If true, the recurring run will only schedule the latest interval if behind schedule. If false, the recurring run will catch up on each past interval.
  --experiment-id: string # ID of the parent experiment this recurring run belongs to.
  --plugins-input: record # Optional input. Plugin inputs to propagate to each triggered run. Each triggered run will inherit these values in its plugins_input field.
]: any -> record<recurring_run_id: string, display_name: string, description: string, pipeline_version_id: string, pipeline_spec: record, pipeline_version_reference: record<pipeline_id: string, pipeline_version_id: string>, runtime_config: record<parameters: record, pipeline_root: string>, service_account: string, max_concurrency: string, trigger: record<cron_schedule: record<start_time: string, end_time: string, cron: string>, periodic_schedule: record<start_time: string, end_time: string, interval_second: string>>, mode: string, created_at: string, updated_at: string, status: string, error: record<code: int, message: string, details: list<record>>, no_catchup: bool, namespace: string, experiment_id: string, plugins_input: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apis/v2beta1/recurringruns")
  let body = {recurring_run_id: $recurring_run_id, display_name: $display_name, description: $description, pipeline_version_id: $pipeline_version_id, pipeline_spec: $pipeline_spec, pipeline_version_reference: $pipeline_version_reference, runtime_config: $runtime_config, service_account: $service_account, max_concurrency: $max_concurrency, trigger: $trigger, mode: $mode, created_at: $created_at, updated_at: $updated_at, status: $status, error: $body_error, no_catchup: $no_catchup, experiment_id: $experiment_id, plugins_input: $plugins_input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finds a specific recurring run by ID.
#
# GET /apis/v2beta1/recurringruns/{recurring_run_id}
# operationId: RecurringRunService_GetRecurringRun
export def "apis-v2beta1-recurringruns GetRecurringRun" [
  recurring_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recurring_run_id: string, display_name: string, description: string, pipeline_version_id: string, pipeline_spec: record, pipeline_version_reference: record<pipeline_id: string, pipeline_version_id: string>, runtime_config: record<parameters: record, pipeline_root: string>, service_account: string, max_concurrency: string, trigger: record<cron_schedule: record<start_time: string, end_time: string, cron: string>, periodic_schedule: record<start_time: string, end_time: string, interval_second: string>>, mode: string, created_at: string, updated_at: string, status: string, error: record<code: int, message: string, details: list<record>>, no_catchup: bool, namespace: string, experiment_id: string, plugins_input: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/recurringruns/($recurring_run_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a recurring run.
#
# DELETE /apis/v2beta1/recurringruns/{recurring_run_id}
# operationId: RecurringRunService_DeleteRecurringRun
export def "apis-v2beta1-recurringruns DeleteRecurringRun" [
  recurring_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --propagation-policy: string@propagation-policy-completer # Optional input field. Set the propagation policy when deleting the recurring run. (default: DELETE_PROPAGATION_POLICY_UNSPECIFIED)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propagation_policy" $propagation_policy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apis/v2beta1/recurringruns/($recurring_run_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stops a recurring run and all its associated runs. The recurring run is not deleted.
#
# POST /apis/v2beta1/recurringruns/{recurring_run_id}:disable
# operationId: RecurringRunService_DisableRecurringRun
export def "apis-v2beta1-recurringruns DisableRecurringRun" [
  recurring_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/recurringruns/($recurring_run_id):disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restarts a recurring run that was previously stopped. All runs associated with the recurring run will continue.
#
# POST /apis/v2beta1/recurringruns/{recurring_run_id}:enable
# operationId: RecurringRunService_EnableRecurringRun
export def "apis-v2beta1-recurringruns EnableRecurringRun" [
  recurring_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/recurringruns/($recurring_run_id):enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /apis/v2beta1/scheduledworkflows
#
# operationId: ReportService_ReportScheduledWorkflow
export def "apis-v2beta1-scheduledworkflows ReportScheduledWorkflow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apis/v2beta1/scheduledworkflows")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /apis/v2beta1/workflows
#
# operationId: ReportService_ReportWorkflow
export def "apis-v2beta1-workflows ReportWorkflow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apis/v2beta1/workflows")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finds all runs in an experiment given by experiment ID. If experiment id is not specified, finds all runs across all experiments.
#
# GET /apis/v2beta1/runs
# operationId: RunService_ListRuns
export def "apis-v2beta1-runs ListRuns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # Optional input field. Filters based on the namespace.
  --experiment-id: string # The ID of the parent experiment. If empty, response includes runs across all experiments.
  --page-token: string # A page token to request the next page of results. The token is acquired from the nextPageToken field of the response from the previous ListRuns call or can be omitted when fetching the first page.
  --page-size: int # The number of runs to be listed per page. If there are more runs than this number, the response message will contain a nextPageToken field you can use to fetch the next page. (format: int32)
  --sort-by: string # Can be format of "field_name", "field_name asc" or "field_name desc" (Example, "name asc" or "id desc"). Ascending by default.
  --filter: string # A url-encoded, JSON-serialized Filter protocol buffer (see [filter.proto](https://github.com/kubeflow/pipelines/blob/master/backend/api/filter.proto)).
]: nothing -> record<runs: table<experiment_id: string, run_id: string, display_name: string, storage_state: string, description: string, pipeline_version_id: string, pipeline_spec: record, pipeline_version_reference: record, runtime_config: record, service_account: string, created_at: string, scheduled_at: string, finished_at: string, state: string, error: record, run_details: record, recurring_run_id: string, state_history: list, plugins_input: record, plugins_output: record>, total_size: int, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "experiment_id" $experiment_id "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apis/v2beta1/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new run in an experiment specified by experiment ID. If experiment ID is not specified, the run is created in the default experiment.
#
# POST /apis/v2beta1/runs
# operationId: RunService_CreateRun
# --pipeline_version_reference shape: {pipeline_id?: string, pipeline_version_id?: string}
# --runtime_config shape: {parameters?: record, pipeline_root?: string}
# --error shape: {code?: int, message?: string, details?: list}
# --run_details shape: {pipeline_context_id?: string, pipeline_run_context_id?: string, task_details?: list}
# --state_history item shape: {update_time?: string, state?: "RUNTIME_STATE_UNSPECIFIED"|"PENDING"|"RUNNING"|"SUCCEEDED"|"SKIPPED"|"FAILED"|"CANCELING"|"CANCELED"|"PAUSED", error?: record}
export def "apis-v2beta1-runs CreateRun" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --experiment-id: string # The ID of the parent experiment.
  --experiment-id: string # Input. ID of the parent experiment. The default experiment ID will be used if this is not specified.
  --run-id: string # Output. Unique run ID. Generated by API server.
  --display-name: string # Required input. Name provided by user, or auto generated if run is created by a recurring run.
  --storage-state: string@storage-state-completer # Describes whether an entity is available or archived.   - STORAGE_STATE_UNSPECIFIED: Default state. This state in not used  - AVAILABLE: Entity is available.  - ARCHIVED: Entity is archived. (default: STORAGE_STATE_UNSPECIFIED)
  --description: string # Optional input. Short description of the run.
  --pipeline-version-id: string # This field is Deprecated. The pipeline version id is under pipeline_version_reference for v2.
  --pipeline-spec: record # Pipeline spec.
  --pipeline-version-reference: record # Reference to an existing pipeline version. — shape: {pipeline_id?: string, pipeline_version_id?: string}
  --runtime-config: record # The runtime config. — shape: {parameters?: record, pipeline_root?: string}
  --service-account: string # Optional input. Specifies which kubernetes service account is used.
  --created-at: string # Output. Creation time of the run. (format: date-time)
  --scheduled-at: string # Output. When this run is scheduled to start. This could be different from created_at. For example, if a run is from a backfilling job that was supposed to run 2 month ago, the created_at will be 2 month behind scheduled_at. (format: date-time)
  --finished-at: string # Output. Completion of the run. (format: date-time)
  --state: string@state-completer # Describes the runtime state of an entity.   - RUNTIME_STATE_UNSPECIFIED: Default value. This value is not used.  - PENDING: Service is preparing to execute an entity.  - RUNNING: Entity execution is in progress.  - SUCCEEDED: Entity completed successfully.  - SKIPPED: Entity has been skipped. For example, due to caching.  - FAILED: Entity execution has failed.  - CANCELING: Entity is being canceled. From this state, an entity may only change its state to SUCCEEDED, FAILED or CANCELED.  - CANCELED: Entity has been canceled.  - PAUSED: Entity has been paused. It can be resumed. (default: RUNTIME_STATE_UNSPECIFIED)
  --body-error: record # The `Status` type defines a logical error model that is suitable for different programming environments, including REST APIs and RPC APIs. It is used by [gRPC](https://github.com/grpc). Each `Status` message contains three pieces of data: error code, error message, and error details.  You can find out more about this error model and how to work with it in the [API Design Guide](https://cloud.google.com/apis/design/errors). — shape: {code?: int, message?: string, details?: list}
  --run-details: record # Runtime details of a run. — shape: {pipeline_context_id?: string, pipeline_run_context_id?: string, task_details?: list}
  --recurring-run-id: string # ID of the recurring run that triggered this run.
  --state-history: list # Output. A sequence of run statuses. This field keeps a record of state transitions. — item shape: {update_time?: string, state?: "RUNTIME_STATE_UNSPECIFIED"|"PENDING"|"RUNNING"|"SUCCEEDED"|"SKIPPED"|"FAILED"|"CANCELING"|"CANCELED"|"PAUSED", error?: record}
  --plugins-input: record # Optional input. Plugin-specific inputs provided by the user at run creation. Each key is a plugin name (e.g., "mlflow") and the value is arbitrary JSON config.
  --plugins-output: record # Output. Plugin-specific outputs populated by backend components. Each key is a plugin name and the value contains the plugin's output entries and state.
]: any -> record<experiment_id: string, run_id: string, display_name: string, storage_state: string, description: string, pipeline_version_id: string, pipeline_spec: record, pipeline_version_reference: record<pipeline_id: string, pipeline_version_id: string>, runtime_config: record<parameters: record, pipeline_root: string>, service_account: string, created_at: string, scheduled_at: string, finished_at: string, state: string, error: record<code: int, message: string, details: list<record>>, run_details: record<pipeline_context_id: string, pipeline_run_context_id: string, task_details: list<record>>, recurring_run_id: string, state_history: table<update_time: string, state: string, error: record>, plugins_input: record, plugins_output: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "experiment_id" $experiment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apis/v2beta1/runs" $qp)
  let body = {experiment_id: $experiment_id, run_id: $run_id, display_name: $display_name, storage_state: $storage_state, description: $description, pipeline_version_id: $pipeline_version_id, pipeline_spec: $pipeline_spec, pipeline_version_reference: $pipeline_version_reference, runtime_config: $runtime_config, service_account: $service_account, created_at: $created_at, scheduled_at: $scheduled_at, finished_at: $finished_at, state: $state, error: $body_error, run_details: $run_details, recurring_run_id: $recurring_run_id, state_history: $state_history, plugins_input: $plugins_input, plugins_output: $plugins_output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Finds a specific run by ID.
#
# GET /apis/v2beta1/runs/{run_id}
# operationId: RunService_GetRun
export def "apis-v2beta1-runs GetRun" [
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --experiment-id: string # The ID of the parent experiment.
]: nothing -> record<experiment_id: string, run_id: string, display_name: string, storage_state: string, description: string, pipeline_version_id: string, pipeline_spec: record, pipeline_version_reference: record<pipeline_id: string, pipeline_version_id: string>, runtime_config: record<parameters: record, pipeline_root: string>, service_account: string, created_at: string, scheduled_at: string, finished_at: string, state: string, error: record<code: int, message: string, details: list<record>>, run_details: record<pipeline_context_id: string, pipeline_run_context_id: string, task_details: list<record>>, recurring_run_id: string, state_history: table<update_time: string, state: string, error: record>, plugins_input: record, plugins_output: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "experiment_id" $experiment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apis/v2beta1/runs/($run_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a run in an experiment given by run ID and experiment ID.
#
# DELETE /apis/v2beta1/runs/{run_id}
# operationId: RunService_DeleteRun
export def "apis-v2beta1-runs DeleteRun" [
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --experiment-id: string # The ID of the parent experiment.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "experiment_id" $experiment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apis/v2beta1/runs/($run_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archives a run in an experiment given by run ID and experiment ID.
#
# POST /apis/v2beta1/runs/{run_id}:archive
# operationId: RunService_ArchiveRun
export def "apis-v2beta1-runs ArchiveRun" [
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --experiment-id: string # The ID of the parent experiment.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "experiment_id" $experiment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apis/v2beta1/runs/($run_id):archive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Re-initiates a failed or terminated run.
#
# POST /apis/v2beta1/runs/{run_id}:retry
# operationId: RunService_RetryRun
export def "apis-v2beta1-runs RetryRun" [
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --experiment-id: string # The ID of the parent experiment.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "experiment_id" $experiment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apis/v2beta1/runs/($run_id):retry" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Terminates an active run.
#
# POST /apis/v2beta1/runs/{run_id}:terminate
# operationId: RunService_TerminateRun
export def "apis-v2beta1-runs TerminateRun" [
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --experiment-id: string # The ID of the parent experiment.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "experiment_id" $experiment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apis/v2beta1/runs/($run_id):terminate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restores an archived run in an experiment given by run ID and experiment ID.
#
# POST /apis/v2beta1/runs/{run_id}:unarchive
# operationId: RunService_UnarchiveRun
export def "apis-v2beta1-runs UnarchiveRun" [
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --experiment-id: string # The ID of the parent experiment.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "experiment_id" $experiment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apis/v2beta1/runs/($run_id):unarchive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /apis/v2beta1/visualizations/{namespace}
#
# operationId: VisualizationService_CreateVisualizationV1
export def "apis-v2beta1-visualizations CreateVisualizationV1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # Type of visualization to be generated. This is required when creating the pipeline through CreateVisualization API. (default: ROC_CURVE)
  --body-source: string # Path pattern of input data to be used during generation of visualizations. This is required when creating the pipeline through CreateVisualization API.
  --arguments: string # Variables to be used during generation of a visualization. This should be provided as a JSON string. This is required when creating the pipeline through CreateVisualization API.
  --html: string # Output. Generated visualization html.
  --body-error: string # In case any error happens when generating visualizations, only visualization ID and the error message are returned. Client has the flexibility of choosing how to handle the error.
]: any -> record<type: string, source: string, arguments: string, html: string, error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apis/v2beta1/visualizations/($namespace)")
  let body = {type: $type, source: $body_source, arguments: $arguments, html: $html, error: $body_error} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
